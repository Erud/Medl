# PowerShell RDP Manager
# Version: 1.1
# Created: 2018-06-28
# Modified: 20-18-07-02
#=====================================================
$RDPFavs = "$env:USERPROFILE\Desktop\RDPFavs.json"
Import-Module AnyBox

#$Cred = Get-Credential 'medline-nt\pa-erudakov'
$password = get-content C:\temp\cred.txt | convertto-securestring
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "medline-nt\pa-erudakov",$password
#read-host -assecurestring | convertfrom-securestring | out-file C:\temp\cred.txt

#$credential = Get-Credential

#$credential | Export-CliXml -Path 'C:\My\Path\cred.xml'
#To re-import:

#$credential = Import-CliXml -Path 'C:\My\Path\cred.xml'

#-------------------------------------------------------------------
Function Connect-Mstsc {
	<#   
.SYNOPSIS   
Function to connect an RDP session without the password prompt
    
.DESCRIPTION 
This function provides the functionality to start an RDP session without having to type in the password
	
.PARAMETER ComputerName
This can be a single computername or an array of computers to which RDP session will be opened

.PARAMETER User
The user name that will be used to authenticate

.PARAMETER Password
The password that will be used to authenticate

.PARAMETER Credential
The PowerShell credential object that will be used to authenticate against the remote system

.PARAMETER Admin
Sets the /admin switch on the mstsc command: Connects you to the session for administering a server

.PARAMETER MultiMon
Sets the /multimon switch on the mstsc command: Configures the Remote Desktop Services session monitor layout to be identical to the current client-side configuration 

.PARAMETER FullScreen
Sets the /f switch on the mstsc command: Starts Remote Desktop in full-screen mode

.PARAMETER Public
Sets the /public switch on the mstsc command: Runs Remote Desktop in public mode

.PARAMETER Width
Sets the /w:<width> parameter on the mstsc command: Specifies the width of the Remote Desktop window

.PARAMETER Height
Sets the /h:<height> parameter on the mstsc command: Specifies the height of the Remote Desktop window

.NOTES   
Name:        Connect-Mstsc
Author:      Jaap Brasser
DateUpdated: 2016-10-28
Version:     1.2.5
Blog:        http://www.jaapbrasser.com

.LINK
http://www.jaapbrasser.com

.EXAMPLE   
. .\Connect-Mstsc.ps1
    
Description 
-----------     
This command dot sources the script to ensure the Connect-Mstsc function is available in your current PowerShell session

.EXAMPLE   
Connect-Mstsc -ComputerName server01 -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force)

Description 
-----------     
A remote desktop session to server01 will be created using the credentials of contoso\jaapbrasser

.EXAMPLE   
Connect-Mstsc server01,server02 contoso\jaapbrasser (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force)

Description 
-----------     
Two RDP sessions to server01 and server02 will be created using the credentials of contoso\jaapbrasser

.EXAMPLE   
server01,server02 | Connect-Mstsc -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) -Width 1280 -Height 720

Description 
-----------     
Two RDP sessions to server01 and server02 will be created using the credentials of contoso\jaapbrasser and both session will be at a resolution of 1280x720.

.EXAMPLE   
server01,server02 | Connect-Mstsc -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) -Wait

Description 
-----------     
RDP sessions to server01 will be created, once the mstsc process is closed the session next session is opened to server02. Using the credentials of contoso\jaapbrasser and both session will be at a resolution of 1280x720.

.EXAMPLE   
Connect-Mstsc -ComputerName server01:3389 -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) -Admin -MultiMon

Description 
-----------     
A RDP session to server01 at port 3389 will be created using the credentials of contoso\jaapbrasser and the /admin and /multimon switches will be set for mstsc

.EXAMPLE   
Connect-Mstsc -ComputerName server01:3389 -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) -Public

Description 
-----------     
A RDP session to server01 at port 3389 will be created using the credentials of contoso\jaapbrasser and the /public switches will be set for mstsc

.EXAMPLE
Connect-Mstsc -ComputerName 192.168.1.10 -Credential $Cred

Description 
-----------     
A RDP session to the system at 192.168.1.10 will be created using the credentials stored in the $cred variable.

