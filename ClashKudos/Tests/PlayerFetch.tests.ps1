$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module ClashKudos | Remove-Module -Force
Import-Module $root\..\ClashKudos.psd1 -Force

InModuleScope 'PlayerFetch' {
    Describe 'PlayerFetch' {
        Context 'Get-PlayerData' {
            it 'should run' {
                Get-PlayerData
            }
        }
    }
}
