﻿<#  
.NOTES  
    File Name  : Mats.exe
    Version    : 1.0
    Authors    : Stephen McComas, Jay Cotton, Ben Winzenz
    Date       : 1/9/2015
    Copyright  : Microsoft Corporation, 2015
#>

#==============================================================================================
# XAML Code
#==============================================================================================
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window Name="MATS"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MATS v1.0    (Managed Availability Trouble Shooter)" Height="500" Width="525" WindowStartupLocation="CenterScreen" WindowStyle="ToolWindow">
    <Grid Margin="0,0,0.4,-4.4">
        <Button Name="btnGo" Content="Get Results" HorizontalAlignment="Left" Margin="251,75,0,0" VerticalAlignment="Top" Width="80" IsEnabled="False" RenderTransformOrigin="2.205,-0.073"/>
        <Button Name="btnServer" Content="Server Health" HorizontalAlignment="Left" Margin="343,99,0,0" VerticalAlignment="Top" Width="80" IsEnabled="False"/>
        <Button Name="btnExit" Content="Exit" HorizontalAlignment="Left" Margin="343,75,0,0" VerticalAlignment="Top" Width="80" />
        <Button Name="btnHealth" Content="Health Report" HorizontalAlignment="Left" Margin="251,99,0,0" VerticalAlignment="Top" Width="80" IsEnabled="False" ToolTip="Get a current Health Report of the selected server" />
        <ComboBox Name="ddlServers" HorizontalAlignment="Left" Margin="72,72,0,0" VerticalAlignment="Top" Width="161" IsEnabled="False" ToolTip="Select a server to run the tools against" IsReadOnly="True"/>
        <GroupBox Name="grpTests" Header="" HorizontalAlignment="Left" Margin="57,127,0,0" VerticalAlignment="Top" Height="151" Width="385">
            <RadioButton Name="radLam" Content="LAM Results" HorizontalAlignment="Left" Margin="10,0,0,0" VerticalAlignment="Top" GroupName="grpTests" IsChecked="False" IsEnabled="False"/>
        </GroupBox>
        <RadioButton Name="radCritical" Content="Critical Events" HorizontalAlignment="Left" Margin="270,143,0,0" VerticalAlignment="Top" GroupName="grpTests" IsEnabled="False"/>
        <ComboBox Name="ddlTest" HorizontalAlignment="Left" Margin="184,175,0,0" VerticalAlignment="Top" Width="161" IsReadOnly="True" ToolTip="Select the Results you want to see here" IsEnabled="False">
            <ListBoxItem Content="ALL"/>
        </ComboBox>
        <GroupBox Name="grpDates" Header="" HorizontalAlignment="Left" Margin="57,283,0,0" VerticalAlignment="Top" Height="123" Width="385">
            <CheckBox Name="chkDates" Content="Select Start/End Time/Dates" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" IsEnabled="False"/>
        </GroupBox>
        <DatePicker Name="dtpStart" HorizontalAlignment="Left" Margin="156,331,0,0" VerticalAlignment="Top" Width="161" IsEnabled="False" Text="Select the start day"/>
        <DatePicker Name="dtpEnd" HorizontalAlignment="Left" Margin="156,360,0,0" VerticalAlignment="Top" Width="161" IsEnabled="False" Text="Select the end day"/>
        <Label Name="lblStart" Content="Start Date" HorizontalAlignment="Left" Margin="89,330,0,0" VerticalAlignment="Top" IsEnabled="False"/>
        <Label Name="lblEnd" Content="End Date" HorizontalAlignment="Left" Margin="89,361,0,0" VerticalAlignment="Top" IsEnabled="False"/>
        <Label Name="lblTests" Content="Select Test" HorizontalAlignment="Left" Margin="72,175,0,0" VerticalAlignment="Top"/>
        <Label Name="lblMax" Content="Max # of Results" HorizontalAlignment="Left" Margin="72,240,0,0" VerticalAlignment="Top"/>
        <TextBox Name="txtMax" HorizontalAlignment="Left" Height="23" Margin="184,242,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="65" IsEnabled="False"/>
        <Label Name="lblWorkItem" Content="Work Item Type" HorizontalAlignment="Left" Margin="72,207,0,0" VerticalAlignment="Top" IsEnabled="False"/>
        <ComboBox Name="ddlWorkItem" HorizontalAlignment="Left" Margin="184,210,0,0" VerticalAlignment="Top" Width="161" IsEnabled="False" ToolTip="Type of work items to fetch. (You Don't have to select a value here...)" RenderTransformOrigin="0.365,0.634"/>
        <CheckBox Name="chkDef" Content="Get Definitions" HorizontalAlignment="Left" Margin="270,246,0,0" VerticalAlignment="Top" ToolTip="Whether to output work item definitions, instead of their results" IsEnabled="False"/>
        <Button Name="btnTips" Content="Troubleshooting Tips" HorizontalAlignment="Left" Margin="184,422,0,0" VerticalAlignment="Top" Width="124"/>
        <TextBox Name="txtURL" HorizontalAlignment="Left" Height="23" Margin="170,23,0,0" VerticalAlignment="Top" Width="161" ToolTip="Enter the URL to connect to Exchange via PowerShell.  For example:  http://FQDN of an exchange server/powershell"/>
        <GroupBox Name="grpMain" Header="" HorizontalAlignment="Left" Margin="57,56,0,0" VerticalAlignment="Top" Height="71" Width="385"/>
        <Button Name="btnConnect" Content="Connect" HorizontalAlignment="Left" Margin="343,23,0,0" VerticalAlignment="Top" Width="75"/>
        <Label Name="lblURL" Content="PowerShell URI" HorizontalAlignment="Left" Margin="57,23,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.459,-0.1"/>
    </Grid>
