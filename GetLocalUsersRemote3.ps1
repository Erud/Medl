
$computers = get-content 'C:\temp\Exchange ServersE.txt'
$outpath = "c:\temp\Exchange ServersE.csv"
$outErrPath = "c:\temp\Exchange ServersError.txt"
if (Test-Path $outpath -PathType Leaf ) {
	Remove-Item -path $outpath
}
if (Test-Path $outErrPath -PathType Leaf ) {
	Remove-Item -path $outErrPath
}
#
$userflags_enum = @{
	"DISABLED"                               = "2";
	"HOMEDIR_REQUIRED"                       = "8";
	"LOCKOUT"                                = "16";
	"PASSWD_NOTREQD"                         = "32";
	"PASSWD_CANT_CHANGE"                     = "64";
	"ENCRYPTED_TEXT_PASSWORD_ALLOWED"        = "128";
	"TEMP_DUPLICATE_ACCOUNT"                 = "256";
	"NORMAL_ACCOUNT"                         = "512";
	"INTERDOMAIN_TRUST_ACCOUNT"              = "2048";
	"WORKSTATION_TRUST_ACCOUNT"              = "4096";
	"SERVER_TRUST_ACCOUNT"                   = "8192";
	"PASSWD_NEWER_EXPIRE"                    = "65536";
	"MNS_LOGON_ACCOUNT"                      = "131072";
	"SMARTCARD_REQUIRED"                     = "262144";
	"TRUSTED_FOR_DELEGATION"                 = "524288";
	"NOT_DELEGATED"                          = "1048576";
	"USE_DES_KEY_ONLY"                       = "2097152";
	"DONT_REQUIRE_PREAUTH"                   = "4194304";
	"EXPIRED"                                = "8388608";
	"TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION" = "16777216";
}

#
foreach ($comp in $computers) {
    $comp
	$aline = $null
	$aline =@()
	if ($comp.Length -gt 0) {
		if(Test-Connection -Cn $comp -BufferSize 16 -Count 1 -ErrorAction 0 -quiet){
			[ADSI]$S = "WinNT://$($comp)"
			$groups = $S.children.where({$_.class -eq 'group'}) 
			foreach ($groupO in $groups) {
				[ADSI]$group = "$($groupO.Parent)/$($groupO.Name),group"
				$members = $Group.psbase.Invoke("Members")
				$emt = $true
				$members | ForEach-Object {
					$path = ($_.GetType().InvokeMember("Adspath", 'GetProperty', $null, $_, $null)) -replace "WinNT://",""
					$apath = $path -split ("/",3)
					$mclass = $_.GetType().InvokeMember("Class", 'GetProperty', $null, $_, $null)
					if ($apath[1] -eq $comp) {
						$path = $apath[1] + "/" + $apath[2]
						if ($mclass -eq "User") {
							$Flags = $_.GetType().InvokeMember("userFlags", 'GetProperty', $null, $_, $null)
							$cflags = " " 
							$enumFlags = $userflags_enum.GetEnumerator()
							foreach ($enumFlag in $enumFlags) { 
								if ( $enumFlag.Value -band $Flags ) {
									if ($cflags -ne " ") { $cflags += ";" } 			
									$cflags += $enumFlag.name
								}
							}
						}
					} else {$cflags = ""}
					$line =[ordered] @{
						"Computer" = $comp
						"Group Name" =$group.name.value
						"Group Description" = $group.Description.value
						"Member Name" = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
						"Member Flags" = $cflags
						"Member Class" = $mclass
						"Member Path" = $path
					}
					$aline += New-Object -Property $line -TypeName PSObject
					$emt = $false
				}
				if ($emt){
					$line =[ordered] @{
						"Computer" = $comp
						"Group Name" =$group.name.value
						"Group Description" = $group.Description.value
						"Member Name" = ""
						"Member Flags" = ""
						"Member Class" = ""
						"Member Path" = ""
					}
					$aline += New-Object -Property $line -TypeName PSObject
				}
			}
			if ($aline.Count -gt "0") {
				$aline | select "Computer","Group Description","Group Name","Member Name","Member Flags","Member Class","Member Path" |
				Export-CSV -path $outpath –notypeinformation -Append
			} 
			else { 
				Out-File -FilePath $outErrPath -InputObject $comp -Append
			}
		}
		else {
			$comp += " No Ping" 
			Out-File -FilePath $outErrPath -InputObject $comp -Append
		}
	}
}