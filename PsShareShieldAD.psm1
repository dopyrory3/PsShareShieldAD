function Reset-ADUserPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

    # setup the environment as best we can
    begin {
        # check if the ActiveDirectory module is loaded
        if (-not (Get-Module -Name "ActiveDirectory")) {
            Import-Module -Name "ActiveDirectory"
        }

        # Set the username
        $username = $Identity
    }

    end {
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
            $password = (Invoke-RestMethod -Uri "https://dinopass.com/password/strong" -Method "GET") `
            | ConvertTo-SecureString -AsPlainText -Force

            # reset the password for the user, set the reset flag to true if successful
            $reset = $false
            try {
                Set-ADAccountPassword -Identity $username -NewPassword $password -Reset
                $reset = $true
            }
            catch [Microsoft.ActiveDirectory.Management.ADPasswordComplexityException] {
                $reset = $false
            }
            catch [System.UnauthorizedAccessException] {
                Write-Error "Access denied to reset password for $username"
                return
            }
        } until ($reset -eq $true)

        # we need to extract the password from the SecureString to send it to ShareShield, then clear it from memory
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

        # create a ShareShield link to share the password securely
        $ssLink = New-ShareShieldSecret -Secret $password -ExpiresInDays 3

        # clear the password from memory
        $password = $null

        # get the ShareShield link URL and copy it to the clipboard, write it out too
        $ssLinkUrl = $ssLink.Url
        Write-Host "Password reset for $username. Link: $ssLinkUrl"
        $ssLinkUrl | Set-Clipboard
        Write-Host "Password copied to clipboard!"
    }
}