</Window>
'@
#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

#===========================================================================
# Functions
#===========================================================================

function ConnectExchange {
    param([string]$URL)
    $CurrSession = @(Get-PSSession | where {($_.ConfigurationName -eq 'Microsoft.Exchange') -and ($_.Availability -eq 'Available')})
    if ($CurrSession.Count -eq 0) {
        $credential = get-credential
        $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $URL -Credential $credential
        Import-PSSession $session -AllowClobber -WarningAction SilentlyContinue
    }
    
    $test = Get-PSSession
    if($test.ConfigurationName -notlike "*exchange*")
    {
        Write-Host "ERROR! It Appears that we could not load the exchange powershell module. Please make sure that the $($URL) is correct.  Cannot continue, exiting script." -ForegroundColor Red
        exit
    }
    else
    {
        $ddlServers.isEnabled = $true
        $servers = Get-ExchangeServer | where {$_.IsE15orLater -eq "True"} | Sort Name
        Write-Host "Found $($servers.length) Exchange 2013 Servers......." -ForegroundColor Cyan
        If($servers.length -gt 0)
        {
            $ddlServers.Items.Add("LocalHost")
            ForEach($server in $servers)
            {
                $ddlServers.Items.Add($server.name)
            }
            $btnConnect.isEnabled = $false
        }
        Else
        {
            Write-host "No Exchange 2013 Servers Found!!"  -ForegroundColor Red
        }
    }
}

