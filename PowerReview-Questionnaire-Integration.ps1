#Requires -Version 7.0

<#
.SYNOPSIS
    PowerReview Questionnaire Integration - Seamlessly integrates discovery questionnaires with PowerReview assessments
.DESCRIPTION
    Provides integration between discovery questionnaires and the main PowerReview assessment framework
.NOTES
    Version: 1.0
#>

# Load required modules
. .\PowerReview-Discovery-Questionnaire.ps1
. .\Electoral-Commission-Questionnaire.ps1

# Integration function for PowerReview
function Start-PowerReviewWithDiscovery {
    param(
        [switch]$RunQuestionnaire = $true,
        [string]$QuestionnaireResultsPath,
        [switch]$InteractiveMode = $true,
        [string]$OutputPath = ".\PowerReview-Results"
    )
    
    Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                     🚀 POWERREVIEW WITH DISCOVERY WIZARD 🚀                   ║
║                                                                               ║
║                 Complete M365 Assessment with Client Discovery                 ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    # Step 1: Run questionnaire if needed
    $questionnaireResults = $null
    if ($RunQuestionnaire) {
        Write-Host "`n📋 Step 1: Discovery Questionnaire" -ForegroundColor Yellow
        Write-Host "Let's gather information about your environment first." -ForegroundColor Gray
        
        $questionnaireChoice = Show-QuestionnaireMenu
        
        switch ($questionnaireChoice) {
            "1" { 
                # Basic PowerReview questionnaire
                $questionnaireResults = Start-DiscoveryQuestionnaire -Interactive:$InteractiveMode
            }
            "2" { 
                # Electoral Commission comprehensive
                $questionnaireResults = Start-ElectoralCommissionQuestionnaire -FullAssessment
            }
            "3" { 
                # Quick start version
                $questionnaireResults = Start-ElectoralCommissionQuestionnaire -QuickStart
            }
            "4" {
                # Custom questionnaire
                $customPath = Read-Host "Enter path to custom questionnaire JSON"
                Import-CustomQuestions -Path $customPath
                $questionnaireResults = Start-DiscoveryQuestionnaire -Interactive:$InteractiveMode
            }
        }
    }
    elseif ($QuestionnaireResultsPath) {
        # Load existing questionnaire results
        Write-Host "`n📂 Loading questionnaire results from: $QuestionnaireResultsPath" -ForegroundColor Cyan
        $questionnaireResults = Get-Content $QuestionnaireResultsPath -Raw | ConvertFrom-Json
    }
    
    # Step 2: Generate PowerReview configuration from questionnaire
    if ($questionnaireResults) {
        Write-Host "`n🔧 Step 2: Generating PowerReview Configuration" -ForegroundColor Yellow
        $powerReviewConfig = Convert-QuestionnaireToConfig -Results $questionnaireResults
        
        # Show configuration summary
        Show-ConfigurationSummary -Config $powerReviewConfig
        
        # Confirm before proceeding
        if ($InteractiveMode) {
            Write-Host "`nProceed with this configuration?" -ForegroundColor Yellow
            $confirm = Read-Host "[Y]es / [N]o / [E]dit"
            
            if ($confirm -eq 'E') {
                $powerReviewConfig = Edit-Configuration -Config $powerReviewConfig
            }
            elseif ($confirm -ne 'Y') {
                Write-Host "Assessment cancelled." -ForegroundColor Red
                return
            }
        }
    }
    else {
        # No questionnaire results - use default configuration
        Write-Host "`n⚠️  No questionnaire results available. Using default configuration." -ForegroundColor Yellow
        $powerReviewConfig = Get-DefaultConfiguration
    }
    
    # Step 3: Run PowerReview assessment
    Write-Host "`n🚀 Step 3: Running PowerReview Assessment" -ForegroundColor Yellow
    Write-Host "This may take several minutes depending on your environment size..." -ForegroundColor Gray
    
    # Load and run main PowerReview script
    . .\PowerReview-Enhanced-Framework.ps1
    
    $assessmentResults = Invoke-PowerReviewAssessment -Configuration $powerReviewConfig -OutputPath $OutputPath
    
    # Step 4: Generate integrated report
    Write-Host "`n📊 Step 4: Generating Integrated Report" -ForegroundColor Yellow
    
    $integratedReport = New-IntegratedReport -QuestionnaireResults $questionnaireResults -AssessmentResults $assessmentResults -OutputPath $OutputPath
    
    # Step 5: Show summary and next steps
    Show-AssessmentComplete -ReportPath $integratedReport -OutputPath $OutputPath
    
    return @{
        QuestionnaireResults = $questionnaireResults
        AssessmentResults = $assessmentResults
        ReportPath = $integratedReport
    }
}

