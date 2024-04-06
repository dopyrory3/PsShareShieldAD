# PsShareShieldAD

## Description
PsShareShieldAD is a PowerShell made to integrate PsShareShield with Active Directory.
It exposes a new cmdlet that allows you to quickly reset a password and generate a link using ShareShield.
Currently the password is reset to a password generated via dinopass.com and the link is generated using the ShareShield API.
In a future release the password will have in-module or shareshield-generated password.

## Installation
```powershell
# The module depends on PsShareShield, so you need to install it first
Install-Module -Name PsShareShield
Install-Module -Name PsShareShieldAD
```

## Usage
```powershell
Import-Module -Name PsShareShieldAD

# Reset the password of a user and return a link, copied to the clipboard
Reset-ADUserPassword -Identity "username"
```

There's also an Active Directory Users and Computers context menu extension that allows you to reset the password of a user and generate a link using ShareShield.

To install the context menu extension, run the following command in an elevated PowerShell session, this will make a directory in the NETLOGON share and copy the necessary files to it.
```powershell
New-Item -ItemType Directory -Path "\\<domain>\NETLOGON\ContextMenu"
Get-ChildItem -Filter ".\ADUC\Reset-PasswordWithShareShield.*" | ForEach-Object { 
    Copy-Item -Path $_.FullName -Destination "\\<domain>\NETLOGON\ContextMenu" -Force
    }

.\Register-AducContextMenu.ps1
```
![alt text](/screenshots\1.png)
![alt text](/screenshots/2.png)
## License
MIT

# Contributing
If you would like to contribute, please open an issue or a pull request.

