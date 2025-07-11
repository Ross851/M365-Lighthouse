#Requires -Version 7.0

<#
.SYNOPSIS
    PowerReview Discovery Questionnaire Module - Interactive questionnaire wizard for gathering client information
.DESCRIPTION
    Provides an interactive questionnaire framework for developers/contractors to gather information from clients
    Based on Electoral Commission Purview Implementation Discovery template
.NOTES
    Version: 1.0
    Author: PowerReview Team
#>

# Question Categories
$script:QuestionCategories = @{
    "GeneralOrganization" = @{
        Title = "General Organization Information"
        Description = "Basic information about the organization and its structure"
        Icon = "🏢"
    }
    "DataClassification" = @{
        Title = "Data Classification & Sensitivity"
        Description = "Understanding data types and sensitivity levels"
        Icon = "🔐"
    }
    "ComplianceRequirements" = @{
        Title = "Compliance & Regulatory Requirements"
        Description = "Legal and regulatory compliance needs"
        Icon = "📋"
    }
    "TechnicalEnvironment" = @{
        Title = "Technical Environment"
        Description = "Current technical setup and infrastructure"
        Icon = "🖥️"
    }
    "SecurityPolicies" = @{
        Title = "Security Policies & Procedures"
        Description = "Existing security measures and policies"
        Icon = "🛡️"
    }
    "DataGovernance" = @{
        Title = "Data Governance"
        Description = "Data lifecycle and governance practices"
        Icon = "📊"
    }
}

