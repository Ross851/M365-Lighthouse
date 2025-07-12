/**
 * Security Configuration Manager
 * Centralized security configuration and policy management
 */

export interface SecurityConfiguration {
    configId: string;
    name: string;
    category: 'baseline' | 'enhanced' | 'enterprise' | 'custom';
    description: string;
    version: string;
    lastUpdated: Date;
    settings: SecuritySettings;
    compliance: ComplianceFramework[];
    riskLevel: 'low' | 'medium' | 'high' | 'critical';
    autoApply: boolean;
    enabled: boolean;
}

export interface SecuritySettings {
    identity: IdentitySettings;
    dataProtection: DataProtectionSettings;
    threatProtection: ThreatProtectionSettings;
    compliance: ComplianceSettings;
    monitoring: MonitoringSettings;
}

export interface IdentitySettings {
    mfaEnforcement: {
        enabled: boolean;
        enforceForAdmins: boolean;
        enforceForUsers: boolean;
        allowedMethods: string[];
        gracePeriodDays: number;
        exemptAccounts: string[];
    };
    conditionalAccess: {
        enabled: boolean;
        requireCompliantDevice: boolean;
        blockLegacyAuth: boolean;
        requireManagedApp: boolean;
        riskBasedAccess: boolean;
        locationBasedAccess: boolean;
        trustedLocations: string[];
    };
    privilegedAccess: {
        enablePIM: boolean;
        requireApproval: boolean;
        maxActivationHours: number;
        requireJustification: boolean;
        enableAccessReviews: boolean;
        reviewFrequencyDays: number;
    };
    passwordPolicy: {
        minimumLength: number;
        requireComplexity: boolean;
        passwordHistoryCount: number;
        maxPasswordAge: number;
        lockoutThreshold: number;
        lockoutDuration: number;
    };
}

export interface DataProtectionSettings {
    encryption: {
        enabled: boolean;
        encryptionStandard: string;
        keyRotationDays: number;
        encryptSharePoint: boolean;
        encryptExchange: boolean;
        encryptOneDrive: boolean;
        encryptTeams: boolean;
    };
    dlp: {
        enabled: boolean;
        protectPII: boolean;
        protectCreditCards: boolean;
        protectSSN: boolean;
        protectHealthRecords: boolean;
        blockExternalSharing: boolean;
        encryptSensitiveData: boolean;
        enableWatermarking: boolean;
        customPatterns: DLPPattern[];
    };
    informationProtection: {
        enableLabeling: boolean;
        autoClassification: boolean;
        mandatoryLabeling: boolean;
        defaultLabel: string;
        labels: InformationLabel[];
    };
    retention: {
        enabled: boolean;
        defaultRetentionPeriod: number;
        emailRetention: number;
        documentsRetention: number;
        teamsRetention: number;
        legalHoldEnabled: boolean;
    };
}

export interface ThreatProtectionSettings {
    defender: {
        enabled: boolean;
        safeAttachments: boolean;
        safeLinks: boolean;
        antiPhishing: boolean;
        antiMalware: boolean;
        realTimeProtection: boolean;
        quarantineSettings: QuarantineSettings;
    };
    casb: {
        enabled: boolean;
        appDiscovery: boolean;
        dataGovernance: boolean;
        threatProtection: boolean;
        complianceAssessment: boolean;
        connectedApps: string[];
    };
    endpointProtection: {
        enabled: boolean;
        requireCompliantDevices: boolean;
        deviceEncryption: boolean;
        mobileThreatDefense: boolean;
        jailbreakDetection: boolean;
        remoteWipe: boolean;
    };
}

export interface ComplianceSettings {
    frameworks: {
        gdpr: GDPRSettings;
        hipaa: HIPAASettings;
        sox: SOXSettings;
        pci: PCISettings;
        nist: NISTSettings;
        iso27001: ISO27001Settings;
    };
    auditing: {
        enabled: boolean;
        auditLogRetention: number;
        realTimeAlerting: boolean;
        complianceReporting: boolean;
        automatedAssessments: boolean;
        riskAssessmentFrequency: number;
    };
}

