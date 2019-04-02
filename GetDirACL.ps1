$path = "C:\Backup"
dir $path -Recurse:$recurse | ? {$_.PSIsContainer} | % {
   $folderName = $_.FullName
 
   try
   {
      $acl = Get-Acl $folderName -ErrorAction SilentlyContinue
 
      $acl.Access | % {
         if (($checkType -eq "") -or ($checkType -eq $_.IdentityReference))
         {
            "'$folderName' has $($_.IdentityReference) access at level: $($_.FileSystemRights)"
         }
      }
   }
   catch
   {
   }
}