# Question Database
$script:QuestionDatabase = @{
    "GeneralOrganization" = @(
        @{
            ID = "GO-001"
            Question = "What is your organization's primary industry/sector?"
            Type = "SingleChoice"
            Options = @("Government", "Financial Services", "Healthcare", "Education", "Retail", "Manufacturing", "Technology", "Non-Profit", "Other")
            Required = $true
            Hint = "This helps determine industry-specific compliance requirements"
            Tips = @(
                "Consider your primary business activities",
                "If multiple sectors apply, choose the one with strictest compliance requirements"
            )
            CommonAnswers = @{
                "Government" = "Typically requires highest security standards (ISO 27001, NIST)"
                "Financial Services" = "Usually requires PCI-DSS, SOX compliance"
                "Healthcare" = "HIPAA compliance is mandatory"
            }
        },
        @{
            ID = "GO-002"
            Question = "How many employees does your organization have?"
            Type = "SingleChoice"
            Options = @("1-50", "51-250", "251-1000", "1001-5000", "5000+")
            Required = $true
            Hint = "Employee count affects licensing and security requirements"
            Tips = @(
                "Include all full-time employees",
                "Consider contractors if they access sensitive data"
            )
        },
        @{
            ID = "GO-003"
            Question = "What geographical regions does your organization operate in?"
            Type = "MultipleChoice"
            Options = @("North America", "Europe", "Asia Pacific", "Middle East", "Africa", "South America", "Australia")
            Required = $true
            Hint = "Different regions have different data protection laws"
            Tips = @(
                "Select all regions where you have offices or process data",
                "Consider GDPR for Europe, CCPA for California"
            )
        },
        @{
            ID = "GO-004"
            Question = "Describe your organization's structure (departments, subsidiaries, etc.)"
            Type = "Text"
            Required = $true
            Hint = "Understanding organizational structure helps design appropriate security boundaries"
            Tips = @(
                "List major departments (HR, Finance, IT, etc.)",
                "Note any subsidiaries or affiliated organizations",
                "Identify departments handling sensitive data"
            )
            Template = "Main Departments:`n- HR`n- Finance`n- IT`n- Operations`n`nSubsidiaries:`n- [List here]"
        }
    )
    "DataClassification" = @(
        @{
            ID = "DC-001"
            Question = "What types of sensitive data does your organization handle?"
            Type = "MultipleChoice"
            Options = @(
                "Personal Identifiable Information (PII)",
                "Financial Data",
                "Health Records",
                "Intellectual Property",
                "Government Classified Information",
                "Customer Data",
                "Employee Data",
                "Trade Secrets"
            )
            Required = $true
            Hint = "Select all types of sensitive data your organization processes"
            Tips = @(
                "PII includes names, addresses, SSNs, etc.",
                "Financial data includes credit cards, bank accounts",
                "Consider data at rest and in transit"
            )
        },
        @{
            ID = "DC-002"
            Question = "Do you have an existing data classification scheme?"
            Type = "YesNo"
            Required = $true
            FollowUp = @{
                "Yes" = "DC-002a"
                "No" = "DC-002b"
            }
            Hint = "Data classification helps apply appropriate security controls"
            Tips = @(
                "Common schemes: Public, Internal, Confidential, Restricted",
                "If informal classification exists, answer Yes"
            )
        },
        @{
            ID = "DC-002a"
            Question = "Describe your current data classification levels"
            Type = "Text"
            Required = $false
            Condition = "DC-002 == Yes"
            Hint = "List each classification level and what it means"
            Template = "Level 1: Public - [Description]`nLevel 2: Internal - [Description]`nLevel 3: Confidential - [Description]`nLevel 4: Restricted - [Description]"
        },
        @{
            ID = "DC-002b"
            Question = "Would you like help establishing a data classification scheme?"
            Type = "YesNo"
            Required = $false
            Condition = "DC-002 == No"
            Hint = "Microsoft Purview can help implement data classification"
        }
    )
    "ComplianceRequirements" = @(
        @{
            ID = "CR-001"
            Question = "Which compliance frameworks does your organization need to meet?"
            Type = "MultipleChoice"
            Options = @(
                "GDPR (General Data Protection Regulation)",
                "HIPAA (Health Insurance Portability and Accountability Act)",
                "PCI-DSS (Payment Card Industry Data Security Standard)",
                "SOX (Sarbanes-Oxley Act)",
                "ISO 27001",
                "NIST Cybersecurity Framework",
                "CCPA (California Consumer Privacy Act)",
                "FERPA (Family Educational Rights and Privacy Act)",
                "None of the above",
                "Other"
            )
            Required = $true
            Hint = "Select all applicable compliance requirements"
            Tips = @(
                "GDPR applies if you process EU citizen data",
                "HIPAA applies to healthcare data in the US",
                "PCI-DSS applies if you process credit cards"
            )
            CommonAnswers = @{
                "GDPR" = "Requires data protection by design, consent management, right to erasure"
                "HIPAA" = "Requires encryption, access controls, audit trails for health data"
                "PCI-DSS" = "Requires network segmentation, encryption, regular security testing"
            }
        },
        @{
            ID = "CR-002"
            Question = "Do you have specific data retention requirements?"
            Type = "YesNo"
            Required = $true
            FollowUp = @{
                "Yes" = "CR-002a"
            }
            Hint = "Legal or business requirements for keeping data"
            Tips = @(
                "Consider legal requirements first",
                "Think about litigation holds",
                "Review industry-specific requirements"
            )
        },
        @{
            ID = "CR-002a"
            Question = "Describe your data retention requirements"
            Type = "Text"
            Required = $false
            Condition = "CR-002 == Yes"
            Hint = "Include timeframes and data types"
            Template = "Email: [X years]`nDocuments: [X years]`nFinancial Records: [X years]`nCustomer Data: [X years]"
        }
    )
    "TechnicalEnvironment" = @(
        @{
            ID = "TE-001"
            Question = "Which Microsoft 365 services are currently in use?"
            Type = "MultipleChoice"
            Options = @(
                "Exchange Online",
                "SharePoint Online",
                "OneDrive for Business",
                "Microsoft Teams",
                "Power Platform",
                "Azure Active Directory",
                "Microsoft Defender",
                "Microsoft Purview",
                "None - New to M365"
            )
            Required = $true
            Hint = "Select all services currently deployed"
            Tips = @(
                "Check your M365 admin center for active services",
                "Include services in pilot or limited deployment"
            )
        },
        @{
            ID = "TE-002"
            Question = "What is your current email system?"
            Type = "SingleChoice"
            Options = @("Exchange Online", "Exchange On-Premises", "Hybrid Exchange", "Other Email System", "No Email System")
            Required = $true
            Hint = "This affects migration and integration planning"
            Tips = @(
                "Hybrid means both on-premises and online",
                "Consider where mailboxes are primarily hosted"
            )
        },
        @{
            ID = "TE-003"
            Question = "Approximately how much data do you have in SharePoint/OneDrive?"
            Type = "SingleChoice"
            Options = @("< 1 TB", "1-10 TB", "10-50 TB", "50-100 TB", "100+ TB", "Unknown")
            Required = $true
            Hint = "Helps plan for scanning and classification performance"
            Tips = @(
                "Check SharePoint admin center for usage reports",
                "Include both SharePoint sites and OneDrive storage"
            )
        }
    )
    "SecurityPolicies" = @(
        @{
            ID = "SP-001"
            Question = "Do you have written information security policies?"
            Type = "YesNo"
            Required = $true
            FollowUp = @{
                "Yes" = "SP-001a"
            }
            Hint = "Formal documented security policies and procedures"
            Tips = @(
                "Include any IT policies, acceptable use policies",
                "Consider both technical and administrative policies"
            )
        },
        @{
            ID = "SP-001a"
            Question = "Which security policies do you have documented?"
            Type = "MultipleChoice"
            Options = @(
                "Information Security Policy",
                "Data Classification Policy",
                "Acceptable Use Policy",
                "Incident Response Plan",
                "Business Continuity Plan",
                "Access Control Policy",
                "Password Policy",
                "Remote Work Policy"
            )
            Required = $false
            Condition = "SP-001 == Yes"
        },
        @{
            ID = "SP-002"
            Question = "How do you currently handle data loss prevention?"
            Type = "Text"
            Required = $true
            Hint = "Describe current DLP measures if any"
            Tips = @(
                "Include technical controls (software, policies)",
                "Mention procedural controls (training, processes)",
                "Note any gaps or challenges"
            )
            Template = "Current DLP Tools: [List tools]`nPolicies: [Describe policies]`nChallenges: [List challenges]"
        }
    )
    "DataGovernance" = @(
        @{
            ID = "DG-001"
            Question = "Do you have a formal data governance program?"
            Type = "YesNo"
            Required = $true
            Hint = "Structured approach to managing data assets"
            Tips = @(
                "Includes data ownership, quality, lifecycle management",
                "May be informal but documented"
            )
        },
        @{
            ID = "DG-002"
            Question = "Who is responsible for data governance in your organization?"
            Type = "Text"
            Required = $true
            Hint = "Person or team responsible for data decisions"
            Tips = @(
                "Could be CIO, CDO, or governance committee",
                "Note if responsibility is distributed"
            )
        },
        @{
            ID = "DG-003"
            Question = "What are your main data governance challenges?"
            Type = "MultipleChoice"
            Options = @(
                "Lack of visibility into data",
                "No clear data ownership",
                "Inconsistent data classification",
                "Manual processes",
                "Compliance tracking",
                "Data sprawl",
                "Shadow IT",
                "User adoption"
            )
            Required = $true
            Hint = "Select all challenges you face"
            Tips = @(
                "Be honest about current challenges",
                "These help prioritize Purview features"
            )
        }
    )
}

