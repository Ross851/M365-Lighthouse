import { spawn, ChildProcess } from 'child_process';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';
import fs from 'fs/promises';
import { getWebSocketServer } from './websocket-server';
// Process management utilities

interface ExecutionOptions {
  sessionId: string;
  script: string;
  parameters?: Record<string, any>;
  workingDirectory?: string;
  timeout?: number; // milliseconds
  streamOutput?: boolean;
}

interface ExecutionResult {
  success: boolean;
  exitCode: number | null;
  stdout: string;
  stderr: string;
  duration: number;
  error?: string;
}

interface ActiveProcess {
  process: ChildProcess;
  sessionId: string;
  startTime: Date;
  timeout?: NodeJS.Timeout;
}

class PowerShellExecutor {
  private activeProcesses: Map<string, ActiveProcess> = new Map();
  private outputDir: string;
  private wsServer = getWebSocketServer();

  constructor() {
    this.outputDir = path.join(process.cwd(), 'assessment-outputs');
    this.ensureOutputDirectory();
  }

  private async ensureOutputDirectory() {
    try {
      await fs.mkdir(this.outputDir, { recursive: true });
    } catch (error) {
      console.error('Failed to create output directory:', error);
    }
  }

  async execute(options: ExecutionOptions): Promise<ExecutionResult> {
    const processId = uuidv4();
    const startTime = new Date();
    
    // Create session output directory
    const sessionDir = path.join(this.outputDir, options.sessionId);
    await fs.mkdir(sessionDir, { recursive: true });

    // Log file paths
    const logFile = path.join(sessionDir, 'execution.log');
    const errorFile = path.join(sessionDir, 'errors.log');
    const outputFile = path.join(sessionDir, 'output.json');

    // Build PowerShell command
    const psCommand = this.buildPowerShellCommand(options);
    
    // Send start notification
    this.sendUpdate(options.sessionId, {
      type: 'execution-started',
      processId,
      script: options.script,
      timestamp: startTime.toISOString()
    });

    return new Promise((resolve, reject) => {
      // Spawn PowerShell process
      const psProcess = spawn('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-Command', psCommand
      ], {
        cwd: options.workingDirectory || path.join(process.cwd(), '..'),
        env: {
          ...process.env,
          POWERREVIEW_SESSION_ID: options.sessionId,
          POWERREVIEW_OUTPUT_PATH: sessionDir
        }
      });

      // Store active process
      const activeProcess: ActiveProcess = {
        process: psProcess,
        sessionId: options.sessionId,
        startTime
      };

      // Set timeout if specified
      if (options.timeout) {
        activeProcess.timeout = setTimeout(() => {
          this.terminateProcess(processId, 'Execution timeout exceeded');
        }, options.timeout);
      }

      this.activeProcesses.set(processId, activeProcess);

      let stdout = '';
      let stderr = '';
      const logStream = fs.open(logFile, 'a');

      // Handle stdout
      psProcess.stdout.on('data', async (data: Buffer) => {
        const output = data.toString();
        stdout += output;

        // Write to log file
        const log = await logStream;
        await log.write(`[STDOUT] ${new Date().toISOString()}: ${output}`);

        // Parse and send real-time updates
        if (options.streamOutput) {
          this.parseAndSendUpdate(options.sessionId, output);
        }
      });

      // Handle stderr
      psProcess.stderr.on('data', async (data: Buffer) => {
        const error = data.toString();
        stderr += error;

        // Write to error file
        await fs.appendFile(errorFile, `[STDERR] ${new Date().toISOString()}: ${error}`);

        // Send error update
        this.sendUpdate(options.sessionId, {
          type: 'error',
          message: error,
          timestamp: new Date().toISOString()
        });
      });

      // Handle process exit
      psProcess.on('exit', async (code, signal) => {
        const endTime = new Date();
        const duration = endTime.getTime() - startTime.getTime();

        // Clear timeout if exists
        if (activeProcess.timeout) {
          clearTimeout(activeProcess.timeout);
        }

        // Remove from active processes
        this.activeProcesses.delete(processId);

        // Close log stream
        const log = await logStream;
        await log.close();

        // Save final output
        const result: ExecutionResult = {
          success: code === 0,
          exitCode: code,
          stdout,
          stderr,
          duration,
          error: signal ? `Process terminated by signal: ${signal}` : undefined
        };

        await fs.writeFile(outputFile, JSON.stringify(result, null, 2));

        // Send completion notification
        this.sendUpdate(options.sessionId, {
          type: 'execution-completed',
          processId,
          success: result.success,
          exitCode: code,
          duration,
          timestamp: endTime.toISOString()
        });

        if (code === 0) {
          resolve(result);
        } else {
          reject(new Error(`PowerShell process exited with code ${code}`));
        }
      });

      // Handle process errors
      psProcess.on('error', async (error) => {
        console.error('PowerShell process error:', error);
        
        // Clear timeout if exists
        if (activeProcess.timeout) {
          clearTimeout(activeProcess.timeout);
        }

        // Remove from active processes
        this.activeProcesses.delete(processId);

        // Send error notification
        this.sendUpdate(options.sessionId, {
          type: 'execution-error',
          processId,
          error: error.message,
          timestamp: new Date().toISOString()
        });

        reject(error);
      });
    });
  }

  private buildPowerShellCommand(options: ExecutionOptions): string {
    const scriptPath = path.join(process.cwd(), '..', options.script);
    let command = `& '${scriptPath}'`;

    // Add parameters
    if (options.parameters) {
      const params = Object.entries(options.parameters)
        .map(([key, value]) => {
          if (typeof value === 'string') {
            return `-${key} '${value.replace(/'/g, "''")}'`;
          } else if (typeof value === 'boolean') {
            return value ? `-${key}` : '';
          } else if (Array.isArray(value)) {
            return `-${key} @(${value.map(v => `'${v}'`).join(',')})`;
          } else {
            return `-${key} ${value}`;
          }
        })
        .filter(p => p)
        .join(' ');

      command += ` ${params}`;
    }

    // Add session ID and streaming flag
    command += ` -SessionId '${options.sessionId}' -StreamOutput`;

    return command;
  }

  private parseAndSendUpdate(sessionId: string, output: string) {
    // Parse PowerShell streaming output format
    const lines = output.split('\n');
    
    for (const line of lines) {
      if (line.startsWith('STREAM:')) {
        try {
          const data = JSON.parse(line.substring(7));
          this.sendUpdate(sessionId, data);
        } catch (error) {
          console.error('Failed to parse stream data:', error);
        }
      } else if (line.trim()) {
        // Send raw output as log
        this.sendUpdate(sessionId, {
          type: 'log',
          message: line,
          timestamp: new Date().toISOString()
        });
      }
    }
  }

  private sendUpdate(sessionId: string, data: any) {
    this.wsServer.sendToSession(sessionId, data);
  }

  async terminateProcess(processId: string, reason?: string): Promise<void> {
    const activeProcess = this.activeProcesses.get(processId);
    if (!activeProcess) return;

    console.log(`Terminating process ${processId}: ${reason || 'User requested'}`);

    // Send termination notice
    this.sendUpdate(activeProcess.sessionId, {
      type: 'execution-terminating',
      processId,
      reason,
      timestamp: new Date().toISOString()
    });

    // Kill process tree (including child processes)
    try {
      const pid = activeProcess.process.pid;
      if (pid) {
        if (process.platform === 'win32') {
          // Windows: use taskkill to kill process tree
          spawn('taskkill', ['/pid', pid.toString(), '/f', '/t']);
        } else {
          // Unix: kill process group
          process.kill(-pid, 'SIGTERM');
          
          // Give it time to clean up, then force kill if needed
          setTimeout(() => {
            try {
              process.kill(-pid, 'SIGKILL');
            } catch (e) {
              // Process already dead
            }
          }, 5000);
        }
      }
    } catch (error) {
      console.error('Error terminating process:', error);
      // Try direct kill as fallback
      activeProcess.process.kill('SIGKILL');
    }

    // Clear timeout if exists
    if (activeProcess.timeout) {
      clearTimeout(activeProcess.timeout);
    }

    // Remove from active processes
    this.activeProcesses.delete(processId);
  }

  async terminateSession(sessionId: string): Promise<void> {
    const processesToTerminate: string[] = [];

    // Find all processes for this session
    this.activeProcesses.forEach((process, processId) => {
      if (process.sessionId === sessionId) {
        processesToTerminate.push(processId);
      }
    });

    // Terminate all processes
    await Promise.all(
      processesToTerminate.map(processId => 
        this.terminateProcess(processId, 'Session terminated')
      )
    );
  }

  getActiveProcesses(): Array<{
    processId: string;
    sessionId: string;
    startTime: Date;
    duration: number;
  }> {
    const now = new Date();
    return Array.from(this.activeProcesses.entries()).map(([processId, process]) => ({
      processId,
      sessionId: process.sessionId,
      startTime: process.startTime,
      duration: now.getTime() - process.startTime.getTime()
    }));
  }
}

// Export singleton instance
let executor: PowerShellExecutor | null = null;

export function getPowerShellExecutor(): PowerShellExecutor {
  if (!executor) {
    executor = new PowerShellExecutor();
  }
  return executor;
}

export { PowerShellExecutor };