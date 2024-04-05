<#
.SYNOPSIS
Registers custom context menu item for the Active Directory Users and Computers snap-in.
#>

#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

Import-Module -Name ActiveDirectory -ErrorAction Stop

[Microsoft.ActiveDirectory.Management.ADRootDSE] $rootDSE = Get-ADRootDSE -ErrorAction Stop
[Microsoft.ActiveDirectory.Management.ADForest] $forest = Get-ADForest -Current LoggedOnUser -ErrorAction Stop

# The settings are stored in the configuration partition and are language-specific
[string] $userDisplaySpecifierTemplate = 'CN=user-Display,CN={0:X2},CN=DisplaySpecifiers,' + $rootDSE.configurationNamingContext

# Although this script only registers a single menu item, it can easily be modified to register additional ones.
# TODO: Translation into all languages supported by AD is needed.
[hashtable[]] $menuItems = @(
    @{
        Order  = 1
        Script = 'Reset-PasswordWithShareShield.bat'
        Labels = @(
            @{
                LCID = 0x409 # US English (en-us)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x405 # Czech (cs)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x407 # German (de)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x40C # French (fr)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x404 # Chinese (zh-tw)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x406 # Danish (da)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x408 # Greek (el)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x410 # Italian (it)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x411 # Japanese (ja)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x412 # Korean (ko)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x413 # Dutch (nl)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x414 # Norwegian (no)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x415 # Polish (pl)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x416 # Portuguese/Brazil (pt-br)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x419 # Russian (ru)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x40B # Finnish (fi)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x40E # Hungarian (hu)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x41D # Swedish (sv)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x41F # Turkish (tr)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x804 # Chinese (zh-cn)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0x816 # Potruguese/Portugal (pt)
                Text = 'Reset password with ShareShield'
            }, @{
                LCID = 0xC0A # Spanish (es)
                Text = 'Reset password with ShareShield'
            }
        )
    }
)

# Scripts referenced by the context menus are placed in this directory
[string] $scriptDirectory = '\\{0}\NETLOGON\ContextMenu' -f $forest.RootDomain

foreach ($menuItem in $menuItems) {
    [string] $scriptPath = Join-Path -Path $scriptDirectory -ChildPath $menuItem.Script -ErrorAction Stop
    [int] $menuItemOrder = $menuItem.Order

    foreach ($label in $menuItem.Labels) {
        # Perform the language-specific registration of a single context menu item
        [string] $userDisplaySpecifier = $userDisplaySpecifierTemplate -f $label.LCID
        [string] $contextMenuValue = '{0},{1},{2}' -f $menuItemOrder, $label.Text, $scriptPath
        Set-ADObject -Identity $userDisplaySpecifier -Add @{ contextMenu = $contextMenuValue } -Verbose -ErrorAction Stop
    }
}