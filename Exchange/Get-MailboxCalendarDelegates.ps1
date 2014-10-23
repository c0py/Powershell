function Get-MailboxCalendarDelegates {
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

    .EXAMPLE
    Get-MailboxCalendarDelegates -MailboxName "Test User1" -Verbose

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
                    Write-Warning "Get-MailboxCalendarDelegates: $_.Exception.Message"
                }
            }
            'AsMailbox' {
               $Mailboxes += $MailboxObject
            }
        }
    }
    end {
        $Mailboxes | Get-CalendarProcessing | Where {($_.resourcedelegates)} | Foreach {
            $_.Identity -match "^.*/(.*)$" | Out-Null
            $mailbox = $Matches[1]
            $delegates = @()
            Foreach ($delegate in $_.resourcedelegates)
            {
                $delegates += $delegate.Name
            }
            New-Object psobject -Property @{
                'Mailbox' = $mailbox
                'Delegates' = $delegates
            }
        }
    }
}