Function Get-UpdatesRemE {
	[cmdletbinding()]
	Param (
	[parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
	[Alias('Name','__Server','IPAddress')]
	[string[]]$Computername=$env:COMPUTERNAME
	)
	Begin {$ErrorActionPreference='Stop'}
	Process {
		ForEach ($Computer in $Computername) {
			If  (Test-Connection -ComputerName  $Computer -Count  1 -Quiet) {
				$sDate = $null
				Try {
					$Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$computer))            
					$Searcher = $Session.CreateUpdateSearcher()            
					$HistoryCount = $Searcher.GetTotalHistoryCount()                      
					$Searcher.QueryHistory(0,$HistoryCount) | ForEach-Object -Process {
						$aDate = $_.Date
						if ($sDate -lt $aDate){
							$Result = $null            
							Switch ($_.ResultCode)            
							{            
								0 { $Result = 'NotStarted'}            
								1 { $Result = 'InProgress' }            
								2 { $Result = 'Succeeded' }            
								3 { $Result = 'SucceededWithErrors' }            
								4 { $Result = 'Failed' }            
								5 { $Result = 'Aborted' }            
								default { $Result = $_.ResultCode }            
							}      
							$oper = $null            
							Switch ($_.operation)            
							{                      
								1 { $oper = 'Installation' }            
								2 { $oper = 'Uninstallation' }            
								3 { $oper = 'Other' }                      
								default { $oper = $_.operation }            
							}      
							[pscustomobject]@{
								Computername = $Computer;
								LastUpDate   = $aDate;
								Operation    = $oper;				           
								Name         = $_.Title;            
								Status       = $Result	
							}
							$sDate = $aDate
						}
					}	
				} 
				Catch {
					#Write-Warning "$($Computer): $_"
					Add-Content C:\Temp\errorP.txt "`n$($Computer)`tW`t$_ "
				}
			}
			Else  {
				#Write-Error  "$($Computer): unable to reach remote system!"
				Add-Content C:\Temp\errorP.txt "`n$($Computer)`tE`tunable to reach remote system!"
			}
		}
	}
	End {$ErrorActionPreference='Continue'}
}

 Import-Csv C:\Temp\serversRemPatchK.csv | Get-UpdatesRemE | Export-Csv C:\Temp\remUpd.csv -NoTypeInformation

#Get-UpdatesRemE MUNDEVSLIMSAP1
