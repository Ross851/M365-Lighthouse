# PowerReview Test Runner
# Orchestrates comprehensive testing of PowerReview system
# Usage: .\run-tests.ps1 -TestType All -TenantId "your-tenant-id"

param(
    [ValidateSet("All", "Unit", "Integration", "Security", "Performance")]
    [string]$TestType = "All",
    [string]$TenantId = "",
    [string]$TestEnvironment = "Development",
    [switch]$GenerateReport,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$TestStartTime = Get-Date

# Test configuration
$TestConfig = @{
    BaseUrl = switch ($TestEnvironment) {
        "Development" { "http://localhost:4321" }
        "Staging" { "https://powerreview-staging.vercel.app" }
        "Production" { "https://powerreview.vercel.app" }
        default { "http://localhost:4321" }
    }
    MaxRetries = 3
    TimeoutSeconds = 30
    ParallelTests = $true
}

Write-Host "🚀 PowerReview Test Runner Starting..." -ForegroundColor Cyan
Write-Host "Test Type: $TestType" -ForegroundColor Yellow
Write-Host "Environment: $TestEnvironment" -ForegroundColor Yellow
Write-Host "Base URL: $($TestConfig.BaseUrl)" -ForegroundColor Yellow
Write-Host "=" * 60

# Test results tracking
$TestResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Skipped = 0
    StartTime = $TestStartTime
    Tests = @()
}

function Write-TestOutput {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $color = switch ($Level) {
        "Success" { "Green" }
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Info" { "White" }
        default { "White" }
    }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Invoke-TestWithRetry {
    param(
        [scriptblock]$TestScript,
        [string]$TestName,
        [int]$MaxRetries = $TestConfig.MaxRetries
    )
    
    $attempt = 1
    $lastError = $null
    
    while ($attempt -le $MaxRetries) {
        try {
            $result = & $TestScript
            return @{
                Success = $true
                Result = $result
                Attempts = $attempt
            }
        } catch {
            $lastError = $_.Exception.Message
            Write-TestOutput "Attempt $attempt failed for $TestName : $lastError" -Level "Warning"
            $attempt++
            
            if ($attempt -le $MaxRetries) {
                Start-Sleep -Seconds (2 * $attempt) # Exponential backoff
            }
        }
    }
    
    return @{
        Success = $false
        Error = $lastError
        Attempts = $attempt - 1
    }
}

function Test-WebEndpoint {
    param(
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [int]$ExpectedStatusCode = 200
    )
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
            TimeoutSec = $TestConfig.TimeoutSeconds
            UseBasicParsing = $true
        }
        
        if ($Body) {
            $params.Body = $Body | ConvertTo-Json -Depth 10
            $params.ContentType = "application/json"
        }
        
        $response = Invoke-WebRequest @params
        
        return @{
            Success = $response.StatusCode -eq $ExpectedStatusCode
            StatusCode = $response.StatusCode
            Content = $response.Content
            Headers = $response.Headers
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            StatusCode = $_.Exception.Response.StatusCode.value__ -as [int]
        }
    }
}

function Test-UnitTests {
    Write-TestOutput "🧪 Running Unit Tests..." -Level "Info"
    
    # Test 1: PowerShell Module Loading
    $test = {
        $modules = @("Microsoft.Graph", "ExchangeOnlineManagement", "MicrosoftTeams")
        $missingModules = @()
        
        foreach ($module in $modules) {
            if (!(Get-Module -ListAvailable -Name $module)) {
                $missingModules += $module
            }
        }
        
        if ($missingModules.Count -eq 0) {
            return @{ Status = "Pass"; Message = "All required modules available" }
        } else {
            return @{ Status = "Fail"; Message = "Missing modules: $($missingModules -join ', ')" }
        }
    }
    
    $result = Invoke-TestWithRetry -TestScript $test -TestName "Module Loading"
    Add-TestResult -Name "PowerShell Module Loading" -Result $result
    
    # Test 2: Configuration Validation
    $test = {
        $configFiles = @(
            ".\package.json",
            ".\astro.config.mjs",
            ".\tsconfig.json"
        )
        
        $missingFiles = @()
        foreach ($file in $configFiles) {
            if (!(Test-Path $file)) {
                $missingFiles += $file
            }
        }
        
        if ($missingFiles.Count -eq 0) {
            return @{ Status = "Pass"; Message = "All configuration files present" }
        } else {
            return @{ Status = "Fail"; Message = "Missing files: $($missingFiles -join ', ')" }
        }
    }
    
    $result = Invoke-TestWithRetry -TestScript $test -TestName "Configuration Validation"
    Add-TestResult -Name "Configuration Files" -Result $result
    
    # Test 3: TypeScript Compilation
    $test = {
        try {
            $output = npm run build 2>&1
            if ($LASTEXITCODE -eq 0) {
                return @{ Status = "Pass"; Message = "TypeScript compilation successful" }
            } else {
                return @{ Status = "Fail"; Message = "Compilation failed: $output" }
            }
        } catch {
            return @{ Status = "Fail"; Message = "Build process failed: $($_.Exception.Message)" }
        }
    }
    
    $result = Invoke-TestWithRetry -TestScript $test -TestName "TypeScript Compilation"
    Add-TestResult -Name "TypeScript Build" -Result $result
}