export interface MonitoringSettings {
    logging: {
        enabled: boolean;
        logLevel: 'info' | 'warning' | 'error' | 'critical';
        retentionPeriod: number;
        realTimeAnalysis: boolean;
        anomalyDetection: boolean;
        behavioralAnalytics: boolean;
    };
    alerting: {
        enabled: boolean;
        emailNotifications: boolean;
        smsNotifications: boolean;
        webhookNotifications: boolean;
        incidentAutoCreation: boolean;
        escalationRules: EscalationRule[];
    };
    reporting: {
        enabled: boolean;
        dailyReports: boolean;
        weeklyReports: boolean;
        monthlyReports: boolean;
        customReports: ReportTemplate[];
        dashboardRefreshInterval: number;
    };
}

export interface DLPPattern {
    id: string;
    name: string;
    pattern: string;
    confidence: number;
    enabled: boolean;
}

export interface InformationLabel {
    id: string;
    name: string;
    description: string;
    sensitivity: 'public' | 'internal' | 'confidential' | 'restricted';
    protectionSettings: LabelProtectionSettings;
}

export interface LabelProtectionSettings {
    encryption: boolean;
    watermarking: boolean;
    accessControl: boolean;
    expirationDays?: number;
    allowedUsers?: string[];
}

export interface QuarantineSettings {
    retentionPeriod: number;
    notifyUsers: boolean;
    allowUserRelease: boolean;
    adminNotification: boolean;
}

export interface ComplianceFramework {
    framework: string;
    version: string;
    requirements: ComplianceRequirement[];
    assessmentDate: Date;
    complianceScore: number;
    gaps: ComplianceGap[];
}

export interface ComplianceRequirement {
    id: string;
    description: string;
    status: 'compliant' | 'partial' | 'non-compliant';
    controls: string[];
    evidence: string[];
}

export interface ComplianceGap {
    requirementId: string;
    description: string;
    severity: 'low' | 'medium' | 'high' | 'critical';
    remediationSteps: string[];
    estimatedEffort: number;
    dueDate?: Date;
}

export interface GDPRSettings {
    enabled: boolean;
    dataSubjectRights: boolean;
    consentManagement: boolean;
    dataBreachNotification: boolean;
    dataProtectionImpactAssessment: boolean;
    privacyByDesign: boolean;
}

export interface HIPAASettings {
    enabled: boolean;
    accessControls: boolean;
    auditControls: boolean;
    integrity: boolean;
    transmission: boolean;
    minimumNecessary: boolean;
}

export interface SOXSettings {
    enabled: boolean;
    financialReporting: boolean;
    internalControls: boolean;
    dataIntegrity: boolean;
    accessManagement: boolean;
    changeManagement: boolean;
}

export interface PCISettings {
    enabled: boolean;
    networkSecurity: boolean;
    dataProtection: boolean;
    accessControl: boolean;
    monitoring: boolean;
    vulnerabilityManagement: boolean;
}

export interface NISTSettings {
    enabled: boolean;
    identify: boolean;
    protect: boolean;
    detect: boolean;
    respond: boolean;
    recover: boolean;
}

export interface ISO27001Settings {
    enabled: boolean;
    informationSecurityPolicy: boolean;
    riskManagement: boolean;
    assetManagement: boolean;
    humanResourceSecurity: boolean;
    physicalSecurity: boolean;
    incidentManagement: boolean;
}

export interface EscalationRule {
    id: string;
    name: string;
    triggerCondition: string;
    escalationLevel: number;
    recipients: string[];
    delayMinutes: number;
}

export interface ReportTemplate {
    id: string;
    name: string;
    description: string;
    frequency: 'daily' | 'weekly' | 'monthly' | 'quarterly';
    recipients: string[];
    sections: ReportSection[];
}