# Show questionnaire menu
function Show-QuestionnaireMenu {
    Write-Host "`nSelect questionnaire type:" -ForegroundColor Cyan
    Write-Host "[1] Basic PowerReview Discovery (Quick)" -ForegroundColor Yellow
    Write-Host "[2] Electoral Commission Comprehensive (Full)" -ForegroundColor Yellow
    Write-Host "[3] Electoral Commission Quick Start" -ForegroundColor Yellow
    Write-Host "[4] Custom Questionnaire (JSON)" -ForegroundColor Yellow
    Write-Host "[S] Skip questionnaire" -ForegroundColor Gray
    
    $choice = Read-Host "`nYour choice"
    return $choice
}

# Convert questionnaire results to PowerReview configuration
function Convert-QuestionnaireToConfig {
    param(
        [Parameter(Mandatory=$true)]
        $Results
    )
    
    # Initialize configuration
    $config = @{
        Organization = $Results.Organization
        TenantId = ""
        ClientId = ""
        Modules = @{
            Purview = @{
                Enabled = $true
                Priority = "High"
                DeepAnalysis = $true
                FocusAreas = @()
                CustomSettings = @{}
            }
            PowerPlatform = @{
                Enabled = $true
                Priority = "Medium"
                AnalysisLevel = "Standard"
            }
            SharePoint = @{
                Enabled = $true
                Priority = "High"
                IncludeTeams = $true
                IncludeOneDrive = $true
            }
            Security = @{
                Enabled = $true
                Priority = "High"
                IncludeConditionalAccess = $true
                IncludeMFA = $true
            }
            AzureLandingZone = @{
                Enabled = $true
                Priority = "Medium"
                Subscriptions = @()
            }
        }
        ComplianceRequirements = @()
        DataTypes = @()
        OutputSettings = @{
            GenerateExecutiveSummary = $true
            GenerateTechnicalReport = $true
            GenerateComplianceReport = $true
            GenerateClientPortal = $true
        }
    }
    
    # Map responses to configuration
    
    # Compliance requirements
    if ($Results.Responses.ContainsKey("CR-001") -or $Results.Responses.ContainsKey("EC-CM-001")) {
        $complianceKey = if ($Results.Responses.ContainsKey("CR-001")) { "CR-001" } else { "EC-CM-001" }
        $config.ComplianceRequirements = $Results.Responses[$complianceKey]
        
        # Adjust priorities based on compliance
        if ($config.ComplianceRequirements -contains "GDPR") {
            $config.Modules.Purview.FocusAreas += "DataPrivacy"
            $config.Modules.Purview.CustomSettings["EnableSubjectRights"] = $true
        }
        if ($config.ComplianceRequirements -contains "HIPAA") {
            $config.Modules.Purview.FocusAreas += "HealthcareCompliance"
            $config.Modules.Security.Priority = "Critical"
        }
    }
    
    # Data types
    if ($Results.Responses.ContainsKey("DC-001") -or $Results.Responses.ContainsKey("EC-OO-003")) {
        $dataKey = if ($Results.Responses.ContainsKey("DC-001")) { "DC-001" } else { "EC-OO-003" }
        $config.DataTypes = $Results.Responses[$dataKey]
        
        if ($config.DataTypes -match "Financial") {
            $config.Modules.Purview.FocusAreas += "FinancialDataProtection"
        }
    }
    
    # Organization size affects analysis depth
    if ($Results.Responses.ContainsKey("GO-002") -or $Results.Responses.ContainsKey("EC-OO-002")) {
        $sizeKey = if ($Results.Responses.ContainsKey("GO-002")) { "GO-002" } else { "EC-OO-002" }
        $size = $Results.Responses[$sizeKey]
        
        if ($size -match "5000\+|1001-5000") {
            $config.Modules.PowerPlatform.Priority = "High"
            $config.Modules.PowerPlatform.AnalysisLevel = "Deep"
        }
    }
    
    # Data classification needs
    if ($Results.Responses.ContainsKey("DC-002") -or $Results.Responses.ContainsKey("EC-DCL-001")) {
        $classKey = if ($Results.Responses.ContainsKey("DC-002")) { "DC-002" } else { "EC-DCL-001" }
        if ($Results.Responses[$classKey] -match "No|no classification") {
            $config.Modules.Purview.FocusAreas += "DataClassification"
            $config.Modules.Purview.CustomSettings["ImplementClassificationScheme"] = $true
        }
    }
    
    # DLP requirements
    if ($Results.Responses.ContainsKey("SP-002") -or $Results.Responses.ContainsKey("EC-DLP-001")) {
        $config.Modules.Purview.FocusAreas += "DataLossPrevention"
        $config.Modules.Purview.CustomSettings["DLPPriority"] = "High"
    }
    
    # Records management
    if ($Results.Responses.ContainsKey("EC-RM-001")) {
        $config.Modules.Purview.FocusAreas += "RecordsManagement"
        $config.Modules.Purview.CustomSettings["RetentionPolicies"] = $true
    }
    
    # Azure subscriptions
    if ($Results.Responses.ContainsKey("TE-001")) {
        if ($Results.Responses["TE-001"] -contains "Azure Active Directory") {
            $config.Modules.AzureLandingZone.Enabled = $true
        }
    }
    
    return $config
}