function Test-IntegrationTests {
    Write-TestOutput "🔗 Running Integration Tests..." -Level "Info"
    
    # Test 1: Web Server Health
    $test = {
        $response = Test-WebEndpoint -Url "$($TestConfig.BaseUrl)/" -ExpectedStatusCode 200
        if ($response.Success) {
            return @{ Status = "Pass"; Message = "Web server responding correctly" }
        } else {
            return @{ Status = "Fail"; Message = "Web server not responding: $($response.Error)" }
        }
    }
    
    $result = Invoke-TestWithRetry -TestScript $test -TestName "Web Server Health"
    Add-TestResult -Name "Web Server Health Check" -Result $result
    
    # Test 2: API Endpoints
    $apiTests = @(
        @{ Path = "/api/auth/login"; Method = "POST"; ExpectedCode = 400 }, # Should fail without credentials
        @{ Path = "/api/assessment/start"; Method = "POST"; ExpectedCode = 401 }, # Should require auth
        @{ Path = "/api/storage/upload"; Method = "POST"; ExpectedCode = 401 } # Should require auth
    )
    
    foreach ($apiTest in $apiTests) {
        $test = {
            $response = Test-WebEndpoint -Url "$($TestConfig.BaseUrl)$($apiTest.Path)" -Method $apiTest.Method -ExpectedStatusCode $apiTest.ExpectedCode
            if ($response.Success) {
                return @{ Status = "Pass"; Message = "API endpoint responding as expected" }
            } else {
                return @{ Status = "Fail"; Message = "API endpoint error: Status $($response.StatusCode)" }
            }
        }
        
        $result = Invoke-TestWithRetry -TestScript $test -TestName "API Test: $($apiTest.Path)"
        Add-TestResult -Name "API Endpoint: $($apiTest.Path)" -Result $result
    }
    
    # Test 3: Authentication Flow
    if (![string]::IsNullOrEmpty($TenantId)) {
        $test = {
            # Test authentication endpoint with sample data
            $authData = @{
                tenantId = $TenantId
                authCode = "test-code"
            }
            
            $response = Test-WebEndpoint -Url "$($TestConfig.BaseUrl)/api/auth/login" -Method "POST" -Body $authData -ExpectedStatusCode 400
            if ($response.StatusCode -eq 400) {
                return @{ Status = "Pass"; Message = "Authentication endpoint properly validates input" }
            } else {
                return @{ Status = "Fail"; Message = "Unexpected auth response: $($response.StatusCode)" }
            }
        }
        
        $result = Invoke-TestWithRetry -TestScript $test -TestName "Authentication Flow"
        Add-TestResult -Name "Authentication Flow Test" -Result $result
    } else {
        Add-TestResult -Name "Authentication Flow Test" -Result @{
            Success = $false
            Result = @{ Status = "Skip"; Message = "No TenantId provided" }
        }
    }
}

