function Invoke-EditSafeLinksFilter {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Exchange.SpamFilter.Read
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers
    Write-LogMessage -headers $Headers -API $APIName -message 'Accessed this API' -Sev 'Debug'

    # Interact with query parameters or the body of the request.
    $TenantFilter = $Request.Query.tenantFilter ?? $Request.Body.tenantFilter
    $RuleName = $Request.Query.RuleName ?? $Request.Body.RuleName
    $State = $Request.Query.State ?? $Request.Body.State

    try {
        $ExoRequestParam = @{
            tenantid         = $TenantFilter
            cmdParams        = @{
                Identity = $RuleName
            }
            useSystemmailbox = $true
        }

        switch ($State) {
            'Enable' {
                $ExoRequestParam.Add('cmdlet', 'Enable-SafeLinksRule')
            }
            'Disable' {
                $ExoRequestParam.Add('cmdlet', 'Disable-SafeLinksRule')
            }
            Default {
                throw 'Invalid state'
            }
        }
        $null = New-ExoRequest @ExoRequestParam

        $Result = "Successfully set SafeLinks rule $($RuleName) to $($State)"
        Write-LogMessage -headers $Headers -API $APIName -tenant $TenantFilter -message $Result -Sev Info
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        $Result = "Failed setting SafeLinks rule $($RuleName) to $($State). Error: $($ErrorMessage.NormalizedError)"
        Write-LogMessage -headers $Headers -API $APIName -tenant $TenantFilter -message $Result -Sev 'Error'
        $StatusCode = [HttpStatusCode]::InternalServerError
    }

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = @{Results = $Result }
        })
}
