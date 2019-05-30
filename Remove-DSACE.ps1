# -----------------------------------------------------------------------------
# Remove-DSACE.ps1
# Written by Bill Stewart (bstewart@iname.com)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Version history:
#
# 1.0 (2013-11-15)
# * Initial version.
#
# This is a PowerShell script replacement for dsrevoke.exe:
# http://www.microsoft.com/en-us/download/details.aspx?id=19288
#
# Why write a replacement?
# 1) Dsrevoke.exe can't handle more than 1000 containers in a tree, and
# 2) Dsrevoke.exe can't handle a "/" in container names.
# See http://support.microsoft.com/kb/927068 for details.
#
# Why not just use dsacls.exe then?
# 1) Dsacls.exe can't recurse into sub-containers.
# 2) Dsacls.exe output is a lot of text that is hard to parse for reporting.
#
# Basically, this script works as an "undo" for the "Delegation of Control"
# wizard in Active Directory Users and Computers.
#
# Terminology:
#
# * Trustee - A user or group that can be granted permissions over a securable
#   resource (such as an OU).
#
# * ACL - Access Control List. Describes what access trustees have over a
#   securable resource.
#
# * ACE - Access Control Entry. A specific entry in an ACL. An ACE specifies
#   what specific access each trustee has over the resource. (An ACL is a list
#   of ACEs.)
#
# * Non-inherited - The ACE was applied directly to the object (i.e., the ACE
#   was not inherited from the object's parent).
#
# Notes:
#
# * When you use the -Remove parameter, THIS SCRIPT REMOVES PERMISSIONS FROM
#   CONTAINER(S) IN YOUR ACTIVE DIRECTORY. THE SCRIPT'S AUTHOR IS NOT
#   RESPONSIBLE IF YOU BREAK YOUR DOMAIN OR IMPEDE YOUR BUSINESS.
#
# * This script only supports 'container' and 'organizationalUnit' objects. The
#   -Path parameter doesn't support reporting or removing ACEs from an entire
#   domain.
#
# * This script doesn't attempt to output the content of ACEs; instead it
#   just gives you a count. If you want to view AD ACLs, I recommend using
#   a GUI like ADUC or LIZA (http://www.ldapexplorer.com/en/liza.htm).
#
# * Alternate credentials are supported with -Credential parameter.
#
# * You can connect to a specific domain controller with the -ServerName
#   parameter.
#
# * If using -Report, the script outputs objects with these properties:
#     Path - The distinguished name of the container
#     Trustee - The trustee named in the ACE
#     ACEs - The number of ACEs containing the trustee
#
# * The -Remove parameter uses the .NET PurgeAccessRules method to remove all
#   non-inherited ACEs from a container's ACL that contain a trustee.
#
# * The -Recurse parameter causes the script to recurse into sub-containers of
#   the specified container(s).
#
# * You can pipe container names to the script.
#
# * You can specify multiple trustee names.
#
# * The -Report parameter is assumed unless you explicitly specify -Remove.
#   This is a safety precaution.
#
# * Confirm impact is "High" when using -Remove. This means the script will
#   always prompt before attempting to remove ACEs from a container (and its
#   sub-containerss, if you use -Recurse). You can use -Confirm:$FALSE on the
#   script's command line to bypass the prompt (be careful!).
# -----------------------------------------------------------------------------

#requires -version 2

<#
.SYNOPSIS
Reports on or removes non-inherited access control entries (ACEs) on Active Directory containers that contain specific security princpials.

.DESCRIPTION
Reports on or removes non-inherited access control entries (ACEs) on Active Directory containers that contain specific security principals. Functionally equivalent to the Dsrevoke.exe utility.

.PARAMETER Report
Outputs the names of containers and the number of non-inherited ACEs containing the trustee(s) specified by the -Trustee parameter. This is the default parameter.

