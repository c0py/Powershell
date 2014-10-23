function Get-MailboxExtendedRights {
    <#
    .SYNOPSIS
    Retrieves a list of mailbox sendonbehalf permissions
    .DESCRIPTION
    Get-MailboxExtendedRights gathers a list of extended permissions like 'send-as' on exchange mailboxes.
    .PARAMETER MailboxName
    One or more mailbox names in string format.
    .PARAMETER MailboxName
    One or more mailbox objects.
    .LINK
    http://www.the-little-things.net   
    .NOTES
    Last edit   :   10/04/2014
    Version     :   1.0.0 10/04/2014
    Author      :   Zachary Loeber

    .EXAMPLE
    Get-MailboxExtendedRights -MailboxName "Test User1" -Verbose

    Description
    -----------
    Gets the send-as rights for "Test User1" and shows verbose information.

    .EXAMPLE
    Get-MailboxExtendedRights -MailboxName "user1","user2" | Format-List

    Description
    -----------
    Gets the send-as rights on mailboxes "user1" and "user2" and returns the info as a format-list.

    .EXAMPLE
    (Get-Mailbox -Database "MDB1") | Get-MailboxExtendedRights

    Description
    -----------
    Gets all mailboxes in the MDB1 database and pipes it to Get-MailboxExtendedRights and returns the 
    send-as rights.
    #>
    [CmdLetBinding(DefaultParameterSetName='AsString')]
    param(
        [Parameter(ParameterSetName='AsString', Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage="Enter an Exchange mailbox name")]
        [string[]]$MailboxName,
        [Parameter(ParameterSetName='AsMailbox', Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage="Enter an Exchange mailbox name")]
        [Microsoft.Exchange.Data.Directory.Management.Mailbox[]]$MailboxObject,
        [Parameter(HelpMessage='Rights to check for.')]
        [string]$Rights="*send-as*",
        [Parameter(HelpMessage='Includes unresolved names (typically deleted accounts).')]
        [switch]$ShowAll
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
                    Write-Warning "Get-MailboxExtendedRights: $_.Exception.Message"
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
            $sendasperms = @(Get-ADPermission $Mailbox.identity | `
                             Where {$_.extendedrights -like $Rights} | `
                             Select @{n='Mailbox';e={$Mailbox.Name}},User,ExtendedRights,isInherited,Deny)
            if ($sendasperms.Count -gt 0)
            {
                if ($ShowAll)
                {
                    $sendasperms
                }
                else
                {
                    $sendasperms | Where {$_.Name -notlike 'S-1-*'}
                }
            }
        }
    }
}