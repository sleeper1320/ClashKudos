<#
 # Tests against the PlayerFetch Module
 #>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module ClashKudos | Remove-Module -Force
Import-Module $root\..\ClashKudos.psd1 -Force

InModuleScope 'PlayerFetch' {
    Describe 'PlayerFetch' {
        Context 'Save-PlayerData' {
            it 'should run' {
                Save-PlayerData
            }
        }

        Context 'Private-RefreshClans' {
            it 'should error out when an invalid parameter is passed through' {

            }

            it 'should accept both a single string and an array' {

            }

            it 'should run correctly' {

            }
        }

        Context 'Private-RefreshMembers' {
            it 'should error out when an invalid parameter is passed through' {

            }

            it 'should return a member list' {

            }
        }
    }
}