function Test-SecurityTests {
    Write-TestOutput "🛡️ Running Security Tests..." -Level "Info"
    
    # Test 1: HTTPS Redirect (for production)
    if ($TestEnvironment -ne "Development") {
        $test = {
            $httpUrl = $TestConfig.BaseUrl -replace "https://", "http://"
            $response = Test-WebEndpoint -Url $httpUrl -ExpectedStatusCode 301
            if ($response.Success -or $response.StatusCode -eq 308) {
                return @{ Status = "Pass"; Message = "HTTPS redirect working" }
            } else {
                return @{ Status = "Fail"; Message = "HTTPS redirect not configured" }
            }
        }
        
        $result = Invoke-TestWithRetry -TestScript $test -TestName "HTTPS Redirect"
        Add-TestResult -Name "HTTPS Security" -Result $result
    }
    
    # Test 2: Security Headers
    $test = {
        $response = Test-WebEndpoint -Url "$($TestConfig.BaseUrl)/"
        if ($response.Success) {
            $securityHeaders = @(
                "X-Content-Type-Options",
                "X-Frame-Options",
                "Referrer-Policy"
            )
            
            $missingHeaders = @()
            foreach ($header in $securityHeaders) {
                if (!$response.Headers.ContainsKey($header)) {
                    $missingHeaders += $header
                }
            }
            
            if ($missingHeaders.Count -eq 0) {
                return @{ Status = "Pass"; Message = "All security headers present" }
            } else {
                return @{ Status = "Warn"; Message = "Missing security headers: $($missingHeaders -join ', ')" }
            }
        } else {
            return @{ Status = "Fail"; Message = "Cannot check security headers: $($response.Error)" }
        }
    }
    
    $result = Invoke-TestWithRetry -TestScript $test -TestName "Security Headers"
    Add-TestResult -Name "Security Headers Check" -Result $result
    
    # Test 3: Input Validation
    $test = {
        # Test various injection attempts
        $maliciousInputs = @(
            "<script>alert('xss')</script>",
            "'; DROP TABLE users; --",
            "../../../etc/passwd",
            "{{7*7}}",
            "${7*7}"
        )
        
        $vulnerabilities = @()
        foreach ($input in $maliciousInputs) {
            $response = Test-WebEndpoint -Url "$($TestConfig.BaseUrl)/api/auth/login" -Method "POST" -Body @{ input = $input }
            
            if ($response.Content -and $response.Content.Contains($input)) {
                $vulnerabilities += $input
            }
        }
        
        if ($vulnerabilities.Count -eq 0) {
            return @{ Status = "Pass"; Message = "Input validation working correctly" }
        } else {
            return @{ Status = "Fail"; Message = "Potential vulnerabilities found with inputs: $($vulnerabilities -join ', ')" }
        }
    }
    
    $result = Invoke-TestWithRetry -TestScript $test -TestName "Input Validation"
    Add-TestResult -Name "Input Validation Security" -Result $result
}

