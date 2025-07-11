#Requires -Version 7.0

<#
.SYNOPSIS
    Electoral Commission Purview Implementation Discovery Questionnaire - Complete Template
.DESCRIPTION
    Comprehensive questionnaire based on Electoral Commission's discovery document
    Covers all aspects of Purview implementation including data classification, 
    compliance, retention, DLP, and information protection
.NOTES
    Version: 1.0
    Based on: Electoral Commission Purview Implementation Discovery
#>

# Load the base questionnaire module
. .\PowerReview-Discovery-Questionnaire.ps1

# Electoral Commission Specific Categories
$ECCategories = @{
    "OrganizationOverview" = @{
        Title = "Organization Overview"
        Description = "Understanding the organization's structure, operations, and data landscape"
        Icon = "🏢"
    }
    "DataClassificationLabeling" = @{
        Title = "Data Classification and Labeling"
        Description = "Current and desired data classification schemes and sensitivity labels"
        Icon = "🏷️"
    }
    "InformationProtection" = @{
        Title = "Information Protection"
        Description = "Data protection requirements including encryption and access controls"
        Icon = "🔐"
    }
    "DataLossPrevention" = @{
        Title = "Data Loss Prevention (DLP)"
        Description = "Requirements for preventing unauthorized data sharing and exfiltration"
        Icon = "🛡️"
    }
    "RecordsManagement" = @{
        Title = "Records Management"
        Description = "Document lifecycle, retention policies, and regulatory requirements"
        Icon = "📁"
    }
    "ComplianceSearch" = @{
        Title = "Compliance and eDiscovery"
        Description = "Legal holds, investigations, and compliance search requirements"
        Icon = "🔍"
    }
    "InsiderRisk" = @{
        Title = "Insider Risk Management"
        Description = "Monitoring and managing risks from internal threats"
        Icon = "👤"
    }
    "InformationBarriers" = @{
        Title = "Information Barriers"
        Description = "Requirements for restricting communication between groups"
        Icon = "🚧"
    }
    "DataLifecycle" = @{
        Title = "Data Lifecycle Management"
        Description = "Data retention, disposal, and archival requirements"
        Icon = "♻️"
    }
    "ComplianceManager" = @{
        Title = "Compliance Manager"
        Description = "Regulatory compliance tracking and management needs"
        Icon = "✅"
    }
    "AuditReporting" = @{
        Title = "Audit and Reporting"
        Description = "Audit log requirements and compliance reporting needs"
        Icon = "📊"
    }
    "Integration" = @{
        Title = "Integration and Migration"
        Description = "Third-party systems and migration requirements"
        Icon = "🔄"
    }
}

# Add Electoral Commission categories
foreach ($cat in $ECCategories.Keys) {
    $script:QuestionCategories[$cat] = $ECCategories[$cat]
}

