<#
 # Tests against the API Interface Module
 #>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module ClashKudos | Remove-Module -Force
Import-Module $root\..\ClashKudos.psd1 -Force

InModuleScope 'SC API' {
    Describe 'SC API' {

        Context 'Get/Set SCToken' {

            <#
             # With no easily identifiable error value to set, test set
             # and get at the same time.
            #>
            it 'should set and retrieve the value' {
                Set-SCToken 'This is a token value that should set'

                Get-SCToken | Should be 'This is a token value that should set'
            }
        }

        Context 'Get/Set SCTokenIP' {
            it 'should error out when a non IPv4 address is passed in' {
                {Set-SCTokenIP -IP 'invalid value'} | Should throw
                {Set-SCTokenIP -IP '1.2.3.4.5'} | Should throw
            }
            it 'should return the expected value' {
                Set-SCTokenIP '1.2.3.4'

                Get-SCTokenIP | Should beoftype IPAddress
                Get-SCTokenIP | Should be '1.2.3.4'
            }
            it 'should set the value' {
                Mock 'Set-Variable'

                Set-SCTokenIP -IP '1.2.3.4'

                Assert-MockCalled 'Set-Variable' -Exactly -Times 1
            }
        }

        Context 'Test-SCTokenIP' {
            it 'should return false when configured and queried value do not match' {
                Mock 'Invoke-RestMethod' {
                    $o = New-Object PSObject
                    $o | Add-Member -MemberType NoteProperty -Name IP -Value '1.2.3.4'
                    return $o
                }
                Mock 'Get-SCTokenIP' {'4.3.2.1'}

                Test-SCTokenIP | Should be $false
            }
            it 'should return true when configured and queried values match' {
                Mock 'Invoke-RestMethod' {
                    $o = New-Object PSObject
                    $o | Add-Member -MemberType NoteProperty -Name IP -Value '1.2.3.4'
                    return $o
                }
                Mock 'Get-SCTokenIP' {'1.2.3.4'}

                Test-SCTokenIP | Should be $true
            }
            it 'should have called each function only once' {
                <#
                 # For each test, increment the times value. Pester counts them per
                 # context block in the current version.
                 #>
                Assert-MockCalled 'Invoke-RestMethod' -Exactly -Times 2
                Assert-MockCalled 'Get-SCTokenIP' -Exactly -Times 2
            }
        }

        Context 'Test-SCToken' {
            it 'should return true when a valid value is found' {
                Mock 'Invoke-SCAPICall' {return 'ValidValue'}

                Test-SCToken | Should be $true
            }
            it 'should return false when the token is invalid' {
                Mock 'Invoke-SCAPICall' {throw}

                Test-SCToken | Should be $false
            }
        }

        Context 'Invoke-SCAPICall' {
            it 'should error out when an invalid uri is passed in' {
                {Invoke-SCAPICall -uri 'http: //google.com/'} | Should throw 'The uri passed in is not a valid uri.'
            }
            it 'should run through the core functions' {
                Mock 'Get-SCToken' {'PretendToken'} -Verifiable
                Mock 'Invoke-WebRequest' {} -Verifiable
                Mock 'Start-Sleep' {} -Verifiable #Mock this to speed up tests.

                Invoke-SCAPICall -Uri 'http://someuri.com'

                Assert-VerifiableMock
            }
        }
    }
}