export interface ReportSection {
    id: string;
    name: string;
    type: 'chart' | 'table' | 'text' | 'metrics';
    dataSource: string;
    configuration: any;
}

export interface ConfigurationTemplate {
    templateId: string;
    name: string;
    description: string;
    category: 'baseline' | 'enhanced' | 'enterprise';
    targetEnvironment: 'small' | 'medium' | 'large' | 'enterprise';
    industryVertical: string[];
    configuration: SecurityConfiguration;
    prerequisites: string[];
    estimatedImplementationTime: number;
}

export class SecurityConfigurationManager {
    private configurations: Map<string, SecurityConfiguration> = new Map();
    private templates: Map<string, ConfigurationTemplate> = new Map();
    private activeConfig: SecurityConfiguration | null = null;

    constructor() {
        this.initializeDefaultConfigurations();
        this.initializeTemplates();
    }

    private initializeDefaultConfigurations() {
        // Baseline Security Configuration
        const baselineConfig: SecurityConfiguration = {
            configId: 'config_baseline',
            name: 'Baseline Security Configuration',
            category: 'baseline',
            description: 'Essential security controls for basic protection',
            version: '1.0',
            lastUpdated: new Date(),
            settings: this.createBaselineSettings(),
            compliance: [],
            riskLevel: 'medium',
            autoApply: false,
            enabled: true
        };

        // Enhanced Security Configuration
        const enhancedConfig: SecurityConfiguration = {
            configId: 'config_enhanced',
            name: 'Enhanced Security Configuration',
            category: 'enhanced',
            description: 'Advanced security controls for comprehensive protection',
            version: '1.0',
            lastUpdated: new Date(),
            settings: this.createEnhancedSettings(),
            compliance: [],
            riskLevel: 'low',
            autoApply: false,
            enabled: false
        };

        // Enterprise Security Configuration
        const enterpriseConfig: SecurityConfiguration = {
            configId: 'config_enterprise',
            name: 'Enterprise Security Configuration',
            category: 'enterprise',
            description: 'Maximum security controls for enterprise environments',
            version: '1.0',
            lastUpdated: new Date(),
            settings: this.createEnterpriseSettings(),
            compliance: [],
            riskLevel: 'low',
            autoApply: false,
            enabled: false
        };

        this.configurations.set(baselineConfig.configId, baselineConfig);
        this.configurations.set(enhancedConfig.configId, enhancedConfig);
        this.configurations.set(enterpriseConfig.configId, enterpriseConfig);
        
        this.activeConfig = baselineConfig;
    }

