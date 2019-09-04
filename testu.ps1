

$managers = Get-ADUser -Filter { emailaddress -Like "RCurran@medline.com"} -Properties manager
foreach($manager in $managers){
    if(($manager.Manager -ne "") -and ($manager.Manager) ) {
    Get-ADUser $manager.Manager
    }
} 