#
# Test the current Token with a sample API call and verifies the response.
#

#Load the module and remove stale instances to be safe.
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Get-Module ClashKudos | Remove-Module -Force
Import-Module (Join-Path $path '..' | Join-Path -ChildPath 'ClashKudos.psd1' )


$globalConfig = (Get-KudosGlobalSettings)

$token = $globalConfig.Token
$hook = $globalConfig.DataResult_Hook

Set-SCToken -token $token

#Test
$message = "Token is currently valid."
try {
    if(-not (Test-SCToken)) {
        $message = "The configured token is no longer valid."
    }
} catch {
    $message = "There was an error attempting to test the token: $($_.Exception.Message)"
}

Send-WebhookMessage `
    -hook $hook `
    -message $message