# Show configuration summary
function Show-ConfigurationSummary {
    param($Config)
    
    Write-Host "`n📋 CONFIGURATION SUMMARY" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    
    Write-Host "`nOrganization: $($Config.Organization)" -ForegroundColor White
    
    Write-Host "`nModules to Assess:" -ForegroundColor Yellow
    foreach ($module in $Config.Modules.Keys) {
        if ($Config.Modules[$module].Enabled) {
            $priority = $Config.Modules[$module].Priority
            $priorityColor = switch ($priority) {
                "Critical" { "Red" }
                "High" { "Yellow" }
                "Medium" { "Cyan" }
                "Low" { "Gray" }
                default { "White" }
            }
            Write-Host "  ✓ $module (Priority: $priority)" -ForegroundColor $priorityColor
        }
    }
    
    if ($Config.ComplianceRequirements.Count -gt 0) {
        Write-Host "`nCompliance Requirements:" -ForegroundColor Yellow
        foreach ($req in $Config.ComplianceRequirements) {
            Write-Host "  • $req" -ForegroundColor White
        }
    }
    
    if ($Config.Modules.Purview.FocusAreas.Count -gt 0) {
        Write-Host "`nPurview Focus Areas:" -ForegroundColor Yellow
        foreach ($area in $Config.Modules.Purview.FocusAreas) {
            Write-Host "  • $area" -ForegroundColor White
        }
    }
}

# Edit configuration interactively
function Edit-Configuration {
    param($Config)
    
    # Simple configuration editor
    Write-Host "`n✏️  CONFIGURATION EDITOR" -ForegroundColor Cyan
    
    # Module toggles
    Write-Host "`nEnable/Disable Modules:" -ForegroundColor Yellow
    foreach ($module in $Config.Modules.Keys) {
        $current = if ($Config.Modules[$module].Enabled) { "Enabled" } else { "Disabled" }
        Write-Host "$module is currently: $current" -ForegroundColor Gray
        $change = Read-Host "Change? (Y/N)"
        if ($change -eq 'Y') {
            $Config.Modules[$module].Enabled = -not $Config.Modules[$module].Enabled
        }
    }
    
    # Priority adjustments
    Write-Host "`nAdjust Priorities:" -ForegroundColor Yellow
    foreach ($module in $Config.Modules.Keys) {
        if ($Config.Modules[$module].Enabled) {
            Write-Host "$module priority is: $($Config.Modules[$module].Priority)" -ForegroundColor Gray
            $newPriority = Read-Host "New priority (Critical/High/Medium/Low or Enter to keep)"
            if ($newPriority -in @("Critical", "High", "Medium", "Low")) {
                $Config.Modules[$module].Priority = $newPriority
            }
        }
    }
    
    return $Config
}