.PARAMETER Remove
Removes all non-inherited ACEs containing the trustee(s) specified by the -Trustee parameter from the container(s) specified by the -Path parameter.

.PARAMETER Path
Specifies distinguished names of one or more Active Directory containers. You can specify multiple containers, but wildcards are not allowed.

.PARAMETER Trustee
Specifies security principals (user or group names). You can specify multiple trustees, but wildcards are not allowed. You can specify a trustee as an NT4 name (DOMAIN\name), a distinguished name, or a canonical name.

.PARAMETER ServerName
Specifies the name of a domain controller to connect to. The default is to connect to the closest domain controller in the current domain.

.PARAMETER Recurse
Specifies whether to recurse into sub-containers of the specified container(s).

.PARAMETER Credential
Specifies credentials.

.OUTPUTS
PSObjects with the following properties:
Path - The container's distinguished name
Trustee  - The trustee name, in 'DOMAIN\name' format
ACEs - The number of non-inherited ACEs in the container's ACL
Result - The word "Removed" or an error message*
*This property only exists when using the -Remove parameter.

.EXAMPLE
PS C:\> Remove-DSACE -Report -Path "OU=Accounting,DC=fabrikam,DC=com" -Trustee "FABRIKAM\Old Group" -Recurse
Outputs OUs with non-inherited ACEs containing 'FABRIKAM\Old Group' starting at 'OU=Accounting,DC=fabrikam,DC=com', including all sub-containers.

.EXAMPLE
PS C:\> Get-Content OUs.txt | Remove-DSACE -Report -Trustee "FABRIKAM\Accountants"
Outputs OUs with non-inherited ACEs containing 'FABRIKAM\Accountants' from the OUs named in the file OUs.txt.

.EXAMPLE
PS C:\> Remove-DSACE -Remove -Path "OU=Disabled,DC=fabrikam,DC=com" -Trustee "FABRIKAM\Help Desk" -Credential (Get-Credential) -Recurse
Removes all non-inherited ACEs containing 'FABRIKAM\Help Desk' from the specified OU and all sub-containers using the specified credentials.

.EXAMPLE
PS C:\> Remove-DSACE -Remove -Path "OU=HR,DC=fabrikam,DC=com" -Trustee "FABRIKAM\Old"
Removes all non-inherited ACEs containing 'FABRIKAM\Old' from the specified OU.

.EXAMPLE
PS C:\> Remove-DSACE -Remove -Path "OU=HR,DC=fabrikam,DC=com" -Trustee "CN=Old,OU=Groups,DC=fabrikam,DC=com"
Same as previous example, except trustee specified as a distinguished name.

.EXAMPLE
PS C:\> Remove-DSACE -Remove -Path "OU=HR,DC=fabrikam,DC=com" -Trustee "fabrikam.com/Groups/Old"
Same as previous example, except trustee specified as a canonical name.
#>

[CmdletBinding(DefaultParameterSetName="Report",ConfirmImpact="High",SupportsShouldProcess=$TRUE)]
param(
[parameter(ParameterSetName="Report")]
[Switch] $Report,
[parameter(ParameterSetName="Remove")]
[Switch] $Remove,
[parameter(ParameterSetName="Report",Position=0,ValueFromPipeline=$TRUE)]
[parameter(ParameterSetName="Remove",Position=0,ValueFromPipeline=$TRUE)]
[String[]] $Path,
[parameter(ParameterSetName="Report",Position=1,Mandatory=$TRUE)]
[parameter(ParameterSetName="Remove",Position=1,Mandatory=$TRUE)]
[String[]] $Trustee,
[parameter(ParameterSetName="Report")]
[parameter(ParameterSetName="Remove")]
[String] $ServerName,
[parameter(ParameterSetName="Report")]
[parameter(ParameterSetName="Remove")]
[System.Management.Automation.PSCredential] $Credential,
[parameter(ParameterSetName="Report")]
[parameter(ParameterSetName="Remove")]
[Switch] $Recurse
)

