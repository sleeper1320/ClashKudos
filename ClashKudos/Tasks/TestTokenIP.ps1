#
# Test the current Token IP and alerts if not valid.
#

#Load the module and remove stale instances to be safe.
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Get-Module ClashKudos | Remove-Module -Force
Import-Module (Join-Path $path '..' | Join-Path -ChildPath 'ClashKudos.psd1' )

$globalConfig = (Get-KudosGlobalSettings)

$tokenIP = $globalConfig.TokenIP
$hook = $globalConfig.DataResult_Hook

Set-SCTokenIP -IP $tokenIP

#Test
$message = "TokenIP matches expected value."
try {
    if(-not (Test-SCTokenIP)) {
        $message = "The configure IP no longer matches the expected value."
    }
} catch {
    $message = "There was an error attempting to test the token: $($_.Exception.Message)"
}

Send-WebhookMessage `
    -hook $hook `
    -message $message