# Electoral Commission Questions Database
$ECQuestions = @{
    "OrganizationOverview" = @(
        @{
            ID = "EC-OO-001"
            Question = "Provide an overview of your organization's primary functions and services"
            Type = "Text"
            Required = $true
            Hint = "Include core business functions, public services, and key stakeholder interactions"
            Tips = @(
                "Describe main organizational objectives",
                "List key services provided to the public",
                "Identify critical business processes"
            )
            Template = "Primary Functions:`n- [Function 1]`n- [Function 2]`n`nKey Services:`n- [Service 1]`n- [Service 2]`n`nStakeholders:`n- [Internal]: [Description]`n- [External]: [Description]"
        },
        @{
            ID = "EC-OO-002"
            Question = "How many employees and contractors access your systems?"
            Type = "Text"
            Required = $true
            Hint = "Break down by employee types and access levels"
            Tips = @(
                "Include full-time, part-time, and contractors",
                "Note different access level requirements",
                "Consider seasonal variations"
            )
            Template = "Full-time employees: [Number]`nPart-time employees: [Number]`nContractors: [Number]`nExternal partners with access: [Number]`n`nAccess Levels:`n- Admin users: [Number]`n- Standard users: [Number]`n- Guest users: [Number]"
        },
        @{
            ID = "EC-OO-003"
            Question = "What are your organization's main data types and their criticality?"
            Type = "Text"
            Required = $true
            Hint = "List data types from most to least critical"
            Tips = @(
                "Consider regulatory data, PII, financial data",
                "Think about electoral rolls, voting data",
                "Include internal operational data"
            )
            Template = "Critical Data:`n- Electoral Rolls: [Volume/Description]`n- Voting Records: [Volume/Description]`n- Financial Data: [Volume/Description]`n`nSensitive Data:`n- Personal Information: [Types]`n- Political Affiliations: [Description]`n`nOperational Data:`n- [Type]: [Description]"
        },
        @{
            ID = "EC-OO-004"
            Question = "Describe your current IT infrastructure and key systems"
            Type = "Text"
            Required = $true
            Hint = "Include on-premises, cloud, and hybrid components"
            Tips = @(
                "List major applications and databases",
                "Note any legacy systems",
                "Include cloud services in use"
            )
            Template = "On-Premises Systems:`n- [System]: [Purpose]`n`nCloud Services:`n- Microsoft 365: [Services used]`n- Azure: [Services used]`n- Other: [List]`n`nKey Applications:`n- [App]: [Purpose/Users]`n`nDatabases:`n- [DB]: [Type/Content]"
        }
    )
    "DataClassificationLabeling" = @(
        @{
            ID = "EC-DCL-001"
            Question = "Do you currently have a data classification scheme? If yes, please describe it"
            Type = "Text"
            Required = $true
            Hint = "Include classification levels, definitions, and how they're applied"
            Tips = @(
                "Common levels: Public, Internal, Confidential, Restricted",
                "Note if classifications are manually or automatically applied",
                "Describe any marking or labeling requirements"
            )
            Template = "Current Classification Levels:`n1. Public: [Definition]`n2. Internal Use: [Definition]`n3. Confidential: [Definition]`n4. Highly Confidential: [Definition]`n`nApplication Method:`n- Manual: [Process]`n- Automated: [Tools/Process]`n`nChallenges:`n- [List current challenges]"
        },
        @{
            ID = "EC-DCL-002"
            Question = "What are your requirements for sensitivity labels?"
            Type = "Text"
            Required = $true
            Hint = "Consider visual markings, protection settings, and user experience"
            Tips = @(
                "Think about headers, footers, watermarks",
                "Consider encryption requirements",
                "Note any co-authoring needs"
            )
            Template = "Visual Markings Required:`n- Headers: [Yes/No - Content]`n- Footers: [Yes/No - Content]`n- Watermarks: [Yes/No - Content]`n`nProtection Settings:`n- Encryption: [When required]`n- Access restrictions: [Requirements]`n`nUser Groups:`n- [Group]: [Label access needed]"
        },
        @{
            ID = "EC-DCL-003"
            Question = "How should automatic classification work in your environment?"
            Type = "Text"
            Required = $true
            Hint = "Describe triggers, conditions, and desired automation level"
            Tips = @(
                "Consider content inspection needs",
                "Think about default classifications",
                "Balance automation with user control"
            )
            Template = "Auto-classification Triggers:`n- Content patterns: [Examples]`n- File locations: [Paths/Sites]`n- Metadata: [Fields]`n`nConditions:`n- PII detection: [Requirements]`n- Keyword matching: [Examples]`n`nUser Override:`n- Allowed: [Yes/No - Conditions]`n- Justification required: [Yes/No]"
        },
        @{
            ID = "EC-DCL-004"
            Question = "What are your trainable classifier requirements?"
            Type = "Text"
            Required = $true
            Hint = "Identify document types that need custom classification models"
            Tips = @(
                "Think about unique document formats",
                "Consider forms, reports, correspondence",
                "Note volume of training data available"
            )
            Template = "Document Types for Custom Classifiers:`n- Electoral Forms: [Types/Volume]`n- Official Correspondence: [Types/Volume]`n- Reports: [Types/Volume]`n`nTraining Data Available:`n- [Document Type]: [Sample Count]`n`nAccuracy Requirements:`n- Target accuracy: [Percentage]`n- False positive tolerance: [Level]"
        }
    )
    "InformationProtection" = @(
        @{
            ID = "EC-IP-001"
            Question = "What are your encryption requirements for data at rest and in transit?"
            Type = "Text"
            Required = $true
            Hint = "Specify requirements for different data types and scenarios"
            Tips = @(
                "Consider regulatory encryption mandates",
                "Think about key management needs",
                "Note any legacy system constraints"
            )
            Template = "Data at Rest:`n- File shares: [Encryption required?]`n- Databases: [Encryption level]`n- Email: [Encryption requirement]`n`nData in Transit:`n- Internal networks: [Requirements]`n- External sharing: [Requirements]`n`nKey Management:`n- Who manages keys: [IT/Security/Other]`n- Key rotation: [Frequency]"
        },
        @{
            ID = "EC-IP-002"
            Question = "Describe your external sharing requirements and restrictions"
            Type = "Text"
            Required = $true
            Hint = "Include partner organizations, public sharing needs, and security requirements"
            Tips = @(
                "List trusted partner organizations",
                "Note any public information sharing needs",
                "Consider time-limited sharing requirements"
            )
            Template = "Allowed External Sharing:`n- Trusted partners: [List organizations]`n- Public sharing: [Allowed? Conditions?]`n- Anonymous links: [Allowed? Restrictions?]`n`nSharing Restrictions:`n- Domain whitelist: [Domains]`n- Expiration required: [Yes/No - Default]`n- Password protection: [Required?]`n`nContent Restrictions:`n- [Data Type]: [Can/Cannot share externally]"
        },
        @{
            ID = "EC-IP-003"
            Question = "What are your requirements for protecting emails and attachments?"
            Type = "Text"
            Required = $true
            Hint = "Consider encryption, forwarding restrictions, and expiration needs"
            Tips = @(
                "Think about Do Not Forward scenarios",
                "Consider reply-all restrictions",
                "Note any legal disclaimer requirements"
            )
            Template = "Email Protection Scenarios:`n- Confidential emails: [Protection needed]`n- Board communications: [Restrictions]`n- External communications: [Requirements]`n`nAttachment Handling:`n- Auto-protect attachments: [Yes/No]`n- Separate protection levels: [Needed?]`n`nRestrictions:`n- Forwarding: [Scenarios to block]`n- Printing: [When to restrict]`n- Copy/paste: [Restrictions needed]"
        },
        @{
            ID = "EC-IP-004"
            Question = "How should protection be applied to Microsoft Teams and SharePoint?"
            Type = "Text"
            Required = $true
            Hint = "Describe container-level protection needs"
            Tips = @(
                "Consider private channels vs standard channels",
                "Think about guest access requirements",
                "Note any compliance recording needs"
            )
            Template = "Teams Protection:`n- Private teams: [Default protection]`n- Public teams: [Restrictions]`n- Guest access: [Allowed? Conditions?]`n`nSharePoint Sites:`n- Departmental sites: [Protection level]`n- Project sites: [Requirements]`n- Public sites: [Restrictions]`n`nDefault Behaviors:`n- New sites/teams: [Auto-protection?]`n- Inheritance: [From parent/Custom]"
        }
    )
    "DataLossPrevention" = @(
        @{
            ID = "EC-DLP-001"
            Question = "What types of sensitive information must be prevented from unauthorized sharing?"
            Type = "Text"
            Required = $true
            Hint = "List specific data types and patterns that need DLP protection"
            Tips = @(
                "Include regulatory numbers (NI, passport, etc.)",
                "Consider internal ID formats",
                "Think about financial data patterns"
            )
            Template = "Government Identifiers:`n- National Insurance Numbers`n- Passport Numbers`n- Electoral Roll Numbers`n`nFinancial Information:`n- Credit Card Numbers`n- Bank Account Numbers`n- Budget Codes`n`nCustom Patterns:`n- Internal Reference Numbers: [Format]`n- Case Numbers: [Pattern]`n- Project Codes: [Format]"
        },
        @{
            ID = "EC-DLP-002"
            Question = "Describe your DLP policy requirements for different channels"
            Type = "Text"
            Required = $true
            Hint = "Specify how DLP should work across email, Teams, SharePoint, and endpoints"
            Tips = @(
                "Consider different rules for internal vs external",
                "Think about user notification needs",
                "Balance security with productivity"
            )
            Template = "Email DLP:`n- Internal emails: [Monitor/Warn/Block]`n- External emails: [Monitor/Warn/Block]`n- Bulk sending: [Thresholds]`n`nTeams/SharePoint:`n- File uploads: [Scanning requirements]`n- Chat/Channel posts: [Monitoring level]`n`nEndpoint DLP:`n- USB blocking: [Requirements]`n- Cloud storage: [Restrictions]`n- Printing: [Monitoring needs]"
        },
        @{
            ID = "EC-DLP-003"
            Question = "What should happen when DLP violations are detected?"
            Type = "Text"
            Required = $true
            Hint = "Describe actions, notifications, and override capabilities"
            Tips = @(
                "Consider severity levels",
                "Think about incident response process",
                "Note any executive override needs"
            )
            Template = "User Actions:`n- Low severity: [Warn/Log]`n- Medium severity: [Warn and justify]`n- High severity: [Block/Escalate]`n`nNotifications:`n- User notification: [Content/Tone]`n- Manager notification: [When?]`n- Security team: [All/High only]`n`nOverride Process:`n- Business justification: [Required fields]`n- Approval needed: [Manager/Security]`n- Time limit: [Override duration]"
        },
        @{
            ID = "EC-DLP-004"
            Question = "Are there specific regulatory requirements that DLP must address?"
            Type = "Text"
            Required = $true
            Hint = "List regulations and their specific DLP requirements"
            Tips = @(
                "Consider GDPR Article 32 requirements",
                "Think about electoral law requirements",
                "Note any freedom of information constraints"
            )
            Template = "Regulatory Requirements:`n- GDPR: [Specific articles/requirements]`n- Electoral Laws: [Data protection needs]`n- FOI Act: [Considerations]`n`nCompliance Evidence:`n- Audit trails: [What to capture]`n- Reporting: [Frequency/Format]`n- Retention: [How long to keep logs]"
        }
    )
    "RecordsManagement" = @(
        @{
            ID = "EC-RM-001"
            Question = "What are your records retention requirements by record type?"
            Type = "Text"
            Required = $true
            Hint = "List record types and their retention periods"
            Tips = @(
                "Include legal minimums and maximums",
                "Consider different rules for different jurisdictions",
                "Note any permanent retention needs"
            )
            Template = "Electoral Records:`n- Voter Registration: [Period]`n- Election Results: [Period]`n- Candidate Information: [Period]`n`nFinancial Records:`n- Invoices: [Period]`n- Budgets: [Period]`n- Expense Claims: [Period]`n`nAdministrative Records:`n- Meeting Minutes: [Period]`n- Correspondence: [Period]`n- Policies: [Period]`n`nPermanent Records:`n- [Type]: [Reason for permanent retention]"
        },
        @{
            ID = "EC-RM-002"
            Question = "How should disposition reviews and approvals work?"
            Type = "Text"
            Required = $true
            Hint = "Describe the process for reviewing and approving record deletion"
            Tips = @(
                "Consider multi-stage approval needs",
                "Think about exception handling",
                "Note any audit requirements"
            )
            Template = "Disposition Review Process:`n- Automatic review: [X days before expiry]`n- Reviewers: [Roles/Departments]`n- Approval stages: [Number and roles]`n`nException Process:`n- Legal holds: [How identified]`n- Business value: [Assessment criteria]`n- Extension approval: [Who can approve]`n`nDisposition Actions:`n- Delete: [Permanent/Recoverable]`n- Archive: [Where/How]`n- Transfer: [To whom/How]"
        },
        @{
            ID = "EC-RM-003"
            Question = "What are your requirements for record declaration?"
            Type = "Text"
            Required = $true
            Hint = "Describe how documents become official records"
            Tips = @(
                "Consider automatic vs manual declaration",
                "Think about metadata requirements",
                "Note any versioning needs"
            )
            Template = "Declaration Triggers:`n- Automatic: [Conditions/Events]`n- Manual: [Who can declare]`n- Bulk: [Allowed? Process?]`n`nRecord Metadata:`n- Required fields: [List]`n- Classification: [How determined]`n- Retention: [How assigned]`n`nRecord Protection:`n- Lock from editing: [Yes/No]`n- Prevent deletion: [Yes/No]`n- Version control: [Requirements]"
        },
        @{
            ID = "EC-RM-004"
            Question = "Describe your file plan structure and taxonomy requirements"
            Type = "Text"
            Required = $true
            Hint = "Include hierarchical structure and metadata schema"
            Tips = @(
                "Consider departmental vs functional structure",
                "Think about cross-references needs",
                "Note any existing classification schemes"
            )
            Template = "File Plan Structure:`n- Level 1: [Departments/Functions]`n- Level 2: [Categories]`n- Level 3: [Record types]`n`nMetadata Schema:`n- Department: [Values]`n- Record Type: [Values]`n- Retention Code: [Format]`n- Security Classification: [Values]`n`nNaming Conventions:`n- Files: [Pattern]`n- Folders: [Pattern]`n- Metadata tags: [Standards]"
        }
    )
    "ComplianceSearch" = @(
        @{
            ID = "EC-CS-001"
            Question = "What are your eDiscovery and legal hold requirements?"
            Type = "Text"
            Required = $true
            Hint = "Describe typical investigation scenarios and legal hold needs"
            Tips = @(
                "Consider FOI requests, investigations, litigation",
                "Think about hold notification requirements",
                "Note any cross-border considerations"
            )
            Template = "Common Scenarios:`n- FOI Requests: [Frequency/Types]`n- Internal Investigations: [Types]`n- Litigation: [Frequency/Types]`n`nLegal Hold Requirements:`n- Hold duration: [Typical/Maximum]`n- Custodian notification: [Required?]`n- Hold scope: [Email/Files/Teams]`n`nSearch Requirements:`n- Date ranges: [Typical span]`n- Data sources: [Which systems]`n- Export format: [PST/PDF/Native]"
        },
        @{
            ID = "EC-CS-002"
            Question = "Who should have access to compliance search capabilities?"
            Type = "Text"
            Required = $true
            Hint = "Define roles and permissions for different search scenarios"
            Tips = @(
                "Consider separation of duties",
                "Think about approval workflows",
                "Note any audit requirements"
            )
            Template = "Search Roles:`n- eDiscovery Managers: [Who/Department]`n- eDiscovery Analysts: [Who/Department]`n- Legal Hold Administrators: [Who]`n`nPermission Scope:`n- Full organization: [Who can search]`n- Department only: [Restrictions]`n- Self-search only: [Who]`n`nApproval Process:`n- Search approval: [Required? Who?]`n- Export approval: [Required? Who?]`n- Hold approval: [Required? Who?]"
        },
        @{
            ID = "EC-CS-003"
            Question = "What are your requirements for audit and activity logging?"
            Type = "Text"
            Required = $true
            Hint = "Describe what activities need to be logged and for how long"
            Tips = @(
                "Consider regulatory audit requirements",
                "Think about security monitoring needs",
                "Note any real-time alerting needs"
            )
            Template = "Activities to Log:`n- File access: [Which files/sites]`n- Email access: [Level of detail]`n- Admin activities: [All/Specific]`n- Search activities: [Who searched what]`n`nRetention Period:`n- Standard logs: [Duration]`n- Security logs: [Duration]`n- Compliance logs: [Duration]`n`nAlerting Requirements:`n- Real-time alerts: [Which activities]`n- Daily summaries: [To whom]`n- Weekly reports: [Content/Recipients]"
        },
        @{
            ID = "EC-CS-004"
            Question = "Describe your content search and export requirements"
            Type = "Text"
            Required = $true
            Hint = "Include search criteria, export formats, and handling procedures"
            Tips = @(
                "Consider search complexity needs",
                "Think about deduplication requirements",
                "Note any redaction needs"
            )
            Template = "Search Capabilities:`n- Boolean searches: [Required?]`n- Proximity searches: [Needed?]`n- Regular expressions: [Use cases]`n- Date ranges: [Precision needed]`n`nExport Requirements:`n- Format: [PST/EML/PDF/Native]`n- Deduplication: [Required?]`n- Metadata: [Include/Exclude]`n- Folder structure: [Preserve?]`n`nPost-Export:`n- Redaction: [Required? Tools?]`n- Review platform: [Which one?]`n- Chain of custody: [Process]"
        }
    )
    "InsiderRisk" = @(
        @{
            ID = "EC-IR-001"
            Question = "What insider risk scenarios are you most concerned about?"
            Type = "Text"
            Required = $true
            Hint = "Describe potential insider threats relevant to your organization"
            Tips = @(
                "Consider data theft, sabotage, policy violations",
                "Think about privileged user risks",
                "Note any past incidents"
            )
            Template = "Risk Scenarios:`n- Data exfiltration: [Sensitive data types at risk]`n- Sabotage: [Critical systems/data]`n- Policy violations: [Common violations]`n- Fraud: [Financial/Electoral]`n`nHigh-Risk Users:`n- Departing employees: [Access concerns]`n- Privileged users: [Admin risks]`n- Third parties: [Contractor risks]`n`nRisk Indicators:`n- Technical: [Unusual access patterns]`n- Behavioral: [HR/Performance issues]"
        },
        @{
            ID = "EC-IR-002"
            Question = "What data sources should be monitored for insider risks?"
            Type = "Text"
            Required = $true
            Hint = "List systems and data types to include in monitoring"
            Tips = @(
                "Balance privacy with security needs",
                "Consider legal constraints on monitoring",
                "Think about data correlation needs"
            )
            Template = "Microsoft 365 Sources:`n- Email: [Monitor attachments/forwards]`n- OneDrive: [Download patterns]`n- SharePoint: [Access to sensitive sites]`n- Teams: [Private messages/files]`n`nNon-M365 Sources:`n- HR systems: [Termination data]`n- Physical access: [Badge data]`n- Network logs: [VPN/Remote access]`n`nPrivacy Considerations:`n- Employee notification: [Required?]`n- Works council approval: [Needed?]`n- Monitoring scope: [Limitations]"
        },
        @{
            ID = "EC-IR-003"
            Question = "How should insider risk alerts be handled?"
            Type = "Text"
            Required = $true
            Hint = "Describe the investigation and response process"
            Tips = @(
                "Define escalation thresholds",
                "Consider false positive handling",
                "Note any union/legal requirements"
            )
            Template = "Alert Triage:`n- Low risk: [Response time/Action]`n- Medium risk: [Response time/Action]`n- High risk: [Immediate actions]`n`nInvestigation Process:`n- Initial review: [Who/How]`n- Evidence gathering: [Procedures]`n- Interview process: [When needed]`n`nResponse Actions:`n- Access suspension: [Approval needed]`n- Legal involvement: [When to engage]`n- HR coordination: [Process]`n`nDocumentation:`n- Case management: [System/Process]`n- Evidence retention: [Duration]"
        }
    )
    "InformationBarriers" = @(
        @{
            ID = "EC-IB-001"
            Question = "Do you have requirements to restrict communication between specific groups?"
            Type = "Text"
            Required = $true
            Hint = "Describe scenarios where groups must be kept separate"
            Tips = @(
                "Consider political party separation",
                "Think about contractor isolation",
                "Note any temporary barriers needed"
            )
            Template = "Separation Requirements:`n- Political parties: [During elections?]`n- Departments: [Which ones/Why]`n- External parties: [Contractors/Partners]`n`nCommunication Restrictions:`n- Email: [Block/Warn]`n- Teams chat: [Block/Warn]`n- File sharing: [Restrictions]`n- Meetings: [Can they meet?]`n`nExceptions:`n- Specific roles: [Who can communicate across]`n- Time-based: [Election periods only?]`n- Approval process: [For exceptions]"
        },
        @{
            ID = "EC-IB-002"
            Question = "How should information barrier segments be defined?"
            Type = "Text"
            Required = $true
            Hint = "Describe how to group users and what attributes to use"
            Tips = @(
                "Consider using existing AD attributes",
                "Think about dynamic vs static segments",
                "Note any complex scenarios"
            )
            Template = "Segment Definition:`n- By department: [Which attributes]`n- By role: [Job titles/Groups]`n- By project: [How to identify]`n- By time: [Temporary segments]`n`nUser Attributes:`n- Primary attribute: [Department/Title/Other]`n- Secondary attributes: [If needed]`n- Source system: [AD/HR/Manual]`n`nSegment Management:`n- Update frequency: [Daily/Weekly]`n- Change approval: [Who approves]`n- Testing process: [How to validate]"
        }
    )
    "DataLifecycle" = @(
        @{
            ID = "EC-DL-001"
            Question = "Describe your data lifecycle from creation to disposal"
            Type = "Text"
            Required = $true
            Hint = "Map out how data flows through your organization"
            Tips = @(
                "Consider all data creation points",
                "Think about data transformation",
                "Note any archival requirements"
            )
            Template = "Data Creation:`n- Sources: [Email/Forms/Documents/Database]`n- Initial classification: [How assigned]`n- Storage location: [Where created]`n`nData Usage:`n- Active period: [Typical duration]`n- Sharing/Distribution: [Internal/External]`n- Modifications: [Who can edit]`n`nData Archival:`n- Criteria: [Age/Last accessed]`n- Archive location: [Where]`n- Access requirements: [Who/How]`n`nData Disposal:`n- Triggers: [Age/Review/Event]`n- Method: [Delete/Shred/Archive]`n- Verification: [How confirmed]"
        },
        @{
            ID = "EC-DL-002"
            Question = "What are your data minimization requirements?"
            Type = "Text"
            Required = $true
            Hint = "Describe how you ensure only necessary data is collected and retained"
            Tips = @(
                "Consider GDPR minimization principles",
                "Think about regular data cleanup",
                "Note any ROT data issues"
            )
            Template = "Collection Minimization:`n- Data justification: [Process]`n- Consent management: [How tracked]`n- Purpose limitation: [Controls]`n`nStorage Minimization:`n- Duplicate detection: [Process]`n- ROT data: [How identified]`n- Cleanup frequency: [Schedule]`n`nRetention Minimization:`n- Regular reviews: [Frequency]`n- Early deletion: [Allowed?]`n- User requests: [Right to erasure]"
        },
        @{
            ID = "EC-DL-003"
            Question = "How do you handle data subject requests (GDPR/Privacy)?"
            Type = "Text"
            Required = $true
            Hint = "Describe processes for access, rectification, and erasure requests"
            Tips = @(
                "Consider request verification",
                "Think about search capabilities",
                "Note any exemptions"
            )
            Template = "Request Types:`n- Access requests: [Frequency/Process]`n- Rectification: [How handled]`n- Erasure: [Right to be forgotten]`n- Portability: [Format/Process]`n`nRequest Handling:`n- Verification: [Identity checks]`n- Search process: [Tools/Scope]`n- Response time: [Target days]`n- Exemptions: [What's excluded]`n`nCompliance Tracking:`n- Request logging: [System]`n- Performance metrics: [KPIs]`n- Audit trail: [Requirements]"
        }
    )
    "ComplianceManager" = @(
        @{
            ID = "EC-CM-001"
            Question = "Which compliance frameworks do you need to track?"
            Type = "Text"
            Required = $true
            Hint = "List all regulatory and voluntary frameworks"
            Tips = @(
                "Include international, national, and industry standards",
                "Consider upcoming regulations",
                "Note any certification requirements"
            )
            Template = "Mandatory Frameworks:`n- GDPR: [Specific requirements]`n- Electoral Laws: [Which ones]`n- Public Sector: [Requirements]`n- Cyber Essentials: [Level]`n`nVoluntary Standards:`n- ISO 27001: [Certified?]`n- ISO 9001: [Certified?]`n- NIST: [Which framework]`n`nUpcoming Requirements:`n- [Regulation]: [Timeline]`n- [Standard]: [Preparation needed]"
        },
        @{
            ID = "EC-CM-002"
            Question = "How do you currently track and evidence compliance?"
            Type = "Text"
            Required = $true
            Hint = "Describe current tools, processes, and challenges"
            Tips = @(
                "Be honest about manual processes",
                "Note any evidence gaps",
                "Consider audit findings"
            )
            Template = "Current Process:`n- Manual tracking: [Spreadsheets/Documents]`n- Evidence storage: [Where/How]`n- Review frequency: [Annual/Quarterly]`n`nChallenges:`n- Evidence collection: [Time/Effort]`n- Control mapping: [Difficulties]`n- Gap identification: [Process]`n`nAudit Support:`n- Internal audits: [Frequency]`n- External audits: [Who/When]`n- Findings tracking: [System]"
        },
        @{
            ID = "EC-CM-003"
            Question = "What are your control assessment requirements?"
            Type = "Text"
            Required = $true
            Hint = "Describe how controls should be tested and monitored"
            Tips = @(
                "Consider automated vs manual testing",
                "Think about continuous monitoring",
                "Note any risk-based approaches"
            )
            Template = "Assessment Types:`n- Self-assessment: [Frequency/Scope]`n- Independent testing: [Who/When]`n- Automated monitoring: [Which controls]`n`nControl Categories:`n- Technical controls: [Testing method]`n- Administrative: [Review process]`n- Physical: [Assessment approach]`n`nRisk Scoring:`n- Methodology: [How calculated]`n- Thresholds: [High/Medium/Low]`n- Remediation: [Timeframes]"
        }
    )
    "AuditReporting" = @(
        @{
            ID = "EC-AR-001"
            Question = "What are your audit log retention and search requirements?"
            Type = "Text"
            Required = $true
            Hint = "Specify retention periods and search capabilities needed"
            Tips = @(
                "Consider longest regulatory requirement",
                "Think about investigation scenarios",
                "Note any real-time monitoring needs"
            )
            Template = "Retention Requirements:`n- Standard logs: [Period]`n- Security events: [Period]`n- Compliance logs: [Period]`n- Legal hold: [Override process]`n`nSearch Requirements:`n- User activity: [By user/date/action]`n- Data access: [File/Site specific]`n- Admin actions: [Privileged events]`n- Bulk operations: [Mass downloads/deletes]`n`nExport Needs:`n- Format: [CSV/JSON/SIEM]`n- Automation: [API/Scheduled]`n- Integration: [SIEM tool]"
        },
        @{
            ID = "EC-AR-002"
            Question = "What compliance reports do you need to generate?"
            Type = "Text"
            Required = $true
            Hint = "List required reports, recipients, and frequency"
            Tips = @(
                "Include regulatory and internal reports",
                "Consider different audience needs",
                "Note any specific formats required"
            )
            Template = "Regulatory Reports:`n- GDPR compliance: [Monthly/Quarterly]`n- Data breaches: [As required]`n- Annual returns: [Content/Deadline]`n`nInternal Reports:`n- Executive dashboard: [KPIs/Frequency]`n- Department reports: [Metrics]`n- Incident reports: [Format/Distribution]`n`nExternal Reports:`n- Auditor reports: [Format/Content]`n- Public transparency: [What to publish]`n- Partner reports: [Sharing metrics]"
        },
        @{
            ID = "EC-AR-003"
            Question = "What key metrics and KPIs need to be tracked?"
            Type = "Text"
            Required = $true
            Hint = "Define success metrics and performance indicators"
            Tips = @(
                "Align with business objectives",
                "Consider trending requirements",
                "Note any SLA commitments"
            )
            Template = "Compliance Metrics:`n- Policy violations: [Target/Threshold]`n- Training completion: [Target %]`n- Assessment scores: [Minimum required]`n`nSecurity Metrics:`n- DLP incidents: [Acceptable rate]`n- Access reviews: [Completion %]`n- Incident response: [Time targets]`n`nOperational Metrics:`n- Classification coverage: [Target %]`n- Retention compliance: [Accuracy]`n- Search response time: [SLA]"
        }
    )
    "Integration" = @(
        @{
            ID = "EC-INT-001"
            Question = "What third-party systems need to integrate with Purview?"
            Type = "Text"
            Required = $true
            Hint = "List systems that need to share data or policies with Purview"
            Tips = @(
                "Consider HR, Finance, CRM systems",
                "Think about security tools",
                "Note any custom applications"
            )
            Template = "Business Systems:`n- HR System: [Name/Integration needs]`n- Finance: [Name/Data types]`n- CRM: [Name/Requirements]`n- Electoral Systems: [Custom apps]`n`nSecurity Tools:`n- SIEM: [Product/Integration type]`n- DLP: [Existing tool/Migration]`n- CASB: [Product/Overlap]`n`nIntegration Requirements:`n- Real-time sync: [Which systems]`n- Batch updates: [Frequency]`n- API access: [Read/Write needs]"
        },
        @{
            ID = "EC-INT-002"
            Question = "What data needs to be migrated from existing systems?"
            Type = "Text"
            Required = $true
            Hint = "Identify data, policies, and configurations to migrate"
            Tips = @(
                "Consider retention policies",
                "Think about classification labels",
                "Note any historical audit data"
            )
            Template = "Policies to Migrate:`n- DLP policies: [Count/Complexity]`n- Retention policies: [Count/Types]`n- Classification: [Existing scheme]`n`nData to Migrate:`n- Audit logs: [Years of history]`n- Legal holds: [Active holds]`n- Compliance records: [Volume]`n`nMigration Priorities:`n- Phase 1: [What/When]`n- Phase 2: [What/When]`n- Phase 3: [What/When]"
        },
        @{
            ID = "EC-INT-003"
            Question = "What are your API and automation requirements?"
            Type = "Text"
            Required = $true
            Hint = "Describe programmatic access needs and automation scenarios"
            Tips = @(
                "Consider reporting automation",
                "Think about workflow integration",
                "Note any custom development needs"
            )
            Template = "API Requirements:`n- Read access: [What data/Purpose]`n- Write access: [Updates needed]`n- Webhooks: [Event notifications]`n`nAutomation Scenarios:`n- Report generation: [Which reports]`n- Policy updates: [Triggers/Process]`n- User provisioning: [Integration]`n`nCustom Development:`n- PowerApps: [Use cases]`n- Power Automate: [Workflows]`n- Custom scripts: [Requirements]"
        }
    )
}