begin {
	$ScriptName = "Remove-DSACE.ps1"
	$ParamSetName = $PSCmdlet.ParameterSetName
	$PipelineInput = -not $PSBoundParameters.ContainsKey("Path")
	
	# ---------------------------------------------------------------------------
	# "Immediate if" - executes $testExpression; if result is $TRUE, then
	# execute $trueExpression; otherwise, execute $falseExpression.
	# ---------------------------------------------------------------------------
	function iif {
		param(
		[ScriptBlock] $testExpression,
		[ScriptBlock] $trueExpression,
		[ScriptBlock] $falseExpression
		)
		if ( & $testExpression ) { & $trueExpression } else { & $falseExpression }
	}
	
	# ---------------------------------------------------------------------------
	# Invokes methods for the NameTranslate and Pathname COM objects.
	# ---------------------------------------------------------------------------
	function Invoke-Method {
		param(
		[__ComObject] $object,
		[String] $method,
		$parameters
		)
		$output = $object.GetType().InvokeMember($method, "InvokeMethod", $NULL, $object, $parameters)
		if ( $output ) { $output }
	}
	
	# ---------------------------------------------------------------------------
	# Sets a property for the Pathname COM object.
	# ---------------------------------------------------------------------------
	function Set-Property {
		param(
		[__ComObject] $object,
		[String] $property,
		$parameters
		)
		[Void] $object.GetType().InvokeMember($property, "SetProperty", $NULL, $object, $parameters)
		if ( $output ) { $output }
	}
	
	# ---------------------------------------------------------------------------
	# BEGIN: NameTranslate object and functions
	# ---------------------------------------------------------------------------
	$ADS_NAME_TYPE_UNKNOWN = 8
	$ADS_NAME_TYPE_NT4 = 3
	$NameTranslate = new-object -comobject NameTranslate
	
	# ---------------------------------------------------------------------------
	# Initialize the NameTranslate object, using credentials if supplied. If
	# initialization fails, write an error and terminate the script.
	# ---------------------------------------------------------------------------
	function Initialize-NameTranslate {
		param(
		[System.Management.Automation.PSCredential] $credential,
		[String] $serverName
		)
		$ADS_NAME_INITTYPE_SERVER = 2
		$ADS_NAME_INITTYPE_GC = 3
		$initType = iif { $serverName } { $ADS_NAME_INITTYPE_SERVER } { $ADS_NAME_INITTYPE_GC }
		try {
			if ( $credential ) {
				$networkCredential = $credential.GetNetworkCredential()
				Invoke-Method $NameTranslate "InitEx" ($initType,$serverName,$networkCredential.UserName,$networkCredential.Domain,$networkCredential.Password)
			}
			else {
				Invoke-Method $NameTranslate "Init" ($initType,$serverName)
			}
		}
		catch [System.Management.Automation.MethodInvocationException] {
			write-error $_.Exception.InnerException.Message
			exit
		}
	}
	Initialize-NameTranslate $Credential $serverName
	
	# ---------------------------------------------------------------------------
	# Collect list of verified trustee names that we can translate to NT4 name
	# format (i.e., 'DOMAIN\name'). If unable to translate any of them, write an
	# error and exit the script.
	# ---------------------------------------------------------------------------
	function Test-Trustee {
		param(
		[String] $trustee
		)
		try {
			Invoke-Method $NameTranslate "Set" ($ADS_NAME_TYPE_UNKNOWN,$trustee)
			Invoke-Method $NameTranslate "Get" $ADS_$ADS_NAME_TYPE_NT4
		}
		catch [System.Management.Automation.MethodInvocationException] {
			write-error "Trustee '$trustee' not found." -category ObjectNotFound
			exit
		}
	}
	$VerifiedTrustee = $Trustee | foreach-object { Test-Trustee $_ }
	# ---------------------------------------------------------------------------
	# END: NameTranslate object and functions
	# ---------------------------------------------------------------------------
	
	# ---------------------------------------------------------------------------
	# BEGIN: Pathname object and functions
	# ---------------------------------------------------------------------------
	$ADS_ESCAPEDMODE_ON = 2
	$ADS_SETTYPE_DN = 4
	$ADS_FORMAT_X500_DN = 7
	$Pathname = new-object -comobject "Pathname"
	
	# Enable EscapedMode for Pathname object.
	Set-Property $Pathname "EscapedMode" $ADS_ESCAPEDMODE_ON
	
	# ---------------------------------------------------------------------------
	# Returns the specified distinguished name as a properly-escaped name; e.g.,
	# the distinguished name "OU=Test/Name,DC=fabrikam,DC=com" is returned as
	# "OU=Test\/Name,DC=fabrikam,DC=com".
	# ---------------------------------------------------------------------------
	function Get-EscapedPath {
		param(
		[String] $distinguishedName
		)
		Invoke-Method $Pathname "Set" ($distinguishedName,$ADS_SETTYPE_DN)
		Invoke-Method $Pathname "Retrieve" $ADS_FORMAT_X500_DN
	}
	# ---------------------------------------------------------------------------
	# END: Pathname object and functions
	# ---------------------------------------------------------------------------
	
	# ---------------------------------------------------------------------------
	# Returns the class of a directory service object.
	# ---------------------------------------------------------------------------
	function Get-ObjectClass {
		param(
		[System.DirectoryServices.DirectoryEntry] $object
		)
		$object.objectClass.Value[$object.objectClass.Count - 1]
	}
	# ---------------------------------------------------------------------------
	
	# ---------------------------------------------------------------------------
	# Searches for OUs starting at the specified location. Returns a
	# SearchResultCollection object. In case of an error, writes to the error
	# stream and returns nothing.
	# ---------------------------------------------------------------------------
	function Search-Container {
		param(
		[String] $path,
		[String] $serverName,
		[System.Management.Automation.PSCredential] $credential,
		[Switch] $recurse
		)
		$bindPrefix = iif { $serverName } { "LDAP://$servername/" } { "LDAP://" }
		$objectPath = "{0}{1}" -f $bindPrefix,(Get-EscapedPath $path)
		if ( $credential ) {
			$networkCredential = $credential.GetNetworkCredential()
			$rootEntry = new-object System.DirectoryServices.DirectoryEntry($objectPath,
			$networkCredential.UserName,$networkCredential.Password)
		}
		else {
			$rootEntry = [ADSI] $objectPath
		}
		try {
			[Void] $rootEntry.Get("distinguishedName")
		}
		catch {
			$errorMessage = $_.Exception.InnerException.Message
			write-error ("Unable to connect to '$objectPath' because of the " +
			"following error: '$errorMessage'")
			return
		}
		$validClasses = @("container","organizationalUnit","domainDNS")
		$objectClass = Get-ObjectClass $rootEntry
		if ( $validClasses -notcontains $objectClass ) {
			$classList = ($validClasses | foreach-object { "'$_'" }) -join ","
			write-error ("The objectClass attribute of directory service object " +
			"'$objectPath' is '$objectClass'. Only the following object classes " +
			"are supported: $classList") -category InvalidType
			return
		}
		$searcher = [ADSISearcher] $rootEntry
		$searcher.Filter = "(|{0})" -f
		(($validClasses | foreach-object { "(objectClass=$_)" }) -join "")
		$searcher.PageSize = 1000
		$searcher.SearchScope = iif { $recurse } { "Subtree" } { "Base" }
		$searcher.FindAll()
	}
	
	# ---------------------------------------------------------------------------
	# Tries to remove all access rules for specified trustee from a directory
	# entry and commit the changes. Returns "Removed" if succeeded, or an error
	# message if it failed.
	# ---------------------------------------------------------------------------
	function Remove-AccessRule {
		param(
		[System.DirectoryServices.DirectoryEntry] $dirEntry,
		[String] $trusteeName
		)
		$ntAccount = [System.Security.Principal.NTAccount] $trusteeName
		try {
			$dirEntry.ObjectSecurity.PurgeAccessRules($ntAccount)
			$dirEntry.CommitChanges()
			"Removed"
		}
		catch {
			if ( $_.Exception.InnerException.ExtendedError ) {
				"Error 0x{0:X8}" -f $_.Exception.InnerException.ExtendedError
			}
			else {
				"{0}" -f $_.Exception.Message
			}
		}
	}
	
	# ---------------------------------------------------------------------------
	# Main function. The script calls this function for each container.
	# ---------------------------------------------------------------------------
	function Main {
		param(
		[String] $path,
		[String[]] $trustee,
		[String] $serverName,
		[String] [ValidateSet("Report","Remove")] $action,
		[System.Management.Automation.PSCredential] $credential,
		[Switch] $recurse
		)
		# Search for containers. If none found, return.
		write-progress $ScriptName "Searching for containers in '$path'"
		$searchResults = Search-Container `
      -path $path `
      -serverName $serverName `
      -credential $credential `
      -recurse:$recurse
		if ( -not $searchResults ) { return }
		$containerCount = ($searchResults | measure-object).Count
		# $counter and $progressVerb are for write-progress.
		$counter = 0
		$progressVerb = iif { $action -eq "Remove" } { "Removing" } { "Searching for" }
		foreach ( $searchResult in $searchResults ) {
			$containerDN = $searchResult.Properties["distinguishedname"][0]
			$dirEntry = $searchResult.GetDirectoryEntry()
			$counter++
			foreach ( $trusteeName in $trustee ) {
				# Count explicit, non-inherited ACEs containing trustee.
				$aceCount = ($dirEntry.ObjectSecurity.GetAccessRules($TRUE,$FALSE,
				[System.Security.Principal.NTAccount]) | where-object {
					$_.IdentityReference.Value -eq $trusteeName } |
				measure-object).Count
				if ( $aceCount -gt 0 ) {
					if ( $action -eq "Remove" ) {
						if ( $PSCmdlet.ShouldProcess($containerDN,
						"Remove non-inherited access control entries for '$trusteeName'") ) {
							$result = Remove-AccessRule $dirEntry $trusteeName
							"" | select-object @{Name="Path"; Expression={$containerDN}},
							@{Name="Trustee"; Expression={$trusteeName}},
							@{Name="ACEs"; Expression={$aceCount}},
							@{Name="Result"; Expression={$result}}
						}
					}
					else {
						"" | select-object @{Name="Path"; Expression={$containerDN}},
						@{Name="Trustee"; Expression={$trusteeName}},
						@{Name="ACEs"; Expression={$aceCount}}
					}
				}
				$percent = ($counter / $containerCount) * 100 -as [Int]
				write-progress `
          -activity $ScriptName `
          -status "$progressVerb non-inherited access control entries for '$trusteeName'" `
          -currentoperation ("[{0:N0}/{1:N0}] {2}" -f $counter,$containerCount,$containerDN) `
          -percentcomplete $percent `
          -completed:($percent -eq 100)
			}
		}
	}
}

process {
	if ( $PipelineInput ) {
		if ( $_ ) {
			Main `
        -path $_ `
        -trustee $VerifiedTrustee `
        -serverName $ServerName `
        -action $ParamSetName `
        -credential $Credential `
        -recurse:$Recurse
		}
		else {
			write-error ("You must provide pipeline input or specify the -Path " +
			"parameter.") -category SyntaxError
		}
	}
	else {
		$Path | foreach-object {
			Main `
        -path $_ `
        -trustee $VerifiedTrustee `
        -serverName $ServerName `
        -action $ParamSetName `
        -credential $Credential `
        -recurse:$Recurse
		}
	}
}