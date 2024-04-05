<#
.SYNOPSIS
This script resets the password for a user in Active Directory and shares it securely using ShareShield.

.DESCRIPTION
This script is intended to be executed by the Active Directory Users and Computers MMC snap-in.

.PARAMETER ObjectPath
ADSI path to the AD object on which the context menu action is being invoked.

.PARAMETER ObjectType
Type/class of the object on which the context menu action is being invoked.

.EXAMPLE
Reset-PasswordWithShareShield.ps1 "LDAP://CN=PC01,CN=Users,DC=contoso,DC=com" username

#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $ObjectPath,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet('user')]
    [string] $ObjectType
)

# Change the PowerShell window title
$Host.ui.RawUI.WindowTitle = 'Resetting password...'

# Fetch the computer object from AD
[adsi] $user = $ObjectPath

# Check that we have a user object with a valid samaccountname
if (-not $user.samaccountname) {
    Write-Error "The object does not have a valid samaccountname."
    return
}

# check if the ActiveDirectory module is loaded
if (-not (Get-Module -Name "ActiveDirectory")) {
    Import-Module -Name "ActiveDirectory"
}

# Set the username
[string] $username = $user.samaccountname

# Check if the user exists in Active Directory
if (-not (Get-ADUser -Filter { SamAccountName -eq $username })) {
    Write-Error "User $username not found in Active Directory"
    return
}

# nullify the password variable
$password = $null

# loop until the password is reset
do {
    # generate a strong password using the DinoPass API, immediately encrypt it to a SecureString
    $password = (Invoke-WebRequest -UseBasicParsing -Uri "https://dinopass.com/password/strong" -Method "GET") `
    | Select-Object -ExpandProperty Content | ConvertTo-SecureString -AsPlainText -Force

    # reset the password for the user, set the reset flag to true if successful
    $reset = $false
    try {
        Set-ADAccountPassword -Identity $username -NewPassword $password -Reset
        $reset = $true
    }
    catch {
        $reset = $false
    }
} until ($reset -eq $true)

# we need to extract the password from the SecureString to send it to ShareShield, then clear it from memory
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# create a ShareShield link to share the password securely
$apiUrl = "https://api.shareshield.net/v1/secrets"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}
$body = @{
    "password" = $password
    "expiry"   = 3
    "showUrl"  = $true
}

try {
    $ssLink = Invoke-WebRequest -UseBasicParsing -Uri $apiUrl -Method Post -Headers $headers -Body ($body | ConvertTo-Json)
    $ssLink = $ssLink.Content | ConvertFrom-Json
}
catch {
    Write-Error "Couldn't create ShareShield link: $($_.Exception.Message)"
    return 1
}

# clear the password from memory
$password = $null

# get the ShareShield link URL and copy it to the clipboard, write it out too
$ssLinkUrl = $ssLink.url

# Launch the HTA file with the link parameter
[Microsoft.ActiveDirectory.Management.ADForest] $forest = Get-ADForest -Current LoggedOnUser -ErrorAction Stop
[string] $scriptDirectory = '\\{0}\NETLOGON\ContextMenu' -f $forest.RootDomain

#$htaFilePath = "C:\Users\adm.rcarter\Documents\test2.hta?link=$ssLinkUrl"
$htaFilePath = "$scriptDirectory\Reset-PasswordWithShareShield.hta?link=$ssLinkUrl"
Start-Process -FilePath mshta.exe -ArgumentList $htaFilePath