.EXAMPLE   
Get-AzureVM | Get-AzureEndPoint -Name 'Remote Desktop' | ForEach-Object { Connect-Mstsc -ComputerName ($_.Vip,$_.Port -join ':') -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) }

Description 
-----------     
A RDP session is started for each Azure Virtual Machine with the user contoso\jaapbrasser and password supersecretpw

.EXAMPLE
PowerShell.exe -Command "& {. .\Connect-Mstsc.ps1; Connect-Mstsc server01 contoso\jaapbrasser (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) -Admin}"

Description
-----------
An remote desktop session to server01 will be created using the credentials of contoso\jaapbrasser connecting to the administrative session, this example can be used when scheduling tasks or for batch files.
#>
	[cmdletbinding(SupportsShouldProcess,DefaultParametersetName='UserPassword')]
	param (
	[Parameter(Mandatory=$true,
	ValueFromPipeline=$true,
	ValueFromPipelineByPropertyName=$true,
	Position=0)]
	[Alias('CN')]
	[string[]]     $ComputerName,
	[Parameter(ParameterSetName='UserPassword',Mandatory=$true,Position=1)]
	[Alias('U')] 
	[string]       $User,
	[Parameter(ParameterSetName='UserPassword',Mandatory=$true,Position=2)]
	[Alias('P')] 
	[string]       $Password,
	[Parameter(ParameterSetName='Credential',Mandatory=$true,Position=1)]
	[Alias('C')]
	[PSCredential] $Credential,
	[Alias('A')]
	[switch]       $Admin,
	[Alias('MM')]
	[switch]       $MultiMon,
	[Alias('F')]
	[switch]       $FullScreen,
	[Alias('Pu')]
	[switch]       $Public,
	[Alias('W')]
	[int]          $Width,
	[Alias('H')]
	[int]          $Height,
	[Alias('WT')]
	[switch]       $Wait
	)
	
	begin {
		[string]$MstscArguments = ''
		switch ($true) {
			{$Admin}      {$MstscArguments += '/admin '}
			{$MultiMon}   {$MstscArguments += '/multimon '}
			{$FullScreen} {$MstscArguments += '/f '}
			{$Public}     {$MstscArguments += '/public '}
			{$Width}      {$MstscArguments += "/w:$Width "}
			{$Height}     {$MstscArguments += "/h:$Height "}
		}
		
		if ($Credential) {
			$User     = $Credential.UserName
			$Password = $Credential.GetNetworkCredential().Password
		}
	}
	process {
		foreach ($Computer in $ComputerName) {
			if(Test-Connection -Cn $Computer -BufferSize 16 -Count 1 -ErrorAction 0 -quiet){
				$ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
				$Process = New-Object System.Diagnostics.Process
				
				# Remove the port number for CmdKey otherwise credentials are not entered correctly
				if ($Computer.Contains(':')) {
					$ComputerCmdkey = ($Computer -split ':')[0]
				} else {
					$ComputerCmdkey = $Computer
				}
				
				$ProcessInfo.FileName    = "$($env:SystemRoot)\system32\cmdkey.exe"
				$ProcessInfo.Arguments   = "/generic:TERMSRV/$ComputerCmdkey /user:$User /pass:$($Password)"
				$ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
				$Process.StartInfo = $ProcessInfo
				if ($PSCmdlet.ShouldProcess($ComputerCmdkey,'Adding credentials to store')) {
					[void]$Process.Start()
				}
				
				$ProcessInfo.FileName    = "$($env:SystemRoot)\system32\mstsc.exe"
				$ProcessInfo.Arguments   = "$MstscArguments /v $Computer"
				$ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
				$Process.StartInfo       = $ProcessInfo
				if ($PSCmdlet.ShouldProcess($Computer,'Connecting mstsc')) {
					[void]$Process.Start()
					if ($Wait) {
						$null = $Process.WaitForExit()
					}       
				}
			} 
			else {
				#Write-Error "$($Computer): Offline"
				#Write-Host "$($Computer): Offline" -ForegroundColor red
				$tm = (get-date).ToString('T')
				$list_Log.Items.Add("$tm  ---> Offline $($list_favs.SelectedItem)")
			}
		}
	}
}
#-------------------------------------------------------------------
#region Import the Assemblies
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion

