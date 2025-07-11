function Invoke-SafeCommand {
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$Command,
        [string]$ErrorMessage = "Command failed",
        [switch]$ContinueOnError
    )
    
    try {
        $result = & $Command
        return @{
            Success = $true
            Result = $result
            Error = $null
        }
    }
    catch {
        $errorDetails = @{
            Success = $false
            Result = $null
            Error = $_
            ErrorMessage = $ErrorMessage
            TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        Write-Log -Level "ERROR" -Message "$ErrorMessage : $_"
        
        if (-not $ContinueOnError) {
            throw $_
        }
        
        return $errorDetails
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [string]$LogFile = "$PSScriptRoot\ReviewLog.txt"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO"  { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG" { Write-Host $logEntry -ForegroundColor Cyan }
    }
}

function Test-CommandExists {
    param([string]$Command)
    
    $exists = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $exists) {
        Write-Log -Level "WARN" -Message "Command '$Command' not found. Skipping..."
        return $false
    }
    return $true
}

function Get-PowerPlatformSecuritySafe {
    if (Test-CommandExists "Get-PowerPlatformSecurity") {
        return Invoke-SafeCommand -Command { Get-PowerPlatformSecurity } -ContinueOnError
    }
    else {
        Write-Log -Level "WARN" -Message "Power Platform Security module not available. Returning empty results."
        return @{
            Success = $false
            Result = @()
            Error = "Module not available"
        }
    }
}