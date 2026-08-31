# SteelSeries Rival 3 Gen 2 USB Watcher

A small PowerShell script that automatically applies custom RGB lighting settings to a **SteelSeries Rival 3 Gen 2** when the mouse is connected.

The Rival 3 Gen 2 does not persist the desired RGB configuration in hardware memory, so the lighting can revert to its default rainbow effect when the mouse is connected or the PC starts. This script detects the mouse and uses [`rivalcfg`](https://github.com/flozz/rivalcfg) to apply the desired colors automatically.

## Features

- Detects the Rival 3 Gen 2 by its USB VID/PID
- Applies the desired RGB configuration when Windows starts
- Detects subsequent mouse disconnects and reconnects
- Automatically reapplies the RGB configuration after reconnecting
- Waits for the mouse to become available during startup
- Optional logging
- Designed to run in the background as a Windows Scheduled Task

## Configuration

At the beginning of the script you can configure the following:

```powershell
$enableLogging = $true

$logPath = "D:\Projects\usb-watcher\logs.txt"
$vidPid = "VID_1038&PID_1870"
$cliToolPath = "D:\Projects\usb-watcher\rivalcfg-cli\rivalcfg.exe"

$cliToolArgsList = @(
    "--reactive-color #8800FF",
    "--strip-top-color fuchsia",
    "--strip-middle-color fuchsia",
    "--strip-bottom-color fuchsia"
)
```

### Scheduled Task

To run the script automatically when Windows starts, create a Windows Scheduled Task with:

**Trigger:**
- At startup

**Action:**
- Program: `powershell.exe`
- Arguments:

```text
-NoProfile -ExecutionPolicy Bypass -File "C:\Path\To\watcher.ps1"
```

It is recommended to configure the task to run whether the user is logged on or not and, if necessary, with elevated privileges.

A short startup delay can also be useful to give Windows time to initialize USB devices.
