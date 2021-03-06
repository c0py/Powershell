﻿<#
.Synopsis
Resolve account name from SID.
.Description
This command uses the WSMAN protocol to query WMI and resolve an account based
on its SID.  Using WMI it was possible to run a command like this:
 
[wmi]$user="\\SERVER01\root\cimv2:Win32_SID.Sid='S-1-5-18'"
 
But this relies on WMI and DCOM. This command uses a CIM-cmdlet approach that
queries WMI over the WSMAN protocol. If the SID can't be resolved to a user name
an exception will be thrown.
 
If you want to revert back to the WMI and DCOM approach, use the -UseWMI parameter.
However, you will not be able to use alternate credentials.
 
.Parameter SID
It is assumed the SID will start with S- and you must enter a complete SID.
Wildcards are not allowed.
 
.Parameter Computername
The name of the computer to query. The default is the localhost. The parameter
has an alias of CN.
 
.Parameter UseWMI
Revert to the legacy [WMI] command. This parameter has an alias of WMI.
 
.Parameter Credential
This parameter as an alias of RunAs. Specify either a username or a PSCredential
object.
 
.Notes
Last Updated: October 15, 2013
Version     : 1.0
 
Learn more:
 PowerShell in Depth: An Administrator's Guide (http://www.manning.com/jones2/)
 PowerShell Deep Dives (http://manning.com/hicks/)
 Learn PowerShell 3 in a Month of Lunches (http://manning.com/jones3/)
 Learn PowerShell Toolmaking in a Month of Lunches (http://manning.com/jones4/)
 PowerShell and WMI (http://www.manning.com/siddaway2/)
 
****************************************************************
* DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
* THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
* YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
* DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
****************************************************************
 
.Example
PS C:\> resolve-sid S-1-5-18
 
Name                 : NT AUTHORITY\SYSTEM
AccountName          : SYSTEM
ReferencedDomainName : NT AUTHORITY
SID                  : S-1-5-18
Computername         : WIN8-LAP
 
.Example
PS C:\> resolve-sid S-1-5-21-1199145963-1667969739-787794555-1011 -Computername chi-win8-01 -Credential globomantics\administrator
 
Name                 : CHI-WIN8-01\localadmin
AccountName          : localadmin
ReferencedDomainName : CHI-WIN8-01
SID                  : S-1-5-21-1199145963-1667969739-787794555-1011
Computername         : CHI-WIN8-01
 
.Example
PS C:\> resolve-sid S-1-5-18 -verbose -computername jdhit-dc01 -UseWMI
 
VERBOSE: Starting Resolve-SID
VERBOSE: Resolving SID S-1-5-18 on jdhit-dc01
VERBOSE: Reverting back to WMI
VERBOSE: \\jdhit-dc01\root\cimv2:Win32_SID.SID='S-1-5-18'
VERBOSE: Associated account found
 
Name                 : NT AUTHORITY\SYSTEM
Accountname          : SYSTEM
ReferencedDomainName : NT AUTHORITY
SID                  : S-1-5-18
Computername         : JDHIT-DC01
 
VERBOSE: Ending Resolve-SID
 
.Link
Get-WSManInstance
Get-CIMInstance
 
.Link
http://jdhitsolutions.com/blog/2013/10/resolving-sids-with-wmi-wsman-and-powershell
 
.Inputs
Strings
 
.Outputs
A custom object
#>
[cmdletbinding(DefaultParameterSetName="CIM")]
 
Param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a SID",
ValueFromPipeline,ValueFromPipelineByPropertyName)]
[ValidatePattern("^S-")]
[string]$SID,
[Parameter(ValueFromPipelineByPropertyName)]
[Alias("CN","PSComputername")]
[ValidateNotNullorEmpty()]
[string]$Computername=$env:computername,
[Alias("RunAs")]
[Parameter(ParameterSetName="CIM")]
[System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty,
[Parameter(ParameterSetName="WMI")]
[Alias("wmi")]
[switch]$UseWMI
)
 
Begin {
    Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"  
} #begin
Process {
    Write-Verbose "Resolving SID $SID on $Computername"
    #build a hashtable of paramters to splat to Get-WSManInstance
    $paramHash=@{
        ErrorAction="Stop"
        ErrorVariable="MyError"
        ResourceURI="wmicimv2/win32_SID"
        SelectorSet=@{SID="$SID"}
        Computername=$Computername
    }
 
    If ($Credential.username) {
        Write-Verbose "Adding alternate credential for $($Credential.username)"
        $paramHash.Add("Credential",$Credential)
    }
 
    Try {
 
        #if UseWMI, use Get-WMIObject
        if ($UseWMI) {
            Write-Verbose "Reverting back to WMI"
            Write-Verbose "\\$computername\root\cimv2:Win32_SID.SID='$SID'"
            [WMI]$Result = "\\$computername\root\cimv2:Win32_SID.SID='$SID'"
 
        }
        else {
            $result = Get-WSManInstance @paramhash 
        }
    }
    Catch {
        Write-Warning "Get-WSManInstance failed to retrieve SID from $($Computername.ToUpper())"
        Write-Warning $myError.ErrorRecord
        #bail out
        Return
    }
 
    <#
    if there is no account name then the SID was not resolved, but there was
    no error. The query will still succeed and write an object to the pipeline
    but it won't have any useful information.  Only write the result to the pipeline
    if there is an associated account, otherwise an exception will be thrown.
    #>
 
    if ($result.AccountName) {
        Write-Verbose "Associated account found"
        $result | 
        Select @{Name="Name";Expression={"$($_.ReferencedDomainName)\$($_.AccountName)"}},
        Accountname,ReferencedDomainName,SID,
        @{Name="Computername";Expression={$Computername.ToUpper()}}
    }
    else {
        Write-Verbose "Failed to resolve SID. This is the result"
        Write-Verbose $($Result | Out-String)
        Throw "Failed to resolve SID $SID on $($Computername.ToUpper())"
    }
} #process
 
End {
    Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
} #end
 
} #close function Resolve-SID
