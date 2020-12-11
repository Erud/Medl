$users=get-content c:\temp\LRusers.txt

Foreach($user in $users){
    
    $Dir = "\\medline.com\files\M197\Users\$user"+'$'
    
    if(-not (Test-Path "$Dir")){
        $acl = Get-Acl (New-Item -Path $Dir -ItemType Directory)
     
         # Make sure access rules inherited from parent folders.
        $acl.SetAccessRuleProtection($true, $false)
     
        $perm_user         = "$domain\$user","Modify", "ContainerInherit,ObjectInherit","None","Allow"
        $userpermissions   = New-Object System.Security.AccessControl.FileSystemAccessRule($perm_user)
        $acl = Get-acl -Path $Dir

        $acl.AddAccessRule($userpermissions)
        
        Set-ACL -Path "$Dir" -AclObject $acl
    } Else {
     $user
    }
}