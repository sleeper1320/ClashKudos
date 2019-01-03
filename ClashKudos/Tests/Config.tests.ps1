<#
 # Tests against the Config Interface Module
 #>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module ClashKudos | Remove-Module -Force
Import-Module $root\..\ClashKudos.psd1 -Force

#Clash Kudos is root scope, so using root module.
InModuleScope 'Config' {
    Describe 'Config' {
        Context 'Get-KudosClanTags' {
            Mock 'Get-KudosClanSettings' {}

            it 'should run and return the expected results' {
                #Mimic a file load. In script context, so modifying variable directly
                $script:config = New-Object -TypeName PSObject

                #Add Global object to test that we don't return that
                $globalConfig = New-Object -TypeName PSObject
                $globalConfig | Add-Member -MemberType NoteProperty -Name tags -Value 'Invalid'

                #Add two sample clan tags.
                $testclan1 = New-Object -TypeName PSObject
                $testclan1 | Add-Member -MemberType NoteProperty -Name tags -Value '#1234,#5678'

                $testclan2 = New-Object -TypeName PSObject
                $testclan2 | Add-Member -MemberType NoteProperty -Name tags -Value '#abcd,#xyz'

                $script:config | Add-Member -MemberType NoteProperty -Name Global -Value $globalConfig
                $script:config | Add-Member -MemberType NoteProperty -Name clan1 -Value $testclan1
                $script:config | Add-Member -MemberType NoteProperty -Name clan2 -Value $testclan2

                $result = Get-KudosClanTags

                Assert-MockCalled 'Get-KudosClanSettings'
                $result.PSObject.Properties.value.tags | ? {$_ -in @('Invalid')}  `
                    | Measure-Object |Select -ExpandProperty Count | Should be 0

                $result.PSObject.Properties.value.tags | ? {$_ -in @('#1234','#5678','#abcd','#xyz')}  `
                    | Measure-Object |Select -ExpandProperty Count | Should be 4
                $result.length | Should Be 2

                #Cleanup
                $script:config = $null
            }
        }

        #If anything in this test is broken, look at the previous test first.
        Context 'Get-KudosGlobalSettings' {
            it 'should call the the root function for getting data' {
                Mock 'Get-KudosClanSettings' {}

                Get-KudosGlobalSettings

                Assert-MockCalled 'Get-KudosClanSettings'
            }
        }

        Context 'Get-KudosClanSettings' {

            #Create config files for the test
            "Data In Here Doesn't Matter" | Out-File (Join-Path "TestDrive:" "kudos.config")
            "Data In Here Doesn't Matter" | Out-File (Join-Path "TestDrive:" "pd.config")
            "Data In Here Doesn't Matter" | Out-File (Join-Path "TestDrive:" "realtest.config")


            it 'should error out when a bad parameter is passed in' {
                {Get-KudosClanSettings -clan ''} | should throw
                {Get-KudosClanSettings -clan $null} | should throw
            }

            it 'should run correctly if PrivateData is empty/null and no config is loaded' {
                #Set the base location for the module base.
                $base = $ExecutionContext.SessionState.Module.ModuleBase

                Mock 'Private-ReadKudosConfig' { return $null } -ParameterFilter {
                    $location -eq (Join-Path $base "kudos.config")
                }

                <#
                 # Calling this function *will* throw an error. Why?
                 # 1. The kudos.config file should never exist in the module base during testing.
                 # 2. Creating a file outside of TestDrive: may cause other issues.
                 # 3. ModuleBase is read-only and cannot be modified.
                 # 4. Private-ReadKudosConfig will fail. See: https://github.com/pester/Pester/issues/734
                 #
                 # We can be reasonably assured everything is working, however, because the error
                 # received was the value we expected. This is not ideal, but a workaround for now.
                 #>
                $expectedError = (Join-Path $base 'kudos.config') + " is not a path to a file leaf."

                { Get-KudosClanSettings -clan 'Global' } | Should throw $expectedError

            }

            it 'should load the privatedata if it exists' {
                #Mock the function and set the PrivateData for the execution context.
                Mock 'Private-ReadKudosConfig' { return $null } -ParameterFilter {
                    $location -eq (Join-Path "TestDrive:" "pd.config")
                }

                $ExecutionContext.SessionState.Module.PrivateData = @{'config' = (Join-Path "TestDrive:" "pd.config")}

                Get-KudosClanSettings -clan 'Global'

                Assert-MockCalled 'Private-ReadKudosConfig'  -ParameterFilter {
                    $location -eq (Join-Path "TestDrive:" "pd.config")
                }
            }

            it 'should not call to read the private data if a config is loaded' {
                Mock 'Private-ReadKudosConfig' {
                    $o = New-Object PSObject
                    $o | Add-Member -MemberType NoteProperty -Name global -Value 1
                    $script:config = $o
                } -ParameterFilter {$location -eq (Join-Path "TestDrive:" "realtest.config")}

                $ExecutionContext.SessionState.Module.PrivateData = @{'config' = (Join-Path "TestDrive:" "realtest.config")}

                Get-KudosClanSettings -clan 'Global'
                Get-KudosClanSettings -clan 'Global'

                Assert-MockCalled 'Private-ReadKudosConfig' -Exactly -Times 1 -ParameterFilter {
                        $location -eq (Join-Path "TestDrive:" "realtest.config")
                }
            }
        }

        Context 'Private-ReadKudosConfig' {
            $goodConfig = (Join-Path 'TestDrive:' 'good.config')

            #Sample file with spacing and webhooks.
            '[Global]' |Out-File -Append $goodConfig
            'sample = value ' |Out-File -Append $goodConfig
            '' |Out-File -Append $goodConfig
            '[Test]' |Out-File -Append $goodConfig
            'hook=http://webhook.com' |Out-File -Append $goodConfig

            it 'should error out when an invalid location is passed in' {
                {Private-ReadKudosConfig -location $null} | Should throw
                {Private-ReadKudosConfig -location 'TestDrive:'} | Should throw
                {Private-ReadKudosConfig -location (Join-Path 'TestDrive:' 'InvalidFile.config')} | Should throw
            }

            it 'should load a sample config file' {
                $result = Private-ReadKudosConfig -location $goodConfig

                #We're in Config's scope, so use the script variable directly.
                $script:config.Global.sample | Should be 'value'
                $script:config.Test.hook | Should be 'http://webhook.com'

            }
        }
    }
}