# Add all Electoral Commission questions to the database
foreach ($category in $ECQuestions.Keys) {
    if (-not $script:QuestionDatabase.ContainsKey($category)) {
        $script:QuestionDatabase[$category] = @()
    }
    $script:QuestionDatabase[$category] += $ECQuestions[$category]
}

# Electoral Commission specific helper functions
function Start-ElectoralCommissionQuestionnaire {
    param(
        [string]$OutputPath = ".\EC-Discovery-Results",
        [switch]$FullAssessment = $true,
        [switch]$QuickStart = $false
    )
    
    Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                 🏛️  ELECTORAL COMMISSION DISCOVERY QUESTIONNAIRE  🏛️           ║
║                                                                               ║
║                    Comprehensive Purview Implementation Assessment             ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

This questionnaire is based on the Electoral Commission's Purview Implementation
Discovery template and covers all aspects of Microsoft Purview deployment.

"@ -ForegroundColor Cyan
    
    $categories = if ($QuickStart) {
        @("OrganizationOverview", "DataClassificationLabeling", "ComplianceRequirements")
    } elseif ($FullAssessment) {
        $ECCategories.Keys
    } else {
        Show-CategorySelection
    }
    
    # Run the questionnaire
    $results = Start-DiscoveryQuestionnaire -OutputPath $OutputPath -Categories $categories
    
    # Generate EC-specific recommendations
    $recommendations = Get-ElectoralCommissionRecommendations -Results $results
    
    # Export recommendations
    $recPath = Join-Path $OutputPath "EC-Recommendations-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $recommendations | ConvertTo-Json -Depth 10 | Out-File -FilePath $recPath -Encoding UTF8
    
    Write-Host "`n✅ Electoral Commission assessment complete!" -ForegroundColor Green
    Write-Host "📁 Results saved to: $OutputPath" -ForegroundColor Cyan
    
    return @{
        Results = $results
        Recommendations = $recommendations
    }
}

