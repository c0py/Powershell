﻿function Import-PSCredential {
    <#
    .SYNOPSIS
    Import credential which was previously exported via teh Export-PSCredential function.
    .DESCRIPTION
    Import credential which was previously exported via teh Export-PSCredential function.
    This will only import correctly on the computer which the export file was created upon.
    .PARAMETER FilePath
    File to import credentials from.
    .EXAMPLE
    $NewCreds = Import-PSCredential -FilePath c:\Temp\testcred.cred
    $UserName= $NewCreds.GetNetworkCredential().UserName
    $Password = $NewCreds.GetNetworkCredential().Password
    $Domain = $NewCreds.GetNetworkCredential().Domain

    Description
    -----------
    Import the credentials of c:\Temp\testcred.cred and then break out the username, password, and domain.
    .LINK
    http://the-little-things.net/
    .NOTES
    Author:  Zachary Loeber
    Created: 08/29/2104
    #>
    [CmdletBinding()]
    param(
        [parameter(HelpMessage='Saved xml credential file.')]
        [ValidateScript({Test-Path $_ })]
        [string]$FilePath
    )
    try {
        $ImportCreds = Import-Clixml $FilePath -ErrorAction Stop
    }
    catch {
        throw 'Import-PSCredential: Load Failed! Validate that the credential file is a valid xml export.'
    }
    
    if ( $ImportCreds.PSObject.TypeNames -notcontains 'Deserialized.ExportedPSCredential' ) {
	    throw "Import-PSCredential: Input is not a valid ExportedPSCredential object, exiting."
    }
    
    try {
        $SecurePass = $ImportCreds.EncryptedPassword | ConvertTo-SecureString -Erroraction Stop
    }
    catch {
        throw 'Import-PSCredential: Password decryption failed!'
    }

    $ImportArgs = @($ImportCreds.UserName, $SecurePass)
    $NewCreds = New-Object System.Management.Automation.PSCredential -ArgumentList $ImportCreds.UserName, $SecurePass -ErrorAction Stop
    
    return $NewCreds
}
