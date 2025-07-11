#Requires -Version 5.1
<#
.SYNOPSIS
    PowerReview Professional UI Components Library
    Advanced UI/UX components for enterprise assessment platform
#>

# Professional Color Scheme
$script:ColorScheme = @{
    Primary = "Cyan"
    Secondary = "Green"
    Accent = "Yellow"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Blue"
    Text = "White"
    Muted = "Gray"
    Background = "Black"
}

#region Advanced UI Components

function Show-SplashScreen {
    Clear-Host
    
    $width = $Host.UI.RawUI.WindowSize.Width
    $height = $Host.UI.RawUI.WindowSize.Height
    
    # Professional gradient effect
    $gradient = @(
        "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░",
        "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒",
        "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓",
        "███████████████████████████████████████████████████████████████████████████████████████████████████████████"
    )
    
    foreach ($line in $gradient) {
        Write-Host $line -ForegroundColor DarkCyan
    }
    
    # 3D Logo Effect
    $logo = @"

    ██████╗  ██████╗ ██╗    ██╗███████╗██████╗ ██████╗ ███████╗██╗   ██╗██╗███████╗██╗    ██╗
    ██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗██╔══██╗██╔════╝██║   ██║██║██╔════╝██║    ██║
    ██████╔╝██║   ██║██║ █╗ ██║█████╗  ██████╔╝██████╔╝█████╗  ██║   ██║██║█████╗  ██║ █╗ ██║
    ██╔═══╝ ██║   ██║██║███╗██║██╔══╝  ██╔══██╗██╔══██╗██╔══╝  ╚██╗ ██╔╝██║██╔══╝  ██║███╗██║
    ██║     ╚██████╔╝╚███╔███╔╝███████╗██║  ██║██║  ██║███████╗ ╚████╔╝ ██║███████╗╚███╔███╔╝
    ╚═╝      ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚═╝╚══════╝ ╚══╝╚══╝
                                                                                               v4.0
"@
    
    # Center the logo
    $logoLines = $logo -split "`n"
    foreach ($line in $logoLines) {
        $padding = [Math]::Max(0, ($width - $line.Length) / 2)
        Write-Host (" " * $padding) -NoNewline
        
        # Gradient effect on logo
        for ($i = 0; $i -lt $line.Length; $i++) {
            $char = $line[$i]
            if ($char -ne ' ') {
                $color = if ($i % 3 -eq 0) { "Cyan" } elseif ($i % 3 -eq 1) { "Blue" } else { "DarkCyan" }
                Write-Host $char -NoNewline -ForegroundColor $color
            }
            else {
                Write-Host $char -NoNewline
            }
        }
        Write-Host ""
    }
    
    Write-Host ""
    Write-Host ""
    
    # Animated tagline
    $tagline = "Enterprise Security Assessment Platform for Microsoft 365 & Azure"
    $padding = [Math]::Max(0, ($width - $tagline.Length) / 2)
    Write-Host (" " * $padding) -NoNewline
    
    foreach ($char in $tagline.ToCharArray()) {
        Write-Host $char -NoNewline -ForegroundColor White
        Start-Sleep -Milliseconds 20
    }
    
    Write-Host ""
    Write-Host ""
    
    # Loading animation
    $padding = [Math]::Max(0, ($width - 50) / 2)
    Write-Host (" " * $padding) -NoNewline
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    
    for ($i = 0; $i -lt 48; $i++) {
        Write-Host "█" -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 30
    }
    
    Write-Host "]" -ForegroundColor DarkGray
    
    Start-Sleep -Milliseconds 500
}

