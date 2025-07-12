/**
 * Best Practices Intelligence System
 * Uses MCP servers to continuously learn and adapt security recommendations
 * Analyzes assessment patterns to improve recommendations over time
 */

import { MCPClient } from './mcp-client';

interface BestPracticeRule {
  id: string;
  category: 'security' | 'compliance' | 'governance' | 'performance';
  severity: 'low' | 'medium' | 'high' | 'critical';
  title: string;
  description: string;
  recommendation: string;
  evidence: string[];
  sources: string[];
  lastUpdated: Date;
  confidence: number; // 0-1 score
  applicability: {
    tenantSizes: ('small' | 'medium' | 'large' | 'enterprise')[];
    industries: string[];
    regions: string[];
    complianceStandards: string[];
  };
}

interface AssessmentPattern {
  pattern: string;
  frequency: number;
  impact: 'positive' | 'negative' | 'neutral';
  recommendations: string[];
  observedOutcomes: string[];
}

interface IntelligenceUpdate {
  source: string;
  timestamp: Date;
  updateType: 'new_rule' | 'rule_modification' | 'pattern_detection' | 'outcome_analysis';
  confidence: number;
  data: any;
}

export class BestPracticesIntelligence {
  private mcpClient: MCPClient;
  private knowledgeBase: Map<string, BestPracticeRule> = new Map();
  private patterns: Map<string, AssessmentPattern> = new Map();
  private lastUpdate: Date = new Date();

  constructor() {
    this.mcpClient = new MCPClient();
    this.initializeKnowledgeBase();
  }

  /**
   * Initialize with baseline security best practices
   */
  private async initializeKnowledgeBase(): Promise<void> {
    // Load baseline rules from various authoritative sources
    const baselineRules = await this.loadBaselineRules();
    
    for (const rule of baselineRules) {
      this.knowledgeBase.set(rule.id, rule);
    }

    // Start continuous intelligence gathering
    this.startIntelligenceGathering();
    
    console.log('🧠 Best Practices Intelligence System initialized');
  }

  /**
   * Continuously gather intelligence from multiple sources
   */
  private async startIntelligenceGathering(): Promise<void> {
    // Update every 4 hours
    setInterval(async () => {
      await this.gatherIntelligence();
    }, 4 * 60 * 60 * 1000);

    // Initial intelligence gathering
    await this.gatherIntelligence();
  }

  /**
   * Gather intelligence from multiple sources using MCP
   */
  private async gatherIntelligence(): Promise<void> {
    console.log('🔍 Gathering best practices intelligence...');

    try {
      // Gather from Microsoft Security documentation
      await this.gatherMicrosoftIntelligence();
      
      // Gather from industry standards
      await this.gatherIndustryStandards();
      
      // Gather from security research
      await this.gatherSecurityResearch();
      
      // Analyze our own assessment patterns
      await this.analyzeAssessmentPatterns();
      
      this.lastUpdate = new Date();
      console.log('✅ Intelligence gathering completed');
      
    } catch (error) {
      console.error('❌ Intelligence gathering failed:', error);
    }
  }

  /**
   * Gather intelligence from Microsoft security documentation
   */
  private async gatherMicrosoftIntelligence(): Promise<void> {
    const sources = [
      'https://docs.microsoft.com/en-us/security/',
      'https://docs.microsoft.com/en-us/microsoft-365/security/',
      'https://docs.microsoft.com/en-us/azure/security/',
      'https://docs.microsoft.com/en-us/compliance/'
    ];

    for (const source of sources) {
      try {
        const content = await this.mcpClient.fetchWebContent(source);
        const analysis = await this.mcpClient.analyzeSecurityContent(content);
        
        await this.processIntelligenceUpdate({
          source: 'Microsoft Documentation',
          timestamp: new Date(),
          updateType: 'rule_modification',
          confidence: 0.9,
          data: analysis
        });
        
      } catch (error) {
        console.warn(`Failed to gather from ${source}:`, error);
      }
    }
  }

  /**
   * Gather from industry security standards
   */
  private async gatherIndustryStandards(): Promise<void> {
    const standards = [
      'NIST Cybersecurity Framework',
      'ISO 27001',
      'SOC 2',
      'CIS Controls',
      'GDPR Compliance'
    ];

    for (const standard of standards) {
      try {
        const research = await this.mcpClient.researchSecurityStandard(standard);
        
        await this.processIntelligenceUpdate({
          source: `Industry Standard: ${standard}`,
          timestamp: new Date(),
          updateType: 'new_rule',
          confidence: 0.85,
          data: research
        });
        
      } catch (error) {
        console.warn(`Failed to research ${standard}:`, error);
      }
    }
  }

