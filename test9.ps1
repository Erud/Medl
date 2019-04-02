$cflags = " "
$userflagsIN = @{
	"DISABLED" = "2";
	"HOMEDIR_REQUIRED" = "8";
	"LOCKOUT" = "16";
	"PASSWD_NOTREQD" = "32";
	"PASSWD_CANT_CHANGE" = "64";
	"ENCRYPTED_TEXT_PASSWORD_ALLOWED" = "128";
	"TEMP_DUPLICATE_ACCOUNT" = "256";
	"INTERDOMAIN_TRUST_ACCOUNT" = "2048";
	"WORKSTATION_TRUST_ACCOUNT" = "4096";
	"SERVER_TRUST_ACCOUNT" = "8192";
	"PASSWD_EXPIRED" = "65536";
	"MNS_LOGON_ACCOUNT" = "131072";
	"SMARTCARD_REQUIRED" = "262144";
	"TRUSTED_FOR_DELEGATION" = "524288";
	"NOT_DELEGATED" = "1048576";
	"USE_DES_KEY_ONLY" = "2097152";
	"DONT_REQUIRE_PREAUTH" = "4194304";
	"PASSWORD_EXPIRED" = "8388608";
	"TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION" = "16777216";
}
 $userflags = $userflagsIN.GetEnumerator()
foreach ($uFlag in $userflags) { 
	if ( $uFlag.Value -band $Flags ) {
		if ($cflags -ne " ") { $cflags += ";" } 			
		$cflags += $uFlag.name
	}
} 
$cflags