function Show-ProfessionalMenu {
    param(
        [string]$Title,
        [array]$MenuItems,
        [string]$Footer = ""
    )
    
    Clear-Host
    
    $width = 110
    
    # Header with gradient border
    Write-Host ("╔" + ("═" * ($width - 2)) + "╗") -ForegroundColor Cyan
    Write-Host ("║" + (" " * ($width - 2)) + "║") -ForegroundColor Cyan
    
    # Title
    $titlePadding = [Math]::Max(0, ($width - $Title.Length - 2) / 2)
    Write-Host "║" -NoNewline -ForegroundColor Cyan
    Write-Host (" " * $titlePadding) -NoNewline
    Write-Host $Title -NoNewline -ForegroundColor White
    Write-Host (" " * ($width - $titlePadding - $Title.Length - 2)) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    
    Write-Host ("║" + (" " * ($width - 2)) + "║") -ForegroundColor Cyan
    Write-Host ("╠" + ("═" * ($width - 2)) + "╣") -ForegroundColor Cyan
    
    # Menu items with hover effect simulation
    foreach ($item in $MenuItems) {
        Write-Host "║  " -NoNewline -ForegroundColor Cyan
        
        if ($item.Separator) {
            Write-Host ("─" * ($width - 6)) -NoNewline -ForegroundColor DarkGray
            Write-Host "  ║" -ForegroundColor Cyan
        }
        else {
            # Menu number/key
            Write-Host ("[" + $item.Key + "]") -NoNewline -ForegroundColor Yellow
            Write-Host " " -NoNewline
            
            # Icon
            if ($item.Icon) {
                Write-Host $item.Icon -NoNewline -ForegroundColor $item.IconColor
                Write-Host " " -NoNewline
            }
            
            # Title
            Write-Host ("{0,-30}" -f $item.Title) -NoNewline -ForegroundColor White
            
            # Description
            if ($item.Description) {
                Write-Host " - " -NoNewline -ForegroundColor DarkGray
                $desc = $item.Description
                if ($desc.Length -gt 60) {
                    $desc = $desc.Substring(0, 57) + "..."
                }
                Write-Host $desc -NoNewline -ForegroundColor Gray
            }
            
            # Padding
            $totalLength = 3 + 3 + 30 + 3 + $desc.Length + 4
            $remainingSpace = $width - $totalLength - 2
            Write-Host (" " * $remainingSpace) -NoNewline
            Write-Host "║" -ForegroundColor Cyan
        }
    }
    
    # Footer
    Write-Host ("╠" + ("═" * ($width - 2)) + "╣") -ForegroundColor Cyan
    
    if ($Footer) {
        Write-Host "║ " -NoNewline -ForegroundColor Cyan
        Write-Host $Footer -NoNewline -ForegroundColor DarkGray
        Write-Host (" " * ($width - $Footer.Length - 3)) -NoNewline
        Write-Host "║" -ForegroundColor Cyan
    }
    
    Write-Host ("╚" + ("═" * ($width - 2)) + "╝") -ForegroundColor Cyan
    Write-Host ""
    
    # Input prompt with styled cursor
    Write-Host "  ▶ " -NoNewline -ForegroundColor Cyan
    Write-Host "Enter your selection: " -NoNewline -ForegroundColor White
}

function Show-ProgressPanel {
    param(
        [string]$Title,
        [int]$PercentComplete,
        [string]$Status,
        [string]$CurrentOperation = ""
    )
    
    $width = 80
    $barWidth = $width - 20
    
    # Don't clear host, update in place
    Write-Host "`r" -NoNewline
    
    # Progress bar
    $completed = [Math]::Round(($PercentComplete / 100) * $barWidth)
    $remaining = $barWidth - $completed
    
    Write-Host "  $Title " -NoNewline -ForegroundColor Cyan
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    
    # Gradient progress bar
    for ($i = 0; $i -lt $completed; $i++) {
        $color = if ($PercentComplete -lt 33) { "Red" }
        elseif ($PercentComplete -lt 66) { "Yellow" }
        else { "Green" }
        Write-Host "█" -NoNewline -ForegroundColor $color
    }
    
    Write-Host ("░" * $remaining) -NoNewline -ForegroundColor DarkGray
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$PercentComplete%" -NoNewline -ForegroundColor White
    
    if ($CurrentOperation) {
        Write-Host " - $CurrentOperation" -NoNewline -ForegroundColor Gray
    }
    
    # Clear to end of line
    Write-Host (" " * 20) -NoNewline
}