Function CriticalEvents
{
param([string]$computer,[string]$component,[string]$Lticks,[string]$Eticks,[string]$MaxEvents)  #added Max Events #

$info = $computer.Split(" ")
$computer = $info[0]
$component = $info[1]
$Lticks = $info[2]
$Eticks = $info[3]
$MaxEvents = $info[4]  ##pulling Max Events out of the array #

        If ($component -eq "AD")
        {
            Get-WinEvent -Computer "$($computer)" -LogName:"Application" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[Provider/@Name='MSExchange ADAccess' and (EventID=2070 or EventID=2164)])]" -ErrorAction SilentlyContinue | Out-GridView -Title "AD $computer"
            Get-WinEvent -Computer "$($computer)" -LogName:"Application" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[Provider/@Name='MSExchange ADAccess' and (EventID=2070 or EventID=2164)])]" -ErrorAction SilentlyContinue 
        }
        If ($component -eq "EWS") 
        {
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionResults" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=501] and UserData/EventXML[(ResourceName='MSExchangeServicesAppPool' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "EWS Recovery Action Results $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/Monitoring"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=4] and UserData/EventXML[(HealthSet='EWS' or HealthSet='EWS.Protocol' or HealthSet='EWS.Proxy')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "EWS Monitoring $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionLogs" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and UserData/EventXML[(ResourceName='MSExchangeServicesAppPool' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "EWS Recovery Action Logs $computer" 
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[(Data[@Name='param1']='World Wide Web Publishing Service' or Data[@Name='param1']='IIS Admin Service')] or System[Provider/@Name='Microsoft-Windows-WAS']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "EWS System Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='EWS'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='EWS'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='EWS' or Data='EWS')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='w3wp'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='w3wp.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='w3wp.exe' or Data='w3wp')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/ews')]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "EWS Application Log $computer"
        }
        If ($component -eq "HA") 
        {
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-HighAvailability/Operational"  -MaxEvents 101 -FilterXPath "*[System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks]]" -ErrorAction SilentlyContinue | Out-GridView -Title "HA Operational $Computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[Provider/@Name='Service Control Manager'] and EventData[Data[@Name='param1']='Microsoft Exchange Replication Service'])]" -ErrorAction SilentlyContinue | Out-GridView -Title "HA System Log $Computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='MSExchangeRepl'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='MSExchangeRepl.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='MSExchangeRepl.exe' or Data='MSExchangeRepl')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchangeIS Mailbox Store' and EventID=9523]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "HA Application Log $Computer"
        }
        If ($component -eq "HM") 
        {
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[Data[@Name='param1']='Microsoft Exchange Health Manager']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "HM System Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[(Data='MSExchangeHMHost' or Data='MSExchangeHMWorker')] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[(Data='MSExchangeHMHost.exe' or Data='MSExchangeHMWorker.exe')] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='MSExchangeHMHost.exe' or Data='MSExchangeHMWorker.exe' or Data='MSExchangeHMHost' or Data='MSExchangeHMWorker')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchangeHM' and (EventID=1001 or EventID=1006 or EventID=1009 or EventID=1010)]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "HM Application Log $computer"
        }

        If ($component -eq "Monitoring") #added Managed Availability Monitoring#
        {
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/Monitoring" -MaxEvents:$MaxEvents -FilterXPath  "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks])]" -ErrorAction SilentlyContinue| Out-GridView -Title "Managed Availability Monitoring $Computer"
        }

        If ($component -eq "OutlookMapiHttp") 
        {
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/Monitoring"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=4] and UserData/EventXML[(HealthSet='OutlookMapiHttp' or HealthSet='OutlookMapiHttp.Protocol' or HealthSet='OutlookMapiHttp.Proxy')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook MAPI HTTP Managed Availability / Monitoring $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionResults"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=501] and UserData/EventXML[(ResourceName='MSExchangeMapiFrontEndAppPool' or ResourceName='MSExchangeMapiMailboxAppPool' or ResourceName='MSExchangeMapiAddressBookAppPool' or ResourceName='MSExchangeProtectedServiceHost' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook MAPI HTTP Recovery Action Results $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionLogs" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and UserData/EventXML[(ResourceName='MSExchangeMapiFrontEndAppPool' or ResourceName='MSExchangeMapiMailboxAppPool' or ResourceName='MSExchangeMapiAddressBookAppPool' or ResourceName='MSExchangeProtectedServiceHost' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook MAPI HTTP Recovery Action Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[(Data[@Name='param1']='World Wide Web Publishing Service' or Data[@Name='param1']='IIS Admin Service')] or System[Provider/@Name='Microsoft-Windows-WAS']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook MAPI HTTP System Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='Mapi'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='Mapi'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='Mapi' or Data='Mapi')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='w3wp'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='w3wp.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='w3wp.exe' or Data='w3wp')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/mapi')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/mapi/emsmdb')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/mapi/nspi')] or System[Provider[@Name='MSExchangeDiagnostics'] and EventID=1005] and EventData[((Data[7]='MSExchangeMapiFrontEndAppPool' or Data[7]='MSExchangeMapiMailboxAppPool' or Data[7]='MSExchangeMapiAddressBookAppPool' or Data[7]='_Total'))]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook MAPI HTTP Application Log $computer"
        }
        If ($component -eq "OutlookRpc") 
        {
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/Monitoring"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=4] and UserData/EventXML[(HealthSet='Outlook' or HealthSet='Outlook.Protocol' or HealthSet='Outlook.Proxy')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook RPC Managed Availability / Monitoring $Computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionResults" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=501] and UserData/EventXML[(ResourceName='MSExchangeRpcProxyAppPool' or ResourceName='MSExchangeRPC' or ResourceName='MSExchangeProtectedServiceHost' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook RPC Recovery Action Results $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionLogs" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and UserData/EventXML[(ResourceName='MSExchangeRpcProxyAppPool' or ResourceName='MSExchangeRPC' or ResourceName='MSExchangeProtectedServiceHost' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook RPC Recovery Action Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[Data[@Name='param1']='Microsoft Exchange RPC Client Access'] or System[Provider/@Name='Service Control Manager'] and EventData[(Data[@Name='param1']='World Wide Web Publishing Service' or Data[@Name='param1']='IIS Admin Service')] or System[Provider/@Name='Microsoft-Windows-WAS']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook RPC System Log $Computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[(Data='M.E.RpcClientAccess.Service' or Data='Microsoft.Exchange.RpcClientAccess.Service')] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='Microsoft.Exchange.RpcClientAccess.Service.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='Microsoft.Exchange.RpcClientAccess.Service.exe' or Data='M.E.RpcClientAccess.Service' or Data='Microsoft.Exchange.RpcClientAccess.Service')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='w3wp'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='w3wp.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='w3wp.exe' or Data='w3wp')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/Rpc')] or System[Provider[@Name='MSExchangeDiagnostics'] and EventID=1005] and EventData[((Data[7]='MSExchangeRPC' or Data[7]='MSExchangeRpcProxyAppPool' or Data[7]='_Total'))] or System[Provider/@Name='MSExchangeRPC' and (EventID=1001 or EventID=1006 or EventID=1026 or Level!=4)] or System[Provider/@Name='MSExchange RPC Over HTTP Autoconfig' and EventID>=4000 and EventID<=4999] or System[Provider/@Name='MSExchange ADAccess' and EventID=2164]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook RPC Application Log $Computer"
        }
        If ($component -eq "OWA") 
        {
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionResults" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=501] and UserData/EventXML[(ResourceName='MSExchangeOWAAppPool' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "OWA Recovery Action Results $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/Monitoring"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=4] and UserData/EventXML[(HealthSet='OWA' or HealthSet='OWA.Protocol' or HealthSet='OWA.Proxy')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "OWA Monitoring $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionLogs" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and UserData/EventXML[(ResourceName='MSExchangeOWAAppPool' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "OWA Recovery Action Logs"
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[(Data[@Name='param1']='World Wide Web Publishing Service' or Data[@Name='param1']='IIS Admin Service')] or System[Provider/@Name='Microsoft-Windows-WAS']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "OWA System Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='OWA'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='OWA'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='OWA' or Data='OWA')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='w3wp'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='w3wp.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='w3wp.exe' or Data='w3wp')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/owa')]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "OWA Application Log $computer"
        }
        If ($component -eq "Perf") 
        {
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[Data[@Name='param1']='Microsoft Exchange Diagnostics']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Perf System Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[(Data='M.E.Diagnostics.Service' or Data='Microsoft.Exchange.Diagnostics.Service')] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='Microsoft.Exchange.Diagnostics.Service.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='Microsoft.Exchange.Diagnostics.Service.exe' or Data='M.E.Diagnostics.Service' or Data='Microsoft.Exchange.Diagnostics.Service')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchangeHM' and (EventID=1001 or EventID=1006 or EventID=1009 or EventID=1010)] or System[Provider[@Name='MSExchangeDiagnostics'] and EventID=1005] ))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Perf Application Log $computer"
        }

        If ($component -eq "Recovery") ##added Recovery Actions ##
        {
        If ($chkDates.isChecked) #Added a check if Dates are checked if so use the dates, if not return last 101
        {
            $RecoveryActionResultsEvents =  Get-WinEvent -Computer:"$($computer)" -LogName "Microsoft-Exchange-ManagedAvailability/RecoveryActionResults" -MaxEvents:$MaxEvents -FilterXPath  "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks])]" -ErrorAction SilentlyContinue 
            $RecoveryActionResultsXML = ($RecoveryActionResultsEvents | Foreach-object -Process {[XML]$_.toXml()}).event.userData.eventXml | Select EndTime, ID, State, ResourceName, RequestorName,Result | Out-GridView -Title "Recovery Actions Taken for $Computer" 
        }
        Else
        {
            $RecoveryActionResultsEvents =  Get-WinEvent -Computer:"$($computer)" -LogName "Microsoft-Exchange-ManagedAvailability/RecoveryActionResults" -MaxEvents:$MaxEvents -ErrorAction SilentlyContinue 
            $RecoveryActionResultsXML = ($RecoveryActionResultsEvents | Foreach-object -Process {[XML]$_.toXml()}).event.userData.eventXml   | Select EndTime, ID, State, ResourceName, RequestorName,Result   | Out-GridView -Title "Recovery Actions Taken for $Computer" 
        }
          }
        If ($component -eq "StoreUser") 
        {
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=9646])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Store User Application Log"
        }
        If ($component -eq "ALL")
        {
            Get-WinEvent -Computer "$($computer)" -LogName:"Application" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[Provider/@Name='MSExchange ADAccess' and (EventID=2070 or EventID=2164)])]" -ErrorAction SilentlyContinue | Out-GridView -Title "AD $computer"
            Get-WinEvent -Computer "$($computer)" -LogName:"Application" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[Provider/@Name='MSExchange ADAccess' and (EventID=2070 or EventID=2164)])]" -ErrorAction SilentlyContinue 
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionResults" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=501] and UserData/EventXML[(ResourceName='MSExchangeServicesAppPool' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "EWS Recovery Action Results $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/Monitoring"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=4] and UserData/EventXML[(HealthSet='EWS' or HealthSet='EWS.Protocol' or HealthSet='EWS.Proxy')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "EWS Monitoring $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionLogs" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and UserData/EventXML[(ResourceName='MSExchangeServicesAppPool' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "EWS Recovery Action Logs $computer" 
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[(Data[@Name='param1']='World Wide Web Publishing Service' or Data[@Name='param1']='IIS Admin Service')] or System[Provider/@Name='Microsoft-Windows-WAS']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "EWS System Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='EWS'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='EWS'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='EWS' or Data='EWS')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='w3wp'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='w3wp.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='w3wp.exe' or Data='w3wp')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/ews')]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "EWS Application Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-HighAvailability/Operational"  -MaxEvents 101 -FilterXPath "*[System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks]]" -ErrorAction SilentlyContinue | Out-GridView -Title "HA Operational $Computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[Provider/@Name='Service Control Manager'] and EventData[Data[@Name='param1']='Microsoft Exchange Replication Service'])]" -ErrorAction SilentlyContinue | Out-GridView -Title "HA System Log $Computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='MSExchangeRepl'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='MSExchangeRepl.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='MSExchangeRepl.exe' or Data='MSExchangeRepl')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchangeIS Mailbox Store' and EventID=9523]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "HA Application Log $Computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[Data[@Name='param1']='Microsoft Exchange Health Manager']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "HM System Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[(Data='MSExchangeHMHost' or Data='MSExchangeHMWorker')] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[(Data='MSExchangeHMHost.exe' or Data='MSExchangeHMWorker.exe')] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='MSExchangeHMHost.exe' or Data='MSExchangeHMWorker.exe' or Data='MSExchangeHMHost' or Data='MSExchangeHMWorker')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchangeHM' and (EventID=1001 or EventID=1006 or EventID=1009 or EventID=1010)]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "HM Application Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/Monitoring"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=4] and UserData/EventXML[(HealthSet='OutlookMapiHttp' or HealthSet='OutlookMapiHttp.Protocol' or HealthSet='OutlookMapiHttp.Proxy')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook MAPI HTTP Managed Availability / Monitoring $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionResults"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=501] and UserData/EventXML[(ResourceName='MSExchangeMapiFrontEndAppPool' or ResourceName='MSExchangeMapiMailboxAppPool' or ResourceName='MSExchangeMapiAddressBookAppPool' or ResourceName='MSExchangeProtectedServiceHost' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook MAPI HTTP Recovery Action Results $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionLogs" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and UserData/EventXML[(ResourceName='MSExchangeMapiFrontEndAppPool' or ResourceName='MSExchangeMapiMailboxAppPool' or ResourceName='MSExchangeMapiAddressBookAppPool' or ResourceName='MSExchangeProtectedServiceHost' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook MAPI HTTP Recovery Action Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[(Data[@Name='param1']='World Wide Web Publishing Service' or Data[@Name='param1']='IIS Admin Service')] or System[Provider/@Name='Microsoft-Windows-WAS']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook MAPI HTTP System Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='Mapi'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='Mapi'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='Mapi' or Data='Mapi')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='w3wp'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='w3wp.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='w3wp.exe' or Data='w3wp')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/mapi')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/mapi/emsmdb')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/mapi/nspi')] or System[Provider[@Name='MSExchangeDiagnostics'] and EventID=1005] and EventData[((Data[7]='MSExchangeMapiFrontEndAppPool' or Data[7]='MSExchangeMapiMailboxAppPool' or Data[7]='MSExchangeMapiAddressBookAppPool' or Data[7]='_Total'))]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook MAPI HTTP Application Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/Monitoring"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=4] and UserData/EventXML[(HealthSet='Outlook' or HealthSet='Outlook.Protocol' or HealthSet='Outlook.Proxy')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook RPC Managed Availability / Monitoring $Computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionResults" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=501] and UserData/EventXML[(ResourceName='MSExchangeRpcProxyAppPool' or ResourceName='MSExchangeRPC' or ResourceName='MSExchangeProtectedServiceHost' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook RPC Recovery Action Results $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionLogs" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and UserData/EventXML[(ResourceName='MSExchangeRpcProxyAppPool' or ResourceName='MSExchangeRPC' or ResourceName='MSExchangeProtectedServiceHost' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook RPC Recovery Action Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[Data[@Name='param1']='Microsoft Exchange RPC Client Access'] or System[Provider/@Name='Service Control Manager'] and EventData[(Data[@Name='param1']='World Wide Web Publishing Service' or Data[@Name='param1']='IIS Admin Service')] or System[Provider/@Name='Microsoft-Windows-WAS']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook RPC System Log $Computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[(Data='M.E.RpcClientAccess.Service' or Data='Microsoft.Exchange.RpcClientAccess.Service')] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='Microsoft.Exchange.RpcClientAccess.Service.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='Microsoft.Exchange.RpcClientAccess.Service.exe' or Data='M.E.RpcClientAccess.Service' or Data='Microsoft.Exchange.RpcClientAccess.Service')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='w3wp'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='w3wp.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='w3wp.exe' or Data='w3wp')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/Rpc')] or System[Provider[@Name='MSExchangeDiagnostics'] and EventID=1005] and EventData[((Data[7]='MSExchangeRPC' or Data[7]='MSExchangeRpcProxyAppPool' or Data[7]='_Total'))] or System[Provider/@Name='MSExchangeRPC' and (EventID=1001 or EventID=1006 or EventID=1026 or Level!=4)] or System[Provider/@Name='MSExchange RPC Over HTTP Autoconfig' and EventID>=4000 and EventID<=4999] or System[Provider/@Name='MSExchange ADAccess' and EventID=2164]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Outlook RPC Application Log $Computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionResults" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=501] and UserData/EventXML[(ResourceName='MSExchangeOWAAppPool' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "OWA Recovery Action Results $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/Monitoring"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=4] and UserData/EventXML[(HealthSet='OWA' or HealthSet='OWA.Protocol' or HealthSet='OWA.Proxy')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "OWA Monitoring $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ManagedAvailability/RecoveryActionLogs" -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and UserData/EventXML[(ResourceName='MSExchangeOWAAppPool' or ResourceName='w3svc' or ResourceName='Ex2013')])]" -ErrorAction SilentlyContinue | Out-GridView -Title "OWA Recovery Action Logs"
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[(Data[@Name='param1']='World Wide Web Publishing Service' or Data[@Name='param1']='IIS Admin Service')] or System[Provider/@Name='Microsoft-Windows-WAS']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "OWA System Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='OWA'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='OWA'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='OWA' or Data='OWA')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[Data='w3wp'] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='w3wp.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='w3wp.exe' or Data='w3wp')] or System[Provider[@Name='ASP.NET 4.0.30319.0' or @Name='ASP.NET 2.0.50727.0'] and EventID=1309] and EventData[Data[1]=3005 and (Data[11]='/owa')]))]" -ErrorAction SilentlyContinue | Out-GridView -Title "OWA Application Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"System"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='EventLog' and (EventID=6006 or EventID=6013)] or System[Provider/@Name='Service Control Manager'] and EventData[Data[@Name='param1']='Microsoft Exchange Diagnostics']))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Perf System Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and (System[Provider/@Name='MSExchange Common' and EventID=4999] and EventData[(Data='M.E.Diagnostics.Service' or Data='Microsoft.Exchange.Diagnostics.Service')] or System[Provider/@Name='Application Error' and EventID=1000] and EventData[Data='Microsoft.Exchange.Diagnostics.Service.exe'] or System[Provider/@Name='Windows Error Reporting' and EventID=1001] and EventData[(Data='Microsoft.Exchange.Diagnostics.Service.exe' or Data='M.E.Diagnostics.Service' or Data='Microsoft.Exchange.Diagnostics.Service')] or System[Provider/@Name='AEDebug' and EventID=1234] or System[Provider/@Name='MSExchangeHM' and (EventID=1001 or EventID=1006 or EventID=1009 or EventID=1010)] or System[Provider[@Name='MSExchangeDiagnostics'] and EventID=1005] ))]" -ErrorAction SilentlyContinue | Out-GridView -Title "Perf Application Log $computer"
            Get-WinEvent -Computer:"$($computer)" -LogName:"Application"  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System[EventID=9646])]" -ErrorAction SilentlyContinue | Out-GridView -Title "Store User Application Log"
        }
    }