function Get-ElectoralCommissionRecommendations {
    param(
        [hashtable]$Results
    )
    
    $recommendations = @{
        Priority1 = @()
        Priority2 = @()
        Priority3 = @()
        QuickWins = @()
        LongTerm = @()
    }
    
    # Analyze responses and generate recommendations
    
    # Data Classification recommendations
    if ($Results.Responses["EC-DCL-001"] -match "No|no classification") {
        $recommendations.Priority1 += @{
            Area = "Data Classification"
            Recommendation = "Implement comprehensive data classification scheme"
            Justification = "No existing classification scheme identified - this is foundational for all Purview features"
            BestPractice = "Start with 4 levels: Public, Internal, Confidential, Highly Confidential"
            Implementation = "Use Purview's built-in classification schema as starting point"
        }
    }
    
    # DLP recommendations
    if ($Results.Responses["EC-DLP-001"]) {
        $recommendations.Priority1 += @{
            Area = "Data Loss Prevention"
            Recommendation = "Deploy DLP policies for identified sensitive information types"
            Justification = "Critical data types identified that need protection"
            BestPractice = "Start in audit mode, then warn, then block"
            Implementation = "Create custom sensitive info types for Electoral Roll Numbers and internal identifiers"
        }
    }
    
    # Compliance recommendations
    if ($Results.Responses["EC-CM-001"] -match "GDPR") {
        $recommendations.Priority1 += @{
            Area = "Compliance"
            Recommendation = "Configure GDPR compliance features in Purview"
            Justification = "GDPR compliance is mandatory for processing EU citizen data"
            BestPractice = "Enable data subject request workflows and audit logging"
            Implementation = "Use Compliance Manager to track GDPR controls"
        }
    }
    
    # Quick wins
    if ($Results.Responses["EC-AR-001"]) {
        $recommendations.QuickWins += @{
            Area = "Audit Logging"
            Recommendation = "Enable unified audit logging immediately"
            Justification = "Audit logs need time to accumulate for investigations"
            BestPractice = "Enable all log types and set appropriate retention"
            Implementation = "PowerShell: Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true"
        }
    }
    
    return $recommendations
}