function Show-InfoPanel {
    param(
        [string]$Title,
        [hashtable]$Information,
        [string]$Type = "Info"
    )
    
    $width = 100
    $borderColor = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "Cyan" }
    }
    
    $icon = switch ($Type) {
        "Success" { "✅" }
        "Warning" { "⚠️" }
        "Error" { "❌" }
        default { "ℹ️" }
    }
    
    # Top border
    Write-Host ("┌" + ("─" * ($width - 2)) + "┐") -ForegroundColor $borderColor
    
    # Title
    Write-Host "│ " -NoNewline -ForegroundColor $borderColor
    Write-Host "$icon $Title" -NoNewline -ForegroundColor White
    Write-Host (" " * ($width - $Title.Length - 5)) -NoNewline
    Write-Host "│" -ForegroundColor $borderColor
    
    # Separator
    Write-Host ("├" + ("─" * ($width - 2)) + "┤") -ForegroundColor $borderColor
    
    # Information
    foreach ($item in $Information.GetEnumerator()) {
        Write-Host "│ " -NoNewline -ForegroundColor $borderColor
        Write-Host ("{0,-30}" -f ($item.Key + ":")) -NoNewline -ForegroundColor White
        Write-Host $item.Value -NoNewline -ForegroundColor Gray
        
        $totalLength = 30 + $item.Value.ToString().Length + 3
        $padding = $width - $totalLength
        Write-Host (" " * $padding) -NoNewline
        Write-Host "│" -ForegroundColor $borderColor
    }
    
    # Bottom border
    Write-Host ("└" + ("─" * ($width - 2)) + "┘") -ForegroundColor $borderColor
}

function Show-TenantSelector {
    param([array]$Tenants)
    
    Clear-Host
    
    Write-Host @"
    ╔═══════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                          TENANT SELECTION                                                 ║
    ╠═══════════════════════════════════════════════════════════════════════════════════════════════════════════╣
    ║                                                                                                           ║
    ║  Select tenants to include in this assessment:                                                           ║
    ║                                                                                                           ║
"@ -ForegroundColor Cyan
    
    $selectedTenants = @()
    
    for ($i = 0; $i -lt $Tenants.Count; $i++) {
        $tenant = $Tenants[$i]
        
        Write-Host "    ║  " -NoNewline -ForegroundColor Cyan
        Write-Host ("[" + ($i + 1) + "]") -NoNewline -ForegroundColor Yellow
        Write-Host " " -NoNewline
        
        # Checkbox style
        Write-Host "[ ]" -NoNewline -ForegroundColor DarkGray
        Write-Host " " -NoNewline
        
        # Tenant info
        Write-Host ("{0,-30}" -f $tenant.Name) -NoNewline -ForegroundColor White
        Write-Host ("{0,-30}" -f $tenant.TenantId) -NoNewline -ForegroundColor Gray
        Write-Host ("{0,-15}" -f $tenant.Region) -NoNewline -ForegroundColor DarkGray
        Write-Host "   ║" -ForegroundColor Cyan
    }
    
    Write-Host @"
    ║                                                                                                           ║
    ╠═══════════════════════════════════════════════════════════════════════════════════════════════════════════╣
    ║  [A] Select All    [N] Select None    [I] Invert Selection    [C] Continue                               ║
    ╚═══════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    
"@ -ForegroundColor Cyan
    
    Write-Host "  Enter selections (comma-separated or use commands): " -NoNewline -ForegroundColor White
    $selection = Read-Host
    
    return $selection
}

