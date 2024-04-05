@ECHO OFF
REM Execute a PowerShell script with the same name and pass-through all command line parameters
start powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%~dpn0.ps1" %*