    private createBaselineSettings(): SecuritySettings {
        return {
            identity: {
                mfaEnforcement: {
                    enabled: true,
                    enforceForAdmins: true,
                    enforceForUsers: false,
                    allowedMethods: ['authenticator', 'sms'],
                    gracePeriodDays: 14,
                    exemptAccounts: []
                },
                conditionalAccess: {
                    enabled: true,
                    requireCompliantDevice: false,
                    blockLegacyAuth: true,
                    requireManagedApp: false,
                    riskBasedAccess: false,
                    locationBasedAccess: false,
                    trustedLocations: []
                },
                privilegedAccess: {
                    enablePIM: false,
                    requireApproval: false,
                    maxActivationHours: 8,
                    requireJustification: true,
                    enableAccessReviews: false,
                    reviewFrequencyDays: 90
                },
                passwordPolicy: {
                    minimumLength: 8,
                    requireComplexity: true,
                    passwordHistoryCount: 12,
                    maxPasswordAge: 90,
                    lockoutThreshold: 5,
                    lockoutDuration: 30
                }
            },
            dataProtection: {
                encryption: {
                    enabled: true,
                    encryptionStandard: 'AES-256',
                    keyRotationDays: 365,
                    encryptSharePoint: true,
                    encryptExchange: true,
                    encryptOneDrive: true,
                    encryptTeams: false
                },
                dlp: {
                    enabled: true,
                    protectPII: true,
                    protectCreditCards: true,
                    protectSSN: false,
                    protectHealthRecords: false,
                    blockExternalSharing: false,
                    encryptSensitiveData: false,
                    enableWatermarking: false,
                    customPatterns: []
                },
                informationProtection: {
                    enableLabeling: false,
                    autoClassification: false,
                    mandatoryLabeling: false,
                    defaultLabel: 'Internal',
                    labels: []
                },
                retention: {
                    enabled: true,
                    defaultRetentionPeriod: 2555, // 7 years
                    emailRetention: 2555,
                    documentsRetention: 2555,
                    teamsRetention: 365,
                    legalHoldEnabled: false
                }
            },
            threatProtection: {
                defender: {
                    enabled: true,
                    safeAttachments: true,
                    safeLinks: true,
                    antiPhishing: true,
                    antiMalware: true,
                    realTimeProtection: true,
                    quarantineSettings: {
                        retentionPeriod: 30,
                        notifyUsers: true,
                        allowUserRelease: false,
                        adminNotification: true
                    }
                },
                casb: {
                    enabled: false,
                    appDiscovery: false,
                    dataGovernance: false,
                    threatProtection: false,
                    complianceAssessment: false,
                    connectedApps: []
                },
                endpointProtection: {
                    enabled: true,
                    requireCompliantDevices: false,
                    deviceEncryption: true,
                    mobileThreatDefense: false,
                    jailbreakDetection: true,
                    remoteWipe: true
                }
            },
            compliance: {
                frameworks: {
                    gdpr: { enabled: false, dataSubjectRights: false, consentManagement: false, dataBreachNotification: false, dataProtectionImpactAssessment: false, privacyByDesign: false },
                    hipaa: { enabled: false, accessControls: false, auditControls: false, integrity: false, transmission: false, minimumNecessary: false },
                    sox: { enabled: false, financialReporting: false, internalControls: false, dataIntegrity: false, accessManagement: false, changeManagement: false },
                    pci: { enabled: false, networkSecurity: false, dataProtection: false, accessControl: false, monitoring: false, vulnerabilityManagement: false },
                    nist: { enabled: true, identify: true, protect: true, detect: true, respond: false, recover: false },
                    iso27001: { enabled: false, informationSecurityPolicy: false, riskManagement: false, assetManagement: false, humanResourceSecurity: false, physicalSecurity: false, incidentManagement: false }
                },
                auditing: {
                    enabled: true,
                    auditLogRetention: 365,
                    realTimeAlerting: false,
                    complianceReporting: true,
                    automatedAssessments: false,
                    riskAssessmentFrequency: 90
                }
            },
            monitoring: {
                logging: {
                    enabled: true,
                    logLevel: 'warning',
                    retentionPeriod: 90,
                    realTimeAnalysis: false,
                    anomalyDetection: false,
                    behavioralAnalytics: false
                },
                alerting: {
                    enabled: true,
                    emailNotifications: true,
                    smsNotifications: false,
                    webhookNotifications: false,
                    incidentAutoCreation: false,
                    escalationRules: []
                },
                reporting: {
                    enabled: true,
                    dailyReports: false,
                    weeklyReports: true,
                    monthlyReports: true,
                    customReports: [],
                    dashboardRefreshInterval: 3600 // 1 hour
                }
            }
        };
    }

