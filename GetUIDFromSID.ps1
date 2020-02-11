$objSID = New-Object System.Security.Principal.SecurityIdentifier ("S-1-5-21-414468895-1955670742-9522986-203047") 
$objUser = $objSID.Translate( [System.Security.Principal.NTAccount]) 
$objUser.Value