function Test-PerformanceTests {
    Write-TestOutput "⚡ Running Performance Tests..." -Level "Info"
    
    # Test 1: Page Load Time
    $test = {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Test-WebEndpoint -Url "$($TestConfig.BaseUrl)/"
        $stopwatch.Stop()
        
        $loadTime = $stopwatch.ElapsedMilliseconds
        
        if ($response.Success) {
            if ($loadTime -lt 2000) {
                return @{ Status = "Pass"; Message = "Page loaded in ${loadTime}ms" }
            } elseif ($loadTime -lt 5000) {
                return @{ Status = "Warn"; Message = "Page load time acceptable: ${loadTime}ms" }
            } else {
                return @{ Status = "Fail"; Message = "Page load time too slow: ${loadTime}ms" }
            }
        } else {
            return @{ Status = "Fail"; Message = "Page failed to load: $($response.Error)" }
        }
    }
    
    $result = Invoke-TestWithRetry -TestScript $test -TestName "Page Load Performance"
    Add-TestResult -Name "Home Page Load Time" -Result $result
    
    # Test 2: Concurrent Request Handling
    $test = {
        $jobs = @()
        $requestCount = 10
        
        for ($i = 1; $i -le $requestCount; $i++) {
            $jobs += Start-Job -ScriptBlock {
                param($BaseUrl)
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    $response = Invoke-WebRequest -Uri "$BaseUrl/" -UseBasicParsing -TimeoutSec 30
                    $stopwatch.Stop()
                    return @{
                        Success = $true
                        Duration = $stopwatch.ElapsedMilliseconds
                        StatusCode = $response.StatusCode
                    }
                } catch {
                    $stopwatch.Stop()
                    return @{
                        Success = $false
                        Duration = $stopwatch.ElapsedMilliseconds
                        Error = $_.Exception.Message
                    }
                }
            } -ArgumentList $TestConfig.BaseUrl
        }
        
        $results = $jobs | Wait-Job | Receive-Job
        $jobs | Remove-Job
        
        $successCount = ($results | Where-Object { $_.Success }).Count
        $avgDuration = ($results | Measure-Object -Property Duration -Average).Average
        
        if ($successCount -eq $requestCount) {
            return @{ Status = "Pass"; Message = "All $requestCount concurrent requests succeeded (avg: ${avgDuration}ms)" }
        } elseif ($successCount -ge ($requestCount * 0.8)) {
            return @{ Status = "Warn"; Message = "$successCount/$requestCount requests succeeded (avg: ${avgDuration}ms)" }
        } else {
            return @{ Status = "Fail"; Message = "Only $successCount/$requestCount requests succeeded" }
        }
    }
    
    $result = Invoke-TestWithRetry -TestScript $test -TestName "Concurrent Request Performance"
    Add-TestResult -Name "Concurrent Request Handling" -Result $result
    
    # Test 3: Memory Usage
    $test = {
        $process = Get-Process -Name "node" -ErrorAction SilentlyContinue | Sort-Object WorkingSet -Descending | Select-Object -First 1
        
        if ($process) {
            $memoryMB = [Math]::Round($process.WorkingSet / 1MB, 2)
            
            if ($memoryMB -lt 100) {
                return @{ Status = "Pass"; Message = "Memory usage: ${memoryMB}MB" }
            } elseif ($memoryMB -lt 250) {
                return @{ Status = "Warn"; Message = "Memory usage acceptable: ${memoryMB}MB" }
            } else {
                return @{ Status = "Fail"; Message = "High memory usage: ${memoryMB}MB" }
            }
        } else {
            return @{ Status = "Skip"; Message = "Node.js process not found" }
        }
    }
    
    $result = Invoke-TestWithRetry -TestScript $test -TestName "Memory Usage Check"
    Add-TestResult -Name "Memory Usage" -Result $result
}

function Add-TestResult {
    param(
        [string]$Name,
        [object]$Result
    )
    
    $TestResults.Total++
    
    $testRecord = @{
        Name = $Name
        Status = $Result.Result.Status
        Message = $Result.Result.Message
        Attempts = $Result.Attempts
        Success = $Result.Success
        Timestamp = Get-Date
    }
    
    $TestResults.Tests += $testRecord
    
    switch ($Result.Result.Status) {
        "Pass" { 
            $TestResults.Passed++
            Write-TestOutput "✅ $Name - $($Result.Result.Message)" -Level "Success"
        }
        "Fail" { 
            $TestResults.Failed++
            Write-TestOutput "❌ $Name - $($Result.Result.Message)" -Level "Error"
        }
        "Warn" { 
            $TestResults.Passed++ # Count as passed but with warning
            Write-TestOutput "⚠️ $Name - $($Result.Result.Message)" -Level "Warning"
        }
        "Skip" { 
            $TestResults.Skipped++
            Write-TestOutput "⏭️ $Name - $($Result.Result.Message)" -Level "Info"
        }
    }
}

