function Send-WebhookMessage {
    <#
    .SYNOPSIS
        Performs a call to a Discord webhook.

    .DESCRIPTION
        Validates the parameters passed in for consistency and, if valid,
        conforms the messages to a Discord consumable format and invokes a web
        request on the passed in webhook uri.

        This function is built to handle Discord webhook rate limitations.
        Consequently, this function may sleep for a short period of time until
        the rate limit reset is called. Normal rate limiting lasts for 1-3
        seconds.

        In extreme cases, where many calls to the webhook are made at once,
        Discord may throw a 429 error. This error is may require the function
        sleep before completing this process.

        At the present time, this is a single threaded function and the caller
        should implement threading if needed.

    .PARAMETER Hook
        A valid, complete Discord webhook to the desired resource.

    .PARAMETER Message
        The desired message to send to Discord.

    .PARAMETER RetryCount
        The number of times to retry after receiving a 429 error before an
        error is rethrown to the caller. Valid values are between 5 and 0.

    .INPUTS
        System.String

    .OUTPUTS
        None
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
        [String] $Message,

        [Parameter(Mandatory=$false)]
        [ValidateRange(0,5)]
        [Int] $RetryCount=5
    )
    $body = New-Object -TypeName PSObject
    $body | Add-Member -MemberType NoteProperty -Name 'content' -Value $message
    $body = $body |ConvertTo-Json

    #Initialize on first run.
    if($script:limitRemaining -eq $null) {$script:limitRemaining = 5}
    if($script:resetTime -eq $null) {$script:resetTime = 0}

    #Get the time to calculate rate limiting below.
    $currentTime = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))

    #Sleep if we will be rate limited.
    if(($script:limitRemaining -eq 0) -and ($script:resetTime -gt $currentTime)) {
        $sleep = ($script:resetTime - $currentTime)

        Write-Verbose "Reached rate limit. Sleeping for $sleep seconds."
        Start-Sleep -Seconds $sleep
    }

    try {
        Write-Verbose "Calling webhook"

        $response = Invoke-WebRequest -Uri $hook -Method POST -Body $body
        $script:limitRemaining = $response.Headers['X-RateLimit-Remaining']
        $script:resetTime = $response.Headers['X-RateLimit-Reset']
    } catch [System.Net.WebException] {
        $response = $_.Exception.Response

        #Throw the error if we've exuasted our retry count.
        if($RetryCount -eq 0) { throw $_ }

        if($response.StatusCode -eq 429) {
            Write-Verbose "Received 429 status response."

            # For whatever reason, after a set amount of invokes, Discord suddenly decides
            # to change the retry time without warning and reset the X-RateLimit-Remaining
            # header to a non zero value. Zero the limit remaining and set the reset time
            # to utilize the Retry-After (as per the documentation)
            $script:limitRemaining = 0
            $script:resetTime = $currentTime + [Math]::Ceiling($response.Headers['Retry-After']/1000) + 1

            #Recurse to let this function handle sleep logic
            Send-WebhookMessage -Hook $hook -Message $message -RetryCount ($RetryCount-1)
        } else {
            Write-Verbose "Exception was not a 429 error. Re-throwing..."
            throw $_
        }
    }
}
