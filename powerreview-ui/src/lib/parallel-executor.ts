/**
 * Parallel Script Executor for PowerReview
 * Integrates with Sequential Thinking MCP for parallel script execution
 */

export interface ScriptTask {
  path: string;
  parameters?: Record<string, any>;
  priority?: number;
  dependencies?: string[];
}

export interface ExecutionResult {
  script: string;
  success: boolean;
  stdout?: string;
  stderr?: string;
  executionTime?: number;
  timestamp: number;
}

export interface AssessmentResult {
  assessmentType: string;
  totalScripts: number;
  executionTime: number;
  results: ExecutionResult[];
  success: boolean;
}

export class ParallelExecutor {
  private websocket: WebSocket | null = null;
  private executionQueue: Map<string, ScriptTask[]> = new Map();
  private activeExecutions: Map<string, AbortController> = new Map();
  
  constructor(private wsUrl: string = 'ws://localhost:3001/parallel-execution') {}
  
  /**
   * Connect to the parallel execution service
   */
  async connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.websocket = new WebSocket(this.wsUrl);
        
        this.websocket.onopen = () => {
          console.log('Connected to parallel execution service');
          resolve();
        };
        
        this.websocket.onerror = (error) => {
          console.error('WebSocket error:', error);
          reject(error);
        };
        
        this.websocket.onmessage = (event) => {
          this.handleMessage(JSON.parse(event.data));
        };
        
      } catch (error) {
        reject(error);
      }
    });
  }
  
  /**
   * Execute multiple scripts in parallel
   */
  async executeParallel(scripts: ScriptTask[]): Promise<ExecutionResult[]> {
    if (!this.websocket || this.websocket.readyState !== WebSocket.OPEN) {
      throw new Error('Not connected to parallel execution service');
    }
    
    const executionId = this.generateExecutionId();
    const abortController = new AbortController();
    this.activeExecutions.set(executionId, abortController);
    
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error('Execution timeout'));
        this.activeExecutions.delete(executionId);
      }, 300000); // 5 minute timeout
      
      // Group scripts by priority
      const priorityGroups = this.groupByPriority(scripts);
      const results: ExecutionResult[] = [];
      
      // Send execution request
      this.websocket!.send(JSON.stringify({
        method: 'execute_parallel',
        params: {
          executionId,
          scripts: scripts.map(s => ({
            path: s.path,
            parameters: s.parameters || {}
          }))
        }
      }));
      
      // Handle response
      const responseHandler = (event: MessageEvent) => {
        const data = JSON.parse(event.data);
        if (data.executionId === executionId) {
          if (data.type === 'result') {
            results.push(...data.results);
            if (results.length === scripts.length) {
              clearTimeout(timeout);
              this.activeExecutions.delete(executionId);
              this.websocket!.removeEventListener('message', responseHandler);
              resolve(results);
            }
          } else if (data.type === 'error') {
            clearTimeout(timeout);
            this.activeExecutions.delete(executionId);
            this.websocket!.removeEventListener('message', responseHandler);
            reject(new Error(data.error));
          }
        }
      };
      
      this.websocket!.addEventListener('message', responseHandler);
    });
  }
  
  /**
   * Run a complete assessment with optimized parallel execution
   */
  async runAssessment(
    assessmentType: 'full' | 'security' | 'compliance' | 'quick',
    parameters: Record<string, any> = {}
  ): Promise<AssessmentResult> {
    const scripts = this.getAssessmentScripts(assessmentType);
    const startTime = Date.now();
    
    // Execute scripts with priority-based parallelism
    const priorityGroups = this.groupByPriority(scripts);
    const allResults: ExecutionResult[] = [];
    
    for (const [priority, group] of priorityGroups) {
      const groupResults = await this.executeParallel(group);
      allResults.push(...groupResults);
      
      // Check if any critical scripts failed
      if (priority === 1 && groupResults.some(r => !r.success)) {
        console.warn('Critical scripts failed, stopping assessment');
        break;
      }
    }
    
    const executionTime = (Date.now() - startTime) / 1000;
    
    return {
      assessmentType,
      totalScripts: scripts.length,
      executionTime,
      results: allResults,
      success: allResults.every(r => r.success)
    };
  }
  
  /**
   * Get scripts for a specific assessment type
   */
  private getAssessmentScripts(assessmentType: string): ScriptTask[] {
    const scriptMap: Record<string, ScriptTask[]> = {
      full: [
        { path: 'PowerReview-AzureAD.ps1', priority: 1 },
        { path: 'PowerReview-Exchange.ps1', priority: 1 },
        { path: 'PowerReview-SharePoint.ps1', priority: 2 },
        { path: 'PowerReview-Teams.ps1', priority: 2 },
        { path: 'PowerReview-Defender.ps1', priority: 3 },
        { path: 'PowerReview-Compliance.ps1', priority: 3 },
        { path: 'PowerReview-Intune.ps1', priority: 3 }
      ],
      security: [
        { path: 'PowerReview-AzureAD.ps1', priority: 1 },
        { path: 'PowerReview-Defender.ps1', priority: 1 },
        { path: 'PowerReview-Exchange.ps1', priority: 2, dependencies: ['PowerReview-AzureAD.ps1'] }
      ],
      compliance: [
        { path: 'PowerReview-Compliance.ps1', priority: 1 },
        { path: 'PowerReview-SharePoint.ps1', priority: 2 },
        { path: 'PowerReview-Teams.ps1', priority: 2 }
      ],
      quick: [
        { path: 'PowerReview-AzureAD.ps1', priority: 1 },
        { path: 'PowerReview-Exchange.ps1', priority: 1 }
      ]
    };
    
    return scriptMap[assessmentType] || scriptMap.full;
  }
  
  /**
   * Group scripts by priority for staged execution
   */
  private groupByPriority(scripts: ScriptTask[]): Map<number, ScriptTask[]> {
    const groups = new Map<number, ScriptTask[]>();
    
    for (const script of scripts) {
      const priority = script.priority || 99;
      if (!groups.has(priority)) {
        groups.set(priority, []);
      }
      groups.get(priority)!.push(script);
    }
    
    // Sort by priority (lower number = higher priority)
    return new Map([...groups.entries()].sort((a, b) => a[0] - b[0]));
  }
  
  /**
   * Cancel an active execution
   */
  cancelExecution(executionId: string): void {
    const controller = this.activeExecutions.get(executionId);
    if (controller) {
      controller.abort();
      this.activeExecutions.delete(executionId);
    }
  }
  
  /**
   * Handle incoming WebSocket messages
   */
  private handleMessage(data: any): void {
    console.log('Received message:', data);
    // Additional message handling logic
  }
  
  /**
   * Generate unique execution ID
   */
  private generateExecutionId(): string {
    return `exec-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
  
  /**
   * Disconnect from the service
   */
  disconnect(): void {
    if (this.websocket) {
      this.websocket.close();
      this.websocket = null;
    }
    
    // Cancel all active executions
    for (const [id, controller] of this.activeExecutions) {
      controller.abort();
    }
    this.activeExecutions.clear();
  }
}

// Export singleton instance
export const parallelExecutor = new ParallelExecutor();