    private createEnhancedSettings(): SecuritySettings {
        const baselineSettings = this.createBaselineSettings();
        
        // Enhanced settings build upon baseline with additional security
        return {
            ...baselineSettings,
            identity: {
                ...baselineSettings.identity,
                mfaEnforcement: {
                    ...baselineSettings.identity.mfaEnforcement,
                    enforceForUsers: true,
                    gracePeriodDays: 7
                },
                conditionalAccess: {
                    ...baselineSettings.identity.conditionalAccess,
                    requireCompliantDevice: true,
                    requireManagedApp: true,
                    riskBasedAccess: true,
                    locationBasedAccess: true
                },
                privilegedAccess: {
                    ...baselineSettings.identity.privilegedAccess,
                    enablePIM: true,
                    requireApproval: true,
                    enableAccessReviews: true,
                    reviewFrequencyDays: 30
                }
            },
            dataProtection: {
                ...baselineSettings.dataProtection,
                dlp: {
                    ...baselineSettings.dataProtection.dlp,
                    protectSSN: true,
                    blockExternalSharing: true,
                    encryptSensitiveData: true,
                    enableWatermarking: true
                },
                informationProtection: {
                    enableLabeling: true,
                    autoClassification: true,
                    mandatoryLabeling: true,
                    defaultLabel: 'Confidential',
                    labels: []
                },
                encryption: {
                    ...baselineSettings.dataProtection.encryption,
                    encryptTeams: true,
                    keyRotationDays: 90
                }
            },
            threatProtection: {
                ...baselineSettings.threatProtection,
                casb: {
                    enabled: true,
                    appDiscovery: true,
                    dataGovernance: true,
                    threatProtection: true,
                    complianceAssessment: true,
                    connectedApps: ['Microsoft 365', 'Salesforce', 'Box']
                },
                endpointProtection: {
                    ...baselineSettings.threatProtection.endpointProtection,
                    requireCompliantDevices: true,
                    mobileThreatDefense: true
                }
            },
            monitoring: {
                ...baselineSettings.monitoring,
                logging: {
                    ...baselineSettings.monitoring.logging,
                    logLevel: 'info',
                    realTimeAnalysis: true,
                    anomalyDetection: true,
                    behavioralAnalytics: true
                },
                alerting: {
                    ...baselineSettings.monitoring.alerting,
                    smsNotifications: true,
                    webhookNotifications: true,
                    incidentAutoCreation: true
                }
            }
        };
    }

    private createEnterpriseSettings(): SecuritySettings {
        const enhancedSettings = this.createEnhancedSettings();
        
        // Enterprise settings provide maximum security
        return {
            ...enhancedSettings,
            identity: {
                ...enhancedSettings.identity,
                mfaEnforcement: {
                    ...enhancedSettings.identity.mfaEnforcement,
                    allowedMethods: ['authenticator', 'hardware_token'],
                    gracePeriodDays: 0
                },
                passwordPolicy: {
                    ...enhancedSettings.identity.passwordPolicy,
                    minimumLength: 12,
                    maxPasswordAge: 60,
                    lockoutThreshold: 3,
                    lockoutDuration: 60
                }
            },
            dataProtection: {
                ...enhancedSettings.dataProtection,
                dlp: {
                    ...enhancedSettings.dataProtection.dlp,
                    protectHealthRecords: true
                },
                encryption: {
                    ...enhancedSettings.dataProtection.encryption,
                    keyRotationDays: 30
                },
                retention: {
                    ...enhancedSettings.dataProtection.retention,
                    legalHoldEnabled: true
                }
            },
            compliance: {
                frameworks: {
                    gdpr: { enabled: true, dataSubjectRights: true, consentManagement: true, dataBreachNotification: true, dataProtectionImpactAssessment: true, privacyByDesign: true },
                    hipaa: { enabled: true, accessControls: true, auditControls: true, integrity: true, transmission: true, minimumNecessary: true },
                    sox: { enabled: true, financialReporting: true, internalControls: true, dataIntegrity: true, accessManagement: true, changeManagement: true },
                    pci: { enabled: true, networkSecurity: true, dataProtection: true, accessControl: true, monitoring: true, vulnerabilityManagement: true },
                    nist: { enabled: true, identify: true, protect: true, detect: true, respond: true, recover: true },
                    iso27001: { enabled: true, informationSecurityPolicy: true, riskManagement: true, assetManagement: true, humanResourceSecurity: true, physicalSecurity: true, incidentManagement: true }
                },
                auditing: {
                    ...enhancedSettings.compliance.auditing,
                    realTimeAlerting: true,
                    automatedAssessments: true,
                    riskAssessmentFrequency: 30
                }
            },
            monitoring: {
                ...enhancedSettings.monitoring,
                reporting: {
                    ...enhancedSettings.monitoring.reporting,
                    dailyReports: true,
                    dashboardRefreshInterval: 900 // 15 minutes
                }
            }
        };
    }

