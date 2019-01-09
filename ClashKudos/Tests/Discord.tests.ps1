<#
 # Tests against the Discord Interface Module
 #>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module ClashKudos | Remove-Module -Force
Import-Module $root\..\ClashKudos.psd1 -Force

InModuleScope 'Discord' {
    Describe 'Discord' {
        Context 'Send-WebhookMessage' {
            #Variables used in tests
            $currentTime = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))

            #Mocks
            Mock 'Invoke-WebRequest' {
                $o = New-Object -TypeName PSObject
                $o | Add-Member -MemberType NoteProperty -Name 'Headers' -Value @{
                        'X-RateLimit-Remaining'=1;
                        'X-RateLimit-Reset'=1
                    }
                return $o
            } -ParameterFilter { $Uri -eq 'http://shortrun.example/' }

            Mock 'Invoke-WebRequest' {
                throw  [System.Net.WebException]
            } -ParameterFilter { $Uri -eq 'http://zeroretry.example/' }

            Mock 'Invoke-WebRequest' {
                throw  [System.Exception]
            } -ParameterFilter { $Uri -eq 'http://notwebexception.example/' }

            Mock 'Start-Sleep' {throw}


            #Actual tests
            it 'should error out if one or more paramters are invalid.' {
                {Send-WebhookMessage} | Should throw

                {Send-WebhookMessage -hook 'http: //google.com/' -message 'Test Message'} | Should throw 'The hook passed in is not a valid uri.'

                {Send-WebhookMessage -hook 'http://testurl.example/' -message $null} | Should throw `
                    'Cannot validate argument on parameter ''message''. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again.'

                {Send-WebhookMessage -hook 'http://testurl.example/' -message ''} | Should throw `
                    'Cannot validate argument on parameter ''message''. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again.'
            }

            it 'should run if X-RateLimit-Remaining > 0 but X-RateLimit-Reset > current time without sleeping' {
                $script:limitRemaining = 1
                $script:resetTime = $currentTime + 1
                Send-WebhookMessage -hook 'http://shortrun.example/' -message 'Test Message'
            }

            it 'should run if X-RateLimit-Remaining = 0 but X-RateLimit-Reset < current time without sleeping' {
                $script:limitRemaining = 0
                $script:resetTime = $currentTime - 1
                Send-WebhookMessage -hook 'http://shortrun.example/' -message 'Test Message'
            }

            <#
             # For the moment, I'm going to skip this test due to the complications needed to mock
             # the function correctly. I'm sure there's an easy way to mock it, but I'm not
             # seeing it and not grasping inheriting the System.Net.WebResponse class correctly.
             # Adding this as an issue to track it later.

            it 'should retry when a 429 exception is caught' {
                Send-WebhookMessage -hook 'http://retryrun.example/' -Message 'Test' -RetryCount 5

                Assert-MockCalled 'Invoke-WebRequest' -Exactly -Times 5 -ParameterFilter {
                    $Uri -eq 'http://retryrun.example/'
                }
            }#>

            it 'should throw when RetryCount is 0' {
                {Send-WebhookMessage -hook 'http://zeroretry.example/' -message 'Test Message' -RetryCount 0} `
                    | Should throw System.Net.WebException

                Assert-MockCalled 'Invoke-WebRequest' -Exactly -Times 1 -ParameterFilter {
                    $Uri -eq  'http://zeroretry.example/'
                }
            }

            it 'should rethrow the error for non 429 exceptions' {
                {Send-WebhookMessage -hook 'http://notwebexception.example/' -message 'Test Message'} `
                    | Should throw System.Exception

                Assert-MockCalled 'Invoke-WebRequest' -Exactly -Times 1 -ParameterFilter {
                    $Uri -eq  'http://notwebexception.example/'
                }
            }

            #Describe block assert verifications.
            Assert-MockCalled 'Invoke-WebRequest' -Exactly -Times 2 -ParameterFilter {
                $Uri -eq 'http://shortrun.example/'
            }
        }
    }
}