# Interactive tips system
function Show-DeveloperTips {
    param(
        [string]$Topic
    )
    
    $tips = @{
        "DataClassification" = @{
            Title = "Data Classification Tips for Developers"
            Tips = @(
                "Start by identifying the most sensitive data types in the organization",
                "Use automatic classification for structured data (databases, forms)",
                "Default classification levels should align with existing policies",
                "Test classification rules with a small pilot group first",
                "Consider user training needs - simpler is often better"
            )
            CommonPitfalls = @(
                "Over-complicated classification schemes (stick to 4-5 levels max)",
                "Not considering user workflow impact",
                "Forgetting about legacy data that needs classification"
            )
            UsefulCommands = @(
                "Get-LabelPolicy - View current label policies",
                "Get-Label - List all sensitivity labels",
                "Set-Label - Modify label properties"
            )
        }
        "DLP" = @{
            Title = "DLP Implementation Tips"
            Tips = @(
                "Always start DLP policies in test/audit mode",
                "Focus on highest risk data types first",
                "Use policy tips to educate users",
                "Consider false positive impact on productivity",
                "Plan for executive override scenarios"
            )
            CommonPitfalls = @(
                "Too aggressive blocking causing business disruption",
                "Not testing with real user scenarios",
                "Forgetting about encrypted files"
            )
            UsefulCommands = @(
                "Get-DlpCompliancePolicy - List DLP policies",
                "New-DlpComplianceRule - Create new DLP rule",
                "Test-DlpPolicies - Test policy matches"
            )
        }
    }
    
    if ($tips.ContainsKey($Topic)) {
        $topicTips = $tips[$Topic]
        Write-Host "`n💡 $($topicTips.Title)" -ForegroundColor Yellow
        Write-Host ("=" * 50) -ForegroundColor Yellow
        
        Write-Host "`n✅ Best Practices:" -ForegroundColor Green
        foreach ($tip in $topicTips.Tips) {
            Write-Host "   • $tip" -ForegroundColor White
        }
        
        Write-Host "`n⚠️  Common Pitfalls:" -ForegroundColor DarkYellow
        foreach ($pitfall in $topicTips.CommonPitfalls) {
            Write-Host "   • $pitfall" -ForegroundColor White
        }
        
        Write-Host "`n🔧 Useful Commands:" -ForegroundColor Cyan
        foreach ($cmd in $topicTips.UsefulCommands) {
            Write-Host "   📌 $cmd" -ForegroundColor White
        }
    }
}

