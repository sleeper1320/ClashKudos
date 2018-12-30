<#
 # Tests against the Discord Interface Module
 #>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module ClashKudos | Remove-Module -Force
Import-Module $root\..\ClashKudos.psd1 -Force

InModuleScope 'Discord' {
    Describe 'Discord' {
        Context 'Send-WebhookMessage' {
            it 'should error out when an invalid hook uri is passed in' {
                {Send-WebhookMessage -hook 'http: //google.com/' -message 'Test Message'} | Should throw 'The hook passed in is not a valid uri.'
            }
            it 'should error out when an invalid message is passed in' {
                {Send-WebhookMessage -hook 'http://testurl.example/' -message $null} | Should throw `
                    'Cannot validate argument on parameter ''message''. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again.'

                {Send-WebhookMessage -hook 'http://testurl.example/' -message ''} | Should throw `
                    'Cannot validate argument on parameter ''message''. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again.'
            }
            it 'should run through the core functions' {
                Mock 'Invoke-WebRequest' {}

                Send-WebhookMessage -hook 'http://testurl.example/' -message 'Test Message'

                Assert-MockCalled 'Invoke-WebRequest'
            }
        }
    }
}
