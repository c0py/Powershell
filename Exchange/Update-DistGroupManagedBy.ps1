﻿<#
    .SYNOPSIS
        Updates distribution list managers with the mailbox enabled members of another AD group.
   
       	Zachary Loeber
    	
    	THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
    	RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
    	
    	Version 1.0 - 04/10/2014
	
    .DESCRIPTION
        Updates distribution list managers with the mailbox enabled members of another AD group.
        Existing distribution group managers are merged with the AD group members.
	
	.PARAMETER GroupManagersToSet
        Name of the AD group containing the distribution group managers you are granting access to.
    
    .PARAMETER DistributionGroup
        Name of a distribution group to update. If not defined ALL distribution groups will be updated.
        
    .PARAMETER TestingMode
        Do not make any actual changes.

    .EXAMPLE
        # Update all distribution groups' managers list with the mailbox enabled members of SEC.DistManagers.
        .\Update-DistGroupManagedBy.ps1 -GroupManagersToSet SEC.DistManagers
        
    .NOTES
        Author: Zachary Loeber

        Version History:
        1.0 - 04/10/2014
            - Initial release
        
    .LINK 
        http://www.the-little-things.net 
#>
[CmdletBinding(SupportsShouldProcess=$True)] 
param ( 
    [Parameter( Mandatory = $true,
                HelpMessage='Name of the AD group containing the distribution group managers you are granting access to.')]
    [String]$GroupManagersToSet,
    
    [Parameter(HelpMessage='Name of a distribution group to update. If not defined ALL distribution groups will be updated.')]
    [String]$DistributionGroup='',
    
    [Parameter(HelpMessage=' Test what would be updated but do not make any actual changes.')]
    [switch]$TestingMode
)

begin {
    Write-Verbose "$($MyInvocation.MyCommand): Begin"
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction SilentlyContinue
    $ADModule = @(Get-Module | where {$_.Name -eq 'ActiveDirectory'})
    $ExchangeSnapin = @(Get-PSSnapin -Registered | where {$_.Name -eq 'Microsoft.Exchange.Management.PowerShell.SnapIn'})
    $WhatifSplat = @{}
    $ManagedByToSet = @()

    if ($TestingMode)
    {
        $WhatifSplat.whatif = $true
    }
    
    if (($ExchangeSnapin.Count -gt 0) -and ($ADModule.Count -gt 0))
    {
        $ModulesLoaded = $true
    }
    else
    {
        $ModulesLoaded = $false
    }
}
process {}
end {
    #if both the snapin and module are loaded then lets rock and roll
    if ($ModulesLoaded) 
    {
        $NewGroupManagers = @(Get-ADGroupMember $GroupManagersToSet -Recursive | 
            Where-Object {$_.objectClass -eq 'user'}).distinguishedName | 
                Select-Object -Unique

        # Use only those accounts associated with a mailbox
        $NewGroupManagers | ForEach-Object {
        	If (Get-Mailbox $_ -erroraction silentlycontinue)
            {
                $ManagedByToSet += $_
            }
        }
        
        if ($ManagedByToSet.Count -gt 0)
        {
            Microsoft.Exchange.Management.PowerShell.SnapIn\Get-DistributionGroup | Foreach {
                # Grab all the current group owners
                $CurrentManagedBy = @()
                if ($_.ManagedBy -ne $null)
                {
                    $CurrentManagedBy = @(($_ | Select -Expand ManagedBy).DistinguishedName)
                }
                
                # Get a count of any differences where a new owner needs to be assigned
                $ManagedByComparison = @(Compare-Object $CurrentManagedBy $ManagedByToSet | 
                                            Where-Object {$_.SideIndicator -eq '=>'})
                if ($ManagedByComparison.Count -gt 0)
                {
                    # If we have to update the dist group then come up with a combination of unique DNs to update with
                    $UpdatedManagedBy = @(($CurrentManagedBy + $ManagedByToSet) | Select-Object -Unique)
                    try
                    {
                        Write-Host "$($MyInvocation.MyCommand): Attempting to set the regular distribution group $($_)"
                        Microsoft.Exchange.Management.PowerShell.SnapIn\Set-DistributionGroup $_ -ManagedBy $UpdatedManagedBy -BypassSecurityGroupManagerCheck @WhatifSplat
                    }
                    catch
                    {
                        Write-Warning "$($MyInvocation.MyCommand): There was an issue updating the $($_) distribution group managedby attribute"
                    }
                }
            }
        }
        else
        {
            Write-Warning "$($MyInvocation.MyCommand): There were no valid mailbox enabled users to assign as distribution group managers."
        }
    }
    else
    {
        Write-Warning "$($MyInvocation.MyCommand): One or both the active directory or exchange components were unable to load"
    }
    Write-Verbose "$($MyInvocation.MyCommand): End"
}
