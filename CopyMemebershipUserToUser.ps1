$CopyFromUser = Get-ADUser pa-eschilling -prop MemberOf
$CopyToUser = Get-ADUser pa-umalik -prop MemberOf
$CopyFromUser.MemberOf | Where{$CopyToUser.MemberOf -notcontains $_} |  Add-ADGroupMember -Members $CopyToUser