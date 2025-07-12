# Test script to demonstrate web integration with real PowerShell assessment
# This shows how the web UI connects to actual security checks

param(
    [string]$SessionId = "test-session-001"
)

Write-Host "=== PowerReview Web Integration Test ===" -ForegroundColor Cyan
Write-Host ""

# Test the web bridge script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$webBridgeScript = "$scriptPath\PowerReview-WebBridge-Enhanced.ps1"

if (-not (Test-Path $webBridgeScript)) {
    Write-Host "ERROR: Web bridge script not found at: $webBridgeScript" -ForegroundColor Red
    exit 1
}

Write-Host "Testing web bridge script..." -ForegroundColor Yellow
Write-Host "This will simulate what happens when the web UI starts an assessment" -ForegroundColor Gray
Write-Host ""

# Simulate web UI calling the assessment
$params = @{
    SessionId = $SessionId
    Services = "m365"
    Depth = "quick"
    CustomerName = "Test Customer"
    OutputFormat = "JSON"
}

Write-Host "Simulating web UI request with parameters:" -ForegroundColor Green
$params.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}
Write-Host ""

Write-Host "Starting assessment..." -ForegroundColor Yellow
Write-Host "Note: This will attempt to connect to Microsoft 365" -ForegroundColor Cyan
Write-Host ""

try {
    # Execute the web bridge script
    & $webBridgeScript @params
    
    Write-Host ""
    Write-Host "Assessment completed successfully!" -ForegroundColor Green
    
    # Check for results
    $outputPath = "$scriptPath\Output\$SessionId"
    if (Test-Path "$outputPath\results.json") {
        Write-Host ""
        Write-Host "Results saved to: $outputPath\results.json" -ForegroundColor Cyan
        
        # Display summary
        $results = Get-Content "$outputPath\results.json" | ConvertFrom-Json
        Write-Host ""
        Write-Host "=== Assessment Summary ===" -ForegroundColor Yellow
        Write-Host "Customer: $($results.customer)"
        Write-Host "Overall Score: $($results.overallScore)%"
        Write-Host "Total Issues: $($results.totalIssues)"
        Write-Host "Critical Findings: $($results.criticalFindings)"
        Write-Host "Duration: $([int]$results.duration) minutes"
    }
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Assessment failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    # Check for error details
    $errorPath = "$scriptPath\Output\$SessionId\error.json"
    if (Test-Path $errorPath) {
        Write-Host ""
        Write-Host "Error details saved to: $errorPath" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan