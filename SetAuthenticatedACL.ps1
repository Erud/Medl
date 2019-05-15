$ComputerList = @(
    'Computer1'
    'Computer2'
)

$ExclusionList = 'ADMIN\$','IPC\$' -join '|'

$ScriptBlock = {

    $ShareList = Get-CimInstance -ClassName Win32_Share |
            Where-Object -FilterScript {
                #keeps only object from the FileSystem
                $PSItem.Path -notmatch '^\w:\\$' -and
                #excludes administrative shares like C$
                $PSItem.Path -match '^\w:\\\.*' -and
                #excludes a custom list
                $PSItem.Name -notmatch $using:ExclusionList
            }
    
    foreach ($Share in $ShareList) {
        
        $Filter = "name='{0}'" -f $Share.Name
        $SecuritySettings = Get-WmiObject -Class Win32_LogicalShareSecuritySetting -Filter $Filter
        $Descriptor = $SecuritySettings.GetSecurityDescriptor().descriptor
        $CurrentDacl = $Descriptor.dacl       

        [System.Management.ManagementBaseObject[]]$NewDacl = $CurrentDacl.Where({$_.Trustee.Name -ne 'Everyone'})

        $ComputerName = $env:COMPUTERNAME

        #AccessPermissions
        $accessFlags = @{
            FullControl = 2032127
            Change = 1245631
            Read = 1179817
        }
        
        #Build the Trustee objects
        $Trustee = ([wmiclass] "\\$ComputerName\root\cimv2:Win32_Trustee").CreateInstance()
        $Trustee.Name = 'Authenticated Users'
        $Trustee.Domain = ''
        
        # Build the Access Control Entry object
        $Ace = ([wmiclass] "\\$ComputerName\root\cimv2:Win32_ACE").CreateInstance()
        $Ace.AccessMask = $accessFlags['Read']
        $Ace.AceFlags = 3 # ContainerInherit + ObjectInherit
        $Ace.AceType = 0 # 0 Allow, 1 = Deny
        $Ace.Trustee = $Trustee
        
        [array]::Resize([ref]$NewDacl, $NewDacl.Count + 1)
        $NewDacl[$NewDacl.Count-1] = $Ace
        
        $Descriptor.dacl = $NewDacl
        $SecuritySettings.SetSecurityDescriptor($Descriptor)
    }
}

Invoke-Command -ComputerName $ComputerList -ScriptBlock $ScriptBlock