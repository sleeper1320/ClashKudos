function Save-PlayerData {
    <#
    .SYNOPSIS
        Stub. Development in progress.

    .DESCRIPTION
        Stub. Development in progress.
     #>
    [CmdletBinding()]
    param()
}

function Private-RefreshClans {
    <#

    #>
    [CmdletBinding()]
    param()

    [System.Collections.ArrayList] $memberlist = New-Object System.Collections.ArrayList($null)

    foreach($c in $clan) {
        $c = [URI]::EscapeDataString($c)
        #Write-Host "Converting Clan tag to $c"

        $uri = [String]::Format($members_uri,$c)
        $result = Invoke-SCAPICall -uri $uri

        foreach($r in $result.items) {
            $memberlist.Add($r.tag) |Out-Null
        }
    }

    return $memberlist
}

function Private-RefreshMembers {
    <#

    #>
    [CmdletBinding()]
    param()

    [System.Collections.ArrayList] $memberdetails = New-Object System.Collections.ArrayList($null)

    foreach($m in $members) {
        $m = [URI]::EscapeDataString($m)

        $uri = [String]::Format($memberdetails_uri,$m)
        $result = (Invoke-WebRequest -Headers $headers $uri).Content |ConvertFrom-Json

        $name = $result.name
        $tag = $result.tag
        $trophies = $result.trophies
        $friend = $result.achievements | where {$_.name -eq 'Friend in Need'} |Select-Object value
        $clan = $result.achievements | where {$_.name -eq 'Games Champion'} |Select-Object value
        $gold = $result.achievements | where {$_.name -eq 'Gold Grab'} |Select-Object value
        $elixir = $result.achievements | where {$_.name -eq'Elixir Escapade'} |Select-Object value
        
        
        $details = New-Object -TypeName PSObject
        $details | Add-Member -MemberType NoteProperty -Name "Name" -Value $name
        $details | Add-Member -MemberType NoteProperty -Name "Tag" -Value $tag
        $details | Add-Member -MemberType NoteProperty -Name "Trophies" -Value $trophies
        $details | Add-Member -MemberType NoteProperty -Name "Friend" -Value $friend
        $details | Add-Member -MemberType NoteProperty -Name "Clan" -Value $clan
        $details | Add-Member -MemberType NoteProperty -Name "Gold" -Value $gold
        $details | Add-Member -MemberType NoteProperty -Name "Elixir" -Value $elixir


        $memberdetails.Add($details) |Out-Null

        #Invoke sleep to prevent rate limits.
        Start-Sleep -Milliseconds 500
    }

    return $memberdetails
}