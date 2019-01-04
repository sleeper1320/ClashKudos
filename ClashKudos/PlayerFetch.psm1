function Update-PlayerData {
    <#
    .SYNOPSIS
        Retrieves the data from the SC API and writes the information to disk.

    .DESCRIPTION
        This function will retrieve the appropriate data from the config file,
        call the SuperCell API to pull the latest data, and then save the data
        to disk.

    .INPUTS
        None

    .OUTPUTS
        None
     #>
    [CmdletBinding()]
    param()

    $config = (Get-KudosGlobalSettings).DataDirectory
    $today = (Get-Date -f "MM.dd.yyyy")
    $clans = Get-KudosClanTags

    foreach($c in $clans) {
        Write-Verbose "Getting the member list for $($c.tags)"
        $members = Private-GetMembersInClan -Clan $c.tags
        
        Write-Verbose "Getting member details for $($c.tags)"
        $fulldetails = Private-GetMemberDetails -Members $members

        $directory = (Join-Path $config $c.name)

        #Create the directory if it doesn't exist
        if(-not(Test-Path -PathType Container $directory)) {
            Write-Verbose "Creating $directory"
            New-Item -ItemType Directory -Path $directory |Out-Null
        }

        $file = "memberdetails-$today"
        $fullfilepath = (Join-Path $directory $file)

        Write-Verbose "Writing data to $file"
        $fulldetails | Export-Clixml $fullfilepath
    }
}

function Private-GetMembersInClan {
   <#
    .SYNOPSIS
        Calls the API to retrieve the member list for the specified clan tag(s)

    .DESCRIPTION
        This function will ensure the parameters passed in is roughly within
        the exepcted range and then use the paramter to get the latest
        member list from the API.

    .PARAMETER Clan
        An array of clan tags to parse for members.

    .INPUTS
        None

    .OUTPUTS
        System.Collections.ArrayList

        The collection of members in the clan(s).
     #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            #Is the object something close to what we expect to see
            if($_ -notmatch '#.') { return $false }

            return $true
        })]
        [Array] $Clan
    )

    $clanURI = 'https://api.clashofclans.com/v1/clans/{0}/members'
    [System.Collections.ArrayList] $memberlist = New-Object System.Collections.ArrayList($null)

    foreach($c in $clan) {
        $c = [URI]::EscapeDataString($c)
        $uri = [String]::Format($clanURI,$c)

        Write-Debug "Converted Clan tag to $c"
        Write-Debug "Converted URI to: $uri"

        $result = Invoke-SCAPICall -uri $uri

        Write-Verbose "Adding results for $c to the member list."
        foreach($r in $result.items) {
            $memberlist.Add($r.tag) |Out-Null
        }
    }

    return $memberlist
}

function Private-GetMemberDetails {
   <#
    .SYNOPSIS
        Calls the API to retrieve the member details for the specified member(s)

    .DESCRIPTION
        This function will ensure the parameters passed in is roughly within
        the exepcted range and then use the paramter to get the latest
        member data from the API.

    .PARAMETER Clan
        An array of member tag(s) to parse for details.

    .INPUTS
        None

    .OUTPUTS
        System.Management.Automation.PSCustomObject

        The collection of members in the clan(s).
     #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            #Is the object something close to what we expect to see
            if($_ -notmatch '#.') { return $false }

            return $true
        })]
        [Array] $Members
    )

    $memberURI = 'https://api.clashofclans.com/v1/players/{0}'
    [System.Collections.ArrayList] $memberdetails = New-Object System.Collections.ArrayList($null)

    foreach($m in $members) {
        $m = [URI]::EscapeDataString($m)
        $uri = [String]::Format($memberURI,$m)

        Write-Debug "Converted member tag to $m"
        Write-Debug "Converted URI to: $uri"

        $result = Invoke-SCAPICall -uri $uri

        $friend = $result.achievements | where {$_.name -eq 'Friend in Need'} |Select-Object -ExpandProperty value
        $clan = $result.achievements | where {$_.name -eq 'Games Champion'} |Select-Object -ExpandProperty value
        $gold = $result.achievements | where {$_.name -eq 'Gold Grab'} |Select-Object -ExpandProperty value
        $elixir = $result.achievements | where {$_.name -eq'Elixir Escapade'} |Select-Object -ExpandProperty value

        $details = New-Object -TypeName PSObject
        $details | Add-Member -MemberType NoteProperty -Name "Name" -Value $result.name
        $details | Add-Member -MemberType NoteProperty -Name "Tag" -Value $result.tag
        $details | Add-Member -MemberType NoteProperty -Name "TownHall" -Value $result.townHallLevel
        $details | Add-Member -MemberType NoteProperty -Name "Trophies" -Value $result.trophies
        $details | Add-Member -MemberType NoteProperty -Name "WarStars" -Value $result.warStars
        $details | Add-Member -MemberType NoteProperty -Name "Friend" -Value $friend
        $details | Add-Member -MemberType NoteProperty -Name "Donations" -Value $result.donations
        $details | Add-Member -MemberType NoteProperty -Name "Clan" -Value $clan
        $details | Add-Member -MemberType NoteProperty -Name "Gold" -Value $gold
        $details | Add-Member -MemberType NoteProperty -Name "Elixir" -Value $elixir

        Write-Verbose "Adding results for $m to the details list"
        $memberdetails.Add($details) |Out-Null
    }

    return $memberdetails
}
