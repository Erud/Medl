<#
.SYNOPSIS
    Creates an .RDG file for Microsoft Remote Desktop Connection Manager 2.7
	
.DESCRIPTION
	Creates an .RDG file for Microsoft Remote Desktop Connection Manager 2.7
	
	- Uses Active Directory Module to create the list of servers.
	- Filters by Operating System (Default = *server*).
	- Filters Operating Systems by last logon date.
	- Organizes servers into groups based upon Domain.
	- Prompts for a single set of credentials for each Domain.
	- Encrypts passwords using the RDCMan Encryption method.  
		- Passwords are optional in the Get-Credential.
	- Sets the RDCMan connection to same size as client area.
	- Creates smart groups in each domain using SPNs for:
		- Clustered Servers
		- DNS Servers
		- Domain Controllers
		- SQL Servers
		- Web Server
	- Add Active Directory comments to each server for:
		- Name
		- IP Address
		- Operating System
		- Managed By
		- Description
	- Add Active Directory Forest and Domain Mode comment to each group.
	- Adds servers as Favorites if $Favorites is specified.
	- Requires Microsoft Remote Desktop Connection Manager 2.7 is installed. 
	- Verbose logging supported.
	
	References and Inspiration
	Markus Lassfolk - https://gallery.technet.microsoft.com/scriptcenter/Automatically-generate-da1d502b
	Trevor Jones - https://smsagent.wordpress.com/2017/01/26/decrypting-remote-desktop-connection-manager-passwords-with-powershell/	
	
.NOTES
	Created:	July 7, 2015
	Author:		Randy Millar
	
	Change Log:
	July 7, 2015			Randy M		Initial Development
	January 4, 2018			Randy M		Added Smart Groups, RDC Encrypted passwords, 
										code-clean up, comments, Try-Catch-Finally.
										Specified PowerShell 5 as a requirement.
										(stop using old versions!)  :)

.PARAMETER OutPath
	[String]
	[Mandatory]
	File path to save XML output to

.PARAMETER LastLogon
	[Int]
	[Mandatory]
	Number of days to filter last logon date for computer objects in Active Directory

.PARAMETER Filter
	[String]
	[Optional]
	Operating System filter for Get-AdComputer.  Default is "*server*"

.PARAMETER Favorites
	[Array]
	[Mandatory]
	Array of strings to mark as favorite servers.

.PARAMETER Verbose
	[Boolean]
	[Optional]
	Output verbose logging on screen during creation.

.EXAMPLE
	Create-RdcMan -Outpath D:\Temp\NewRdcMan.Rdg -LastLogon 15 -Favorites "DC*", "File*", "DHCP*"
	
	Creates a new RDC Manager file called NewRdcMan.Rdg filtering servers that connected in the last
	15 days.  Marks any server that is named DC*, File*, and DHCP* as a favorite.
	
.EXAMPLE
	Create-RdcMan -Outpath D:\Temp\NewRdcMan.Rdg -LastLogon 21 -Favorites "DC*", "File*", "DHCP*" -filter "*windows*"
	
	Creates a new RDC Manager file called NewRdcMan.Rdg adding all Windows operating systems 
	that connected in the last 21 days.  Marks any computer that is named DC*, File*, and DHCP* as a favorite.
	
