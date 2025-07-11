# Fix for missing Get-PowerPlatformSecurity cmdlet
# This wrapper will prevent the script from failing when Power Platform module is not available

. "$PSScriptRoot\PowerReview-ErrorHandling.ps1"

function Get-PowerPlatformSecurity {
    Write-Log -Level "INFO" -Message "Attempting to gather Power Platform security information..."
    
    $results = @{
        PowerApps = @()
        PowerAutomate = @()
        PowerBI = @()
        SecurityPolicies = @()
    }
    
    # Try to get Power Apps info
    $powerAppsResult = Invoke-SafeCommand -Command {
        Get-AdminPowerApp -ErrorAction Stop
    } -ErrorMessage "Failed to retrieve Power Apps" -ContinueOnError
    
    if ($powerAppsResult.Success) {
        $results.PowerApps = $powerAppsResult.Result
    }
    
    # Try to get Power Automate flows
    $flowsResult = Invoke-SafeCommand -Command {
        Get-AdminFlow -ErrorAction Stop
    } -ErrorMessage "Failed to retrieve Power Automate flows" -ContinueOnError
    
    if ($flowsResult.Success) {
        $results.PowerAutomate = $flowsResult.Result
    }
    
    # Try to get Power BI workspaces
    $powerBIResult = Invoke-SafeCommand -Command {
        Get-PowerBIWorkspace -Scope Organization -ErrorAction Stop
    } -ErrorMessage "Failed to retrieve Power BI workspaces" -ContinueOnError
    
    if ($powerBIResult.Success) {
        $results.PowerBI = $powerBIResult.Result
    }
    
    # Return results even if some components failed
    return $results
}

# Export the function for use in other scripts
Export-ModuleMember -Function Get-PowerPlatformSecurity