Function LAMResults
{
param([string]$computer,[string]$component,[string]$Lticks,[string]$Eticks,[string]$WorkItem,[string]$MaxEvents,[string]$getDefs)

$info = $computer.Split(" ")
$computer = $info[0]
$set = $info[1]
$Lticks = $info[2]
$Eticks = $info[3]
$WorkItem = $info[4]
$MaxEvents = $info[5]
$getDefs = $info[6]

If ($WorkItem -eq "Probe") 
{
    If ($Set -eq "All")
    {
       $Probes =  (Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ActiveMonitoring/ProbeResult" -MaxEvents:$MaxEvents -FilterXPath  "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System/Level!=4 and UserData/EventXML/ResultType!=5)]" | % {[xml]$_.toXml()}).event.userData.eventXml | Select MachineName, ExecutionStartTime, ServiceName,ResultName, Error -ErrorAction SilentlyContinue | Out-GridView -Title "Health Set All: $computer"
    }
    Else 
    { 
        $Probes = (Get-WinEvent -Computer:"$($computer)" -LogName:"Microsoft-Exchange-ActiveMonitoring/ProbeResult" -MaxEvents:$MaxEvents  -FilterXPath "*[(System/TimeCreated[timediff(@SystemTime)>=$Eticks and timediff(@SystemTime)<=$Lticks] and System/Level!=4 and UserData/EventXML/ResultType!=5 and UserData/EventXML[ServiceName='$Set'])]" | % {[xml]$_.toXml()}).event.userData.eventXml | Select MachineName, ExecutionStartTime, ServiceName,ResultName, Error -ErrorAction SilentlyContinue| Out-GridView -Title "HealthSet: $Set : $computer"
    } 
}
If ($WorkItem -eq "Responders")  
    {
        $DefinedResponders = (Get-WinEvent -Computer: "$($computer)" -LogName Microsoft-Exchange-ActiveMonitoring/ResponderDefinition | % {[xml]$_.toXml()}).event.userData.eventXml
        $DefinedResponders | ? {$_.ServiceName -like $Set} | select TypeName,Name,TargetResource,AlertMask,WaitIntervalSeconds | Out-GridView -Title "Defined Responders for $Set"
    }