# Function to add new questions dynamically
function Add-DiscoveryQuestion {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Category,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Question
    )
    
    if (-not $script:QuestionDatabase.ContainsKey($Category)) {
        $script:QuestionDatabase[$Category] = @()
    }
    
    # Validate question structure
    $requiredFields = @("ID", "Question", "Type", "Required")
    foreach ($field in $requiredFields) {
        if (-not $Question.ContainsKey($field)) {
            throw "Question must contain field: $field"
        }
    }
    
    # Add to database
    $script:QuestionDatabase[$Category] += $Question
    
    Write-Host "✅ Question added successfully: $($Question.ID)" -ForegroundColor Green
}

# Interactive questionnaire wizard
function Start-DiscoveryQuestionnaire {
    param(
        [string]$OutputPath = ".\Discovery-Results",
        [string[]]$Categories = @(),
        [switch]$Interactive = $true,
        [switch]$ShowHints = $true,
        [switch]$ExportTemplate = $false
    )
    
    # Initialize results
    $results = @{
        Organization = ""
        StartTime = Get-Date
        Responses = @{}
        Categories = @{}
    }
    
    # Show welcome screen
    if ($Interactive) {
        Show-QuestionnaireWelcome
    }
    
    # Get organization name
    $results.Organization = Read-Host "Enter organization name"
    
    # Determine which categories to run
    if ($Categories.Count -eq 0) {
        $Categories = Show-CategorySelection
    }
    
    # Process each category
    foreach ($category in $Categories) {
        if ($script:QuestionDatabase.ContainsKey($category)) {
            Write-Host "`n`n$($script:QuestionCategories[$category].Icon) $($script:QuestionCategories[$category].Title)" -ForegroundColor Cyan
            Write-Host ("=" * 60) -ForegroundColor Cyan
            Write-Host $script:QuestionCategories[$category].Description -ForegroundColor Gray
            
            $categoryResponses = @{}
            $questions = $script:QuestionDatabase[$category]
            
            for ($i = 0; $i -lt $questions.Count; $i++) {
                $q = $questions[$i]
                
                # Check conditions
                if ($q.Condition) {
                    if (-not (Test-QuestionCondition -Condition $q.Condition -Responses $results.Responses)) {
                        continue
                    }
                }
                
                # Show progress
                $progress = [math]::Round((($i + 1) / $questions.Count) * 100)
                Write-Progress -Activity "Category: $category" -Status "Question $($i + 1) of $($questions.Count)" -PercentComplete $progress
                
                # Ask question
                $response = Ask-Question -Question $q -ShowHints:$ShowHints
                
                if ($response -ne $null) {
                    $categoryResponses[$q.ID] = $response
                    $results.Responses[$q.ID] = $response
                    
                    # Handle follow-up questions
                    if ($q.FollowUp -and $q.FollowUp.ContainsKey($response)) {
                        $followUpId = $q.FollowUp[$response]
                        $followUpQ = $questions | Where-Object { $_.ID -eq $followUpId }
                        if ($followUpQ) {
                            $followUpResponse = Ask-Question -Question $followUpQ -ShowHints:$ShowHints
                            if ($followUpResponse -ne $null) {
                                $categoryResponses[$followUpQ.ID] = $followUpResponse
                                $results.Responses[$followUpQ.ID] = $followUpResponse
                            }
                        }
                    }
                }
            }
            
            $results.Categories[$category] = $categoryResponses
            Write-Progress -Activity "Category: $category" -Completed
        }
    }
    
    # Complete questionnaire
    $results.EndTime = Get-Date
    $results.Duration = $results.EndTime - $results.StartTime
    
    # Show summary
    if ($Interactive) {
        Show-QuestionnaireSummary -Results $results
    }
    
    # Export results
    Export-QuestionnaireResults -Results $results -OutputPath $OutputPath
    
    # Generate assessment input
    $assessmentInput = Convert-ToAssessmentInput -Results $results
    Export-AssessmentInput -Input $assessmentInput -OutputPath $OutputPath
    
    return $results
}

