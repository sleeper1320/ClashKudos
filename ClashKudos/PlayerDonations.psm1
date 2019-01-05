function Publish-KudosBestDonator {
    <#
    .SYNOPSIS
        Publishes the best donator for the last day to the specified webhook.

    .DESCRIPTION
        Reads the data file for yesterday and today and then compares the file to determine
        the best donator. Once found, sends a webhook notification to the Discord URL specified in
        the clan configuration.

        Note: The function will look at both the Friend In Need Achievement and the in game
        donation statistics to determine the highest donator. Due to how the API tracks
        donations in game, this method is not perfect but a best effort.

    .PARAMETER ClanName
        The name of the clan in which to publish to.

    .PARAMETER Hook
        The Discord webhook to which will be called when the function determines the best donator.

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
        [String] $Hook
    )

    $globalSettings = (Get-KudosGlobalSettings)
    $file = (Join-Path $globalSettings.DataDirectory $ClanName | Join-Path -ChildPath "memberdetails-{0}.xml")

    #Load the files to calculate kudos.
    $todayFile = [String]::Format($file, (Get-Date).ToString('MM.dd.yyyy'))
    $yesterdayFile = [String]::Format($file, (Get-Date).AddDays(-1).ToString('MM.dd.yyyy'))

    try {
        $today = Import-Clixml -Path $todayFile
        $yesterday = Import-Clixml -Path $yesterdayFile
    } catch {
        Send-WebhookMessage -Hook $globalSettings.DataError_Hook -Message "Unable to open a kudos file for $ClanName"
        return
    }

    # Figure out the best donator
    $bestDonaterName = "Error!"
    $bestDonations = 0
    foreach($i in $today) {
        #Is there a matching player
        $matchingPlayer = ($yesterday |Where {$_.tag -eq $i.tag})
        if($matchingPlayer -eq $null) {
            continue
        }

        #Matching player found. Continuing...
        $previousFINDonations = $matchingPlayer.Friend
        $previousGameDonations = $matchingPlayer.Donations
        $currentFINDonations = $i.Friend
        $currentGameDonations = $i.Donations

        #Determine which stat to track
        $difference = ($currentFINDonations - $previousFINDonations)
        if(($currentGameDonations - $previousGameDonations) -gt $difference) {
            $difference = ($currentGameDonations - $previousGameDonations)
        }

        if($difference -eq $bestDonations) {
            $bestDonaterName = $bestDonaterName + " & " + $i.name
        }
        elseif($difference -gt $bestDonations) {
            $bestDonaterName = $i.name
            $bestDonations = $difference
        }
    }

    #Send Kudos Shoutout
    $message = Private-GetKudosMessage -Name $bestDonaterName -Donations $bestDonations
    Send-WebhookMessage -hook $hook -Message $message
}

function Private-GetKudosMessage{
    <#
    .SYNOPSIS
        Returns a randomized string from the built in list.

    .DESCRIPTION
        This function will randomly select one of the kudos messages, customize
        the message with the parameters passed in, and return that message.

    .PARAMETER Name
        The name of the person who donated the most.

    .PARAMETER Donations
        The amount that person donated.

    .INPUTS
        System.String, int

    .OUTPUTS
        System.String
     #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        [Parameter(Mandatory=$true)]
        [int] $Donations
    )

    $shoutMessages = @(
        "The amazing **{0}** has donated **{1}** troops recently! Wowzers!",
        "I can assure you with the highest confidence that **{0}** donated **{1}** troops recently. You are a rockstar **{0}**.",
        "If I had a beer for every troop **{0}** donated, I would have **{1}** beers. ... That's a lot of beers! :beers:",
        "Today's MVD (Most Valuable Donator) goes to **{0}** with **{1}** donations. Congratulations!",
        "Can anyone beat **{0}** and their **{1}** donations? Tune in tomorrow to find out!",
        "Is **{0}** a knight? A samurai? A robot? No one knows! **{0}**'s **{1}** donations absorb even the mightiest of blows."
    )

    $message = $shoutMessages[(Get-Random -Maximum $shoutMessages.Length)]
    $message = [String]::Format($message, $Name, $Donations)
    return $message
}
