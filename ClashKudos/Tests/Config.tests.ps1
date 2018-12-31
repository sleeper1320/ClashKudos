<#
 # Tests against the Config Interface Module
 #>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module ClashKudos | Remove-Module -Force
Import-Module $root\..\ClashKudos.psd1 -Force

InModuleScope 'Config' {
    Describe 'Config' {
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

            it 'should use the default file if PrivateData does not exist' {
                Mock 'Private-ReadKudosConfig' { return $null } -ParameterFilter {
                    $location -eq (Join-Path "." "kudos.config")
                }

                #Get current working directory to reset later so Pester is happy.
                $currentDirectory = (Get-Location)

                #Change directory so the default config file location is in TestDrive
                Set-Location 'TestDrive:'

                Get-KudosClanSettings -clan 'Global'

                Assert-MockCalled 'Private-ReadKudosConfig' -ParameterFilter {
                    $location -eq (Join-Path "." "kudos.config")
                }

                #Reset Location
                Set-Location $currentDirectory
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

            it 'should call to read the file if the config is not loaded' {
                Mock 'Private-ReadKudosConfig' {} -ParameterFilter {$location -eq (Join-Path "." "kudos.config")}

                Get-KudosClanSettings -clan 'Global'

                Assert-MockCalled 'Private-ReadKudosConfig' -ParameterFilter {
                    $location -eq (Join-Path "." "kudos.config")
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
