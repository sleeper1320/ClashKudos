function Send-WebhookMessage {
    <#
    .SYNOPSIS
        Performs a call to a Discord webhook.

    .DESCRIPTION
        Validates the parameters passed in for consistency and, if valid, conforms the
        messages to a Discord consumable format and invokes a web request on the passed
        in webhook uri.

        At the moment, errors received when calling the web request are passed to the
        calling function. Future revisions of this function may handle errors internally.

    .PARAMETER hook
        A valid, complete Discord webhook to the desired resource.

    .PARAMETER message
        The desired message to send to Discord.

    .INPUTS
        System.String

    .OUTPUTS
        None
     #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
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
        [String] $hook,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String] $message
    )
    $body = New-Object -TypeName PSObject
    $body | Add-Member -MemberType NoteProperty -Name 'content' -Value $message
    $body = $body |ConvertTo-Json

    Invoke-WebRequest -Uri $hook -Method POST -Body $body | Out-Null
}