# Get default configuration
function Get-DefaultConfiguration {
    return @{
        Organization = "Default Organization"
        TenantId = ""
        ClientId = ""
        Modules = @{
            Purview = @{
                Enabled = $true
                Priority = "High"
                DeepAnalysis = $false
                FocusAreas = @()
            }
            PowerPlatform = @{
                Enabled = $true
                Priority = "Medium"
                AnalysisLevel = "Standard"
            }
            SharePoint = @{
                Enabled = $true
                Priority = "Medium"
                IncludeTeams = $true
                IncludeOneDrive = $true
            }
            Security = @{
                Enabled = $true
                Priority = "High"
                IncludeConditionalAccess = $true
                IncludeMFA = $true
            }
            AzureLandingZone = @{
                Enabled = $false
                Priority = "Low"
                Subscriptions = @()
            }
        }
        ComplianceRequirements = @()
        DataTypes = @()
        OutputSettings = @{
            GenerateExecutiveSummary = $true
            GenerateTechnicalReport = $true
            GenerateComplianceReport = $false
            GenerateClientPortal = $true
        }
    }
}

# Generate integrated report
function New-IntegratedReport {
    param(
        $QuestionnaireResults,
        $AssessmentResults,
        $OutputPath
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportPath = Join-Path $OutputPath "PowerReview-Integrated-Report-$timestamp.html"
    
    # Generate comprehensive HTML report combining questionnaire and assessment results
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>PowerReview Integrated Assessment Report</title>
    <style>
        /* Styles from client portal */
        body { font-family: 'Segoe UI', sans-serif; margin: 0; padding: 0; background: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #0078D4 0%, #40E0D0 100%); color: white; padding: 40px; border-radius: 10px; margin-bottom: 30px; }
        .section { background: white; padding: 30px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric-card { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; }
        .finding { margin: 15px 0; padding: 20px; border-left: 4px solid #0078D4; background: #f8f9fa; }
        .critical { border-left-color: #dc3545; }
        .high { border-left-color: #fd7e14; }
        .medium { border-left-color: #ffc107; }
        .low { border-left-color: #28a745; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 PowerReview Integrated Assessment Report</h1>
            <p>Organization: $($QuestionnaireResults.Organization ?? 'N/A')</p>
            <p>Assessment Date: $(Get-Date -Format 'MMMM dd, yyyy')</p>
        </div>
"@
    
    # Add discovery summary if available
    if ($QuestionnaireResults) {
        $html += @"
        <div class="section">
            <h2>📋 Discovery Summary</h2>
            <div class="metric-grid">
                <div class="metric-card">
                    <h3>Questions Answered</h3>
                    <p style="font-size: 2em; font-weight: bold;">$($QuestionnaireResults.Responses.Count)</p>
                </div>
                <div class="metric-card">
                    <h3>Categories Assessed</h3>
                    <p style="font-size: 2em; font-weight: bold;">$($QuestionnaireResults.Categories.Count)</p>
                </div>
                <div class="metric-card">
                    <h3>Time Taken</h3>
                    <p style="font-size: 2em; font-weight: bold;">$([math]::Round($QuestionnaireResults.Duration.TotalMinutes, 1)) min</p>
                </div>
            </div>
"@
        
        # Add key questionnaire findings
        $findings = Get-KeyFindings -Responses $QuestionnaireResults.Responses
        if ($findings.Count -gt 0) {
            $html += "<h3>Key Discovery Findings</h3>"
            foreach ($finding in $findings) {
                $html += "<div class='finding medium'>$finding</div>"
            }
        }
        $html += "</div>"
    }
    
    # Add assessment results
    if ($AssessmentResults) {
        $html += @"
        <div class="section">
            <h2>🔍 Assessment Results</h2>
"@
        
        # Add module results
        foreach ($module in $AssessmentResults.Modules) {
            $html += @"
            <h3>$($module.Name)</h3>
            <p>Status: $($module.Status)</p>
            <p>Findings: $($module.FindingsCount)</p>
"@
        }
        
        $html += "</div>"
    }
    
    # Add recommendations
    $html += @"
        <div class="section">
            <h2>💡 Recommendations</h2>
            <div class="finding high">
                <h4>Priority 1: Immediate Actions</h4>
                <ul>
                    <li>Enable unified audit logging</li>
                    <li>Implement data classification scheme</li>
                    <li>Configure DLP policies in test mode</li>
                </ul>
            </div>
            <div class="finding medium">
                <h4>Priority 2: Short-term Goals</h4>
                <ul>
                    <li>Deploy sensitivity labels</li>
                    <li>Configure retention policies</li>
                    <li>Enable insider risk management</li>
                </ul>
            </div>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $reportPath -Encoding UTF8
    return $reportPath
}

# Show completion summary
function Show-AssessmentComplete {
    param(
        [string]$ReportPath,
        [string]$OutputPath
    )
    
    Write-Host @"

╔═══════════════════════════════════════════════════════════════════════════════╗
║                           ✅ ASSESSMENT COMPLETE! ✅                           ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Your PowerReview assessment with discovery is complete!

📁 Results saved to: $OutputPath

Key files generated:
  • Discovery Results (JSON)
  • Assessment Results (JSON)
  • Integrated Report (HTML): $ReportPath
  • Client Portal (HTML)
  • Executive Summary (PDF)

Next Steps:
  1. Review the integrated report with your team
  2. Share the client portal with stakeholders
  3. Create an implementation plan based on recommendations
  4. Schedule follow-up assessments quarterly

Need help? Contact the PowerReview team or visit our documentation.

"@ -ForegroundColor Green
}

# Developer helper functions
function Show-DeveloperHelp {
    Write-Host @"

🛠️  DEVELOPER GUIDE - PowerReview Questionnaire System

ADDING CUSTOM QUESTIONS:
========================
`$customQuestion = @{
    ID = "CUSTOM-001"
    Question = "Your question text here"
    Type = "SingleChoice" # or MultipleChoice, Text, YesNo
    Options = @("Option1", "Option2") # For choice questions
    Required = `$true
    Hint = "Help text for the user"
    Tips = @("Tip 1", "Tip 2")
    CommonAnswers = @{
        "Option1" = "What this typically means"
    }
}

Add-DiscoveryQuestion -Category "GeneralOrganization" -Question `$customQuestion

CREATING QUESTION TEMPLATES:
===========================
# Export current questions as template
Export-QuestionnaireTemplate -OutputPath ".\MyTemplate.json"

# Import custom questions
Import-CustomQuestions -Path ".\MyCustomQuestions.json"

ACCESSING QUESTIONNAIRE DATA:
============================
# Get all responses
`$results.Responses

# Get specific category responses
`$results.Categories["DataClassification"]

# Get specific answer
`$results.Responses["DC-001"]

INTEGRATION WITH POWERREVIEW:
============================
# Convert questionnaire to config
`$config = Convert-QuestionnaireToConfig -Results `$results

# Export for PowerReview
Export-ForPowerReview -QuestionnaireResults `$results

TIPS FOR DEVELOPERS:
===================
1. Keep questions clear and concise
2. Always provide hints for complex questions
3. Use templates for text questions
4. Test with real users before deploying
5. Consider compliance requirements when designing questions

"@ -ForegroundColor Cyan
}

# Quick start function for developers
function Start-DeveloperQuickAssessment {
    param(
        [string]$Organization = "Test Organization"
    )
    
    Write-Host "🚀 Starting Developer Quick Assessment..." -ForegroundColor Cyan
    
    # Run minimal questionnaire
    $categories = @("OrganizationOverview", "DataClassification", "ComplianceRequirements")
    $results = Start-DiscoveryQuestionnaire -Categories $categories -Interactive:$false
    
    # Generate config
    $config = Convert-QuestionnaireToConfig -Results $results
    
    # Show results
    Write-Host "`n✅ Quick Assessment Complete!" -ForegroundColor Green
    Write-Host "Configuration generated with focus areas:" -ForegroundColor Cyan
    $config.Modules.Purview.FocusAreas | ForEach-Object {
        Write-Host "  • $_" -ForegroundColor White
    }
    
    return $config
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host @"
PowerReview Questionnaire Integration Module Loaded!

This module integrates discovery questionnaires with PowerReview assessments.

Available Commands:
  • Start-PowerReviewWithDiscovery    - Run complete assessment with questionnaire
  • Show-DeveloperHelp               - Show developer guide
  • Start-DeveloperQuickAssessment   - Quick assessment for testing

Example:
  Start-PowerReviewWithDiscovery -RunQuestionnaire -InteractiveMode

"@ -ForegroundColor Cyan
}