Function Load-Favs {
	If (Test-Path -Path $RDPFavs -ErrorAction SilentlyContinue) {
		$Favs = Get-Content -Raw $RDPFavs | ConvertFrom-Json
		ForEach ($Fav in $Favs) {
			$list_favs.Items.Add($Fav)
		}
	} Else {
		$Favs = $null
	}
}

Function Save-Favs {
	$list_favs.Items | ConvertTo-Json | Out-File $RDPFavs
}

Function Start-RDP ($computername){    
	#Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$computername"
	Connect-Mstsc -Credential $Cred -ComputerName $computername
}

Function Get-AllDCs {
	#$ADDCs = (Get-ADForest 'medline.com' -ErrorAction SilentlyContinue -ErrorVariable errForest ).domains | ForEach {Get-ADDomain -Identity $_ -ErrorAction SilentlyContinue } | ForEach {Get-ADDomainController -Server $_.DNSRoot -Filter * -ErrorAction SilentlyContinue } | select HostName | Sort-Object
	$ADDCs = Get-ADComputer -Filter 'Name -like "*PRDDC*"' | select DNSHostName | Sort-Object
	
	ForEach ($DC in $ADDCs) {
		$cmb_allDCs.items.Add( $dc.DNSHostName )
	}
	$cmb_allDCs.Sorted = $true
	
}
$listBox_DrawItem={
	param(
	[System.Object] $sender, 
	[System.Windows.Forms.DrawItemEventArgs] $e
	)
	#Suppose Sender de type Listbox
	if ($Sender.Items.Count -eq 0) {return}
	
	#Suppose item de type String
	$lbItem=$Sender.Items[$e.Index]
	if ( $lbItem.Contains('--->'))  
	{ 
		$Color=[System.Drawing.Color]::pink     
		try
		{
			$brush = new-object System.Drawing.SolidBrush($Color)
			$e.Graphics.FillRectangle($brush, $e.Bounds)
		}
		finally
		{
			$brush.Dispose()
		}
	}
	$e.Graphics.DrawString($lbItem, $e.Font, [System.Drawing.SystemBrushes]::ControlText, (new-object System.Drawing.PointF($e.Bounds.X, $e.Bounds.Y)))
}   
  

#region begin GUI{ 

$rdpManager                      = New-Object system.Windows.Forms.Form
$rdpManager.ClientSize           = '600,455'
$rdpManager.text                 = "RDP Manager"
$rdpManager.TopMost              = $false
$rdpManager.icon                 = 'C:\Users\erudakov\Documents\PS\favicon.ico'

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Favorites"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(12,15)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$cmb_allDCs                      = New-Object system.Windows.Forms.ComboBox
$cmb_allDCs.text                 = "Select"
$cmb_allDCs.width                = 278
$cmb_allDCs.height               = 20
$cmb_allDCs.location             = New-Object System.Drawing.Point(302,42)
$cmb_allDCs.Font                 = 'Microsoft Sans Serif,10'
$cmb_allDCs.AutoSize             = $true

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "All Domain Controllers"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(302,18)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$btn_AddToFavs                   = New-Object system.Windows.Forms.Button
$btn_AddToFavs.text              = "Add To Favs"
$btn_AddToFavs.width             = 115
$btn_AddToFavs.height            = 27
$btn_AddToFavs.location          = New-Object System.Drawing.Point(465,133)
$btn_AddToFavs.Font              = 'Microsoft Sans Serif,10'

$btn_removeFav                   = New-Object system.Windows.Forms.Button
$btn_removeFav.text              = "Remove Fav"
$btn_removeFav.width             = 115
$btn_removeFav.height            = 27
$btn_removeFav.location          = New-Object System.Drawing.Point(302,133)
$btn_removeFav.Font              = 'Microsoft Sans Serif,10'

$btn_NewPass                     = New-Object system.Windows.Forms.Button
$btn_NewPass.text                = "Change Password"
$btn_NewPass.width               = 245
$btn_NewPass.height              = 30
$btn_NewPass.location            = New-Object System.Drawing.Point(26,310)
$btn_NewPass.Font                = 'Microsoft Sans Serif,10'