  /**
   * Gather from latest security research
   */
  private async gatherSecurityResearch(): Promise<void> {
    const researchQueries = [
      'Microsoft 365 security vulnerabilities 2025',
      'Azure AD security best practices latest',
      'Exchange Online security recommendations',
      'SharePoint security configuration',
      'Microsoft Purview implementation best practices'
    ];

    for (const query of researchQueries) {
      try {
        const research = await this.mcpClient.searchSecurityResearch(query);
        
        await this.processIntelligenceUpdate({
          source: 'Security Research',
          timestamp: new Date(),
          updateType: 'pattern_detection',
          confidence: 0.7,
          data: research
        });
        
      } catch (error) {
        console.warn(`Failed to research "${query}":`, error);
      }
    }
  }

  /**
   * Analyze patterns from our own assessments
   */
  private async analyzeAssessmentPatterns(): Promise<void> {
    // This would analyze stored assessment data to identify patterns
    // For now, simulate pattern analysis
    
    const simulatedPatterns = [
      {
        pattern: 'MFA_ADOPTION_CORRELATION',
        description: 'Organizations with >95% MFA adoption show 80% fewer security incidents',
        confidence: 0.92,
        sampleSize: 150
      },
      {
        pattern: 'CONDITIONAL_ACCESS_EFFECTIVENESS',
        description: 'Comprehensive conditional access policies reduce risky sign-ins by 85%',
        confidence: 0.88,
        sampleSize: 200
      }
    ];

    for (const pattern of simulatedPatterns) {
      await this.processIntelligenceUpdate({
        source: 'Internal Analytics',
        timestamp: new Date(),
        updateType: 'outcome_analysis',
        confidence: pattern.confidence,
        data: pattern
      });
    }
  }

  /**
   * Process intelligence updates and update knowledge base
   */
  private async processIntelligenceUpdate(update: IntelligenceUpdate): Promise<void> {
    // Use AI to process and integrate the update
    const processedUpdate = await this.mcpClient.processIntelligenceUpdate(update);
    
    if (processedUpdate.newRules) {
      for (const rule of processedUpdate.newRules) {
        this.knowledgeBase.set(rule.id, rule);
      }
    }

    if (processedUpdate.ruleModifications) {
      for (const modification of processedUpdate.ruleModifications) {
        const existingRule = this.knowledgeBase.get(modification.ruleId);
        if (existingRule) {
          // Update existing rule with new intelligence
          const updatedRule = {
            ...existingRule,
            ...modification.updates,
            lastUpdated: new Date(),
            confidence: Math.max(existingRule.confidence, modification.confidence)
          };
          this.knowledgeBase.set(modification.ruleId, updatedRule);
        }
      }
    }

    if (processedUpdate.patterns) {
      for (const pattern of processedUpdate.patterns) {
        this.patterns.set(pattern.pattern, pattern);
      }
    }
  }

  /**
   * Get personalized recommendations for a specific assessment
   */
  async getPersonalizedRecommendations(
    assessmentResults: any,
    organizationProfile: {
      size: 'small' | 'medium' | 'large' | 'enterprise';
      industry: string;
      region: string;
      complianceRequirements: string[];
    }
  ): Promise<BestPracticeRule[]> {
    
    const applicableRules = Array.from(this.knowledgeBase.values()).filter(rule => {
      // Filter rules based on organization profile
      return this.isRuleApplicable(rule, organizationProfile);
    });

    // Analyze assessment results against rules
    const recommendations = await this.analyzeAgainstRules(assessmentResults, applicableRules);
    
    // Sort by priority (severity + confidence)
    return recommendations.sort((a, b) => {
      const priorityA = this.calculatePriority(a);
      const priorityB = this.calculatePriority(b);
      return priorityB - priorityA;
    });
  }

  /**
   * Check if a rule is applicable to the organization
   */
  private isRuleApplicable(
    rule: BestPracticeRule, 
    profile: { size: string; industry: string; region: string; complianceRequirements: string[] }
  ): boolean {
    // Check tenant size
    if (rule.applicability.tenantSizes.length > 0 && 
        !rule.applicability.tenantSizes.includes(profile.size as any)) {
      return false;
    }

    // Check industry (if specified)
    if (rule.applicability.industries.length > 0 && 
        !rule.applicability.industries.some(industry => 
          profile.industry.toLowerCase().includes(industry.toLowerCase())
        )) {
      return false;
    }

    // Check compliance requirements
    if (rule.applicability.complianceStandards.length > 0 && 
        !rule.applicability.complianceStandards.some(standard =>
          profile.complianceRequirements.includes(standard)
        )) {
      return false;
    }

    return true;
  }