# Function to ask a single question
function Ask-Question {
    param(
        [hashtable]$Question,
        [bool]$ShowHints = $true
    )
    
    Write-Host "`n`n❓ $($Question.Question)" -ForegroundColor Yellow
    
    if ($ShowHints -and $Question.Hint) {
        Write-Host "   💡 Hint: $($Question.Hint)" -ForegroundColor DarkGray
    }
    
    if ($ShowHints -and $Question.Tips) {
        Write-Host "   📌 Tips:" -ForegroundColor DarkGray
        foreach ($tip in $Question.Tips) {
            Write-Host "      • $tip" -ForegroundColor DarkGray
        }
    }
    
    $response = $null
    
    switch ($Question.Type) {
        "YesNo" {
            Write-Host "`n   [Y] Yes" -ForegroundColor Green
            Write-Host "   [N] No" -ForegroundColor Red
            
            do {
                $answer = Read-Host "`n   Your choice (Y/N)"
                $answer = $answer.ToUpper()
            } while ($answer -ne 'Y' -and $answer -ne 'N')
            
            $response = if ($answer -eq 'Y') { "Yes" } else { "No" }
        }
        
        "SingleChoice" {
            Write-Host ""
            for ($i = 0; $i -lt $Question.Options.Count; $i++) {
                Write-Host "   [$($i + 1)] $($Question.Options[$i])" -ForegroundColor Cyan
                
                if ($ShowHints -and $Question.CommonAnswers -and $Question.CommonAnswers.ContainsKey($Question.Options[$i])) {
                    Write-Host "       → $($Question.CommonAnswers[$Question.Options[$i]])" -ForegroundColor DarkGray
                }
            }
            
            do {
                $choice = Read-Host "`n   Select option (1-$($Question.Options.Count))"
                $valid = $choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Question.Options.Count
            } while (-not $valid)
            
            $response = $Question.Options[[int]$choice - 1]
        }
        
        "MultipleChoice" {
            Write-Host ""
            for ($i = 0; $i -lt $Question.Options.Count; $i++) {
                Write-Host "   [$($i + 1)] $($Question.Options[$i])" -ForegroundColor Cyan
                
                if ($ShowHints -and $Question.CommonAnswers -and $Question.CommonAnswers.ContainsKey($Question.Options[$i])) {
                    Write-Host "       → $($Question.CommonAnswers[$Question.Options[$i]])" -ForegroundColor DarkGray
                }
            }
            
            Write-Host "`n   Enter numbers separated by commas (e.g., 1,3,5)" -ForegroundColor Gray
            $choices = Read-Host "   Select options"
            
            $selectedOptions = @()
            foreach ($c in $choices -split ',') {
                $c = $c.Trim()
                if ($c -match '^\d+$' -and [int]$c -ge 1 -and [int]$c -le $Question.Options.Count) {
                    $selectedOptions += $Question.Options[[int]$c - 1]
                }
            }
            
            $response = $selectedOptions
        }
        
        "Text" {
            if ($Question.Template) {
                Write-Host "`n   Template:" -ForegroundColor DarkGray
                $Question.Template -split "`n" | ForEach-Object {
                    Write-Host "   $_" -ForegroundColor DarkGray
                }
            }
            
            Write-Host "`n   Enter your response (press Enter twice to finish):" -ForegroundColor Gray
            $lines = @()
            do {
                $line = Read-Host
                if ($line -ne "") {
                    $lines += $line
                }
            } while ($line -ne "")
            
            $response = $lines -join "`n"
        }
    }
    
    # Skip if not required and empty
    if (-not $Question.Required -and [string]::IsNullOrWhiteSpace($response)) {
        $response = $null
    }
    
    return $response
}

