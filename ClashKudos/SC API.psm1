<#
 # Functions to support Clash Kudos interaction with developer API.
 #>

function Get-SCToken {
    <#
    .SYNOPSIS
        Retrieves the stored token value.

    .DESCRIPTION
        A standard get method for a class style variable.

    .INPUTS
        None

    .OUTPUTS
        The stored token value, or $null if no value has been set.

    .LINK
        Set-SCToken

    .LINK
        Test-SCToken
     #>
    [CmdletBinding()]
    param()

    (Get-Variable -Name scToken -Scope Script).value
}

function Get-SCTokenIP {
    <#
    .SYNOPSIS
        Gets the stored token IP.

    .DESCRIPTION
        A standard get method for a class style variable.

    .INPUTS
        None

    .OUTPUTS
        The stored IP address.

    .LINK
        Set-SCTokenIP

    .LINK
        Test-SCTokenIP
     #>
    [CmdletBinding()]
    param()

    (Get-Variable -Name scTokenIP -Scope Script).value
}

function Invoke-SCAPICall {
    <#
    .SYNOPSIS
        Performs a call to the SuperCell Clash developer API

    .DESCRIPTION
        Validates the parameter passed in for consistency and, if valid, performs a query
        to the specified URI with the appropriate headers.

        At the moment, errors received when calling the API are passed to the calling
        function. Future revisions of this function may handle errors internally.

    .PARAMETER uri
        A valid, complete URI to the desired resource.

    .INPUTS
        System.String

    .OUTPUTS
        System.PSObject

        A PSCustomObject from the converted JSON response.

    .LINK
        Get-SCToken

    .LINK
        Set-SCToken

    .LINK
        Test-SCToken
     #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            $output = ''
            $result = $false
            try {
                $result = ([System.URI]::TryCreate($_,[System.URIKind]::Absolute, [ref]$output))
            } catch {
                throw [System.Management.Automation.ValidationMetadataException] `
                            'Attempting to parse the uri parameter resulted in an exception.'
            }
            if(-not $result) {
                throw [System.Management.Automation.ValidationMetadataException] `
                            'The uri passed in is not a valid uri.'
            }

            #Return the result. At this point, it should be $true.
            $result
        })]
        [String] $uri
    )


    $token = (Get-SCToken)

    $headers = @{}
    $headers.Add('Accept', 'application/json')
    $headers.Add('authorization', "Bearer $token")

    (Invoke-WebRequest -Headers $headers -Uri $uri).Content |ConvertFrom-Json
}

function Set-SCToken {
    <#
    .SYNOPSIS
        Sets the token

    .DESCRIPTION
        A standard set method for a class style variable. The token is used
        as the authenticator to SuperCell's API and must be present when
        any relevant function that needs it is called.

    .PARAMETER token
        The token value to store.

    .INPUTS
        System.Object

    .OUTPUTS
        None

    .LINK
        Set-SCToken

    .LINK
        Test-SCToken

    .LINK
        Invoke-SCAPICall
     #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $token
    )

    Set-Variable -Scope Script -Name scToken -Value $token
}

function Set-SCTokenIP {
    <#

    .SYNOPSIS
        Sets the Token IP value.

    .DESCRIPTION
        A standard set method for a class style variable. The token IP is not
        absolutely necessary for invoking token calls, but is useful for quickly
        verifying a token without a formal API call.

    .PARAMETER IP
        A valid IPv4 address to reference.

        **Note: This parameter will accept IPv6 addresses, though SuperCell's API may
                or may not actually support IPv6.

    .INPUTS
        System.Object

    .OUTPUTS
        None

    .LINK
        Set-SCTokenIP

    .LINK
        Test-TokenIP
     #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [IPAddress] $IP
    )

    Set-Variable -Scope Script -Name scTokenIP -Value $IP
}

function Test-SCTokenIP {
    <#
    .SYNOPSIS
        Tests the stored token IP to verify the configured/stored value is a valid
        active value.

    .DESCRIPTION
        Using an online service from ipinfo.io, this function tests the current IP
        against the configured IP and returns the comparison result.

    .INPUTS
        None

    .OUTPUTS
        System.ValueType

        Boolean

    .LINK
        Get-SCTokenIP

    .LINK
        Set-SCTokenIP
    #>
    [CmdletBinding()]
    param()

    $ip = (Invoke-RestMethod 'http://ipinfo.io/json' | Select -ExpandProperty IP)
    return ($ip -eq (Get-SCTokenIP))
}

function Test-SCToken {
    <#
    .SYNOPSIS
        Performs an abbreviated call to the SuperCell API and confirms a resonse
        is received.

    .DESCRIPTION
        Uses a sample URI from the SuperCell developer API to perform a call and
        verify some data is returned. If the returned data is as expected, true is
        returned and the token should be good.

        Note that this should be considered as an API call for rate limiting calculations.

        Known Issues: Currently, the function does not differentiate between authenticatin
        issues and 500 issues.

    .INPUTS
        None

    .OUTPUTS
        System.ValueType

        Boolean

    .LINK
        Invoke-SCPICall
    #>
    [CmdletBinding()]
    param()

    $result = $null
    try {
        $result = (Invoke-SCAPICall -uri 'https://api.clashofclans.com/v1/clans?name=Zero')
    } catch {}

    if($result -eq $null) {
        return $false
    }

    return $true
}
