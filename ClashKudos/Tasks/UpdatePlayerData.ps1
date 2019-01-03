#
# Updates the Player Data for every clan in the config
#

#Load the module and remove stale instances to be safe.
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Get-Module ClashKudos | Remove-Module -Force
Import-Module (Join-Path $path '..' | Join-Path -ChildPath 'ClashKudos.psd1' )

$globalConfig = (Get-KudosGlobalSettings)

$token = $globalConfig.Token
$hook = $globalConfig.DataResult_Hook
$message = "Updated all clans successfully."

#Set the token and go.
Set-SCToken -token $token

try {
    Update-PlayerData
} catch {
    $message = "There was an error attempting to update one or more clans."
}

Send-WebhookMessage `
    -hook $hook `
    -message $message
