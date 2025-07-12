/**
 * Real-Time Compliance Monitoring System
 * Tracks compliance scores, detects violations, and sends instant alerts
 */

import { EventEmitter } from 'events';
import { WebSocket } from 'ws';

export interface ComplianceEvent {
  eventId: string;
  timestamp: Date;
  clientId: string;
  regionCode: string;
  eventType: 'violation' | 'warning' | 'resolved' | 'score_change' | 'policy_update';
  severity: 'critical' | 'high' | 'medium' | 'low' | 'info';
  category: string;
  title: string;
  description: string;
  impactedSystems?: string[];
  complianceStandard?: string;
  previousScore?: number;
  currentScore?: number;
  requiredScore?: number;
  metadata?: Record<string, any>;
}

export interface ComplianceMetrics {
  clientId: string;
  regionCode: string;
  overallScore: number;
  scores: {
    dataProtection: number;
    accessControl: number;
    encryption: number;
    auditLogging: number;
    incidentResponse: number;
    businessContinuity: number;
  };
  violations: number;
  warnings: number;
  lastUpdated: Date;
}

export interface ComplianceThreshold {
  metric: keyof ComplianceMetrics['scores'] | 'overallScore';
  criticalBelow: number;
  warningBelow: number;
  targetScore: number;
}

export interface MonitoringRule {
  ruleId: string;
  ruleName: string;
  description: string;
  enabled: boolean;
  checkInterval: number; // milliseconds
  conditions: {
    metric: string;
    operator: 'lt' | 'gt' | 'eq' | 'lte' | 'gte' | 'ne';
    value: number | string;
    duration?: number; // How long condition must persist
  }[];
  actions: {
    type: 'alert' | 'email' | 'webhook' | 'auto_remediate';
    config: Record<string, any>;
  }[];
}

export class ComplianceMonitoringService extends EventEmitter {
  private metrics = new Map<string, ComplianceMetrics>();
  private events: ComplianceEvent[] = [];
  private rules = new Map<string, MonitoringRule>();
  private activeViolations = new Map<string, ComplianceEvent>();
  private monitoringIntervals = new Map<string, NodeJS.Timeout>();
  private wsConnections = new Set<WebSocket>();
  
  // Default thresholds
  private thresholds: ComplianceThreshold[] = [
    { metric: 'overallScore', criticalBelow: 60, warningBelow: 80, targetScore: 90 },
    { metric: 'dataProtection', criticalBelow: 70, warningBelow: 85, targetScore: 95 },
    { metric: 'accessControl', criticalBelow: 70, warningBelow: 85, targetScore: 95 },
    { metric: 'encryption', criticalBelow: 80, warningBelow: 90, targetScore: 100 },
    { metric: 'auditLogging', criticalBelow: 60, warningBelow: 80, targetScore: 90 },
    { metric: 'incidentResponse', criticalBelow: 50, warningBelow: 70, targetScore: 85 },
    { metric: 'businessContinuity', criticalBelow: 60, warningBelow: 75, targetScore: 85 }
  ];

  constructor() {
    super();
    this.initializeDefaultRules();
  }

