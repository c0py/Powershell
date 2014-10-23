function Get-MailboxSendOnBehalfPermission {
    <#
    .SYNOPSIS
    Retrieves a list of mailbox sendonbehalf permissions
    .DESCRIPTION
    Get-MailboxSendOnBehalfPermission gathers a list of users with sendonbehalf permissions for a mailbox.
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
    Get-MailboxSendOnBehalfPermission -MailboxName "Test User1" -Verbose

    Description
    -----------
    Gets the sendonbehalf permissions for "Test User1" and shows verbose information.

    .EXAMPLE
    Get-MailboxSendOnBehalfPermission -MailboxName "user1","user2" | Format-List

    Description
    -----------
    Gets the sendonbehalf permissions for "user1" and "user2" and returns the info as a format-list.

    .EXAMPLE
    (Get-Mailbox -Database "MDB1") | Get-MailboxSendOnBehalfPermission | Where {$_.SendOnBehalf -notlike "S-1-*"}

    Description
    -----------
    Gets all mailboxes in the MDB1 database and pipes it to Get-MailboxSendOnBehalfPermission and returns the 
    sendonbehalf permissions as an autosized format-table containing the Mailbox and sendonbehalf User.
    #>
    [CmdLetBinding(DefaultParameterSetName='AsString')]
    param(
        [Parameter(ParameterSetName='AsString', Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage="Enter an Exchange mailbox name")]
        [string[]]$MailboxName,
        [Parameter(ParameterSetName='AsMailbox', Mandatory=$True, ValueFromPipeline=$True, Position=0, HelpMessage="Enter an Exchange mailbox name")]
        [Microsoft.Exchange.Data.Directory.Management.Mailbox[]]$MailboxObject,
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
                    Write-Warning "Get-MailboxSendOnBehalfPermission: $_.Exception.Message"
                }
            }
            'AsMailbox' {
               $Mailboxes += $MailboxObject
            }
        }
    }
    end {
        $Mailboxes | Foreach {
            $sendbehalfperms = @($_ | Select -expand grantsendonbehalfto | Select -expand rdn | Select Unescapedname)
            if ($sendbehalfperms.Count -gt 0)
            {
                if ($ShowAll)
                {
                    $sendbehalfperms = ($sendbehalfperms).Unescapedname
                }
                else
                {
                    $sendbehalfperms = ($sendbehalfperms | Where {$_.Unescapedname -notlike 'S-1-*'}).Unescapedname
                }
                New-Object psobject -Property @{
                    'Mailbox' = $_.Name
                    'SendOnBehalf' = $sendbehalfperms
                }
            }
        }
    }
}

#        Where {($USERPERM_IGNORE_LIST -notcontains $_.Unescapedname)} 