function Generate-TestReport {
    Write-TestOutput "📊 Generating Test Report..." -Level "Info"
    
    $TestResults.EndTime = Get-Date
    $TestResults.Duration = $TestResults.EndTime - $TestResults.StartTime
    $TestResults.SuccessRate = [Math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 2)
    
    $reportPath = ".\test-results\TestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    
    # Ensure test-results directory exists
    if (!(Test-Path ".\test-results")) {
        New-Item -ItemType Directory -Path ".\test-results" -Force | Out-Null
    }
    
    $TestResults | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8
    
    # Generate HTML report
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>PowerReview Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .summary { display: flex; gap: 20px; margin-bottom: 20px; }
        .metric { background: #e9ecef; padding: 15px; border-radius: 5px; text-align: center; }
        .metric h3 { margin: 0; color: #333; }
        .metric .value { font-size: 24px; font-weight: bold; color: #007bff; }
        .test-results { background: white; border: 1px solid #ddd; border-radius: 5px; }
        .test-row { padding: 10px; border-bottom: 1px solid #eee; display: flex; align-items: center; }
        .status-pass { color: #28a745; }
        .status-fail { color: #dc3545; }
        .status-warn { color: #ffc107; }
        .status-skip { color: #6c757d; }
    </style>
</head>
<body>
    <div class="header">
        <h1>PowerReview Test Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Environment: $TestEnvironment</p>
        <p>Test Type: $TestType</p>
    </div>
    
    <div class="summary">
        <div class="metric">
            <h3>Total Tests</h3>
            <div class="value">$($TestResults.Total)</div>
        </div>
        <div class="metric">
            <h3>Passed</h3>
            <div class="value status-pass">$($TestResults.Passed)</div>
        </div>
        <div class="metric">
            <h3>Failed</h3>
            <div class="value status-fail">$($TestResults.Failed)</div>
        </div>
        <div class="metric">
            <h3>Success Rate</h3>
            <div class="value">$($TestResults.SuccessRate)%</div>
        </div>
        <div class="metric">
            <h3>Duration</h3>
            <div class="value">$([Math]::Round($TestResults.Duration.TotalMinutes, 2)) min</div>
        </div>
    </div>
    
    <div class="test-results">
        <h2>Test Results</h2>
"@

    foreach ($test in $TestResults.Tests) {
        $statusClass = "status-$($test.Status.ToLower())"
        $icon = switch ($test.Status) {
            "Pass" { "✅" }
            "Fail" { "❌" }
            "Warn" { "⚠️" }
            "Skip" { "⏭️" }
        }
        
        $htmlReport += @"
        <div class="test-row">
            <span style="margin-right: 10px;">$icon</span>
            <span style="flex: 1; font-weight: bold;">$($test.Name)</span>
            <span class="$statusClass" style="margin-left: 10px;">$($test.Status)</span>
        </div>
        <div style="padding: 5px 40px; color: #666; font-size: 14px;">$($test.Message)</div>
"@
    }
    
    $htmlReport += @"
    </div>
</body>
</html>
"@
    
    $htmlReportPath = ".\test-results\TestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $htmlReport | Out-File $htmlReportPath -Encoding UTF8
    
    Write-TestOutput "Test report saved to: $reportPath" -Level "Success"
    Write-TestOutput "HTML report saved to: $htmlReportPath" -Level "Success"
}

# Main execution
try {
    # Run selected test types
    switch ($TestType) {
        "All" {
            Test-UnitTests
            Test-IntegrationTests
            Test-SecurityTests
            Test-PerformanceTests
        }
        "Unit" { Test-UnitTests }
        "Integration" { Test-IntegrationTests }
        "Security" { Test-SecurityTests }
        "Performance" { Test-PerformanceTests }
    }
    
    # Generate report if requested or if running all tests
    if ($GenerateReport -or $TestType -eq "All") {
        Generate-TestReport
    }
    
    # Print summary
    Write-Host "`n" + "=" * 60
    Write-Host "TEST EXECUTION COMPLETE" -ForegroundColor Cyan
    Write-Host "=" * 60
    Write-Host "Total Tests: $($TestResults.Total)" -ForegroundColor White
    Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor Red
    Write-Host "Skipped: $($TestResults.Skipped)" -ForegroundColor Yellow
    Write-Host "Success Rate: $($TestResults.SuccessRate)%" -ForegroundColor $(if ($TestResults.SuccessRate -ge 80) { "Green" } else { "Red" })
    Write-Host "Duration: $([Math]::Round($TestResults.Duration.TotalMinutes, 2)) minutes" -ForegroundColor White
    Write-Host "=" * 60
    
    # Exit with appropriate code
    if ($TestResults.Failed -gt 0) {
        Write-TestOutput "❌ Tests completed with failures" -Level "Error"
        exit 1
    } else {
        Write-TestOutput "✅ All tests completed successfully!" -Level "Success"
        exit 0
    }
    
} catch {
    Write-TestOutput "❌ Test execution failed: $($_.Exception.Message)" -Level "Error"
    exit 1
}