  /**
   * Initialize default monitoring rules
   */
  private initializeDefaultRules(): void {
    // Critical compliance score drop
    this.addRule({
      ruleId: 'critical-score-drop',
      ruleName: 'Critical Compliance Score Drop',
      description: 'Triggers when overall compliance score drops below critical threshold',
      enabled: true,
      checkInterval: 30000, // 30 seconds
      conditions: [
        { metric: 'overallScore', operator: 'lt', value: 60 }
      ],
      actions: [
        { type: 'alert', config: { priority: 'critical' } },
        { type: 'email', config: { template: 'critical-compliance' } }
      ]
    });

    // Data encryption compliance
    this.addRule({
      ruleId: 'encryption-compliance',
      ruleName: 'Encryption Compliance Check',
      description: 'Monitors encryption compliance across all regions',
      enabled: true,
      checkInterval: 60000, // 1 minute
      conditions: [
        { metric: 'encryption', operator: 'lt', value: 90, duration: 300000 } // 5 minutes
      ],
      actions: [
        { type: 'alert', config: { priority: 'high' } }
      ]
    });

    // Regional data residency violation
    this.addRule({
      ruleId: 'data-residency-violation',
      ruleName: 'Data Residency Violation Detection',
      description: 'Detects when data is stored outside permitted regions',
      enabled: true,
      checkInterval: 120000, // 2 minutes
      conditions: [
        { metric: 'dataResidencyCompliant', operator: 'eq', value: false }
      ],
      actions: [
        { type: 'alert', config: { priority: 'critical' } },
        { type: 'webhook', config: { url: '/api/compliance/violations' } }
      ]
    });

    // Access control anomaly
    this.addRule({
      ruleId: 'access-control-anomaly',
      ruleName: 'Access Control Anomaly Detection',
      description: 'Detects unusual access patterns or permission changes',
      enabled: true,
      checkInterval: 60000, // 1 minute
      conditions: [
        { metric: 'accessControl', operator: 'lt', value: 85 }
      ],
      actions: [
        { type: 'alert', config: { priority: 'medium' } }
      ]
    });

    // Audit log gaps
    this.addRule({
      ruleId: 'audit-log-gaps',
      ruleName: 'Audit Log Gap Detection',
      description: 'Identifies gaps in audit logging',
      enabled: true,
      checkInterval: 300000, // 5 minutes
      conditions: [
        { metric: 'auditLogging', operator: 'lt', value: 80, duration: 600000 } // 10 minutes
      ],
      actions: [
        { type: 'alert', config: { priority: 'high' } }
      ]
    });
  }

  /**
   * Start monitoring for a client in a specific region
   */
  startMonitoring(clientId: string, regionCode: string): void {
    const key = `${clientId}:${regionCode}`;
    
    // Initialize metrics if not exists
    if (!this.metrics.has(key)) {
      this.metrics.set(key, {
        clientId,
        regionCode,
        overallScore: 100,
        scores: {
          dataProtection: 100,
          accessControl: 100,
          encryption: 100,
          auditLogging: 100,
          incidentResponse: 100,
          businessContinuity: 100
        },
        violations: 0,
        warnings: 0,
        lastUpdated: new Date()
      });
    }

    // Start monitoring rules
    this.rules.forEach((rule, ruleId) => {
      if (!rule.enabled) return;
      
      const intervalKey = `${key}:${ruleId}`;
      if (this.monitoringIntervals.has(intervalKey)) {
        clearInterval(this.monitoringIntervals.get(intervalKey)!);
      }

      const interval = setInterval(() => {
        this.checkRule(clientId, regionCode, rule);
      }, rule.checkInterval);

      this.monitoringIntervals.set(intervalKey, interval);
    });

    console.log(`Started compliance monitoring for ${clientId} in ${regionCode}`);
  }

  /**
   * Stop monitoring for a client/region
   */
  stopMonitoring(clientId: string, regionCode: string): void {
    const key = `${clientId}:${regionCode}`;
    
    // Clear all intervals for this client/region
    this.monitoringIntervals.forEach((interval, intervalKey) => {
      if (intervalKey.startsWith(key)) {
        clearInterval(interval);
        this.monitoringIntervals.delete(intervalKey);
      }
    });

    console.log(`Stopped compliance monitoring for ${clientId} in ${regionCode}`);
  }

  /**
   * Update compliance metrics
   */
  updateMetrics(clientId: string, regionCode: string, updates: Partial<ComplianceMetrics>): void {
    const key = `${clientId}:${regionCode}`;
    const current = this.metrics.get(key);
    
    if (!current) {
      console.warn(`No metrics found for ${key}`);
      return;
    }

    const previous = { ...current };
    const updated: ComplianceMetrics = {
      ...current,
      ...updates,
      scores: {
        ...current.scores,
        ...(updates.scores || {})
      },
      lastUpdated: new Date()
    };

    // Calculate overall score
    const scores = Object.values(updated.scores);
    updated.overallScore = Math.round(scores.reduce((a, b) => a + b, 0) / scores.length);

    this.metrics.set(key, updated);

    // Check for significant changes
    this.detectChanges(previous, updated);

    // Broadcast update
    this.broadcastMetricsUpdate(updated);
  }

