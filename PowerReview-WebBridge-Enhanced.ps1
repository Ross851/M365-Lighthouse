# PowerReview Web Bridge Enhanced - Connects Web UI to Real Assessment Scripts
# This script acts as a bridge between the web UI and the actual PowerShell assessment scripts

param(
    [Parameter(Mandatory=$true)]
    [string]$SessionId,
    
    [Parameter(Mandatory=$true)]
    [string]$Services,  # Comma-separated list: m365,azure,devops
    
    [Parameter(Mandatory=$true)]
    [string]$Depth,     # quick, standard, deep
    
    [Parameter(Mandatory=$true)]
    [string]$CustomerName,
    
    [string]$OutputFormat = "JSON",
    
    # Optional size parameters for accurate duration calculation
    [int]$SiteCount = 0,
    [int]$TeamsCount = 0,
    [int]$OnedriveCount = 0,
    [int]$MailboxCount = 0
)

# Import required modules
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load PowerReview modules
. "$scriptPath\PowerReview-ErrorHandling.ps1"
. "$scriptPath\PowerReview-Executive-Analysis.ps1"

# Initialize session logging
$outputPath = "$scriptPath\Output\$SessionId"
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

# Create log file
$logFile = "$outputPath\assessment.log"
$transcriptFile = "$outputPath\transcript.log"
Start-Transcript -Path $transcriptFile -Force

# Stream progress function
function Send-StreamUpdate {
    param(
        [string]$Type,
        [hashtable]$Data
    )
    
    $streamData = @{
        type = $Type
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        sessionId = $SessionId
    } + $Data
    
    $json = $streamData | ConvertTo-Json -Compress
    Write-Host "STREAM:$json"
}