function Show-ModuleConfiguration {
    param([array]$Modules)
    
    Clear-Host
    
    $width = 110
    
    Write-Host ("╔" + ("═" * ($width - 2)) + "╗") -ForegroundColor Cyan
    Write-Host "║" -NoNewline -ForegroundColor Cyan
    Write-Host ("MODULE CONFIGURATION".PadLeft(($width + 20) / 2).PadRight($width - 2)) -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Cyan
    Write-Host ("╠" + ("═" * ($width - 2)) + "╣") -ForegroundColor Cyan
    
    foreach ($module in $Modules) {
        # Module header
        Write-Host "║" -NoNewline -ForegroundColor Cyan
        Write-Host (" $($module.Icon) $($module.Name)".PadRight($width - 2)) -NoNewline -BackgroundColor DarkBlue -ForegroundColor White
        Write-Host "║" -ForegroundColor Cyan
        
        # Module description
        Write-Host "║   " -NoNewline -ForegroundColor Cyan
        Write-Host $module.Description -NoNewline -ForegroundColor Gray
        Write-Host (" " * ($width - $module.Description.Length - 5)) -NoNewline
        Write-Host "║" -ForegroundColor Cyan
        
        # Module options
        Write-Host "║" -NoNewline -ForegroundColor Cyan
        Write-Host ("   ├─ Depth: ".PadRight(25)) -NoNewline -ForegroundColor DarkGray
        Write-Host ("[Basic] [Standard] [Deep]".PadRight($width - 27)) -NoNewline -ForegroundColor Yellow
        Write-Host "║" -ForegroundColor Cyan
        
        Write-Host "║" -NoNewline -ForegroundColor Cyan
        Write-Host ("   ├─ Include: ".PadRight(25)) -NoNewline -ForegroundColor DarkGray
        Write-Host ("[✓] Yes  [ ] No".PadRight($width - 27)) -NoNewline -ForegroundColor Green
        Write-Host "║" -ForegroundColor Cyan
        
        Write-Host "║" -NoNewline -ForegroundColor Cyan
        Write-Host ("   └─ Options: ".PadRight(25)) -NoNewline -ForegroundColor DarkGray
        Write-Host ("[Configure]".PadRight($width - 27)) -NoNewline -ForegroundColor Cyan
        Write-Host "║" -ForegroundColor Cyan
        
        # Separator
        if ($module -ne $Modules[-1]) {
            Write-Host ("║" + (" " * ($width - 2)) + "║") -ForegroundColor Cyan
        }
    }
    
    Write-Host ("╚" + ("═" * ($width - 2)) + "╝") -ForegroundColor Cyan
}

function Show-Notification {
    param(
        [string]$Message,
        [string]$Type = "Info",
        [int]$Duration = 3000
    )
    
    $icon = switch ($Type) {
        "Success" { "✅" }
        "Warning" { "⚠️" }
        "Error" { "❌" }
        "Info" { "ℹ️" }
        default { "💬" }
    }
    
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Info" { "Cyan" }
        default { "White" }
    }
    
    $width = $Message.Length + 8
    
    # Position at bottom right
    $startPos = $Host.UI.RawUI.CursorPosition
    $notificationPos = New-Object System.Management.Automation.Host.Coordinates
    $notificationPos.X = $Host.UI.RawUI.WindowSize.Width - $width - 2
    $notificationPos.Y = $Host.UI.RawUI.WindowSize.Height - 5
    
    $Host.UI.RawUI.CursorPosition = $notificationPos
    
    # Draw notification
    Write-Host ("┌" + ("─" * ($width - 2)) + "┐") -ForegroundColor $color
    
    $notificationPos.Y++
    $Host.UI.RawUI.CursorPosition = $notificationPos
    Write-Host "│ " -NoNewline -ForegroundColor $color
    Write-Host "$icon $Message" -NoNewline -ForegroundColor White
    Write-Host " │" -ForegroundColor $color
    
    $notificationPos.Y++
    $Host.UI.RawUI.CursorPosition = $notificationPos
    Write-Host ("└" + ("─" * ($width - 2)) + "┘") -ForegroundColor $color
    
    # Return cursor
    $Host.UI.RawUI.CursorPosition = $startPos
    
    if ($Duration -gt 0) {
        Start-Sleep -Milliseconds $Duration
        
        # Clear notification
        for ($i = 0; $i -lt 3; $i++) {
            $notificationPos.Y = $Host.UI.RawUI.WindowSize.Height - 5 + $i
            $Host.UI.RawUI.CursorPosition = $notificationPos
            Write-Host (" " * ($width + 2))
        }
        
        $Host.UI.RawUI.CursorPosition = $startPos
    }
}

