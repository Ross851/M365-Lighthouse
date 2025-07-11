#Requires -Version 7.0

<#
.SYNOPSIS
    PowerReview Client Feedback and Communication System
.DESCRIPTION
    Manages client portal generation, feedback collection, and communication workflows
.NOTES
    Version: 1.0
#>

# Feedback configuration
$script:FeedbackConfig = @{
    PortalExpiration = 30  # Days
    FeedbackTypes = @("Technical", "Business", "Priority", "Timeline", "Budget")
    PriorityLevels = @("Critical", "High", "Medium", "Low")
    ResponseTemplates = @{}
}

# Function to generate client feedback portal
function New-ClientFeedbackPortal {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AssessmentId,
        
        [Parameter(Mandatory=$true)]
        [string]$OrganizationName,
        
        [Parameter(Mandatory=$true)]
        [string]$ClientEmail,
        
        [string]$ClientName,
        
        [int]$ExpirationDays = 30,
        
        [switch]$IncludeDetailedFindings,
        
        [switch]$AllowFeedback,
        
        [switch]$AllowPriorityRanking,
        
        [string[]]$CustomQuestions = @()
    )
    
    Write-Host "`n🌐 Generating Client Feedback Portal..." -ForegroundColor Cyan
    
    # Generate secure access token
    $accessToken = [System.Guid]::NewGuid().ToString()
    $expirationDate = (Get-Date).AddDays($ExpirationDays)
    
    # Load assessment data
    $assessmentData = Get-AssessmentData -AssessmentId $AssessmentId
    
    # Create portal data structure
    $portalData = @{
        PortalId = [System.Guid]::NewGuid().ToString()
        AssessmentId = $AssessmentId
        Organization = $OrganizationName
        ClientEmail = $ClientEmail
        ClientName = $ClientName
        AccessToken = $accessToken
        CreatedDate = Get-Date
        ExpirationDate = $expirationDate
        Features = @{
            DetailedFindings = $IncludeDetailedFindings
            FeedbackEnabled = $AllowFeedback
            PriorityRanking = $AllowPriorityRanking
        }
        CustomQuestions = $CustomQuestions
        ViewCount = 0
        FeedbackSubmitted = $false
    }
    
    # Generate HTML portal
    $htmlContent = Generate-FeedbackPortalHTML -PortalData $portalData -AssessmentData $assessmentData
    
    # Save portal
    $portalPath = ".\Client-Portals\$($portalData.PortalId)"
    New-Item -ItemType Directory -Path $portalPath -Force | Out-Null
    
    # Save HTML
    $htmlPath = Join-Path $portalPath "index.html"
    $htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
    
    # Save portal metadata
    $metadataPath = Join-Path $portalPath "portal-metadata.json"
    $portalData | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding UTF8
    
    # Generate access URL
    $accessUrl = "https://portal.powerreview.com/feedback/$($portalData.PortalId)?token=$accessToken"
    
    Write-Host "✅ Client portal generated successfully!" -ForegroundColor Green
    Write-Host "   Portal ID: $($portalData.PortalId)" -ForegroundColor White
    Write-Host "   Expires: $($expirationDate.ToString('yyyy-MM-dd'))" -ForegroundColor White
    Write-Host "   Access URL: $accessUrl" -ForegroundColor Cyan
    
    # Send email notification
    if ($ClientEmail) {
        Send-ClientPortalNotification -PortalData $portalData -AccessUrl $accessUrl
    }
    
    return @{
        PortalId = $portalData.PortalId
        AccessUrl = $accessUrl
        ExpirationDate = $expirationDate
    }
}

