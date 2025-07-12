import { v4 as uuidv4 } from 'uuid';
import path from 'path';
import fs from 'fs/promises';

export interface AssessmentSession {
  id: string;
  userId: string;
  userName: string;
  tenantName: string;
  assessments: string[];
  status: 'pending' | 'running' | 'completed' | 'failed' | 'cancelled';
  startTime: Date;
  endTime?: Date;
  progress: {
    current: string;
    completed: string[];
    totalSteps: number;
    currentStep: number;
  };
  results?: {
    overallScore: number;
    issuesFound: number;
    recommendations: number;
    criticalFindings: number;
  };
  outputPath: string;
  error?: string;
}

class SessionManager {
  private sessions: Map<string, AssessmentSession> = new Map();
  private sessionsFile: string;

  constructor() {
    this.sessionsFile = path.join(process.cwd(), 'assessment-outputs', 'sessions.json');
    this.loadSessions();
  }

  private async loadSessions() {
    try {
      const data = await fs.readFile(this.sessionsFile, 'utf-8');
      const sessions = JSON.parse(data);
      
      // Restore sessions with proper Date objects
      Object.entries(sessions).forEach(([id, session]: [string, any]) => {
        session.startTime = new Date(session.startTime);
        if (session.endTime) {
          session.endTime = new Date(session.endTime);
        }
        this.sessions.set(id, session);
      });
    } catch (error) {
      // File doesn't exist yet or is invalid
      console.log('No existing sessions found, starting fresh');
    }
  }

  private async saveSessions() {
    try {
      const sessionsObj: Record<string, AssessmentSession> = {};
      this.sessions.forEach((session, id) => {
        sessionsObj[id] = session;
      });
      
      await fs.mkdir(path.dirname(this.sessionsFile), { recursive: true });
      await fs.writeFile(this.sessionsFile, JSON.stringify(sessionsObj, null, 2));
    } catch (error) {
      console.error('Failed to save sessions:', error);
    }
  }

  async createSession(
    userId: string,
    userName: string,
    tenantName: string,
    assessments: string[]
  ): Promise<AssessmentSession> {
    const sessionId = `session_${Date.now()}_${uuidv4().substring(0, 8)}`;
    const outputPath = path.join(process.cwd(), 'assessment-outputs', sessionId);

    const session: AssessmentSession = {
      id: sessionId,
      userId,
      userName,
      tenantName,
      assessments,
      status: 'pending',
      startTime: new Date(),
      progress: {
        current: '',
        completed: [],
        totalSteps: assessments.length,
        currentStep: 0
      },
      outputPath
    };

    // Create output directory
    await fs.mkdir(outputPath, { recursive: true });

    // Save session
    this.sessions.set(sessionId, session);
    await this.saveSessions();

    return session;
  }

  async updateSession(
    sessionId: string,
    updates: Partial<AssessmentSession>
  ): Promise<AssessmentSession | null> {
    const session = this.sessions.get(sessionId);
    if (!session) return null;

    // Update session
    Object.assign(session, updates);
    
    // Save changes
    await this.saveSessions();
    
    return session;
  }

  async updateProgress(
    sessionId: string,
    currentAssessment: string,
    completed?: boolean
  ): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) return;

    session.progress.current = currentAssessment;
    
    if (completed && !session.progress.completed.includes(currentAssessment)) {
      session.progress.completed.push(currentAssessment);
      session.progress.currentStep = session.progress.completed.length;
    }

    await this.saveSessions();
  }

  async completeSession(
    sessionId: string,
    results?: AssessmentSession['results']
  ): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) return;

    session.status = 'completed';
    session.endTime = new Date();
    if (results) {
      session.results = results;
    }

    await this.saveSessions();
  }

  async failSession(sessionId: string, error: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) return;

    session.status = 'failed';
    session.endTime = new Date();
    session.error = error;

    await this.saveSessions();
  }

  async cancelSession(sessionId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) return;

    session.status = 'cancelled';
    session.endTime = new Date();

    await this.saveSessions();
  }

  getSession(sessionId: string): AssessmentSession | undefined {
    return this.sessions.get(sessionId);
  }

  getUserSessions(userId: string): AssessmentSession[] {
    return Array.from(this.sessions.values())
      .filter(session => session.userId === userId)
      .sort((a, b) => b.startTime.getTime() - a.startTime.getTime());
  }

  getAllSessions(): AssessmentSession[] {
    return Array.from(this.sessions.values())
      .sort((a, b) => b.startTime.getTime() - a.startTime.getTime());
  }

  getActiveSessions(): AssessmentSession[] {
    return Array.from(this.sessions.values())
      .filter(session => session.status === 'running' || session.status === 'pending');
  }

  async cleanupOldSessions(daysToKeep: number = 30): Promise<number> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);
    
    let cleaned = 0;
    const sessionsToDelete: string[] = [];

    this.sessions.forEach((session, id) => {
      if (session.endTime && session.endTime < cutoffDate) {
        sessionsToDelete.push(id);
      }
    });

    // Delete sessions and their output directories
    for (const sessionId of sessionsToDelete) {
      const session = this.sessions.get(sessionId);
      if (session) {
        try {
          await fs.rm(session.outputPath, { recursive: true, force: true });
        } catch (error) {
          console.error(`Failed to delete output directory for session ${sessionId}:`, error);
        }
        this.sessions.delete(sessionId);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      await this.saveSessions();
    }

    return cleaned;
  }
}

// Export singleton instance
let sessionManager: SessionManager | null = null;

export function getSessionManager(): SessionManager {
  if (!sessionManager) {
    sessionManager = new SessionManager();
  }
  return sessionManager;
}

export { SessionManager };