If ($WorkItem -eq "Monitors") 
    {
        $DefinedMonitors = (Get-WinEvent -Computer:"$($computer)" -LogName Microsoft-Exchange-ActiveMonitoring/ResponderDefinition | % {[xml]$_.toXml()}).event.userData.eventXml
        $DefinedMonitors | ? {$_.ServiceName -like $Set} | select Name,ServiceName,AlertMask | Out-GridView -Title "Defined Monitors for $Set"
    }
If ($getdefs -eq "True")
    {
        (Get-WinEvent -LogName Microsoft-Exchange-ActiveMonitoring/ProbeDefinition | % {[XML]$_.toXml()}).event.userData.eventXml | ?{$_.Name -like "$computer"} | select Name,ID,Endpoint,ServiceName,TargetResource,RecurrenceIntervalSeconds,TimeoutSeconds -ErrorAction SilentlyContinue |Out-GridView -Title "Definition For $computer"
    }
}

#===========================================================================
# Add events to Form Objects
#===========================================================================

$ddlServers.Add_SelectionChanged({
$btnHealth.IsEnabled = $true
$btnServer.IsEnabled = $true
$radCritical.IsEnabled = $true
$radLam.IsEnabled = $true
$chkDates.IsEnabled = $true
})

$chkDates.Add_Checked({
$dtpStart.IsEnabled=$true
$dtpEnd.IsEnabled =$true
})