  /**
   * Detect significant changes in metrics
   */
  private detectChanges(previous: ComplianceMetrics, current: ComplianceMetrics): void {
    // Check overall score change
    if (Math.abs(previous.overallScore - current.overallScore) >= 5) {
      this.createEvent({
        clientId: current.clientId,
        regionCode: current.regionCode,
        eventType: 'score_change',
        severity: current.overallScore < previous.overallScore ? 'high' : 'info',
        category: 'compliance_score',
        title: `Compliance Score ${current.overallScore < previous.overallScore ? 'Decreased' : 'Increased'}`,
        description: `Overall compliance score changed from ${previous.overallScore}% to ${current.overallScore}%`,
        previousScore: previous.overallScore,
        currentScore: current.overallScore
      });
    }

    // Check each metric against thresholds
    this.thresholds.forEach(threshold => {
      const currentValue = threshold.metric === 'overallScore' 
        ? current.overallScore 
        : current.scores[threshold.metric as keyof typeof current.scores];
        
      const previousValue = threshold.metric === 'overallScore'
        ? previous.overallScore
        : previous.scores[threshold.metric as keyof typeof previous.scores];

      // Crossing critical threshold
      if (previousValue >= threshold.criticalBelow && currentValue < threshold.criticalBelow) {
        this.createEvent({
          clientId: current.clientId,
          regionCode: current.regionCode,
          eventType: 'violation',
          severity: 'critical',
          category: threshold.metric,
          title: `Critical ${this.formatMetricName(threshold.metric)} Violation`,
          description: `${this.formatMetricName(threshold.metric)} score dropped below critical threshold (${threshold.criticalBelow}%)`,
          previousScore: previousValue,
          currentScore: currentValue,
          requiredScore: threshold.criticalBelow
        });
        current.violations++;
      }
      // Crossing warning threshold
      else if (previousValue >= threshold.warningBelow && currentValue < threshold.warningBelow) {
        this.createEvent({
          clientId: current.clientId,
          regionCode: current.regionCode,
          eventType: 'warning',
          severity: 'medium',
          category: threshold.metric,
          title: `${this.formatMetricName(threshold.metric)} Warning`,
          description: `${this.formatMetricName(threshold.metric)} score dropped below warning threshold (${threshold.warningBelow}%)`,
          previousScore: previousValue,
          currentScore: currentValue,
          requiredScore: threshold.warningBelow
        });
        current.warnings++;
      }
      // Resolved violation
      else if (previousValue < threshold.warningBelow && currentValue >= threshold.targetScore) {
        this.createEvent({
          clientId: current.clientId,
          regionCode: current.regionCode,
          eventType: 'resolved',
          severity: 'info',
          category: threshold.metric,
          title: `${this.formatMetricName(threshold.metric)} Compliance Restored`,
          description: `${this.formatMetricName(threshold.metric)} score improved to target level`,
          previousScore: previousValue,
          currentScore: currentValue,
          requiredScore: threshold.targetScore
        });
        if (previousValue < threshold.criticalBelow) current.violations--;
        else current.warnings--;
      }
    });
  }

  /**
   * Check a monitoring rule
   */
  private async checkRule(clientId: string, regionCode: string, rule: MonitoringRule): Promise<void> {
    const key = `${clientId}:${regionCode}`;
    const metrics = this.metrics.get(key);
    
    if (!metrics) return;

    let conditionsMet = true;
    
    for (const condition of rule.conditions) {
      const value = this.getMetricValue(metrics, condition.metric);
      
      if (!this.evaluateCondition(value, condition.operator, condition.value)) {
        conditionsMet = false;
        break;
      }
    }

    if (conditionsMet) {
      // Execute rule actions
      for (const action of rule.actions) {
        await this.executeAction(clientId, regionCode, rule, action);
      }
    }
  }

  /**
   * Get metric value from metrics object
   */
  private getMetricValue(metrics: ComplianceMetrics, metricPath: string): any {
    const parts = metricPath.split('.');
    let value: any = metrics;
    
    for (const part of parts) {
      value = value[part];
      if (value === undefined) break;
    }
    
    return value;
  }