    private initializeTemplates() {
        // Small Business Template
        const smallBusinessTemplate: ConfigurationTemplate = {
            templateId: 'template_small_business',
            name: 'Small Business Security Template',
            description: 'Cost-effective security for small businesses (1-50 users)',
            category: 'baseline',
            targetEnvironment: 'small',
            industryVertical: ['general', 'professional_services', 'retail'],
            configuration: this.configurations.get('config_baseline')!,
            prerequisites: ['Microsoft 365 Business Premium', 'Azure AD P1'],
            estimatedImplementationTime: 8 // hours
        };

        // Healthcare Template
        const healthcareTemplate: ConfigurationTemplate = {
            templateId: 'template_healthcare',
            name: 'Healthcare HIPAA Compliance Template',
            description: 'HIPAA-compliant security configuration for healthcare organizations',
            category: 'enterprise',
            targetEnvironment: 'medium',
            industryVertical: ['healthcare', 'pharmaceuticals'],
            configuration: this.createHealthcareConfiguration(),
            prerequisites: ['Microsoft 365 E5', 'Azure AD P2', 'Microsoft Defender for Office 365'],
            estimatedImplementationTime: 40 // hours
        };

        // Financial Services Template
        const financialTemplate: ConfigurationTemplate = {
            templateId: 'template_financial',
            name: 'Financial Services Compliance Template',
            description: 'SOX and PCI-DSS compliant configuration for financial organizations',
            category: 'enterprise',
            targetEnvironment: 'large',
            industryVertical: ['financial_services', 'banking', 'insurance'],
            configuration: this.createFinancialConfiguration(),
            prerequisites: ['Microsoft 365 E5', 'Azure AD P2', 'Microsoft Cloud App Security'],
            estimatedImplementationTime: 60 // hours
        };

        this.templates.set(smallBusinessTemplate.templateId, smallBusinessTemplate);
        this.templates.set(healthcareTemplate.templateId, healthcareTemplate);
        this.templates.set(financialTemplate.templateId, financialTemplate);
    }

    private createHealthcareConfiguration(): SecurityConfiguration {
        const enterpriseConfig = { ...this.configurations.get('config_enterprise')! };
        
        // Customize for healthcare
        enterpriseConfig.settings.compliance.frameworks.hipaa.enabled = true;
        enterpriseConfig.settings.dataProtection.dlp.protectHealthRecords = true;
        enterpriseConfig.settings.dataProtection.retention.legalHoldEnabled = true;
        
        return enterpriseConfig;
    }

    private createFinancialConfiguration(): SecurityConfiguration {
        const enterpriseConfig = { ...this.configurations.get('config_enterprise')! };
        
        // Customize for financial services
        enterpriseConfig.settings.compliance.frameworks.sox.enabled = true;
        enterpriseConfig.settings.compliance.frameworks.pci.enabled = true;
        enterpriseConfig.settings.dataProtection.dlp.protectCreditCards = true;
        enterpriseConfig.settings.identity.passwordPolicy.minimumLength = 14;
        
        return enterpriseConfig;
    }

    // Public API methods
    public getConfigurations(): SecurityConfiguration[] {
        return Array.from(this.configurations.values());
    }

    public getConfiguration(configId: string): SecurityConfiguration | undefined {
        return this.configurations.get(configId);
    }

    public getActiveConfiguration(): SecurityConfiguration | null {
        return this.activeConfig;
    }