function Show-ComplianceMatrix {
    param([hashtable]$ComplianceData)
    
    Clear-Host
    
    Write-Host @"
    ╔═══════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                      COMPLIANCE REQUIREMENTS MATRIX                                       ║
    ╠═══════════════════════════════════════════════════════════════════════════════════════════════════════════╣
"@ -ForegroundColor Cyan
    
    # Headers
    Write-Host "    ║  " -NoNewline -ForegroundColor Cyan
    Write-Host ("{0,-20}" -f "Framework") -NoNewline -ForegroundColor Yellow
    Write-Host ("{0,-15}" -f "Status") -NoNewline -ForegroundColor Yellow
    Write-Host ("{0,-15}" -f "Score") -NoNewline -ForegroundColor Yellow
    Write-Host ("{0,-20}" -f "Last Assessed") -NoNewline -ForegroundColor Yellow
    Write-Host ("{0,-30}" -f "Key Requirements") -NoNewline -ForegroundColor Yellow
    Write-Host " ║" -ForegroundColor Cyan
    
    Write-Host "    ╠" -NoNewline -ForegroundColor Cyan
    Write-Host ("═" * 103) -NoNewline -ForegroundColor Cyan
    Write-Host "╣" -ForegroundColor Cyan
    
    $frameworks = @("GDPR", "HIPAA", "SOC2", "ISO27001", "PCI-DSS", "NIST", "CIS")
    
    foreach ($framework in $frameworks) {
        Write-Host "    ║  " -NoNewline -ForegroundColor Cyan
        
        # Framework name with icon
        $icon = switch ($framework) {
            "GDPR" { "🇪🇺" }
            "HIPAA" { "🏥" }
            "SOC2" { "🔒" }
            "ISO27001" { "📋" }
            "PCI-DSS" { "💳" }
            "NIST" { "🏛️" }
            "CIS" { "🛡️" }
        }
        
        Write-Host ("{0,-20}" -f "$icon $framework") -NoNewline -ForegroundColor White
        
        # Status
        $status = if ($ComplianceData[$framework]) { $ComplianceData[$framework].Status } else { "Not Assessed" }
        $statusColor = switch ($status) {
            "Compliant" { "Green" }
            "Partial" { "Yellow" }
            "Non-Compliant" { "Red" }
            default { "Gray" }
        }
        Write-Host ("{0,-15}" -f $status) -NoNewline -ForegroundColor $statusColor
        
        # Score
        $score = if ($ComplianceData[$framework]) { "$($ComplianceData[$framework].Score)%" } else { "N/A" }
        $scoreColor = if ($ComplianceData[$framework]) {
            if ($ComplianceData[$framework].Score -ge 80) { "Green" }
            elseif ($ComplianceData[$framework].Score -ge 60) { "Yellow" }
            else { "Red" }
        } else { "Gray" }
        Write-Host ("{0,-15}" -f $score) -NoNewline -ForegroundColor $scoreColor
        
        # Last assessed
        $lastAssessed = if ($ComplianceData[$framework]) { 
            $ComplianceData[$framework].LastAssessed.ToString("yyyy-MM-dd") 
        } else { "Never" }
        Write-Host ("{0,-20}" -f $lastAssessed) -NoNewline -ForegroundColor Gray
        
        # Key requirements
        $requirements = switch ($framework) {
            "GDPR" { "Data Protection, Privacy Rights" }
            "HIPAA" { "PHI Security, Access Controls" }
            "SOC2" { "Security, Availability, Confidentiality" }
            "ISO27001" { "ISMS, Risk Management" }
            "PCI-DSS" { "Cardholder Data Protection" }
            "NIST" { "Cybersecurity Framework" }
            "CIS" { "Security Best Practices" }
        }
        Write-Host ("{0,-30}" -f $requirements) -NoNewline -ForegroundColor DarkGray
        Write-Host " ║" -ForegroundColor Cyan
    }
    
    Write-Host @"
    ╚═══════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    
"@ -ForegroundColor Cyan
}