# Show welcome screen
function Show-QuestionnaireWelcome {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                      🚀 POWERREVIEW DISCOVERY QUESTIONNAIRE 🚀                ║
║                                                                               ║
║                    Microsoft 365 & Azure Assessment Wizard                     ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Welcome to the PowerReview Discovery Questionnaire!

This interactive wizard will help you gather essential information about your
client's environment, compliance requirements, and security needs.

Features:
  ✓ Guided questions with hints and tips
  ✓ Industry best practice recommendations
  ✓ Automatic report generation
  ✓ Integration with PowerReview assessment

The questionnaire typically takes 15-30 minutes to complete.

"@ -ForegroundColor Cyan
    
    Write-Host "Press any key to begin..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Category selection menu
function Show-CategorySelection {
    Clear-Host
    Write-Host "`n📋 SELECT QUESTIONNAIRE CATEGORIES" -ForegroundColor Cyan
    Write-Host ("=" * 40) -ForegroundColor Cyan
    
    $categories = @()
    $i = 1
    
    foreach ($cat in $script:QuestionCategories.Keys) {
        Write-Host "[$i] $($script:QuestionCategories[$cat].Icon) $($script:QuestionCategories[$cat].Title)" -ForegroundColor Yellow
        Write-Host "    $($script:QuestionCategories[$cat].Description)" -ForegroundColor Gray
        $categories += $cat
        $i++
    }
    
    Write-Host "`n[A] All Categories" -ForegroundColor Green
    Write-Host "[C] Custom Selection" -ForegroundColor Cyan
    
    $choice = Read-Host "`nSelect option"
    
    if ($choice -eq 'A') {
        return $categories
    }
    elseif ($choice -eq 'C') {
        Write-Host "`nEnter category numbers separated by commas (e.g., 1,3,5):" -ForegroundColor Cyan
        $selections = Read-Host
        
        $selected = @()
        foreach ($s in $selections -split ',') {
            $s = $s.Trim()
            if ($s -match '^\d+$' -and [int]$s -ge 1 -and [int]$s -le $categories.Count) {
                $selected += $categories[[int]$s - 1]
            }
        }
        
        return $selected
    }
    else {
        return $categories
    }
}

# Test question conditions
function Test-QuestionCondition {
    param(
        [string]$Condition,
        [hashtable]$Responses
    )
    
    # Simple condition parser (e.g., "DC-002 == Yes")
    if ($Condition -match '^(\S+)\s*==\s*(.+)$') {
        $questionId = $matches[1]
        $expectedValue = $matches[2]
        
        if ($Responses.ContainsKey($questionId)) {
            return $Responses[$questionId] -eq $expectedValue
        }
    }
    
    return $false
}

# Show questionnaire summary
function Show-QuestionnaireSummary {
    param(
        [hashtable]$Results
    )
    
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                           📊 QUESTIONNAIRE SUMMARY 📊                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green
    
    Write-Host "`nOrganization: $($Results.Organization)" -ForegroundColor Cyan
    Write-Host "Duration: $([math]::Round($Results.Duration.TotalMinutes, 1)) minutes" -ForegroundColor Cyan
    Write-Host "Questions Answered: $($Results.Responses.Count)" -ForegroundColor Cyan
    
    Write-Host "`nCategories Completed:" -ForegroundColor Yellow
    foreach ($cat in $Results.Categories.Keys) {
        $count = $Results.Categories[$cat].Count
        Write-Host "  ✓ $($script:QuestionCategories[$cat].Title) ($count responses)" -ForegroundColor Green
    }
    
    Write-Host "`nKey Findings:" -ForegroundColor Yellow
    
    # Analyze responses for key findings
    $findings = Get-KeyFindings -Responses $Results.Responses
    foreach ($finding in $findings) {
        Write-Host "  • $finding" -ForegroundColor White
    }
}

# Get key findings from responses
function Get-KeyFindings {
    param(
        [hashtable]$Responses
    )
    
    $findings = @()
    
    # Check compliance requirements
    if ($Responses.ContainsKey("CR-001")) {
        $compliance = $Responses["CR-001"]
        if ($compliance -contains "GDPR") {
            $findings += "GDPR compliance required - need data protection controls"
        }
        if ($compliance -contains "HIPAA") {
            $findings += "HIPAA compliance required - healthcare data protection needed"
        }
    }
    
    # Check data classification
    if ($Responses.ContainsKey("DC-002") -and $Responses["DC-002"] -eq "No") {
        $findings += "No data classification scheme - recommend implementing one"
    }
    
    # Check security policies
    if ($Responses.ContainsKey("SP-001") -and $Responses["SP-001"] -eq "No") {
        $findings += "No formal security policies - high priority to establish"
    }
    
    # Check data governance
    if ($Responses.ContainsKey("DG-001") -and $Responses["DG-001"] -eq "No") {
        $findings += "No formal data governance program - recommend establishing"
    }
    
    return $findings
}

# Export questionnaire results
function Export-QuestionnaireResults {
    param(
        [hashtable]$Results,
        [string]$OutputPath
    )
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    # Export as JSON
    $jsonPath = Join-Path $OutputPath "Discovery-Results-$timestamp.json"
    $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
    
    # Export as HTML report
    $htmlPath = Join-Path $OutputPath "Discovery-Report-$timestamp.html"
    $htmlContent = Generate-HTMLReport -Results $Results
    $htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
    
    # Export as CSV for easy analysis
    $csvPath = Join-Path $OutputPath "Discovery-Responses-$timestamp.csv"
    $csvData = @()
    
    foreach ($qId in $Results.Responses.Keys) {
        $category = Get-QuestionCategory -QuestionId $qId
        $question = Get-QuestionById -QuestionId $qId
        
        $csvData += [PSCustomObject]@{
            Category = $category
            QuestionID = $qId
            Question = $question.Question
            Response = if ($Results.Responses[$qId] -is [array]) {
                $Results.Responses[$qId] -join "; "
            } else {
                $Results.Responses[$qId]
            }
            Required = $question.Required
        }
    }
    
    $csvData | Export-Csv -Path $csvPath -NoTypeInformation
    
    Write-Host "`n✅ Results exported to:" -ForegroundColor Green
    Write-Host "   • JSON: $jsonPath" -ForegroundColor White
    Write-Host "   • HTML: $htmlPath" -ForegroundColor White
    Write-Host "   • CSV: $csvPath" -ForegroundColor White
}

# Generate HTML report
function Generate-HTMLReport {
    param(
        [hashtable]$Results
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>PowerReview Discovery Report - $($Results.Organization)</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #2c3e50 0%, #3498db 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
        }
        .header .subtitle {
            margin-top: 10px;
            opacity: 0.9;
        }
        .summary {
            background: white;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .category {
            background: white;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .category h2 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .question {
            margin: 20px 0;
            padding: 15px;
            background: #f8f9fa;
            border-left: 4px solid #3498db;
            border-radius: 5px;
        }
        .question-text {
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 10px;
        }
        .response {
            color: #27ae60;
            font-weight: 500;
        }
        .hint {
            color: #7f8c8d;
            font-size: 0.9em;
            font-style: italic;
            margin-top: 5px;
        }
        .findings {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            padding: 20px;
            border-radius: 10px;
            margin-top: 30px;
        }
        .findings h3 {
            color: #856404;
            margin-top: 0;
        }
        .findings ul {
            margin: 10px 0;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: #7f8c8d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 PowerReview Discovery Report</h1>
        <div class="subtitle">$($Results.Organization) - $(Get-Date -Format "MMMM dd, yyyy")</div>
    </div>
    
    <div class="summary">
        <h2>📊 Summary</h2>
        <p><strong>Assessment Duration:</strong> $([math]::Round($Results.Duration.TotalMinutes, 1)) minutes</p>
        <p><strong>Questions Answered:</strong> $($Results.Responses.Count)</p>
        <p><strong>Categories Completed:</strong> $($Results.Categories.Count)</p>
    </div>
"@
    
    # Add category responses
    foreach ($category in $Results.Categories.Keys) {
        $categoryInfo = $script:QuestionCategories[$category]
        $html += @"
    <div class="category">
        <h2>$($categoryInfo.Icon) $($categoryInfo.Title)</h2>
        <p>$($categoryInfo.Description)</p>
"@
        
        foreach ($qId in $Results.Categories[$category].Keys) {
            $question = Get-QuestionById -QuestionId $qId
            $response = $Results.Categories[$category][$qId]
            
            $html += @"
        <div class="question">
            <div class="question-text">$($question.Question)</div>
            <div class="response">
"@
            
            if ($response -is [array]) {
                $html += "<ul>"
                foreach ($item in $response) {
                    $html += "<li>$item</li>"
                }
                $html += "</ul>"
            } else {
                $html += $response -replace "`n", "<br/>"
            }
            
            $html += "</div>"
            
            if ($question.Hint) {
                $html += @"
            <div class="hint">💡 $($question.Hint)</div>
"@
            }
            
            $html += "</div>"
        }
        
        $html += "</div>"
    }
    
    # Add key findings
    $findings = Get-KeyFindings -Responses $Results.Responses
    if ($findings.Count -gt 0) {
        $html += @"
    <div class="findings">
        <h3>🔍 Key Findings & Recommendations</h3>
        <ul>
"@
        foreach ($finding in $findings) {
            $html += "<li>$finding</li>"
        }
        $html += @"
        </ul>
    </div>
"@
    }
    
    $html += @"
    <div class="footer">
        Generated by PowerReview Discovery Questionnaire<br/>
        © $(Get-Date -Format yyyy) PowerReview Team
    </div>
</body>
</html>
"@
    
    return $html
}

# Convert questionnaire results to assessment input
function Convert-ToAssessmentInput {
    param(
        [hashtable]$Results
    )
    
    $assessmentInput = @{
        Organization = $Results.Organization
        Timestamp = Get-Date
        Configuration = @{
            Purview = @{
                Enabled = $true
                Priority = "High"
                Focus = @()
            }
            PowerPlatform = @{
                Enabled = $true
                Priority = "Medium"
            }
            SharePoint = @{
                Enabled = $true
                Priority = "High"
            }
            Security = @{
                Enabled = $true
                Priority = "High"
            }
        }
        ComplianceRequirements = @()
        DataTypes = @()
        Recommendations = @()
    }
    
    # Extract compliance requirements
    if ($Results.Responses.ContainsKey("CR-001")) {
        $assessmentInput.ComplianceRequirements = $Results.Responses["CR-001"]
    }
    
    # Extract data types
    if ($Results.Responses.ContainsKey("DC-001")) {
        $assessmentInput.DataTypes = $Results.Responses["DC-001"]
    }
    
    # Set Purview focus areas based on responses
    if ($Results.Responses.ContainsKey("DC-002") -and $Results.Responses["DC-002"] -eq "No") {
        $assessmentInput.Configuration.Purview.Focus += "Data Classification"
        $assessmentInput.Recommendations += "Implement data classification scheme"
    }
    
    if ($Results.Responses.ContainsKey("SP-002")) {
        $assessmentInput.Configuration.Purview.Focus += "Data Loss Prevention"
    }
    
    # Adjust priorities based on organization size
    if ($Results.Responses.ContainsKey("GO-002")) {
        $size = $Results.Responses["GO-002"]
        if ($size -in @("1001-5000", "5000+")) {
            $assessmentInput.Configuration.PowerPlatform.Priority = "High"
        }
    }
    
    return $assessmentInput
}

# Export assessment input
function Export-AssessmentInput {
    param(
        [hashtable]$Input,
        [string]$OutputPath
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $assessmentPath = Join-Path $OutputPath "Assessment-Input-$timestamp.json"
    
    $Input | ConvertTo-Json -Depth 10 | Out-File -FilePath $assessmentPath -Encoding UTF8
    
    Write-Host "   • Assessment Input: $assessmentPath" -ForegroundColor White
}

# Helper functions
function Get-QuestionCategory {
    param([string]$QuestionId)
    
    foreach ($cat in $script:QuestionDatabase.Keys) {
        if ($script:QuestionDatabase[$cat] | Where-Object { $_.ID -eq $QuestionId }) {
            return $cat
        }
    }
    return "Unknown"
}

function Get-QuestionById {
    param([string]$QuestionId)
    
    foreach ($cat in $script:QuestionDatabase.Keys) {
        $question = $script:QuestionDatabase[$cat] | Where-Object { $_.ID -eq $QuestionId }
        if ($question) {
            return $question
        }
    }
    return $null
}

# Export questionnaire template
function Export-QuestionnaireTemplate {
    param(
        [string]$OutputPath = ".\QuestionnaireTemplate.json"
    )
    
    $template = @{
        Categories = $script:QuestionCategories
        Questions = $script:QuestionDatabase
    }
    
    $template | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "✅ Questionnaire template exported to: $OutputPath" -ForegroundColor Green
}

# Import custom questions
function Import-CustomQuestions {
    param(
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Host "❌ File not found: $Path" -ForegroundColor Red
        return
    }
    
    try {
        $customData = Get-Content $Path -Raw | ConvertFrom-Json
        
        # Import categories
        if ($customData.Categories) {
            foreach ($cat in $customData.Categories.PSObject.Properties) {
                if (-not $script:QuestionCategories.ContainsKey($cat.Name)) {
                    $script:QuestionCategories[$cat.Name] = $cat.Value
                    Write-Host "✅ Added category: $($cat.Name)" -ForegroundColor Green
                }
            }
        }
        
        # Import questions
        if ($customData.Questions) {
            foreach ($cat in $customData.Questions.PSObject.Properties) {
                foreach ($question in $cat.Value) {
                    Add-DiscoveryQuestion -Category $cat.Name -Question $question
                }
            }
        }
        
        Write-Host "✅ Custom questions imported successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error importing questions: $_" -ForegroundColor Red
    }
}

# Example: Adding a custom question
function Example-AddCustomQuestion {
    $customQuestion = @{
        ID = "CUSTOM-001"
        Question = "Do you have any specific security concerns or incidents in the past year?"
        Type = "Text"
        Required = $false
        Hint = "This helps us focus on areas of concern"
        Tips = @(
            "Include any data breaches or security incidents",
            "Mention any compliance violations",
            "Note any areas where you feel vulnerable"
        )
        Template = "Incidents:`n- [Date]: [Description]`n`nConcerns:`n- [Area]: [Description]"
    }
    
    Add-DiscoveryQuestion -Category "SecurityPolicies" -Question $customQuestion
}

# Main execution example
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host @"
PowerReview Discovery Questionnaire Module Loaded!

Available Commands:
  • Start-DiscoveryQuestionnaire    - Run the interactive questionnaire
  • Add-DiscoveryQuestion           - Add custom questions
  • Export-QuestionnaireTemplate    - Export question template
  • Import-CustomQuestions          - Import custom questions

Example:
  Start-DiscoveryQuestionnaire -Interactive -ShowHints

"@ -ForegroundColor Cyan
}