$chkDates.Add_UnChecked({
$dtpStart.IsEnabled=$false
$dtpEnd.IsEnabled =$false
})

$radCritical.Add_Click({
#Clean up some of the LAM Stuff if they Exist
$txtMax.text = ""
$chkDef.IsChecked = $False  
$ddlWorkItem.Items.Clear()
$ddlWorkItem.IsEnabled = $false
$txtMax.isEnabled = $True
$chkDef.isEnabled = $false
$ddltest.isEnabled = $True


#Add Items to Test Drop Down
$ddlTest.items.Clear()
$ddlTest.items.Add("All")
$ddlTest.Items.Add("AD")
$ddlTest.Items.Add("EWS")
$ddlTest.Items.Add("HA")
$ddlTest.Items.Add("HM")
$ddlTest.Items.Add("Monitoring")  #added Monitoring#
$ddlTest.Items.Add("OutllokMapiHttp")
$ddlTest.Items.Add("OutlookRpc")
$ddlTest.Items.Add("OWA")
$ddlTest.Items.Add("Perf")
$ddlTest.Items.Add("Recovery")  #added recovery Actions ####
$ddlTest.Items.Add("StoreUser")
})

$btnConnect.Add_Click({
$URL = $txtURL.text
ConnectExchange($URL)
})