  /**
   * Evaluate a condition
   */
  private evaluateCondition(value: any, operator: string, target: any): boolean {
    switch (operator) {
      case 'lt': return value < target;
      case 'gt': return value > target;
      case 'eq': return value === target;
      case 'lte': return value <= target;
      case 'gte': return value >= target;
      case 'ne': return value !== target;
      default: return false;
    }
  }

  /**
   * Execute rule action
   */
  private async executeAction(
    clientId: string, 
    regionCode: string, 
    rule: MonitoringRule, 
    action: MonitoringRule['actions'][0]
  ): Promise<void> {
    switch (action.type) {
      case 'alert':
        this.createEvent({
          clientId,
          regionCode,
          eventType: 'violation',
          severity: action.config.priority || 'high',
          category: 'rule_violation',
          title: rule.ruleName,
          description: rule.description,
          metadata: { ruleId: rule.ruleId }
        });
        break;
        
      case 'email':
        // Email notification would be implemented here
        console.log(`Email alert: ${rule.ruleName} for ${clientId} in ${regionCode}`);
        break;
        
      case 'webhook':
        // Webhook call would be implemented here
        console.log(`Webhook triggered: ${action.config.url}`);
        break;
        
      case 'auto_remediate':
        // Auto-remediation logic would be implemented here
        console.log(`Auto-remediation attempted for ${rule.ruleName}`);
        break;
    }
  }