function Show-RealTimeMetrics {
    param(
        [hashtable]$Metrics,
        [int]$RefreshInterval = 1000
    )
    
    $width = 110
    
    # Save cursor position
    $originalPos = $Host.UI.RawUI.CursorPosition
    
    # Draw metrics panel
    Write-Host ("┌" + ("─" * ($width - 2)) + "┐") -ForegroundColor Cyan
    Write-Host "│" -NoNewline -ForegroundColor Cyan
    Write-Host ("REAL-TIME ASSESSMENT METRICS".PadLeft(($width + 28) / 2).PadRight($width - 2)) -NoNewline -ForegroundColor Yellow
    Write-Host "│" -ForegroundColor Cyan
    Write-Host ("├" + ("─" * ($width - 2)) + "┤") -ForegroundColor Cyan
    
    # Metrics rows
    $metricRows = @(
        @{Label="Items Scanned"; Value=$Metrics.ItemsScanned; Icon="📊"},
        @{Label="Issues Found"; Value=$Metrics.IssuesFound; Icon="⚠️"},
        @{Label="Critical Findings"; Value=$Metrics.CriticalFindings; Icon="🚨"},
        @{Label="Data Processed"; Value="$($Metrics.DataProcessedMB) MB"; Icon="💾"},
        @{Label="Elapsed Time"; Value=$Metrics.ElapsedTime; Icon="⏱️"},
        @{Label="Current Module"; Value=$Metrics.CurrentModule; Icon="🔧"}
    )
    
    foreach ($metric in $metricRows) {
        Write-Host "│  " -NoNewline -ForegroundColor Cyan
        Write-Host "$($metric.Icon) " -NoNewline
        Write-Host ("{0,-25}" -f ($metric.Label + ":")) -NoNewline -ForegroundColor White
        
        # Animated value update
        $valueColor = "Green"
        if ($metric.Label -eq "Critical Findings" -and $metric.Value -gt 0) {
            $valueColor = "Red"
        }
        elseif ($metric.Label -eq "Issues Found" -and $metric.Value -gt 10) {
            $valueColor = "Yellow"
        }
        
        Write-Host ("{0,-20}" -f $metric.Value) -NoNewline -ForegroundColor $valueColor
        
        # Progress indicator for current module
        if ($metric.Label -eq "Current Module") {
            Write-Host "[" -NoNewline -ForegroundColor DarkGray
            for ($i = 0; $i -lt 10; $i++) {
                if ($i -lt ($Metrics.ModuleProgress / 10)) {
                    Write-Host "█" -NoNewline -ForegroundColor Green
                }
                else {
                    Write-Host "░" -NoNewline -ForegroundColor DarkGray
                }
            }
            Write-Host "] $($Metrics.ModuleProgress)%" -NoNewline -ForegroundColor White
        }
        
        # Padding
        $currentLength = $Host.UI.RawUI.CursorPosition.X - 1
        $padding = $width - $currentLength - 1
        Write-Host (" " * $padding) -NoNewline
        Write-Host "│" -ForegroundColor Cyan
    }
    
    Write-Host ("└" + ("─" * ($width - 2)) + "┘") -ForegroundColor Cyan
    
    # Restore cursor position
    $Host.UI.RawUI.CursorPosition = $originalPos
}

#endregion

#region Export Functions

Export-ModuleMember -Function @(
    'Show-SplashScreen',
    'Show-ProfessionalMenu',
    'Show-ProgressPanel',
    'Show-InfoPanel',
    'Show-TenantSelector',
    'Show-ModuleConfiguration',
    'Show-Notification',
    'Show-ComplianceMatrix',
    'Show-RealTimeMetrics'
) -Variable @(
    'ColorScheme'
)