    public setActiveConfiguration(configId: string): boolean {
        const config = this.configurations.get(configId);
        if (config) {
            this.activeConfig = config;
            config.enabled = true;
            
            // Disable other configurations
            this.configurations.forEach((cfg, id) => {
                if (id !== configId) {
                    cfg.enabled = false;
                }
            });
            
            return true;
        }
        return false;
    }

    public createCustomConfiguration(name: string, baseConfigId: string): SecurityConfiguration {
        const baseConfig = this.configurations.get(baseConfigId);
        if (!baseConfig) {
            throw new Error('Base configuration not found');
        }

        const customConfig: SecurityConfiguration = {
            configId: `config_custom_${Date.now()}`,
            name,
            category: 'custom',
            description: `Custom configuration based on ${baseConfig.name}`,
            version: '1.0',
            lastUpdated: new Date(),
            settings: JSON.parse(JSON.stringify(baseConfig.settings)), // Deep copy
            compliance: [],
            riskLevel: baseConfig.riskLevel,
            autoApply: false,
            enabled: false
        };

        this.configurations.set(customConfig.configId, customConfig);
        return customConfig;
    }

    public updateConfiguration(configId: string, updates: Partial<SecurityConfiguration>): boolean {
        const config = this.configurations.get(configId);
        if (!config) return false;

        Object.assign(config, updates, { 
            lastUpdated: new Date(),
            version: this.incrementVersion(config.version)
        });
        
        this.configurations.set(configId, config);
        return true;
    }

    public getTemplates(): ConfigurationTemplate[] {
        return Array.from(this.templates.values());
    }

    public getTemplate(templateId: string): ConfigurationTemplate | undefined {
        return this.templates.get(templateId);
    }

    public applyTemplate(templateId: string): SecurityConfiguration | null {
        const template = this.templates.get(templateId);
        if (!template) return null;

        const configId = `config_from_${templateId}_${Date.now()}`;
        const newConfig: SecurityConfiguration = {
            ...template.configuration,
            configId,
            name: `${template.name} - Applied ${new Date().toLocaleDateString()}`,
            lastUpdated: new Date()
        };

        this.configurations.set(configId, newConfig);
        return newConfig;
    }

    public validateConfiguration(configId: string): {
        isValid: boolean;
        warnings: string[];
        errors: string[];
        recommendations: string[];
    } {
        const config = this.configurations.get(configId);
        if (!config) {
            return {
                isValid: false,
                warnings: [],
                errors: ['Configuration not found'],
                recommendations: []
            };
        }

        const warnings: string[] = [];
        const errors: string[] = [];
        const recommendations: string[] = [];

        // Validate MFA settings
        if (!config.settings.identity.mfaEnforcement.enabled) {
            errors.push('MFA enforcement is disabled - this is a critical security risk');
        } else if (!config.settings.identity.mfaEnforcement.enforceForUsers) {
            warnings.push('MFA is not enforced for all users');
            recommendations.push('Enable MFA for all users to improve security posture');
        }

        // Validate data protection
        if (!config.settings.dataProtection.encryption.enabled) {
            errors.push('Data encryption is disabled');
        }

        if (!config.settings.dataProtection.dlp.enabled) {
            warnings.push('Data Loss Prevention is disabled');
            recommendations.push('Enable DLP to prevent data leakage');
        }

        // Validate threat protection
        if (!config.settings.threatProtection.defender.enabled) {
            errors.push('Microsoft Defender is disabled');
        }

        // Validate compliance frameworks
        const enabledFrameworks = Object.entries(config.settings.compliance.frameworks)
            .filter(([_, settings]) => (settings as any).enabled)
            .map(([name, _]) => name);
            
        if (enabledFrameworks.length === 0) {
            warnings.push('No compliance frameworks are enabled');
            recommendations.push('Enable relevant compliance frameworks for your industry');
        }

        return {
            isValid: errors.length === 0,
            warnings,
            errors,
            recommendations
        };
    }

