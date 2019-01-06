#
# Sends the daily kudos for the specified clan.
#

param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $ClanName
)

#Load the module and remove stale instances to be safe.
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Get-Module ClashKudos | Remove-Module -Force
Import-Module (Join-Path $path '..' | Join-Path -ChildPath 'ClashKudos.psd1' )