#>
Param(
	[Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
	[ValidateNotNullOrEmpty()]
	[String]$OutPath,
	[Parameter(Mandatory=$True, ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
	[ValidateNotNullOrEmpty()]
	[Int]$LastLogon,
	[Parameter(Mandatory=$False, ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
	[ValidateNotNullOrEmpty()]
	[String]$Filter = "*server*",
	[Parameter(Mandatory=$False, ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
	[ValidateNotNullOrEmpty()]
	[Array]$Favorites
)

#Requires -Version 5
#Requires -Modules ActiveDirectory

# Functions #
Function Decrypt-SecureString()
{
	Param(
		[Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
		[ValidateNotNullOrEmpty()]
		[System.Security.SecureString]$Password
	)
	Return [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($Password))
}
Function Import-RdcManModule()
{ 
	Param(
		[Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
		[ValidateNotNullOrEmpty()]
		[String]$Path
	)
	$TempFolder = $Env:Temp
	$RdcManDll = "$(Get-Random -min 1000 -max 9999).dll"
	Copy-Item $Path "$TempFolder\$RdcManDll"
	Import-Module "$TempFolder\$RdcManDll"
	Return $RdcManDll
}
Function Encrypt-RdcManPassword()
{
Param(
		[Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
		[ValidateNotNullOrEmpty()]
		[String]$Password
	)
	$EncryptSettings = New-Object -TypeName RdcMan.EncryptionSettings
	Return [RdcMan.Encryption]::EncryptString($Password, $EncryptSettings)
}
Try
{
	# Variables #
	$ThisScript = Get-ChildItem $myInvocation.MyCommand.Source
	$ThisVersion = Get-Date $ThisScript.LastWriteTime -Format "MMy 'Build' HHmmss"
	$RdcManComment = "Version $ThisVersion - $([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String("UgBhAG4AZAB5ACAATQBpAGwAbABhAHIA")))"
	$LastLogonDate = (Get-Date).AddDays($LastLogon*-1)
	$MarkAsFavorite = @()
	$AdForest = Get-AdForest
	$RdcManExePath = "C:\Program Files (x86)\Microsoft\Remote Desktop Connection Manager\rdcMan.exe"
	
	# Validate RdcMan.Exe exists
	If (!(Test-Path -Path $RdcManExePath))
	{
		Throw "Microsoft Remote Desktop Connection Manager 2.7 is not installed!"
	}
	Else
	{
		$RdcModule = Import-RdcManModule -Path $RdcManExePath
	}
		
	Write-Verbose -Message "Found ($AdForest.Name) Active Directory Forest."
	Write-Verbose -Message "Enumerating Domain Controllers."
	$DomainControllerList = $AdForest.GlobalCatalogs

	Write-Verbose -Message "Found $($DomainControllerList.Count) domain controllers."
	Write-Verbose -Message "Creating RDCMan XML File."
	$Encoding = [System.Text.Encoding]::UTF8
	$XmlWriter = New-Object System.XML.XmlTextWriter($OutPath, $Encoding)
	$XmlWriter.Formatting = "Indented"
	$XmlWriter.Indentation = 2
	$XmlWriter.IndentChar = " "
	$XmlWriter.WriteStartDocument()

	$XmlWriter.WriteComment($RdcManComment)
	$XmlWriter.WriteStartElement("RDCMan")
	$XmlWriter.WriteAttributeString("programVersion","2.7")
	$XmlWriter.WriteAttributeString("schemaVersion", "3")

	# XML Create Element - file
	$XmlWriter.WriteStartElement("file")

	# XML Create Element - credentialsProfiles
	$XmlWriter.WriteStartElement("credentialsProfiles")
	Foreach ($AdDomain in $AdForest.Domains)
	{
		Write-Verbose -Message "Querying credentials for $AdDomain."
		$DomainInfo = Get-AdDomain $AdDomain
		$Creds = Get-Credential -Message "Specify $($DomainInfo.Name) Credential" -Username "$($DomainInfo.NetBIOSName)\"
		$PlainText = Decrypt-SecureString -Password $Creds.Password
		If ($PlainText -ne "")
		{
			$RdcEncrypt = Encrypt-RdcManPassword -Password $PlainText
		}
		Else
		{
			$RdcEncrypt = ""
		}
		# XML Create Element - credentialsProfile
		$XmlWriter.WriteStartElement("credentialsProfile")
		$XmlWriter.WriteAttributeString("inherit", "None")
		
		# XML Create Element - profileName
		$XmlWriter.WriteStartElement("profileName")
		$XmlWriter.WriteAttributeString("scope","Local")
		$XmlWriter.WriteString($($DomainInfo.Name))
		
		# XML Close Element - profileName
		$XmlWriter.WriteEndElement()
		$XmlWriter.WriteElementString("userName",$Creds.Username)
		$XmlWriter.WriteElementString("password", $RdcEncrypt)
		$XmlWriter.WriteElementString("domain", $($DomainInfo.NetBIOSName))
		
		# Close Element - credentialsProfile
		$XmlWriter.WriteEndElement()
	}
		  
	# Close Element - credentialsProfiles
	$XmlWriter.WriteEndElement()

	# Specify Elements
	$RootElement = $AdForest.Name.ToUpper()

	# XML Create Element - properties
	$XmlWriter.WriteStartElement("properties")
	$XmlWriter.WriteElementString("expanded", "False")
	$XmlWriter.WriteElementString("name", $RootElement)
	$XmlWriter.WriteElementString("comment", "AD Forest Mode:  $($AdForest.ForestMode)")

	# Close Element - properties
	$XmlWriter.WriteEndElement()

	# Create Element - remoteDesktop
	$XmlWriter.WriteStartElement("remoteDesktop")
	$XmlWriter.WriteAttributeString("inherit", "None")
	$XmlWriter.WriteElementString("sameSizeAsClientArea","True")
	$XmlWriter.WriteElementString("fullScreen","False")
	$XmlWriter.WriteElementString("colorDepth","32")

	# Close Element - remoteDesktop
	$XmlWriter.WriteEndElement()

	# Create Element - localResources
	$XmlWriter.WriteStartElement("localResources")
	$XmlWriter.WriteAttributeString("inherit", "None")
	$XmlWriter.WriteElementString("audioRedirection","NoSound")
	$XmlWriter.WriteElementString("audioRedirectionQuality","Dynamic")
	$XmlWriter.WriteElementString("audioCaptureRedirection","DoNotRecord")
	$XmlWriter.WriteElementString("keyboardHook","FullScreenClient")
	$XmlWriter.WriteElementString("redirectClipboard","True")
	$XmlWriter.WriteElementString("redirectDrives","False")
	$XmlWriter.WriteElementString("redirectPrinters","False")
	$XmlWriter.WriteElementString("redirectPorts","False")
	$XmlWriter.WriteElementString("redirectSmartCards","False")
	$XmlWriter.WriteElementString("redirectPnpDevices","False")

	# Close Element - localResources
	$XmlWriter.WriteEndElement()

	# Create Server Connection
	Foreach ($AdDomain in $AdForest.Domains)
	{
		Write-Verbose -Message "Querying Active Directory computers."
		$ComputerList = Get-AdComputer -Filter {(OperatingSystem -like $Filter) -and (LastLogonDate -ge $LastLogonDate)} `
		-Properties ServicePrincipalNames, CanonicalName, DNSHostName, Name, IPv4Address, LastLogonDate, OperatingSystem, Description, ManagedBy `
		-Server $AdDomain | Sort CanonicalName, Name, ServicePrincipalNames
		$DomainInfo = Get-AdDomain $AdDomain
		
		# Create Element - group
		$XmlWriter.WriteStartElement("group")

		# Specify Child Element
		$ChildElement = $DomainInfo.DNSRoot.ToUpper()
		$ServerElement = " Servers"
		
		# Create Element - properties
		$XmlWriter.WriteStartElement("properties")
		$XmlWriter.WriteElementString("expanded", "False")
		$XmlWriter.WriteElementString("name", $ChildElement)
		$XmlWriter.WriteElementString("comment", "AD Domain Mode:  $($DomainInfo.DomainMode)")

		# Close Element - group
		$XmlWriter.WriteEndElement()
		
		# Create Element - logonCredentials
		$XmlWriter.WriteStartElement("logonCredentials")
		$XmlWriter.WriteAttributeString("inherit", "None")
		
		# Create Element - profileName
		$XmlWriter.WriteStartElement("profileName")
		$XmlWriter.WriteAttributeString("scope", "File")
		$XmlWriter.WriteString($($DomainInfo.Name))
		
		# Close Element - profileName
		$XmlWriter.WriteEndElement()
		
		# Close Element - logonCredentials
		$XmlWriter.WriteEndElement()
		
		# Create Element - group
		$XmlWriter.WriteStartElement("group")

		# Create Element - properties
		$XmlWriter.WriteStartElement("properties")
		$XmlWriter.WriteElementString("expanded", "False")
		$XmlWriter.WriteElementString("name", $ServerElement)  

		# Close Element - properties
		$XmlWriter.WriteEndElement()

		Write-Verbose -Message "Generating server connection list."		
		Foreach ($Computer in $ComputerList)
		{
			$Comment = @"
Name:`t`t$($Computer.Name.ToLower())
IP:`t`t$($Computer.IPv4Address)
OS:`t`t$($Computer.OperatingSystem)
Managed By:`t$($Computer.ManagedBy)
Description:`t$($Computer.Description)
"@
			$DisplayName = $Computer.Name.ToLower()
			$ServerName = $Computer.DNSHostName.ToLower()
			$ParentFolder = $Computer.CanonicalName
			
			# Mark server as a favorite
			If ($Favorites -ne $Null)
			{
				Foreach ($Item in $Favorites)
				{
					If ($Computer.Name -like $Item)
					{
						$MarkAsFavorite += "$RootElement\$ChildElement\$ServerElement\$DisplayName"
					}
				}
			}
			
			# Create Element - server
			$XmlWriter.WriteStartElement("server")
			If ($DomainControllerList -contains $ServerName)
			{
				$Comment += "`rADDC"
			}
			If (($Computer.ServicePrincipalNames -match "DNS").Count -gt 0)
			{
				$Comment += "`rDNS"
			}
			If (($Computer.ServicePrincipalNames -match "MSSQLSvc").Count -gt 0)
			{
				$Comment += "`rMSSQLSvc"
			}
			If (($Computer.ServicePrincipalNames -match "MSServerCluster").Count -gt 0)
			{
				$Comment += "`rMSServerCluster"
			}
			If (($Computer.ServicePrincipalNames -match "HTTP").Count -gt 0)
			{
				$Comment += "`rHTTP"
			}
			# Create Element - properties
			$XmlWriter.WriteStartElement("properties")
			$XmlWriter.WriteElementString("displayName", $DisplayName)
			$XmlWriter.WriteElementString("name", $ServerName)
			$XmlWriter.WriteElementString("comment", $Comment)
			
			# Close Element - properties
			$XmlWriter.WriteEndElement()
		
			# Close Element - server
			$XmlWriter.WriteEndElement()
		}
		
		# Close Element - group
		$XmlWriter.WriteEndElement()
		
		# Create Element - smartGroup
		$XmlWriter.WriteStartElement("smartGroup")

		# Create Element - properties
		$XmlWriter.WriteStartElement("properties")
		$XmlWriter.WriteElementString("expanded", "False")
		$XmlWriter.WriteElementString("name", "Domain Controllers")

		# Close Element - properties
		$XmlWriter.WriteEndElement()
		
		# Create Element - ruleGroup
		$XmlWriter.WriteStartElement("ruleGroup")
		$XmlWriter.WriteAttributeString("operator", "All")

		# Create Element - rule
		$XmlWriter.WriteStartElement("rule")
		$XmlWriter.WriteElementString("property", "Comment")
		$XmlWriter.WriteElementString("operator", "Matches")
		$XmlWriter.WriteElementString("value", "ADDC")
		
		# Close Element - rule
		$XmlWriter.WriteEndElement()
		
		# Close Element - ruleGroup
		$XmlWriter.WriteEndElement()
		  
		# Close Element - smartGroup
		$XmlWriter.WriteEndElement()

		# Create Element - smartGroup
		$XmlWriter.WriteStartElement("smartGroup")

		# Create Element - properties
		$XmlWriter.WriteStartElement("properties")
		$XmlWriter.WriteElementString("expanded", "False")
		$XmlWriter.WriteElementString("name", "SQL Servers")

		# Close Element - properties
		$XmlWriter.WriteEndElement()
		
		# Create Element - ruleGroup
		$XmlWriter.WriteStartElement("ruleGroup")
		$XmlWriter.WriteAttributeString("operator", "All")

		# Create Element - rule
		$XmlWriter.WriteStartElement("rule")
		$XmlWriter.WriteElementString("property", "Comment")
		$XmlWriter.WriteElementString("operator", "Matches")
		$XmlWriter.WriteElementString("value", "MSSQLSvc")
		
		# Close Element - rule
		$XmlWriter.WriteEndElement()
		
		# Close Element - ruleGroup
		$XmlWriter.WriteEndElement()
		  
		# Close Element - smartGroup
		$XmlWriter.WriteEndElement()

		# Create Element - smartGroup
		$XmlWriter.WriteStartElement("smartGroup")

		# Create Element - properties
		$XmlWriter.WriteStartElement("properties")
		$XmlWriter.WriteElementString("expanded", "False")
		$XmlWriter.WriteElementString("name", "DNS Servers")

		# Close Element - properties
		$XmlWriter.WriteEndElement()
		
		# Create Element - ruleGroup
		$XmlWriter.WriteStartElement("ruleGroup")
		$XmlWriter.WriteAttributeString("operator", "All")

		# Create Element - rule
		$XmlWriter.WriteStartElement("rule")
		$XmlWriter.WriteElementString("property", "Comment")
		$XmlWriter.WriteElementString("operator", "Matches")
		$XmlWriter.WriteElementString("value", "DNS")
		
		# Close Element - rule
		$XmlWriter.WriteEndElement()
		
		# Close Element - ruleGroup
		$XmlWriter.WriteEndElement()
		  
		# Close Element - smartGroup
		$XmlWriter.WriteEndElement()

		# Create Element - smartGroup
		$XmlWriter.WriteStartElement("smartGroup")

		# Create Element - properties
		$XmlWriter.WriteStartElement("properties")
		$XmlWriter.WriteElementString("expanded", "False")
		$XmlWriter.WriteElementString("name", "Clustered Servers")

		# Close Element - properties
		$XmlWriter.WriteEndElement()
		
		# Create Element - ruleGroup
		$XmlWriter.WriteStartElement("ruleGroup")
		$XmlWriter.WriteAttributeString("operator", "All")

		# Create Element - rule
		$XmlWriter.WriteStartElement("rule")
		$XmlWriter.WriteElementString("property", "Comment")
		$XmlWriter.WriteElementString("operator", "Matches")
		$XmlWriter.WriteElementString("value", "MSServerCluster")
		
		# Close Element - rule
		$XmlWriter.WriteEndElement()
		
		# Close Element - ruleGroup
		$XmlWriter.WriteEndElement()
		  
		# Close Element - smartGroup
		$XmlWriter.WriteEndElement()

		# Create Element - smartGroup
		$XmlWriter.WriteStartElement("smartGroup")

		# Create Element - properties
		$XmlWriter.WriteStartElement("properties")
		$XmlWriter.WriteElementString("expanded", "False")
		$XmlWriter.WriteElementString("name", "Web Servers")

		# Close Element - properties
		$XmlWriter.WriteEndElement()
		
		# Create Element - ruleGroup
		$XmlWriter.WriteStartElement("ruleGroup")
		$XmlWriter.WriteAttributeString("operator", "All")

		# Create Element - rule
		$XmlWriter.WriteStartElement("rule")
		$XmlWriter.WriteElementString("property", "Comment")
		$XmlWriter.WriteElementString("operator", "Matches")
		$XmlWriter.WriteElementString("value", "HTTP")
		
		# Close Element - rule
		$XmlWriter.WriteEndElement()
		
		# Close Element - ruleGroup
		$XmlWriter.WriteEndElement()
		  
		# Close Element - smartGroup
		$XmlWriter.WriteEndElement()
		
		# Close Element - group
		$XmlWriter.WriteEndElement()
	}

	# Close Element - file
	Write-Verbose -Message "Completed server connection list."
	$XmlWriter.WriteEndElement()
	  
	# Create Element - connected  
	$XmlWriter.WriteStartElement("connected")
	$XmlWriter.WriteEndElement()

	# Create Element - favorites 
	Write-Verbose -Message "Generating favorite list."
	$XmlWriter.WriteStartElement("favorites")
	If ($MarkAsFavorite -ne $Null)
	{
		Foreach ($Favorite in $MarkAsFavorite)
		{
			$XmlWriter.WriteElementString("server", $Favorite)
		}
	}
	
	# Close Element - favorites
	$XmlWriter.WriteEndElement()

	# Create Element - recentlyUsed 
	$XmlWriter.WriteStartElement("recentlyUsed")
	$XmlWriter.WriteEndElement()

	# Close Element - RDCMan
	$XmlWriter.WriteEndElement()

	# Save Xml
	$XmlWriter.WriteEndDocument()
	$XmlWriter.Flush()
	$XmlWriter.Close()
	Write-Verbose -Message "RDC Manager XML completed."
}
Catch
{
	Write-Warning -Message "Oops!"
	Write-Warning -Message "ScriptLine: $($_.InvocationInfo.ScriptLineNumber)"
	Write-Warning -Message $_.Exception.GetType().FullName
	Write-Warning -Message $_.Exception.Message
	$XmlWriter.Flush()
	$XmlWriter.Close()
	Clear-Variable XmlWriter
	$CleanUpTask = 1
}
Finally
{
	If ($RdcModule -ne $Null)
	{
		Write-Verbose -Message "Remove loaded modules."
		$RdcModule.Split(".") | Select -First 1 | Remove-Module -Force
	}
	
	If ($CleanUpTask -ne 1)
	{
		# Launch RDG File
		. $OutPath
	}
	Else
	{
		# Delete RDG File
		Remove-Item $OutPath -Force -Confirm:$False
		Write-Warning -Message "File $OutPath was not created succesfully."
	}	
}