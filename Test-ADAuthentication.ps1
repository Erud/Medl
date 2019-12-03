Function Test-ADAuthentication {
    param($username,$password)
    (new-object directoryservices.directoryentry "",$username,$password).psbase.name -ne $null
}

Test-ADAuthentication "Medline-nt\svc_prd_shavlik" "mYv06*l)U&I$"