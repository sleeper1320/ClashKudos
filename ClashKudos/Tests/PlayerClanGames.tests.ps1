<#
 # Tests against the Clan Games Interface Module
 #>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module ClashKudos | Remove-Module -Force
Import-Module $root\..\ClashKudos.psd1 -Force

#Clash Kudos is root scope, so using root module.
InModuleScope 'PlayerClanGames' {
    Describe 'PlayerClanGames' {
        Context 'Publish-KudosClanGames' {

            $file = "memberdetails-{0}.xml"
            $today = (Get-Date).ToString('MM.dd.yyyy')
            $yesterday = (Get-Date).AddDays(-1).ToString('MM.dd.yyyy')

            $todayFile = [String]::Format($file, $today )
            $yesterdayFile = [String]::Format($file, $yesterday)

            #Save the XML for the tests. Use a tool to unmifiy if additional tests are needed.
            $yesterdayXML =
            '<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
            <Obj RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T>
            <T>System.Object</T></TN><MS><S N="Name">player1</S><S N="Tag">#123</S>
            <I32 N="Clan">0</I32></MS></Obj><Obj RefId="1"><TNRef RefId="0" /><MS>
            <S N="Name">player2</S><S N="Tag">#abcd</S><I32 N="Clan">1000</I32></MS></Obj>
            <Obj RefId="2"><TNRef RefId="0" /><MS><S N="Name">player3</S><S N="Tag">#a1b2c3</S>
            <I32 N="Clan">0</I32></MS></Obj><Obj RefId="3"><TNRef RefId="0" /><MS>
            <S N="Name">player4</S><S N="Tag">#xyz</S><I32 N="Clan">4888</I32></MS></Obj></Objs>'

            $todayXML =
            '<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
            <Obj RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T>
            <T>System.Object</T></TN><MS><S N="Name">player1</S><S N="Tag">#123</S>
            <I32 N="Clan">1000</I32></MS></Obj><Obj RefId="1"><TNRef RefId="0" /><MS>
            <S N="Name">player2</S><S N="Tag">#abcd</S><I32 N="Clan">2000</I32></MS></Obj>
            <Obj RefId="2"><TNRef RefId="0" /><MS><S N="Name">player3</S><S N="Tag">#a1b2c3</S>
            <I32 N="Clan">999</I32></MS></Obj><Obj RefId="3"><TNRef RefId="0" /><MS>
            <S N="Name">player4</S><S N="Tag">#xyz</S><I32 N="Clan">5999</I32></MS></Obj></Objs>'

            New-Item -Path (Join-Path 'TestDrive:' 'CG') -ItemType Directory
            $yesterdayXML | Set-Content (Join-Path 'TestDrive:' 'CG' | Join-Path -ChildPath $yesterdayFile)
            $todayXML | Set-Content (Join-Path 'TestDrive:' 'CG' | Join-Path -ChildPath $todayFile)

            Mock 'Get-KudosGlobalSettings' {
                @{
                    'DataDirectory'='TestDrive:'
                    'DataError_Hook'='http://errorhook.example'
                }
            }

            Mock 'Send-WebhookMessage' {} -ParameterFilter {
                $Message -like "Unable to open a kudos file for*"
            }

            Mock 'Send-WebhookMessage' {} -ParameterFilter {
                $Hook -eq 'http://goodhook.example'
                $Message -in (
                    "Thanks **player1** for contributing max points in clan games! :heart:",
                    "Thanks **player2** for contributing max points in clan games! :heart:",
                    "Thanks **player4** for contributing max points in clan games! :heart:"
                )
            }

            it 'should error out when an invalid clan name is passed in' {
                {
                    Publish-KudosClanGames -ClanName $null -Hook 'http://hook.com' `
                        -StartDate '01/01/01' -EndDate '01/01/01' -MaxPoints 1000
                } | Should throw

                {
                    Publish-KudosClanGames -ClanName '' -Hook 'http://hook.com' `
                        -StartDate '01/01/01' -EndDate '01/01/01' -MaxPoints 1000
                } | Should throw
            }

            it 'should error out when an invalid hook is passed in' {
                {
                    Publish-KudosClanGames -ClanName 'TestClan' -Hook 'Bad Data Hook' `
                        -StartDate '01/01/01' -EndDate '01/01/01' -MaxPoints 1000
                } | Should throw
            }

            it 'should error out when an invalid date is passed in' {
                {
                    Publish-KudosClanGames -ClanName 'TestClan' -Hook 'http://hook.com' `
                        -StartDate 'NotADate' -EndDate '01/01/01' -MaxPoints 1000
                } | Should throw

                {
                    Publish-KudosClanGames -ClanName 'TestClan' -Hook 'http://hook.com' `
                        -StartDate '01/01/01' -EndDate 'NotADate' -MaxPoints 1000
                } | Should throw
            }

            it 'should error out when an invalid max points value is passed in' {
                {
                    Publish-KudosClanGames -ClanName 'TestClan' -Hook 'http://hook.com' `
                        -StartDate '01/01/01' -EndDate '01/01/01' -MaxPoints 'NotAnInt'
                } | Should throw
            }

            it 'should send a webhook when a file cannot be read' {
                Publish-KudosClanGames -ClanName 'TestClan' -Hook 'http://goodhook.com' `
                    -StartDate '01/01/01' -EndDate '01/02/01' -MaxPoints 1000

                Assert-MockCalled 'Send-WebhookMessage' -Exactly -Times 1 -ParameterFilter {
                    $Hook -eq 'http://errorhook.example' -and
                    $Message -like "Unable to open a kudos file for*"
                }
            }

            it 'should calculate the correct clan game winners' {
                Publish-KudosClanGames -ClanName 'CG' -Hook 'http://goodhook.example' `
                    -StartDate $yesterday -EndDate $today -MaxPoints 1000

                Assert-MockCalled 'Send-WebhookMessage' -Exactly -Times 3 -ParameterFilter {
                    $Hook -eq 'http://goodhook.example' -and
                    $Message -in (
                        "Thanks **player1** for contributing max points in clan games! :heart:",
                        "Thanks **player2** for contributing max points in clan games! :heart:",
                        "Thanks **player4** for contributing max points in clan games! :heart:"
                    )
                }
            }
        }
    }
}