$btnTips.Add_Click({
$ie = New-Object -ComObject InternetExplorer.Application
$ie.Navigate("https://technet.microsoft.com/en-us/library/dn195892(v=exchg.150).aspx")
$ie.Visible = $true
})

$radLam.Add_Click({
$server = $ddlServers.text
$ddlTest.isEnabled = $true
$txtMax.isEnabled = $true
$chkDef.isEnabled = $true
$sets = Get-HealthReport -Server $server | Sort HealthSet
$ddlTest.items.Clear()
$ddlTest.items.Add("All")
    ForEach($set in $sets)
    {
        $ddlTest.Items.Add($set.HealthSet)
    }
#Defaults to 'Probe'. Can also be 'Monitor', 'Responder' or 'Maintenance'.
$ddlWorkItem.isEnabled = $true
$ddlWorkItem.Items.Clear()
$ddlWorkItem.Items.Add("Probe")
$ddlWorkItem.Items.Add("Monitors")
$ddlWorkItem.Items.Add("Responders")
})

$ddlTest.Add_SelectionChanged({$btnGo.IsEnabled = $true })

$btnExit.Add_Click(  #Added Cleanup to support removing PSSessions upon exit
{
If ($btnConnect.IsEnabled = $false)
{
    $Cleanup = Get-PSSession | where {$_.ConfigurationName -like "*Exchange"}
    ForEach ($Clean in $Cleanup)
    {
        Remove-PSSession $Clean.Id
    }
}
    $form.Close()
})