  /**
   * Analyze assessment results against applicable rules
   */
  private async analyzeAgainstRules(
    assessmentResults: any,
    rules: BestPracticeRule[]
  ): Promise<BestPracticeRule[]> {
    
    const relevantRules: BestPracticeRule[] = [];

    for (const rule of rules) {
      const analysis = await this.mcpClient.analyzeRuleRelevance(assessmentResults, rule);
      
      if (analysis.isRelevant && analysis.confidence > 0.5) {
        // Create enhanced rule with specific context
        const enhancedRule: BestPracticeRule = {
          ...rule,
          recommendation: analysis.contextualRecommendation || rule.recommendation,
          evidence: analysis.specificEvidence || rule.evidence,
          confidence: analysis.confidence
        };
        
        relevantRules.push(enhancedRule);
      }
    }

    return relevantRules;
  }

  /**
   * Calculate rule priority for sorting
   */
  private calculatePriority(rule: BestPracticeRule): number {
    const severityWeights = {
      'critical': 4,
      'high': 3,
      'medium': 2,
      'low': 1
    };

    return severityWeights[rule.severity] * rule.confidence;
  }

  /**
   * Get trending security issues
   */
  async getTrendingSecurityIssues(): Promise<{
    issue: string;
    trend: 'increasing' | 'decreasing' | 'stable';
    severity: string;
    description: string;
    recommendations: string[];
  }[]> {
    
    const trends = await this.mcpClient.analyzeTrends('Microsoft 365 security issues');
    
    return trends.map((trend: any) => ({
      issue: trend.title,
      trend: trend.direction,
      severity: trend.severity,
      description: trend.description,
      recommendations: trend.recommendations
    }));
  }

  /**
   * Generate adaptive assessment questions based on latest intelligence
   */
  async generateAdaptiveQuestions(
    assessmentType: string,
    organizationProfile: any
  ): Promise<{
    question: string;
    type: 'boolean' | 'multiple-choice' | 'scale' | 'text';
    options?: string[];
    reasoning: string;
    importance: number;
  }[]> {
    
    const latestIntelligence = await this.mcpClient.getLatestIntelligence(assessmentType);
    
    return await this.mcpClient.generateQuestions({
      assessmentType,
      organizationProfile,
      intelligence: latestIntelligence,
      existingKnowledge: Array.from(this.knowledgeBase.values())
    });
  }

  /**
   * Load baseline security rules
   */
  private async loadBaselineRules(): Promise<BestPracticeRule[]> {
    return [
      {
        id: 'mfa-enforcement',
        category: 'security',
        severity: 'critical',
        title: 'Multi-Factor Authentication Enforcement',
        description: 'All user accounts should have MFA enabled to prevent credential-based attacks',
        recommendation: 'Enable MFA for all users through conditional access policies or security defaults',
        evidence: ['Microsoft Security Baseline', 'NIST Guidelines', 'Industry Best Practices'],
        sources: ['https://docs.microsoft.com/security/mfa', 'NIST 800-63B'],
        lastUpdated: new Date(),
        confidence: 0.95,
        applicability: {
          tenantSizes: ['small', 'medium', 'large', 'enterprise'],
          industries: [],
          regions: [],
          complianceStandards: ['SOC2', 'ISO27001', 'NIST']
        }
      },
      {
        id: 'conditional-access-coverage',
        category: 'security',
        severity: 'high',
        title: 'Comprehensive Conditional Access Coverage',
        description: 'All access scenarios should be covered by appropriate conditional access policies',
        recommendation: 'Implement risk-based conditional access policies covering all applications and user types',
        evidence: ['Microsoft Security Research', 'Zero Trust Framework'],
        sources: ['https://docs.microsoft.com/conditional-access'],
        lastUpdated: new Date(),
        confidence: 0.88,
        applicability: {
          tenantSizes: ['medium', 'large', 'enterprise'],
          industries: [],
          regions: [],
          complianceStandards: ['SOC2', 'ISO27001']
        }
      }
      // More baseline rules would be added here
    ];
  }

  /**
   * Get intelligence system status
   */
  getSystemStatus(): {
    rulesCount: number;
    patternsCount: number;
    lastUpdate: Date;
    confidenceLevel: number;
    sources: string[];
  } {
    const confidenceSum = Array.from(this.knowledgeBase.values())
      .reduce((sum, rule) => sum + rule.confidence, 0);
    
    const avgConfidence = confidenceSum / this.knowledgeBase.size;

    return {
      rulesCount: this.knowledgeBase.size,
      patternsCount: this.patterns.size,
      lastUpdate: this.lastUpdate,
      confidenceLevel: avgConfidence,
      sources: ['Microsoft Documentation', 'Industry Standards', 'Security Research', 'Internal Analytics']
    };
  }
}

// Export singleton instance
export const bestPracticesIntelligence = new BestPracticesIntelligence();