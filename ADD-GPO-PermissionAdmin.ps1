$AllGPOs = Get-GPO -All
$Admin = "RG-Administrators-GroupPolicy"
foreach ($GPO in $AllGPOs)
{
	Set-GPPermissions -Name $GPO.displayname.ToString() -TargetName $Admin -TargetType Group -PermissionLevel GpoEditDeleteModifySecurity -Replace
}
#Get-GPPermission -Name "Google" -All
#Set-GPPermissions -Name "Google" -TargetName "RG-GroupPolicy-Administrators" -TargetType Group -PermissionLevel GpoEditDeleteModifySecurity -Replace

#Set-GPPermissions -All -TargetName "RG-GroupPolicy-Administrators" -TargetType Group -PermissionLevel GpoEditDeleteModifySecurity -Replace

#break
#Get-GPO -All | ForEach-Object { if($_ | Get-GPPermission -TargetName "Marketing Admins" -TargetType Group -ErrorAction SilentlyContinue) {$_ | 
#Set-GPPermission -Replace -PermissionLevel GpoApply -TargetName "Marketing Admins" -TargetType Group }}