$btnServer.Add_Click({Get-ServerHealth -Server $ddlservers.text | Out-GridView -Title "Current Server Health Report for server $($ddlservers.text)"})

$btnHealth.Add_Click({Get-HealthReport -Server $ddlservers.text | Out-GridView -Title "Current Health Report for server $($ddlservers.text)"})

$btnGo.Add_Click(
{
    If ($ddlTest.text -eq $null)
    {
        Write-Host "Please Select a test" -ForegroundColor Cyan
    }

    Else
    {
        $servername = $ddlServers.text
        $component = $ddlTest.text
        $WorkItem = $ddlWorkItem.text
        $MaxEvents = $txtMax.text 

    If   ($MaxEvents -eq "")  ##set Max events to 101 if left blank ##
    {
        $MaxEvents  = 101
    }

    If ($chkDef.isChecked)
    {
        $defs = "True"
    }
    Else
    {
        $defs = "False"
    }

    If ($chkDates.IsChecked)
    {
        If($dtpStart -like "*/*")
        {
            $LastN = $dtpStart.Text
        }
        If($dtpEnd -like "*/*")
        {
            $EndAt = $dtpEnd.Text
        }
    }

    $test = $ddlTest.Text.Length

    If ($test -eq "0")
    {
        Write-Host "Please Select a test" -ForegroundColor Cyan
        #Need to see about adding popup box 
    }
    else
    {
        $servername = $ddlServers.text
        $component = $ddlTest.text
        If ($LastN -eq $null)
        {
            $LTimeDiff = New-TimeSpan -Start (Get-Date).AddDays(-1) -End (Get-Date)
            $Lticks = $LTimeDiff.TotalMilliseconds.ToString()
        }
        ElseIf ($LastN -ne $null)
        {
            $LtempTime = New-TimeSpan -Start $LastN -End (Get-Date)
            $LTimeDiff = New-TimeSpan -Start (Get-Date).AddDays(-$LtempTime.Days) -End (Get-Date)
            $Lticks = $LTimeDiff.TotalMilliseconds.ToString()
        }
        If ($EndAt -eq $null)
        {
            $Eticks = 0
        }
        ElseIf ($EndAt -ne $null)
        {
            $ETimeDiff = New-TimeSpan -Start $EndAt -End (Get-Date)
            $Eticks = $ETimeDiff.TotalMilliseconds.ToString()
        }
        If ($radCritical.Ischecked)
        {
            CriticalEvents($servername, $component, $LTicks, $Eticks, $MaxEvents)  ##Added MaxEvents ##
        }
        If ($radLam.Ischecked)
        {
            LamResults($servername, $component, $LTicks, $Eticks,$WorkItem,$MaxEvents,$defs)  ##Added MaxEvents and WorkItems ##
        }
    }
}})
#===========================================================================
# Shows the form
#===========================================================================
$form.ShowDialog() | out-null
