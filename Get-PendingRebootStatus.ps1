Function Get-PendingRebootStatus {
	
	<#
.Synopsis
    This will check to see if a server or computer has a reboot pending.
    For updated help and examples refer to -Online version.
  
 
.DESCRIPTION
    This will check to see if a server or computer has a reboot pending.
    For updated help and examples refer to -Online version.
 
 
.NOTES  
    Name: Get-PendingRebootStatus
    Author: The Sysadmin Channel
    Version: 1.00
    DateCreated: 2018-Jun-6
    DateUpdated: 2018-Jun-6
 
.LINK
    https://thesysadminchannel.com/remotely-check-pending-reboot-status-powershell -
 
 
.PARAMETER ComputerName
    By default it will check the local computer.
 
     
    .EXAMPLE
    Get-PendingRebootStatus -ComputerName PAC-DC01, PAC-WIN1001
 
    Description:
    Check the computers PAC-DC01 and PAC-WIN1001 if there are any pending reboots.
 
#>
	
	[CmdletBinding()]
	Param (
	[Parameter(
	ValueFromPipeline=$true,
	ValueFromPipelineByPropertyName=$true,
	Position=0)]
	
	[string[]]     $ComputerName = $env:COMPUTERNAME,
	
	[switch]       $ShowErrors
	
	)
	
	
	BEGIN {
		$ErrorsArray = @()
	}
	
	PROCESS {
		foreach ($Computer in $ComputerName) {
			try {
				$PendingReboot = $false
				
				
				$HKLM = [UInt32] "0x80000002"
				$WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
				
				if ($WMI_Reg) {
					if (($WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")).sNames -contains 'RebootPending') {$PendingReboot = $true}
					if (($WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")).sNames -contains 'RebootRequired') {$PendingReboot = $true}
					
					#Checking for SCCM namespace
					$SCCM_Namespace = Get-WmiObject -Namespace ROOT\CCM\ClientSDK -List -ComputerName $Computer -ErrorAction Ignore
					if ($SCCM_Namespace) {
						if (([WmiClass]"\\$Computer\ROOT\CCM\ClientSDK:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending -eq 'True') {$PendingReboot = $true}   
					}
					
					
					if ($PendingReboot -eq $true) {
						$Properties = @{ComputerName   = $Computer.ToUpper()
							PendingReboot  = 'True'
						}
						$Object = New-Object -TypeName PSObject -Property $Properties | Select ComputerName, PendingReboot
					} else {
						$Properties = @{ComputerName   = $Computer.ToUpper()
							PendingReboot  = 'False'
						}
						$Object = New-Object -TypeName PSObject -Property $Properties | Select ComputerName, PendingReboot
					}
				}
				
			} catch {
				$Properties = @{ComputerName   = $Computer.ToUpper()
					PendingReboot  = 'Error'
				}
				$Object = New-Object -TypeName PSObject -Property $Properties | Select ComputerName, PendingReboot
				
				$ErrorMessage = $Computer + " Error: " + $_.Exception.Message
				$ErrorsArray += $ErrorMessage
				
			} finally {
				Write-Output $Object
				
				$Object         = $null
				$ErrorMessage   = $null
				$Properties     = $null
				$WMI_Reg        = $null
				$SCCM_Namespace = $null
			}
		}
		if ($ShowErrors) {
			Write-Output "`n"
			Write-Output $ErrorsArray
		}
	}
	
	END {}
}

$name = "ServPr"
$computers = get-content "c:\temp\$name.txt"
$nameOk = "C:\Temp\$name" + "OK.txt"

foreach ($comp in $computers) {
	#	$comp = $comp.Trim() + ".centurionmp.com"
	$comp = $comp.Trim()
	$comp
	$result = Get-PendingRebootStatus -ComputerName $comp
	
	Add-Content $nameOk "$($comp + " " + $result.PendingReboot)"
	
}

