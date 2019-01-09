function Publish-KudosClanGames {
    <#
    .SYNOPSIS
        Looks through the clan data and sends a Kudos shoutout to the players
        who reached max clan game points.

    .DESCRIPTION
        After validating paramters, this function loads the appropriate data
        files and compares the start and end clan games information to award
        the players who achieved the maximum amount of points.

    .PARAMETER ClanName
        The name of the clan

    .PARAMETER Hook
        The hook to send the kudos shoutout to.

    .PARAMETER StartDate
        A date prior to the start of Clan Games. If the file pull is at 6am and
        clan games starts at 1am, then the start should be the day before
        the actual start of clan games.

    .PARAMETER EndDate
        A date on or after the end of Clan Games. If the file pull is at 6am
        and clan games ends at 1am, then the end can be the same day. If the
        file pull is at 12am and clan games ends at 1am, then the end date
        should use the next day's file.

    .PARAMETER MaxPoints
        The amount of points SuperCell rewards a player before they can no
        longer continue clan games.

    .INPUTS
        System.String, System.String

    .OUTPUTS
        None
     #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $ClanName,

        [Parameter(Mandatory=$true)]
        [ValidateScript({
            $output = ''
            $result = $false
            try {
                $result = ([System.URI]::TryCreate($_,[System.URIKind]::Absolute, [ref]$output))
            } catch {
                #This version of TryCreate shouldn't throw this, but it's a bit safer to have it.
                throw [System.Management.Automation.ValidationMetadataException] `
                    'Attempting to parse the hook resulted in an exception.'
            }
            if(-not $result) {
                throw [System.Management.Automation.ValidationMetadataException] `
                    'The hook passed in is not a valid uri.'
            }

            #Return the result. At this point, it should be $true.
            $result
        })]
        [String] $Hook,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $StartDate,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $EndDate,

        [Parameter(Mandatory=$true)]
        [ValidateScript({
            ($_ -gt 0)
        })]
        [Int] $MaxPoints
    )

    $globalSettings = (Get-KudosGlobalSettings)
    $shoutMessages = @("Thanks **{0}** for contributing max points in clan games! :heart:")
    $file = (Join-Path $globalSettings.DataDirectory $ClanName | Join-Path -ChildPath "memberdetails-{0}.xml")

    $startCGFile = [String]::Format($file, [DateTime]::Parse($startDate).toString('MM.dd.yyyy'))
    $endCGFile = [String]::Format($file, [DateTime]::Parse($endDate).toString('MM.dd.yyyy'))

    #Load the files
    try {
        $start = Import-Clixml $startCGFile
        $end = Import-Clixml $endCGFile
    } catch {
        Send-WebhookMessage -Hook $globalSettings.DataError_Hook -Message "Unable to open a kudos file for $ClanName"
        return
    }

    #Give Kudos to max clan games participants.
    $name = "Error!"
    foreach($i in ($start | Sort-Object -Property Name)) {
        $matchingPlayer = ($end |Where {$_.tag -eq $i.tag})
        if($matchingPlayer -eq $null) {
            Write-Verbose "Skipping $($i.Name)..."
            continue
        }

        $startPoints = $i.Clan
        $endPoints = $matchingPlayer.Clan

        $difference = ($endPoints - $startPoints)
        if($difference -ge $maxPoints) {
            $shoutMessage = $shoutMessages[(Get-Random -Maximum $shoutMessages.Length)]
            $shoutMessage = [String]::Format($shoutMessage, $matchingPlayer.Name)

            #Send the shoutout.
            write-host $shoutMessage
            Send-WebhookMessage -Hook $Hook -Message $shoutMessage
        }
    }
}
