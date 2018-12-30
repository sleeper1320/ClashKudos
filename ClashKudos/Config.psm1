<#
 # Functions to support Clash Kudos interaction with local saved configs.
 #>

function Get-KudosClanSettings {
    <#
    .SYNOPSIS
        Retrieves the config file data for the specified clan.

    .DESCRIPTION
        Upon first call, this function will load the config file from either the
        the location specified by the 'config' hash entry in PrivateData or the
        default location (./kudos.config) if a specified location is not found.

        Once loaded and for ever subsequent call after that, the data is saved
        in memory. At this time, there is no way to reload an updated config
        without reloading the entire module.

    .PARAMETER clan
        The clan whose configuration data is returned.

    .INPUTS
        System.String

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        A PSCustomObject of specific configuration data, or $null if no data
        is found for the specified $clan.

    .LINK
        Get-KudosGlobalSettings
     #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $clan
    )

    if($script:config -eq $null) {
        $configFileLocation = (Join-Path '.' 'kudos.config')
        $privateData = $MyInvocation.MyCommand.Module.PrivateData

        Write-Verbose 'Looking for custom defined config file.'

        #Use the default config file if the value doesn't exist.
        if(
                ($privateData -eq $null) `
            -or ($privateData['config'] -eq $null) `
            -or ($privateData['config'].trim() -eq '')
        ) {
            Write-Verbose 'No config file setting found. Using default.'
        }else {
            Write-Verbose 'Using found configuration setting.'
            $configFileLocation = $privateData['config']
        }
        Write-host "Calling: $configFileLocation"
        Private-ReadKudosConfig -location $configFileLocation
    }

    return $script:config.$clan
}

function Get-KudosGlobalSettings {
    <#
    .SYNOPSIS
        Retrieves the config file data for the global setting.

    .DESCRIPTION
        Upon first call, this function will load the config file from either the
        the location specified by the 'config' hash entry in PrivateData or the
        default location (./kudos.config) if a specified location is not found.

        Once loaded and for ever subsequent call after that, the data is saved
        in memory. At this time, there is no way to reload an updated config
        without reloading the entire module.

    .INPUTS
        None

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        A PSCustomObject of the data which applies to all clans

    .LINK
        Get-KudosClanSettings
     #>
    [CmdletBinding()]
    param()

    return (Get-KudosClanSettings -clan 'global')
}

function Private-ReadKudosConfig {
    <#
    .SYNOPSIS
        Loads the data from the config file.
     #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            Test-Path -Path $_ -PathType Leaf
        })]
        [String] $location
    )

    #Create the variable to hold the data. This overwrites existing config.
    Set-Variable -Scope Script -Name config -Value (New-Object PSObject)
    Set-Variable -Name working -Value (New-Object PSObject)
    Set-Variable -Name workingName -Value 'Undefined'

    #Get the file and parse the contents.
    $file = Get-Content $location
    foreach($f in $file) {

        Write-Verbose $f
        $split = [Regex]::Split($f, '=')

        #Ignore empty lines
        if($split[0].trim().length -eq 0) { continue }

        #Ignore the comments.
        if($split[0].startsWith('#')) { continue }

        #Load the data
        if($split[0] -match '\[(?<name>.*)\]') {

            #Handle non-first block context.
            if($workingName -ne 'Undefined') {
                Write-Verbose "New Section Discovered. Saving $workingName section..."
                $script:config | Add-Member -MemberType NoteProperty -Name $workingName -Value $working
            }

            $working = New-Object PSObject
            $workingName = $Matches['name'].trim()
        } else {
            $working | Add-Member -MemberType NoteProperty -Name $split[0].trim() -Value $split[1].trim()
        }
    }

    #Finish out by adding the last section we saw.
    Write-Verbose "Saving the final section in the file."
    $script:config | Add-Member -MemberType NoteProperty -Name $workingName -Value $working
}