# Function to generate feedback portal HTML
function Generate-FeedbackPortalHTML {
    param($PortalData, $AssessmentData)
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PowerReview Assessment - $($PortalData.Organization)</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background: linear-gradient(135deg, #0078D4 0%, #40E0D0 100%);
            color: white;
            padding: 40px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header .subtitle {
            font-size: 1.2em;
            opacity: 0.9;
        }
        .summary-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        .card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }
        .score-circle {
            width: 120px;
            height: 120px;
            margin: 0 auto 15px;
            position: relative;
        }
        .score-text {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            font-size: 2.5em;
            font-weight: bold;
        }
        .findings-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .finding {
            border-left: 4px solid #0078D4;
            padding: 20px;
            margin: 15px 0;
            background: #f8f9fa;
            border-radius: 5px;
        }
        .finding.critical { border-left-color: #dc3545; }
        .finding.high { border-left-color: #fd7e14; }
        .finding.medium { border-left-color: #ffc107; }
        .finding.low { border-left-color: #28a745; }
        .feedback-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .feedback-form {
            margin-top: 20px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: 600;
            color: #555;
        }
        .form-group input,
        .form-group textarea,
        .form-group select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
        }
        .form-group textarea {
            min-height: 100px;
            resize: vertical;
        }
        .priority-ranking {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .priority-item {
            background: white;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
            cursor: move;
            display: flex;
            align-items: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .priority-item:hover {
            box-shadow: 0 2px 5px rgba(0,0,0,0.15);
        }
        .priority-number {
            background: #0078D4;
            color: white;
            width: 30px;
            height: 30px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 15px;
            font-weight: bold;
        }
        .btn {
            background: #0078D4;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            transition: background 0.2s;
        }
        .btn:hover {
            background: #106ebe;
        }
        .btn-secondary {
            background: #6c757d;
        }
        .btn-secondary:hover {
            background: #5a6268;
        }
        .timeline {
            position: relative;
            padding: 20px 0;
        }
        .timeline-item {
            display: flex;
            margin-bottom: 30px;
        }
        .timeline-date {
            min-width: 120px;
            text-align: right;
            padding-right: 20px;
            color: #666;
        }
        .timeline-content {
            flex: 1;
            padding-left: 20px;
            border-left: 2px solid #0078D4;
            position: relative;
        }
        .timeline-content::before {
            content: '';
            position: absolute;
            left: -6px;
            top: 5px;
            width: 10px;
            height: 10px;
            background: #0078D4;
            border-radius: 50%;
        }
        .comment-section {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin-top: 20px;
        }
        .comment {
            background: white;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .comment-header {
            font-weight: 600;
            margin-bottom: 5px;
            color: #0078D4;
        }
        .comment-date {
            font-size: 0.9em;
            color: #666;
        }
        .alert {
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .alert.warning {
            background: #fff3cd;
            color: #856404;
            border-color: #ffeaa7;
        }
        @media print {
            .feedback-section, .btn { display: none; }
            .header { background: #0078D4; print-color-adjust: exact; }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1>🛡️ Security Assessment Results</h1>
            <div class="subtitle">$($PortalData.Organization) - $(Get-Date -Format "MMMM dd, yyyy")</div>
            <p style="margin-top: 15px;">This portal is available until: $($PortalData.ExpirationDate.ToString('MMMM dd, yyyy'))</p>
        </div>

        <!-- Summary Cards -->
        <div class="summary-cards">
            <div class="card">
                <div class="score-circle">
                    <svg viewBox="0 0 120 120">
                        <circle cx="60" cy="60" r="54" fill="none" stroke="#e0e0e0" stroke-width="12"/>
                        <circle cx="60" cy="60" r="54" fill="none" stroke="#0078D4" stroke-width="12"
                                stroke-dasharray="339" stroke-dashoffset="$([math]::Round(339 * (1 - $AssessmentData.OverallScore / 100)))"
                                transform="rotate(-90 60 60)"/>
                    </svg>
                    <div class="score-text">$($AssessmentData.OverallScore)%</div>
                </div>
                <h3 style="text-align: center;">Overall Security Score</h3>
                <p style="text-align: center; color: #666;">Industry Average: 72%</p>
            </div>

            <div class="card">
                <h3>🔍 Total Findings</h3>
                <div style="font-size: 3em; font-weight: bold; color: #0078D4;">$($AssessmentData.TotalFindings)</div>
                <div style="margin-top: 10px;">
                    <div style="color: #dc3545;">Critical: $($AssessmentData.CriticalFindings)</div>
                    <div style="color: #fd7e14;">High: $($AssessmentData.HighFindings)</div>
                    <div style="color: #ffc107;">Medium: $($AssessmentData.MediumFindings)</div>
                    <div style="color: #28a745;">Low: $($AssessmentData.LowFindings)</div>
                </div>
            </div>

            <div class="card">
                <h3>📊 Areas Assessed</h3>
                <ul style="list-style: none; padding: 0; margin-top: 15px;">
                    <li>✅ Microsoft Purview</li>
                    <li>✅ SharePoint & Teams</li>
                    <li>✅ Security Posture</li>
                    <li>✅ Compliance Status</li>
                </ul>
            </div>

            <div class="card">
                <h3>💰 Estimated Risk</h3>
                <div style="font-size: 2em; font-weight: bold; color: #dc3545; margin: 15px 0;">
                    \$$($AssessmentData.EstimatedRisk)K
                </div>
                <p style="color: #666;">Potential cost of unaddressed vulnerabilities</p>
            </div>
        </div>

        <!-- Executive Summary -->
        <div class="findings-section">
            <h2>📋 Executive Summary</h2>
            <p style="margin: 20px 0; font-size: 1.1em; line-height: 1.8;">
                Our comprehensive security assessment of $($PortalData.Organization)'s Microsoft 365 environment has identified 
                <strong>$($AssessmentData.TotalFindings) findings</strong> requiring attention. The overall security posture 
                score of <strong>$($AssessmentData.OverallScore)%</strong> indicates 
                $(if ($AssessmentData.OverallScore -ge 80) { "a mature security posture with room for optimization" } 
                  elseif ($AssessmentData.OverallScore -ge 60) { "moderate security controls requiring enhancement" }
                  else { "significant security gaps requiring immediate attention" }).
            </p>
            
            <h3 style="margin-top: 30px;">🎯 Key Recommendations</h3>
            <ol style="margin: 20px 0; padding-left: 20px;">
                <li style="margin: 10px 0;"><strong>Immediate Actions</strong>: Address $($AssessmentData.CriticalFindings) critical findings within 30 days</li>
                <li style="margin: 10px 0;"><strong>Quick Wins</strong>: Implement MFA for all admin accounts (2-hour effort, high impact)</li>
                <li style="margin: 10px 0;"><strong>Strategic Initiatives</strong>: Deploy Microsoft Purview for comprehensive data governance</li>
            </ol>
        </div>

"@

    # Add detailed findings if enabled
    if ($PortalData.Features.DetailedFindings) {
        $html += @"
        <!-- Detailed Findings -->
        <div class="findings-section">
            <h2>🔍 Detailed Findings</h2>
            <p style="margin-bottom: 20px;">Below are the key findings organized by priority. Click on any finding for more details.</p>
"@
        
        foreach ($finding in $AssessmentData.Findings | Sort-Object -Property Severity) {
            $severityClass = $finding.Severity.ToLower()
            $html += @"
            <div class="finding $severityClass">
                <h3>$($finding.Title)</h3>
                <p style="margin: 10px 0;">$($finding.Description)</p>
                <div style="margin-top: 15px;">
                    <strong>Impact:</strong> $($finding.Impact)<br>
                    <strong>Recommendation:</strong> $($finding.Recommendation)<br>
                    <strong>Effort:</strong> $($finding.Effort) | <strong>Priority:</strong> $($finding.Priority)
                </div>
            </div>
"@
        }
        
        $html += "</div>"
    }

    # Add feedback section if enabled
    if ($PortalData.Features.FeedbackEnabled) {
        $html += @"
        <!-- Feedback Section -->
        <div class="feedback-section">
            <h2>💬 Your Feedback</h2>
            <p>We value your input on this assessment. Please share your thoughts below.</p>
            
            <form class="feedback-form" id="feedbackForm">
                <div class="form-group">
                    <label for="overallSatisfaction">Overall, how satisfied are you with this assessment?</label>
                    <select id="overallSatisfaction" name="overallSatisfaction" required>
                        <option value="">Please select...</option>
                        <option value="5">Very Satisfied</option>
                        <option value="4">Satisfied</option>
                        <option value="3">Neutral</option>
                        <option value="2">Dissatisfied</option>
                        <option value="1">Very Dissatisfied</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="findingsAccuracy">How accurate do you find these findings?</label>
                    <select id="findingsAccuracy" name="findingsAccuracy" required>
                        <option value="">Please select...</option>
                        <option value="5">Very Accurate</option>
                        <option value="4">Mostly Accurate</option>
                        <option value="3">Somewhat Accurate</option>
                        <option value="2">Not Very Accurate</option>
                        <option value="1">Inaccurate</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="actionableInsights">How actionable are the recommendations?</label>
                    <select id="actionableInsights" name="actionableInsights" required>
                        <option value="">Please select...</option>
                        <option value="5">Very Actionable</option>
                        <option value="4">Actionable</option>
                        <option value="3">Somewhat Actionable</option>
                        <option value="2">Not Very Actionable</option>
                        <option value="1">Not Actionable</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="additionalComments">Additional Comments</label>
                    <textarea id="additionalComments" name="additionalComments" 
                              placeholder="Please share any additional thoughts, concerns, or questions..."></textarea>
                </div>

                <div class="form-group">
                    <label for="followUpRequested">
                        <input type="checkbox" id="followUpRequested" name="followUpRequested">
                        I would like someone to contact me to discuss these findings
                    </label>
                </div>

                <button type="submit" class="btn">Submit Feedback</button>
            </form>
        </div>
"@
    }

    # Add priority ranking if enabled
    if ($PortalData.Features.PriorityRanking) {
        $html += @"
        <!-- Priority Ranking -->
        <div class="findings-section">
            <h2>📊 Priority Ranking</h2>
            <p>Please drag and drop the findings below to indicate your priority for addressing them:</p>
            
            <div class="priority-ranking" id="priorityList">
"@
        
        $priority = 1
        foreach ($finding in $AssessmentData.Findings | Where-Object { $_.Severity -in @('Critical', 'High') } | Select-Object -First 10) {
            $html += @"
                <div class="priority-item" data-finding-id="$($finding.Id)">
                    <div class="priority-number">$priority</div>
                    <div>
                        <strong>$($finding.Title)</strong><br>
                        <small>Current Priority: $($finding.Priority) | Severity: $($finding.Severity)</small>
                    </div>
                </div>
"@
            $priority++
        }
        
        $html += @"
            </div>
            <button class="btn" onclick="savePriorityRanking()">Save Priority Order</button>
        </div>
"@
    }

    # Add custom questions if provided
    if ($PortalData.CustomQuestions.Count -gt 0) {
        $html += @"
        <!-- Custom Questions -->
        <div class="feedback-section">
            <h2>📝 Additional Questions</h2>
            <form id="customQuestionsForm">
"@
        
        foreach ($question in $PortalData.CustomQuestions) {
            $html += @"
                <div class="form-group">
                    <label for="custom_$($question.Id)">$($question.Text)</label>
                    $(if ($question.Type -eq 'text') {
                        "<input type='text' id='custom_$($question.Id)' name='custom_$($question.Id)'>"
                    } elseif ($question.Type -eq 'textarea') {
                        "<textarea id='custom_$($question.Id)' name='custom_$($question.Id)'></textarea>"
                    } elseif ($question.Type -eq 'select') {
                        "<select id='custom_$($question.Id)' name='custom_$($question.Id)'>
                         <option value=''>Please select...</option>
                         $($question.Options | ForEach-Object { "<option value='$_'>$_</option>" })
                         </select>"
                    })
                </div>
"@
        }
        
        $html += @"
                <button type="submit" class="btn">Submit Answers</button>
            </form>
        </div>
"@
    }

    # Add timeline section
    $html += @"
        <!-- Next Steps Timeline -->
        <div class="findings-section">
            <h2>📅 Recommended Timeline</h2>
            <div class="timeline">
                <div class="timeline-item">
                    <div class="timeline-date">Week 1-2</div>
                    <div class="timeline-content">
                        <h4>Immediate Actions</h4>
                        <p>Address critical findings and implement quick wins</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <div class="timeline-date">Week 3-4</div>
                    <div class="timeline-content">
                        <h4>High Priority Items</h4>
                        <p>Deploy MFA, configure DLP policies, update retention</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <div class="timeline-date">Month 2</div>
                    <div class="timeline-content">
                        <h4>Strategic Initiatives</h4>
                        <p>Implement Purview, enhance monitoring, staff training</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <div class="timeline-date">Month 3</div>
                    <div class="timeline-content">
                        <h4>Review & Optimize</h4>
                        <p>Reassess security posture, fine-tune policies</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Footer -->
        <div style="margin-top: 50px; padding: 30px; background: #f8f9fa; border-radius: 10px; text-align: center;">
            <h3>Need Help?</h3>
            <p style="margin: 15px 0;">Our security experts are ready to assist with implementation</p>
            <a href="mailto:support@powerreview.com?subject=Assessment%20$($AssessmentData.Id)" class="btn">Contact Support</a>
            <a href="#" class="btn btn-secondary" style="margin-left: 10px;" onclick="window.print()">Print Report</a>
        </div>
    </div>

    <script>
        // Handle feedback form submission
        document.getElementById('feedbackForm')?.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(e.target);
            const feedback = Object.fromEntries(formData);
            
            // Send feedback (in real implementation, this would send to server)
            console.log('Feedback submitted:', feedback);
            
            // Show success message
            alert('Thank you for your feedback! We will review it and get back to you soon.');
            
            // Disable form
            e.target.style.opacity = '0.5';
            e.target.querySelectorAll('input, textarea, select, button').forEach(el => el.disabled = true);
        });

        // Handle priority ranking
        function savePriorityRanking() {
            const items = document.querySelectorAll('.priority-item');
            const ranking = Array.from(items).map((item, index) => ({
                findingId: item.dataset.findingId,
                priority: index + 1
            }));
            
            console.log('Priority ranking:', ranking);
            alert('Priority ranking saved successfully!');
        }

        // Simple drag and drop for priority ranking
        let draggedElement = null;

        document.querySelectorAll('.priority-item').forEach(item => {
            item.draggable = true;
            
            item.addEventListener('dragstart', function(e) {
                draggedElement = this;
                this.style.opacity = '0.5';
            });
            
            item.addEventListener('dragend', function(e) {
                this.style.opacity = '';
            });
            
            item.addEventListener('dragover', function(e) {
                e.preventDefault();
                this.style.borderTop = '2px solid #0078D4';
            });
            
            item.addEventListener('dragleave', function(e) {
                this.style.borderTop = '';
            });
            
            item.addEventListener('drop', function(e) {
                e.preventDefault();
                this.style.borderTop = '';
                
                if (this !== draggedElement) {
                    this.parentNode.insertBefore(draggedElement, this);
                    updatePriorityNumbers();
                }
            });
        });

        function updatePriorityNumbers() {
            document.querySelectorAll('.priority-number').forEach((num, index) => {
                num.textContent = index + 1;
            });
        }

        // Track page views
        window.addEventListener('load', function() {
            console.log('Portal viewed at:', new Date().toISOString());
        });
    </script>
</body>
</html>
"@
    
    return $html
}

# Function to send client portal notification
function Send-ClientPortalNotification {
    param($PortalData, $AccessUrl)
    
    $emailTemplate = @"
Subject: Your PowerReview Security Assessment is Ready

Dear $($PortalData.ClientName ?? 'Valued Client'),

Your security assessment for $($PortalData.Organization) has been completed and is now available for review.

📊 Assessment Summary:
- Overall Security Score: $($AssessmentData.OverallScore)%
- Total Findings: $($AssessmentData.TotalFindings)
- Critical Issues: $($AssessmentData.CriticalFindings)

🔗 Access Your Personalized Portal:
$AccessUrl

This secure portal includes:
✓ Executive summary of findings
✓ Detailed recommendations
✓ Priority roadmap
✓ Feedback submission form

⏰ Important: This portal will expire on $($PortalData.ExpirationDate.ToString('MMMM dd, yyyy'))

If you have any questions or need assistance accessing the portal, please don't hesitate to contact us.

Best regards,
The PowerReview Team

--
This is an automated message. Please do not reply directly to this email.
"@
    
    Write-Host "📧 Email notification prepared for: $($PortalData.ClientEmail)" -ForegroundColor Green
    Write-Host $emailTemplate -ForegroundColor Gray
}

# Function to collect client feedback
function Get-ClientFeedback {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PortalId,
        
        [Parameter(Mandatory=$true)]
        [string]$AccessToken
    )
    
    $portalPath = ".\Client-Portals\$PortalId"
    $feedbackPath = Join-Path $portalPath "feedback.json"
    
    if (Test-Path $feedbackPath) {
        $feedback = Get-Content $feedbackPath -Raw | ConvertFrom-Json
        return $feedback
    }
    
    return $null
}

# Function to save client feedback
function Save-ClientFeedback {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PortalId,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$FeedbackData
    )
    
    $portalPath = ".\Client-Portals\$PortalId"
    $feedbackPath = Join-Path $portalPath "feedback.json"
    
    $feedback = @{
        PortalId = $PortalId
        SubmittedDate = Get-Date
        FeedbackData = $FeedbackData
    }
    
    $feedback | ConvertTo-Json -Depth 10 | Out-File -FilePath $feedbackPath -Encoding UTF8
    
    # Send notification to team
    Send-FeedbackNotification -Feedback $feedback
}

# Function to generate feedback summary report
function New-FeedbackSummaryReport {
    param(
        [string]$StartDate,
        [string]$EndDate
    )
    
    Write-Host "`n📊 Generating Feedback Summary Report..." -ForegroundColor Cyan
    
    $allFeedback = @()
    
    # Collect all feedback
    Get-ChildItem -Path ".\Client-Portals" -Directory | ForEach-Object {
        $feedbackPath = Join-Path $_.FullName "feedback.json"
        if (Test-Path $feedbackPath) {
            $feedback = Get-Content $feedbackPath -Raw | ConvertFrom-Json
            $allFeedback += $feedback
        }
    }
    
    # Generate summary
    $summary = @{
        TotalResponses = $allFeedback.Count
        AverageSatisfaction = ($allFeedback.FeedbackData.overallSatisfaction | Measure-Object -Average).Average
        AverageAccuracy = ($allFeedback.FeedbackData.findingsAccuracy | Measure-Object -Average).Average
        AverageActionability = ($allFeedback.FeedbackData.actionableInsights | Measure-Object -Average).Average
        FollowUpRequests = ($allFeedback.FeedbackData.followUpRequested | Where-Object { $_ -eq $true }).Count
    }
    
    # Generate report
    $reportHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>Client Feedback Summary Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 40px; }
        .metric { background: #f0f0f0; padding: 20px; margin: 10px 0; border-radius: 5px; }
        .score { font-size: 2em; font-weight: bold; color: #0078D4; }
    </style>
</head>
<body>
    <h1>Client Feedback Summary</h1>
    <p>Period: $StartDate to $EndDate</p>
    
    <div class="metric">
        <h3>Total Responses</h3>
        <div class="score">$($summary.TotalResponses)</div>
    </div>
    
    <div class="metric">
        <h3>Average Satisfaction</h3>
        <div class="score">$([math]::Round($summary.AverageSatisfaction, 1))/5</div>
    </div>
    
    <div class="metric">
        <h3>Follow-up Requests</h3>
        <div class="score">$($summary.FollowUpRequests)</div>
    </div>
    
    <h2>Comments</h2>
    <ul>
"@
    
    foreach ($feedback in $allFeedback | Where-Object { $_.FeedbackData.additionalComments }) {
        $reportHtml += "<li>$($feedback.FeedbackData.additionalComments)</li>"
    }
    
    $reportHtml += @"
    </ul>
</body>
</html>
"@
    
    $reportPath = ".\Reports\Feedback-Summary-$(Get-Date -Format 'yyyyMMdd').html"
    $reportHtml | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "✅ Feedback summary report generated: $reportPath" -ForegroundColor Green
}

# Function to create follow-up tasks from feedback
function New-FollowUpTasks {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PortalId
    )
    
    $feedback = Get-ClientFeedback -PortalId $PortalId
    
    if ($feedback.FeedbackData.followUpRequested) {
        $task = @{
            TaskId = [Guid]::NewGuid().ToString()
            Type = "ClientFollowUp"
            Priority = "High"
            AssignedTo = "Sales Team"
            DueDate = (Get-Date).AddDays(2)
            Description = "Follow up with client regarding assessment feedback"
            ClientInfo = @{
                Organization = $feedback.Organization
                ContactEmail = $feedback.ClientEmail
                PortalId = $PortalId
            }
        }
        
        # Save task
        $taskPath = ".\Tasks\FollowUp-$($task.TaskId).json"
        $task | ConvertTo-Json -Depth 10 | Out-File -FilePath $taskPath -Encoding UTF8
        
        Write-Host "✅ Follow-up task created: $($task.TaskId)" -ForegroundColor Green
    }
}

# Function to get sample assessment data
function Get-AssessmentData {
    param($AssessmentId)
    
    # For demo purposes, return sample data
    return @{
        Id = $AssessmentId
        OverallScore = 75
        TotalFindings = 47
        CriticalFindings = 3
        HighFindings = 12
        MediumFindings = 20
        LowFindings = 12
        EstimatedRisk = 250
        Findings = @(
            @{
                Id = "F001"
                Title = "Multi-Factor Authentication Not Enforced for Admins"
                Description = "Administrative accounts can access systems without MFA"
                Severity = "Critical"
                Impact = "High risk of account compromise and unauthorized access"
                Recommendation = "Enable MFA for all administrative accounts immediately"
                Effort = "2 hours"
                Priority = "P1"
            },
            @{
                Id = "F002"
                Title = "Data Loss Prevention Policies Not Configured"
                Description = "No DLP policies are active to prevent data exfiltration"
                Severity = "High"
                Impact = "Sensitive data could be shared externally without detection"
                Recommendation = "Implement DLP policies for PII and financial data"
                Effort = "8 hours"
                Priority = "P2"
            }
        )
    }
}

# Help function
function Show-FeedbackHelp {
    Write-Host @"

🔄 POWERREVIEW CLIENT FEEDBACK SYSTEM
════════════════════════════════════════════════════════════════

AVAILABLE COMMANDS:

📧 Portal Generation:
   New-ClientFeedbackPortal    # Create client portal with feedback options

📊 Feedback Management:
   Get-ClientFeedback          # Retrieve submitted feedback
   Save-ClientFeedback         # Save feedback data
   New-FeedbackSummaryReport   # Generate feedback summary

📋 Follow-up:
   New-FollowUpTasks          # Create tasks from feedback

EXAMPLES:

# Create a basic client portal
New-ClientFeedbackPortal -AssessmentId "ASMT-001" `
    -OrganizationName "Contoso Ltd" `
    -ClientEmail "cto@contoso.com" `
    -ClientName "John Smith"

# Create portal with all features
New-ClientFeedbackPortal -AssessmentId "ASMT-001" `
    -OrganizationName "Contoso Ltd" `
    -ClientEmail "cto@contoso.com" `
    -IncludeDetailedFindings `
    -AllowFeedback `
    -AllowPriorityRanking

# Add custom questions
`$questions = @(
    @{Id="Q1"; Text="What are your top 3 security concerns?"; Type="textarea"},
    @{Id="Q2"; Text="When would you like to start implementation?"; Type="select"; 
      Options=@("Immediately", "Within 30 days", "Within 90 days", "Next fiscal year")}
)

New-ClientFeedbackPortal -AssessmentId "ASMT-001" `
    -OrganizationName "Contoso Ltd" `
    -ClientEmail "cto@contoso.com" `
    -CustomQuestions `$questions

"@ -ForegroundColor Cyan
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Show-FeedbackHelp
}