    public generateConfigurationReport(configId: string): {
        configuration: SecurityConfiguration;
        validation: ReturnType<typeof this.validateConfiguration>;
        securityScore: number;
        complianceStatus: any;
        implementationPlan: any[];
    } {
        const config = this.configurations.get(configId);
        if (!config) {
            throw new Error('Configuration not found');
        }

        const validation = this.validateConfiguration(configId);
        const securityScore = this.calculateSecurityScore(config);
        const complianceStatus = this.assessComplianceStatus(config);
        const implementationPlan = this.generateImplementationPlan(config);

        return {
            configuration: config,
            validation,
            securityScore,
            complianceStatus,
            implementationPlan
        };
    }

    private incrementVersion(version: string): string {
        const parts = version.split('.');
        const patch = parseInt(parts[2] || '0') + 1;
        return `${parts[0]}.${parts[1]}.${patch}`;
    }

    private calculateSecurityScore(config: SecurityConfiguration): number {
        let score = 0;
        let maxScore = 0;

        // Identity security (30% weight)
        maxScore += 30;
        if (config.settings.identity.mfaEnforcement.enabled) {
            score += config.settings.identity.mfaEnforcement.enforceForUsers ? 25 : 15;
            score += config.settings.identity.mfaEnforcement.enforceForAdmins ? 5 : 0;
        }

        // Data protection (25% weight)
        maxScore += 25;
        if (config.settings.dataProtection.encryption.enabled) score += 10;
        if (config.settings.dataProtection.dlp.enabled) score += 10;
        if (config.settings.dataProtection.informationProtection.enableLabeling) score += 5;

        // Threat protection (25% weight)
        maxScore += 25;
        if (config.settings.threatProtection.defender.enabled) score += 15;
        if (config.settings.threatProtection.casb.enabled) score += 5;
        if (config.settings.threatProtection.endpointProtection.enabled) score += 5;

        // Monitoring (20% weight)
        maxScore += 20;
        if (config.settings.monitoring.logging.enabled) score += 10;
        if (config.settings.monitoring.alerting.enabled) score += 5;
        if (config.settings.monitoring.reporting.enabled) score += 5;

        return Math.round((score / maxScore) * 100);
    }

    private assessComplianceStatus(config: SecurityConfiguration): any {
        const frameworks = config.settings.compliance.frameworks;
        const status: any = {};

        Object.entries(frameworks).forEach(([name, settings]) => {
            const frameworkSettings = settings as any;
            if (frameworkSettings.enabled) {
                const enabledControls = Object.values(frameworkSettings).filter(Boolean).length - 1; // -1 for enabled flag
                const totalControls = Object.keys(frameworkSettings).length - 1;
                status[name] = {
                    enabled: true,
                    compliance: Math.round((enabledControls / totalControls) * 100),
                    enabledControls,
                    totalControls
                };
            } else {
                status[name] = {
                    enabled: false,
                    compliance: 0,
                    enabledControls: 0,
                    totalControls: Object.keys(frameworkSettings).length - 1
                };
            }
        });

        return status;
    }

    private generateImplementationPlan(config: SecurityConfiguration): any[] {
        const plan = [];
        const validation = this.validateConfiguration(config.configId);

        // Add high-priority items first
        if (validation.errors.length > 0) {
            plan.push({
                phase: 1,
                priority: 'critical',
                title: 'Fix Critical Security Issues',
                tasks: validation.errors,
                estimatedHours: validation.errors.length * 2
            });
        }

        if (validation.warnings.length > 0) {
            plan.push({
                phase: 2,
                priority: 'high',
                title: 'Address Security Warnings',
                tasks: validation.warnings,
                estimatedHours: validation.warnings.length * 1
            });
        }

        if (validation.recommendations.length > 0) {
            plan.push({
                phase: 3,
                priority: 'medium',
                title: 'Implement Recommendations',
                tasks: validation.recommendations,
                estimatedHours: validation.recommendations.length * 0.5
            });
        }

        return plan;
    }
}

// Initialize the security configuration manager
export const securityConfigManager = new SecurityConfigurationManager();