# Export function for integration with PowerReview
function Export-ForPowerReview {
    param(
        [hashtable]$QuestionnaireResults,
        [string]$OutputPath = ".\PowerReview-Input"
    )
    
    $powerReviewConfig = @{
        Organization = $QuestionnaireResults.Results.Organization
        AssessmentConfig = @{
            Purview = @{
                Enabled = $true
                Priority = "High"
                DeepAnalysis = $true
                FocusAreas = @()
            }
        }
        DiscoveryResults = @{}
        Recommendations = @()
    }
    
    # Map questionnaire results to PowerReview configuration
    foreach ($category in $QuestionnaireResults.Results.Categories.Keys) {
        $powerReviewConfig.DiscoveryResults[$category] = $QuestionnaireResults.Results.Categories[$category]
    }
    
    # Set focus areas based on responses
    if ($QuestionnaireResults.Results.Responses["EC-DCL-001"] -match "No") {
        $powerReviewConfig.AssessmentConfig.Purview.FocusAreas += "DataClassification"
    }
    
    if ($QuestionnaireResults.Results.Responses["EC-DLP-001"]) {
        $powerReviewConfig.AssessmentConfig.Purview.FocusAreas += "DataLossPrevention"
    }
    
    # Include recommendations
    if ($QuestionnaireResults.Recommendations) {
        $powerReviewConfig.Recommendations = $QuestionnaireResults.Recommendations
    }
    
    # Export configuration
    $configPath = Join-Path $OutputPath "PowerReview-Config-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $powerReviewConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
    
    Write-Host "`n✅ PowerReview configuration exported to: $configPath" -ForegroundColor Green
    
    return $configPath
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host @"
Electoral Commission Purview Discovery Questionnaire Loaded!

This comprehensive questionnaire covers all aspects of Microsoft Purview implementation
based on the Electoral Commission's discovery template.

Quick Start Commands:
  • Start-ElectoralCommissionQuestionnaire -FullAssessment
  • Start-ElectoralCommissionQuestionnaire -QuickStart
  • Show-DeveloperTips "DataClassification"
  • Export-ForPowerReview -QuestionnaireResults `$results

The questionnaire includes:
  ✓ 12 comprehensive categories
  ✓ 50+ detailed questions with hints and tips
  ✓ Best practice recommendations
  ✓ Integration with PowerReview assessment

"@ -ForegroundColor Cyan
}