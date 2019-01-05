<#
 # Tests against the Donations Interface Module
 #>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module ClashKudos | Remove-Module -Force
Import-Module $root\..\ClashKudos.psd1 -Force

#Clash Kudos is root scope, so using root module.
InModuleScope 'PlayerDonations' {
    Describe 'PlayerDonations' {
        Context 'Publish-KudosBestDonator' {
            #========================================================
            # Create the files needed for the tests. Opting for this
            # instead of mocking Import-CliXML
            #========================================================
            $file = "memberdetails-{0}.xml"
            $todayFile = [String]::Format($file, (Get-Date).ToString('MM.dd.yyyy'))
            $yesterdayFile = [String]::Format($file, (Get-Date).AddDays(-1).ToString('MM.dd.yyyy'))

            #Save the XML for the tests. Use a tool to unmifiy if additional tests are needed.
            $yesterday = '<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
            <Obj RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS>
            <S N="Name">FIN_Winner</S><S N="Tag">#12345</S><I32 N="Friend">100</I32><I32 N="Donations">100</I32></MS></Obj>
            <Obj RefId="1"><TN RefId="1"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS>
            <S N="Name">Donation_Winner</S><S N="Tag">#ABCD</S><I32 N="Friend">100</I32><I32 N="Donations">100</I32></MS>
            </Obj><Obj RefId="1"><TN RefId="2"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN>
            <MS><S N="Name">Loserr</S><S N="Tag">#XYZ</S><I32 N="Friend">0</I32><I32 N="Donations">0</I32></MS></Obj></Objs>'

            $todayFIN_Winner = '<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
            <Obj RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS>
            <S N="Name">FIN_Winner</S><S N="Tag">#12345</S><I32 N="Friend">200</I32><I32 N="Donations">0</I32></MS></Obj>
            <Obj RefId="1"><TN RefId="1"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS>
            <S N="Name">Donation_Winner</S><S N="Tag">#ABCD</S><I32 N="Friend">199</I32><I32 N="Donations">199</I32></MS>
            </Obj><Obj RefId="2"><TN RefId="2"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN>
            <MS><S N="Name">Loserr</S><S N="Tag">#XYZ</S><I32 N="Friend">99</I32><I32 N="Donations">99</I32></MS></Obj></Objs>
            '
            $todayDonation_Winner = '<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
            <Obj RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS>
            <S N="Name">FIN_Winner</S><S N="Tag">#12345</S><I32 N="Friend">199</I32><I32 N="Donations">199</I32></MS></Obj>
            <Obj RefId="1"><TN RefId="1"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS>
            <S N="Name">Donation_Winner</S><S N="Tag">#ABCD</S><I32 N="Friend">150</I32><I32 N="Donations">200</I32></MS>
            </Obj><Obj RefId="2"><TN RefId="2"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN>
            <MS><S N="Name">Loserr</S><S N="Tag">#XYZ</S><I32 N="Friend">99</I32><I32 N="Donations">99</I32></MS></Obj></Objs>
            '
            $todayTie = '<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj RefId="0">
            <TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS>
            <S N="Name">FIN_Winner</S><S N="Tag">#12345</S><I32 N="Friend">200</I32><I32 N="Donations">200</I32></MS></Obj>
            <Obj RefId="2"><TN RefId="1"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS>
            <S N="Name">Donation_Winner</S><S N="Tag">#ABCD</S><I32 N="Friend">200</I32><I32 N="Donations">200</I32></MS>
            </Obj><Obj RefId="2"><TN RefId="2"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN>
            <MS><S N="Name">Loserr</S><S N="Tag">#XYZ</S><I32 N="Friend">99</I32><I32 N="Donations">99</I32></MS></Obj></Objs>
            '

            #Create the clan test folders
            New-Item -Path (Join-Path 'TestDrive:' 'FINClan') -ItemType Directory
            New-Item -Path (Join-Path 'TestDrive:' 'DonationClan') -ItemType Directory
            New-Item -Path (Join-Path 'TestDrive:' 'TieClan') -ItemType Directory

            #Save the XML
            $yesterday | Set-Content (Join-Path 'TestDrive:' 'FINClan' | Join-Path -ChildPath $yesterdayFile)
            $yesterday | Set-Content (Join-Path 'TestDrive:' 'DonationClan' | Join-Path -ChildPath $yesterdayFile)
            $yesterday | Set-Content (Join-Path 'TestDrive:' 'TieClan' | Join-Path -ChildPath $yesterdayFile)

            $todayFIN_Winner | Set-Content (Join-Path 'TestDrive:' 'FINClan' | Join-Path -ChildPath $todayFile)
            $todayDonation_Winner | Set-Content (Join-Path 'TestDrive:' 'DonationClan' | Join-Path -ChildPath $todayFile)
            $todayTie | Set-Content (Join-Path 'TestDrive:' 'TieClan' | Join-Path -ChildPath $todayFile)

            #========================================================
            # Mock the functions needed for the tests below.
            #========================================================
            Mock 'Get-KudosGlobalSettings' { return @{
                    'DataDirectory'='TestDrive:'; 'DataError_Hook'='http://testdatahook.com'
                }
            }
            Mock 'Send-WebhookMessage' {} -ParameterFilter {
                $hook -eq 'http://testdatahook.com' -and $message -eq "Unable to open a kudos file for TestClan"
            }
            Mock 'Send-WebhookMessage' {} -ParameterFilter {
                $hook -eq 'http://gooddatahook.com' -and $message -eq "FIN_Winner-100"
            }
            Mock 'Send-WebhookMessage' {} -ParameterFilter {
                $hook -eq 'http://gooddatahook.com' -and $message -eq "Donation_Winner-100"
            }
            Mock 'Send-WebhookMessage' {} -ParameterFilter {
                $hook -eq 'http://gooddatahook.com' -and $message -eq "FIN_Winner & Donation_Winner-100"
            }
            Mock 'Private-GetKudosMessage' {
                return "$Name-$Donations"
            }

            #========================================================
            # The actual tests to perform.
            #========================================================
            it 'should throw an error if an invalid parameter is passed in' {
                {Publish-KudosBestDonator -ClanName $null -Hook 'http://test.com'} | Should throw
                {Publish-KudosBestDonator -ClanName '' -Hook 'http://test.com'} | Should throw
                {Publish-KudosBestDonator -ClanName 'Test' -Hook 'NotAURI'} | Should throw
            }

            it 'should send a Discord webhook if a file is unable to be opened' {
                Publish-KudosBestDonator -ClanName 'TestClan' -Hook "http://doesnotmatter.com"

                Assert-MockCalled 'Send-WebhookMessage' -Exactly -Times 1 -ParameterFilter {
                    $hook -eq 'http://testdatahook.com' -and $message -eq "Unable to open a kudos file for TestClan"
                }
            }

            it 'should use the FIN Achievement value when sending kudos' {
                Publish-KudosBestDonator -ClanName 'FINClan' -Hook 'http://gooddatahook.com'

                Assert-MockCalled 'Send-WebhookMessage' -Exactly -Times 1 -ParameterFilter {
                    $hook -eq 'http://gooddatahook.com' -and $message -eq "FIN_Winner-100"
                }
            }

            it 'should use the in game donation value when sending kudos' {
                Publish-KudosBestDonator -ClanName 'DonationClan' -Hook 'http://gooddatahook.com'

                Assert-MockCalled 'Send-WebhookMessage' -Exactly -Times 1 -ParameterFilter {
                    $hook -eq 'http://gooddatahook.com' -and $message -eq "Donation_Winner-100"
                }
            }

            it 'should use recognize a tie and reward both people' {
                Publish-KudosBestDonator -ClanName 'TieClan' -Hook 'http://gooddatahook.com'

                Assert-MockCalled 'Send-WebhookMessage' -Exactly -Times 1 -ParameterFilter {
                    $hook -eq 'http://gooddatahook.com' -and $message -eq "FIN_Winner & Donation_Winner-100"
                }
            }
        }

        Context 'Private-GetKudosMessage' {
            Mock 'Get-Random' {return 0}

            it 'should throw an error if if a parameter is incorrect' {
                {Private-GetKudosMessage -Name $null -Value 1} | Should throw
                {Private-GetKudosMessage -Name '' -Value 1} | Should throw
                {Private-GetKudosMessage -Name 'Bob' -Value 'Bob'} | Should throw
            }

            #This test will fail if the error messages are changed. Simply update the test.
            it 'should build the string correctly' {
                Private-GetKudosMessage -Name 'TestPlayer' -Donations '1234567' `
                    | Should Be "The amazing **TestPlayer** has donated **1234567** troops recently! Wowzers!"
            }
        }
    }
}
