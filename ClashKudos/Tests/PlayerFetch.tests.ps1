<#
 # Tests against the PlayerFetch Module
 #>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module ClashKudos | Remove-Module -Force
Import-Module $root\..\ClashKudos.psd1 -Force

InModuleScope 'PlayerFetch' {
    Describe 'PlayerFetch' {
        Context 'Update-PlayerData' {
            Mock 'Get-KudosGlobalSettings' {return @{'DataDirectory'='TestDrive:'}} -Verifiable
            Mock 'Get-KudosClanTags' {
                [System.Collections.ArrayList] $result = New-Object System.Collections.ArrayList($null)
                foreach($i in 1..4) {
                    $r = New-Object -TypeName PSObject
                    $r | Add-Member -MemberType NoteProperty -Name name -Value $i

                    #Add some entropy for tests.
                    if($i -eq 1) {
                        $r | Add-Member -MemberType NoteProperty -Name tags -Value @("#$i","#$i$i")
                    } else {
                        $r | Add-Member -MemberType NoteProperty -Name tags -Value "#$i"
                    }

                    $result.add($r) |Out-Null
                }
                Write-Host $result
                return $result
            }
            Mock 'Private-GetMembersInClan' {return @('#1234')}
            Mock 'Private-GetMemberDetails' {return 'Test Details'}
            Mock 'Export-Clixml' {} -Verifiable

            it 'should create the directory if it does not exist' {
                Update-PlayerData

                Test-Path -PathType Container -Path (Join-Path 'TestDrive:' '1') | Should be $true
                Test-Path -PathType Container -Path (Join-Path 'TestDrive:' '2') | Should be $true
                Test-Path -PathType Container -Path (Join-Path 'TestDrive:' '3') | Should be $true
                Test-Path -PathType Container -Path (Join-Path 'TestDrive:' '4') | Should be $true
            }

            it 'should through the steps' {
                Update-PlayerData

                Assert-VerifiableMock
                Assert-MockCalled 'Private-GetMembersInClan' -Exactly -Times 4 -Scope It
                Assert-MockCalled 'Private-GetMemberDetails' -Exactly -Times 4 -Scope It
            }
        }

        Context 'Private-GetMembersInClan' {
            Mock 'Invoke-SCAPICall' {
                $item1 = New-Object -TypeName PSObject
                $item1 | Add-Member -MemberType NoteProperty -Name tag -Value "#123"

                $item2 = New-Object -TypeName PSObject
                $item2 | Add-Member -MemberType NoteProperty -Name tag -Value "#Abc"

                $o = New-Object -TypeName PSObject
                $o | Add-Member -MemberType NoteProperty -Name items -Value @($item1,$item2)

                return $o
            }

            it 'should error out when an incorrect value is passed in' {
                {Private-GetMembersInClan -Clan 1} | Should throw
                {Private-GetMembersInClan -Clan @('12345','Abcd')} | Should throw
                {Private-GetMembersInClan -Clan @('#12345','Abcd','#xyz')} | Should throw
            }

            it 'should pass parameter validation run correctly' {
                Private-GetMembersInClan -Clan @('#12345','#Abcd','#xyz')

                Assert-MockCalled Invoke-SCAPICall -Exactly -Times 3 -Scope It
            }

            it 'should run and return the correct values' {
                $result = Private-GetMembersInClan -Clan @('#12345')

                $result.Length | Should Be 2
                $result[0] -in ("#123","#Abc") | Should Be $true
                $result[1] -in ("#123","#Abc") | Should Be $true
            }
        }

        Context 'Private-GetMemberDetails' {
            Mock 'Invoke-SCAPICall' {
                return '{
                    "name":"TestName",
                    "Tag":"#1234",
                    "townHallLevel":1,
                    "trophies":100,
                    "warStars":500,
                    "donations":300,
                    "achievements" : [
                        {"name":"Friend in Need", "value":1234567},
                        {"name":"Games Champion", "value":987},
                        {"name":"Gold Grab", "value":111},
                        {"name":"Elixir Escapade", "value":222}
                    ]
                }'  | ConvertFrom-Json
            }
            it 'should error out when an incorrect value is passed in' {
                {Private-GetMemberDetails -Members 1} |Should throw
                {Private-GetMemberDetails -Members @('12345','Abcd')} | Should throw
                {Private-GetMemberDetails -Members @('#12345','Abcd','#xyz')} | Should throw
            }

            it 'should pass parameter validation and run as expected' {
                Private-GetMemberDetails -Members @('#12345','#Abcd') |Out-Null

                Assert-MockCalled 'Invoke-SCAPICall' -Exactly -Times 2 -Scope It
            }

            it 'should create and return the objects correctly' {
                $result = Private-GetMemberDetails -Members @('#Abcd')

                Assert-MockCalled 'Invoke-SCAPICall'

                #Test the values
                $result.name | Should be 'TestName'
                $result.Tag | Should be "#1234"
                $result.TownHall | Should be 1
                $result.Trophies | Should be 100
                $result.WarStars | Should be 500
                $result.Donations | Should be 300
                $result.Friend | Should be '1234567'
                $result.Clan | Should be 987
                $result.Gold | Should be 111
                $result.Elixir | Should be 222
            }
        }
    }
}