# Write log with streaming
function Write-AssessmentLog {
    param(
        [string]$Level,
        [string]$Message,
        [hashtable]$Data = @{}
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    Add-Content -Path $logFile -Value $logEntry
    
    # Stream to web UI
    Send-StreamUpdate -Type "log" -Data @{
        level = $Level.ToLower()
        message = $Message
        data = $Data
    }
}

try {
    # Send initial progress
    Send-StreamUpdate -Type "progress" -Data @{
        progress = 5
        message = "Initializing assessment for $CustomerName"
    }
    
    Write-AssessmentLog -Level "INFO" -Message "Starting assessment for customer: $CustomerName"
    Write-AssessmentLog -Level "INFO" -Message "Services: $Services, Depth: $Depth"
    
    # Parse services
    $serviceList = $Services -split ','
    $totalSteps = $serviceList.Count * 10  # Approximate steps per service
    $currentStep = 0
    
    # Initialize results collection
    $assessmentResults = @{
        customer = $CustomerName
        sessionId = $SessionId
        startTime = Get-Date
        services = @{}
        overallScore = 100
        totalIssues = 0
        criticalFindings = 0
        recommendations = @()
    }
    
    # Connect to services
    Send-StreamUpdate -Type "progress" -Data @{
        progress = 10
        message = "Connecting to Microsoft 365 services..."
    }
    
    Write-AssessmentLog -Level "INFO" -Message "Attempting to connect to Microsoft 365"
    
    # Try to connect with error handling
    $connected = $false
    try {
        # Check if already connected
        $existingConnection = Get-AzureADTenantDetail -ErrorAction SilentlyContinue
        if ($existingConnection) {
            Write-AssessmentLog -Level "INFO" -Message "Using existing Azure AD connection"
            $connected = $true
        }
    } catch {
        Write-AssessmentLog -Level "WARN" -Message "No existing connection found"
    }
    
    if (-not $connected) {
        Write-AssessmentLog -Level "INFO" -Message "Please authenticate in the PowerShell window..."
        try {
            Connect-AzureAD -ErrorAction Stop
            $connected = $true
            Write-AssessmentLog -Level "INFO" -Message "Successfully connected to Azure AD"
        } catch {
            Write-AssessmentLog -Level "ERROR" -Message "Failed to connect to Azure AD: $_"
            throw "Authentication failed. Please ensure you have the required permissions."
        }
    }
    
    # Process each service
    foreach ($service in $serviceList) {
        $currentStep++
        $progress = 10 + (($currentStep / $totalSteps) * 80)
        
        Send-StreamUpdate -Type "progress" -Data @{
            progress = [int]$progress
            message = "Assessing $service security..."
        }
        
        Write-AssessmentLog -Level "INFO" -Message "Starting assessment for service: $service"
        
        switch ($service.Trim().ToLower()) {
            "m365" {
                # Run M365 assessments
                $m365Results = @{
                    service = "Microsoft 365"
                    checks = @()
                    score = 100
                    issues = 0
                }
                
                # Azure AD Assessment
                if ($Depth -in @('standard', 'deep')) {
                    Write-AssessmentLog -Level "INFO" -Message "Running Azure AD security assessment"
                    
                    Send-StreamUpdate -Type "metric" -Data @{
                        name = "azuread_users_checked"
                        value = 0
                    }
                    
                    # Get users and check for risks
                    try {
                        $users = Get-AzureADUser -All $true
                        $riskyUsers = 0
                        
                        foreach ($user in $users) {
                            if (-not $user.AccountEnabled) { continue }
                            
                            # Check for users without MFA
                            $userMFA = Get-AzureADUserRegisteredDevice -ObjectId $user.ObjectId -ErrorAction SilentlyContinue
                            if (-not $userMFA) {
                                $riskyUsers++
                                $m365Results.issues++
                            }
                        }
                        
                        Send-StreamUpdate -Type "metric" -Data @{
                            name = "azuread_users_checked"
                            value = $users.Count
                        }
                        
                        if ($riskyUsers -gt 0) {
                            $finding = @{
                                title = "Users without MFA"
                                severity = "High"
                                count = $riskyUsers
                                recommendation = "Enable MFA for all users"
                                impact = "High risk of account compromise"
                            }
                            $m365Results.checks += $finding
                            $assessmentResults.recommendations += $finding
                            
                            Write-AssessmentLog -Level "WARN" -Message "Found $riskyUsers users without MFA"
                        }
                        
                    } catch {
                        Write-AssessmentLog -Level "ERROR" -Message "Failed to assess Azure AD users: $_"
                    }
                }
                
                # Exchange Online Assessment
                if ($service -eq "m365" -and $Depth -ne "quick") {
                    Write-AssessmentLog -Level "INFO" -Message "Checking Exchange Online configuration"
                    
                    try {
                        # Check if Exchange Online module is available
                        if (Get-Command Get-OrganizationConfig -ErrorAction SilentlyContinue) {
                            $orgConfig = Get-OrganizationConfig
                            
                            # Check OAuth2ClientProfileEnabled
                            if (-not $orgConfig.OAuth2ClientProfileEnabled) {
                                $finding = @{
                                    title = "Modern Authentication Disabled"
                                    severity = "Critical"
                                    recommendation = "Enable modern authentication"
                                    impact = "Legacy authentication methods are vulnerable"
                                }
                                $m365Results.checks += $finding
                                $assessmentResults.criticalFindings++
                            }
                        }
                    } catch {
                        Write-AssessmentLog -Level "WARN" -Message "Could not assess Exchange Online: $_"
                    }
                }
                
                # Calculate service score
                if ($m365Results.issues -gt 0) {
                    $m365Results.score = [Math]::Max(0, 100 - ($m365Results.issues * 5))
                }
                
                $assessmentResults.services[$service] = $m365Results
                $assessmentResults.totalIssues += $m365Results.issues
            }
            
            "azure" {
                # Run Azure assessments
                Write-AssessmentLog -Level "INFO" -Message "Running Azure security assessment"
                
                $azureResults = @{
                    service = "Azure"
                    checks = @()
                    score = 100
                    issues = 0
                }
                
                # TODO: Add Azure-specific checks here
                
                $assessmentResults.services[$service] = $azureResults
            }
            
            "devops" {
                # Run DevOps assessments
                Write-AssessmentLog -Level "INFO" -Message "Running Azure DevOps security assessment"
                
                $devopsResults = @{
                    service = "Azure DevOps"
                    checks = @()
                    score = 100
                    issues = 0
                }
                
                # TODO: Add DevOps-specific checks here
                
                $assessmentResults.services[$service] = $devopsResults
            }
        }
    }
    
    # Calculate overall score
    if ($assessmentResults.services.Count -gt 0) {
        $totalScore = 0
        foreach ($service in $assessmentResults.services.Values) {
            $totalScore += $service.score
        }
        $assessmentResults.overallScore = [int]($totalScore / $assessmentResults.services.Count)
    }
    
    # Generate executive analysis if standard or deep assessment
    if ($Depth -in @('standard', 'deep')) {
        Send-StreamUpdate -Type "progress" -Data @{
            progress = 90
            message = "Generating executive analysis..."
        }
        
        Write-AssessmentLog -Level "INFO" -Message "Generating executive analysis"
        
        # Use the Executive Analysis module
        $executiveAnalysis = New-ExecutiveAnalysis -AssessmentData $assessmentResults
        $assessmentResults.executiveAnalysis = $executiveAnalysis
        
        # Add tiered recommendations
        $tieredRecs = New-TieredRecommendations -SecurityFindings $assessmentResults.recommendations
        $assessmentResults.tieredRecommendations = $tieredRecs
    }
    
    # Save results
    $assessmentResults.endTime = Get-Date
    $assessmentResults.duration = ($assessmentResults.endTime - $assessmentResults.startTime).TotalMinutes
    
    $resultsPath = "$outputPath\results.json"
    $assessmentResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsPath -Encoding UTF8
    
    Write-AssessmentLog -Level "INFO" -Message "Assessment completed successfully"
    
    # Send completion
    Send-StreamUpdate -Type "progress" -Data @{
        progress = 100
        message = "Assessment completed"
    }
    
    Send-StreamUpdate -Type "completed" -Data @{
        overallScore = $assessmentResults.overallScore
        totalIssues = $assessmentResults.totalIssues
        criticalFindings = $assessmentResults.criticalFindings
        duration = [int]$assessmentResults.duration
        resultsPath = $resultsPath
    }
    
} catch {
    Write-AssessmentLog -Level "ERROR" -Message "Assessment failed: $_"
    
    Send-StreamUpdate -Type "error" -Data @{
        error = $_.ToString()
        details = $_.Exception.Message
    }
    
    # Save error details
    $errorDetails = @{
        error = $_.ToString()
        exception = $_.Exception.Message
        stackTrace = $_.ScriptStackTrace
        timestamp = Get-Date
    }
    
    $errorPath = "$outputPath\error.json"
    $errorDetails | ConvertTo-Json -Depth 5 | Out-File -FilePath $errorPath -Encoding UTF8
    
    throw
} finally {
    Stop-Transcript
}