  /**
   * Create and broadcast compliance event
   */
  private createEvent(eventData: Omit<ComplianceEvent, 'eventId' | 'timestamp'>): void {
    const event: ComplianceEvent = {
      eventId: `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      timestamp: new Date(),
      ...eventData
    };

    this.events.push(event);
    
    // Keep only last 1000 events
    if (this.events.length > 1000) {
      this.events = this.events.slice(-1000);
    }

    // Track active violations
    if (event.eventType === 'violation') {
      this.activeViolations.set(`${event.clientId}:${event.category}`, event);
    } else if (event.eventType === 'resolved') {
      this.activeViolations.delete(`${event.clientId}:${event.category}`);
    }

    // Emit event
    this.emit('compliance-event', event);
    
    // Broadcast to WebSocket connections
    this.broadcastEvent(event);
  }

  /**
   * Broadcast event to WebSocket connections
   */
  private broadcastEvent(event: ComplianceEvent): void {
    const message = JSON.stringify({
      type: 'compliance-event',
      data: event
    });

    this.wsConnections.forEach(ws => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(message);
      }
    });
  }

  /**
   * Broadcast metrics update
   */
  private broadcastMetricsUpdate(metrics: ComplianceMetrics): void {
    const message = JSON.stringify({
      type: 'metrics-update',
      data: metrics
    });

    this.wsConnections.forEach(ws => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(message);
      }
    });
  }

  /**
   * Add WebSocket connection for real-time updates
   */
  addWebSocketConnection(ws: WebSocket): void {
    this.wsConnections.add(ws);
    
    ws.on('close', () => {
      this.wsConnections.delete(ws);
    });

    // Send current state
    const currentState = {
      metrics: Array.from(this.metrics.values()),
      activeViolations: Array.from(this.activeViolations.values()),
      recentEvents: this.events.slice(-50)
    };

    ws.send(JSON.stringify({
      type: 'initial-state',
      data: currentState
    }));
  }

  /**
   * Get compliance summary
   */
  getComplianceSummary(): {
    totalClients: number;
    averageScore: number;
    criticalViolations: number;
    activeWarnings: number;
    regionsMonitored: Set<string>;
    worstPerformers: Array<{ clientId: string; regionCode: string; score: number }>;
  } {
    const allMetrics = Array.from(this.metrics.values());
    const criticalViolations = Array.from(this.activeViolations.values())
      .filter(v => v.severity === 'critical').length;
    const activeWarnings = Array.from(this.activeViolations.values())
      .filter(v => v.severity === 'high' || v.severity === 'medium').length;

    const worstPerformers = allMetrics
      .sort((a, b) => a.overallScore - b.overallScore)
      .slice(0, 5)
      .map(m => ({
        clientId: m.clientId,
        regionCode: m.regionCode,
        score: m.overallScore
      }));

    const regionsMonitored = new Set(allMetrics.map(m => m.regionCode));

    return {
      totalClients: new Set(allMetrics.map(m => m.clientId)).size,
      averageScore: allMetrics.length > 0
        ? Math.round(allMetrics.reduce((sum, m) => sum + m.overallScore, 0) / allMetrics.length)
        : 0,
      criticalViolations,
      activeWarnings,
      regionsMonitored,
      worstPerformers
    };
  }

  /**
   * Get recent events
   */
  getRecentEvents(limit: number = 50, filters?: {
    clientId?: string;
    regionCode?: string;
    eventType?: ComplianceEvent['eventType'];
    severity?: ComplianceEvent['severity'];
  }): ComplianceEvent[] {
    let events = [...this.events].reverse();

    if (filters) {
      if (filters.clientId) {
        events = events.filter(e => e.clientId === filters.clientId);
      }
      if (filters.regionCode) {
        events = events.filter(e => e.regionCode === filters.regionCode);
      }
      if (filters.eventType) {
        events = events.filter(e => e.eventType === filters.eventType);
      }
      if (filters.severity) {
        events = events.filter(e => e.severity === filters.severity);
      }
    }

    return events.slice(0, limit);
  }

  /**
   * Add monitoring rule
   */
  addRule(rule: MonitoringRule): void {
    this.rules.set(rule.ruleId, rule);
  }

  /**
   * Update monitoring rule
   */
  updateRule(ruleId: string, updates: Partial<MonitoringRule>): void {
    const rule = this.rules.get(ruleId);
    if (rule) {
      this.rules.set(ruleId, { ...rule, ...updates });
    }
  }

  /**
   * Delete monitoring rule
   */
  deleteRule(ruleId: string): void {
    this.rules.delete(ruleId);
    
    // Clear any active intervals for this rule
    this.monitoringIntervals.forEach((interval, key) => {
      if (key.endsWith(`:${ruleId}`)) {
        clearInterval(interval);
        this.monitoringIntervals.delete(key);
      }
    });
  }

  /**
   * Format metric name for display
   */
  private formatMetricName(metric: string): string {
    return metric
      .replace(/([A-Z])/g, ' $1')
      .replace(/^./, str => str.toUpperCase())
      .trim();
  }

  /**
   * Simulate compliance changes for testing
   */
  simulateComplianceChanges(clientId: string, regionCode: string): void {
    const variations = [
      { metric: 'dataProtection', change: () => Math.random() * 20 - 10 },
      { metric: 'accessControl', change: () => Math.random() * 15 - 7.5 },
      { metric: 'encryption', change: () => Math.random() * 10 - 5 },
      { metric: 'auditLogging', change: () => Math.random() * 25 - 12.5 },
      { metric: 'incidentResponse', change: () => Math.random() * 30 - 15 },
      { metric: 'businessContinuity', change: () => Math.random() * 20 - 10 }
    ];

    setInterval(() => {
      const key = `${clientId}:${regionCode}`;
      const current = this.metrics.get(key);
      if (!current) return;

      const updates: Partial<ComplianceMetrics> = { scores: { ...current.scores } };
      
      // Randomly change 1-3 metrics
      const numChanges = Math.floor(Math.random() * 3) + 1;
      const selectedMetrics = variations
        .sort(() => Math.random() - 0.5)
        .slice(0, numChanges);

      selectedMetrics.forEach(({ metric, change }) => {
        const currentValue = updates.scores![metric as keyof typeof updates.scores];
        const newValue = Math.max(0, Math.min(100, currentValue + change()));
        updates.scores![metric as keyof typeof updates.scores] = Math.round(newValue);
      });

      this.updateMetrics(clientId, regionCode, updates);
    }, 10000); // Every 10 seconds
  }

  /**
   * Cleanup resources
   */
  cleanup(): void {
    // Clear all monitoring intervals
    this.monitoringIntervals.forEach(interval => clearInterval(interval));
    this.monitoringIntervals.clear();
    
    // Close WebSocket connections
    this.wsConnections.forEach(ws => ws.close());
    this.wsConnections.clear();
    
    // Clear data
    this.metrics.clear();
    this.events = [];
    this.activeViolations.clear();
  }
}

// Export singleton instance
export const complianceMonitoring = new ComplianceMonitoringService();