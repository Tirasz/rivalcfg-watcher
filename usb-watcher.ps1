$enableLogging = $false
$logPath = "D:\Projects\usb-watcher\logs.txt"
$vidPid = "VID_1038&PID_1870"

$cliToolPath = "D:\Projects\usb-watcher\rivalcfg-cli\rivalcfg.exe"
$cliToolArgsList = @(
    "--reactive-color #8800FF",
    "--strip-top-color fuchsia",
    "--strip-middle-color fuchsia",
    "--strip-bottom-color fuchsia"
)

$arrivalQuery = "SELECT * FROM __InstanceCreationEvent WITHIN 2 WHERE TargetInstance ISA 'Win32_PnPEntity' AND TargetInstance.DeviceID LIKE '%$vidPid%'"
$removalQuery = "SELECT * FROM __InstanceDeletionEvent WITHIN 2 WHERE TargetInstance ISA 'Win32_PnPEntity' AND TargetInstance.DeviceID LIKE '%$vidPid%'"

$global:mouseTriggered = $false

function Write-Log { param ( [string]$Message ) if ($enableLogging) { Add-Content -Path $logPath -Value $Message } }

function Set-MouseColors {
    param (
        [string]$Path,
        [string]$ToolPath,
        [array]$ToolArgsList
    )

    if ($global:mouseTriggered) {
        return
    }

    $global:mouseTriggered = $true

    foreach ($toolArgs in $ToolArgsList) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $line = "[$timestamp] >>> RUNNING: $ToolPath $toolArgs"

        Write-Log $line

        Start-Process `
            -FilePath $ToolPath `
            -ArgumentList $toolArgs `
            -NoNewWindow `
            -Wait
    }
}

# Wait until the mouse is detected
do {
    $existingMouse = Get-CimInstance Win32_PnPEntity |
        Where-Object {
            $_.DeviceID -like "*$vidPid*"
        }

    if (-not $existingMouse) {
        Start-Sleep -Seconds 1
    }
}
while (-not $existingMouse)

# Mouse is connected, apply the colors
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
$line = "[$timestamp] STARTUP | Mouse detected | Name=$($existingMouse.Name) | DeviceID=$($existingMouse.DeviceID)"
Write-Log $line

Set-MouseColors `
    -Path $logPath `
    -ToolPath $cliToolPath `
    -ToolArgsList $cliToolArgsList

# Register ARRIVAL watcher
Register-WmiEvent `
    -Query $arrivalQuery `
    -SourceIdentifier USBMouseArrival `
    -MessageData @{
        Path = $logPath
        ToolPath = $cliToolPath
        ToolArgsList = $cliToolArgsList
    } `
    -Action {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $path = $Event.MessageData.Path
        $device = $Event.SourceEventArgs.NewEvent.TargetInstance

        $line = "[$timestamp] ARRIVED | Name=$($device.Name) | DeviceID=$($device.DeviceID)"
        Write-Log $line

        Set-MouseColors `
            -Path $path `
            -ToolPath $Event.MessageData.ToolPath `
            -ToolArgsList $Event.MessageData.ToolArgsList
    }

# Register REMOVAL watcher
Register-WmiEvent `
    -Query $removalQuery `
    -SourceIdentifier USBMouseRemoval `
    -MessageData $logPath `
    -Action {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $path = $Event.MessageData
        $device = $Event.SourceEventArgs.NewEvent.TargetInstance

        $line = "[$timestamp] REMOVED | Name=$($device.Name) | DeviceID=$($device.DeviceID)"
        Write-Log $line

        $global:mouseTriggered = $false
    }

# Keep the script alive
Wait-Event