$txt_addFav                      = New-Object system.Windows.Forms.TextBox
$txt_addFav.multiline            = $false
$txt_addFav.width                = 279
$txt_addFav.height               = 20
$txt_addFav.location             = New-Object System.Drawing.Point(302,74)
$txt_addFav.Font                 = 'Microsoft Sans Serif,10'

$Label3                          = New-Object system.Windows.Forms.Label
$Label3.text                     = "Select from above, or enter hostname manually"
$Label3.AutoSize                 = $true
$Label3.width                    = 25
$Label3.height                   = 10
$Label3.location                 = New-Object System.Drawing.Point(300,109)
$Label3.Font                     = 'Microsoft Sans Serif,8'

$btn_launch                      = New-Object system.Windows.Forms.Button
$btn_launch.text                 = "Launch RDP for Fav"
$btn_launch.width                = 250
$btn_launch.height               = 30
$btn_launch.location             = New-Object System.Drawing.Point(317,310)
$btn_launch.Font                 = 'Microsoft Sans Serif,10'

$list_favs                        = New-Object system.Windows.Forms.ListBox
$list_favs.text                   = "Select"
$list_favs.width                  = 275
$list_favs.height                 = 249
$list_favs.location               = New-Object System.Drawing.Point(12,42)

$list_Log                        = New-Object system.Windows.Forms.ListBox
$list_Log.text                   = "Select"
$list_Log.width                  = 572
$list_Log.height                 = 95
$list_Log.location               = New-Object System.Drawing.Point(12,355)
$list_Log.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
$list_Log.Add_DrawItem($listBox_DrawItem)
#$list_Log.DrawMode               = 'OwnerDrawFixed'
#$list_Log.FormattingEnabled      = $True

$rdpManager.controls.AddRange(@($Label1,$cmb_allDCs,$Label2,$btn_AddToFavs,$btn_NewPass,$btn_removeFav,$txt_addFav,$Label3,$btn_launch,$list_favs,$list_Log))

#region gui events {
$btn_NewPass.Add_Click({
	#read-host "Enter a Password" -assecurestring | convertfrom-securestring | out-file C:\temp\cred.txt
	$ans = Show-AnyBox -Title 'Credentials' -Buttons 'Cancel','Submit' -MinWidth 100 -Prompts @(
	New-AnyBoxPrompt -Group 'Connection Info' -Message 'User Name:' -DefaultValue "medline/pa-erudakov"
	New-AnyBoxPrompt -Group 'Connection Info' -Message 'Password:' -InputType Password
	)
	$ans.Input_1 | convertfrom-securestring | out-file C:\temp\cred.txt
	$tm = (get-date).ToString('T')
	$list_Log.Items.Add("$tm  Password for $($ans.Input_0) updated")
})

$btn_launch.Add_Click({
	Start-RDP($list_favs.SelectedItem)
	$tm = (get-date).ToString('T')
	$list_Log.Items.Add("$tm  Launching RDP for $($list_favs.SelectedItem)")
})
$btn_removeFav.Add_Click({    
	$list_favs.Items.RemoveAt($list_favs.SelectedIndex)
	Save-Favs
})
$btn_AddToFavs.Add_Click({    
	If ($txt_addFav.Text.Length -gt 0){
		$list_favs.Items.Add($txt_addFav.Text)
		Save-Favs
		$txt_addFav.Text = ""
	} Else {
		$list_favs.Items.Add($cmb_allDCs.SelectedItem)
		Save-Favs
	}
})

$txt_addFav.Add_KeyUp({
	if ($_.KeyCode -eq "Enter") {
		If ($txt_addFav.Text.Length -gt 0){
			$list_favs.Items.Add($txt_addFav.Text)
			Save-Favs
			$txt_addFav.Text = ""
		}
	}
})

$rdpManager.Add_Load({ Load-Favs; Get-AllDCs })
$list_favs.Add_DoubleClick({
	Start-RDP($list_favs.SelectedItem)
	$tm = (get-date).ToString('T')
	#	Write-Host "Launching RDP for $($list_favs.SelectedItem)"
	$list_Log.Items.Add("$tm  Launching RDP for $($list_favs.SelectedItem)")
})
#endregion events }

#endregion GUI }

[void]$rdpManager.ShowDialog()
