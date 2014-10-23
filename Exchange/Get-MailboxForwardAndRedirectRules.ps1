function Get-MailboxForwardAndRedirectRules {
    <#
    .SYNOPSIS
    Retrieves a list of mailbox rules which forward or redirect email elsewhere.
    .DESCRIPTION
    Retrieves a list of mailbox rules which forward or redirect email elsewhere.
    .PARAMETER MailboxName
    One or more mailbox names in string format.
    .PARAMETER MailboxObject
    One or more mailbox objects.
    .LINK
    http://www.the-little-things.net
    .NOTES
    Last edit   :   10/10/2014
    Version     :   1.0.0 10/10/2014
    Author      :   Zachary Loeber
    Original Author: https://gallery.technet.microsoft.com/PowerShell-Script-To-Get-0f1bb6a7/

    .EXAMPLE
    Get-MailboxForwardAndRedirectRules -MailboxName "Test User1"

    Description
    -----------
    TBD
    #>
    [CmdLetBinding(DefaultParameterSetName='AsString')]
    param(
        [Parameter(ParameterSetName='AsString', Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage="Enter an Exchange mailbox name")]
        [string[]]$MailboxName,
        [Parameter(ParameterSetName='AsMailbox', Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage="Enter an Exchange mailbox name")]
        [Microsoft.Exchange.Data.Directory.Management.Mailbox[]]$MailboxObject
    )
    begin {
        $Mailboxes = @()
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'AsString' {
                try {
                    $Mailboxes = @($MailboxName | Foreach {Get-Mailbox $_ -erroraction Stop})
                }
                catch {
                    Write-Warning "Get-MailboxForwardAndRedirectRules: $_.Exception.Message"
                }
            }
            'AsMailbox' {
               $Mailboxes += $MailboxObject
            }
        }
    }
    end {
        Foreach ($Mailbox in $Mailboxes)
        {
            Write-Verbose "Get-MailboxForwardAndRedirectRules: Checking $($Mailbox.Name) for rules..."
            $rules = Get-InboxRule -mailbox $Mailbox.DistinguishedName -ErrorAction:SilentlyContinue | `
                     Where {($_.forwardto -ne $null) -or `
                            ($_.redirectto -ne $null) -or `
                            ($_.ForwardAsAttachmentTo -ne $null) -and `
                            ($_.ForwardTo -notmatch "EX:/") -and `
                            ($_.RedirectTo -notmatch "EX:/") -and `
                            ($_.ForwardAsAttachmentTo -notmatch "EX:/")} 
            if ($rules.Count -gt 0)
            {
                $rules | `
                    Select @{n="Mailbox";e={($Mailbox.Name)}}, `
                           @{n="Rule";e={$_.name}},Enabled, `
                           @{Name="ForwardTo";Expression={[string]::join(";",($_.forwardTo))}}, `
                           @{Name="RedirectTo";Expression={[string]::join(";",($_.redirectTo))}}, `
                           @{Name="ForwardAsAttachmentTo";Expression={[string]::join(";",($_.ForwardAsAttachmentTo))}} 
            }
        }
    }
}