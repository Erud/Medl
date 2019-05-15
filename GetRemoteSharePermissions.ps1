$ACLs = @()
Get-Content C:\Temp\servers2.txt |
%{ 
	$_ 
	if(Test-Connection -Cn $_ -BufferSize 16 -Count 1 -ErrorAction 0 -quiet){
		Try {
			$sessionD = New-CimSession -ComputerName $_ -ErrorAction Stop
			$shares = Get-SmbShare -CimSession $sessionD -Special $false
			foreach ($share in $shares) {
				if ($share.Name -notmatch 'ADMIN\$|IPC\$') { 
					$shareACLs = Get-SmbShareAccess -Name $share.Name -CimSession $sessionD -ErrorAction Stop
					foreach ($ACL in $shareACLs) {
						$shareACL = New-Object PSObject -Property @{
							ComputerName = $ACL.PSComputerName
							Name = $ACL.Name
							Path = $share.Path
							AccountName = $ACL.AccountName
							AccessControlType = $ACL.AccessControlType
							AccessRight = $ACL.AccessRight
						}
						$ACLs += $shareACL
					}
				}
			}
			Remove-CimSession -CimSession $sessionD
		}
		Catch {
			Write-Host "$($_): Error CIM connecting" -ForegroundColor red
			Remove-CimSession -CimSession $sessionD -ErrorAction Ignore
		}
	} 	else { Write-Host "$($_): Offline" -ForegroundColor red }
}
$ACLs | Export-Csv C:\Temp\SharesACL.csv -NoTypeInformation