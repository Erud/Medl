<#
.Synopsis
   Quick way to dump OU structure to the text format
.DESCRIPTION
   This cmdlet is dumping OU structure to the text format. I'm using recurse function to create tree structure.
.EXAMPLE
   Get-OUStructure -RootOU "dc=company,dc=local"
#>
function Get-OUStructure
{
    [CmdletBinding()]
    Param
    (
        # LDAP path to OU where you wish to start
        [Parameter(Mandatory=$true,
                   Position=0)]
        $RootOU
    )

    Begin
    {
        try
        {
            Import-Module ActiveDirectory
        }
        catch
        {
        }
    }
    Process
    {
        $i = 0
        function getOuRec($baseou)
        {
            $i++
            $ous = Get-ADOrganizationalUnit -Filter * -SearchScope OneLevel -SearchBase $baseou
            foreach ($o in $ous)
            {
                if ((Get-ADOrganizationalUnit -Filter * -SearchScope OneLevel -SearchBase $o|measure|select -ExpandProperty count) -gt 0)
                {
                     $line  = ("`t" * $i) + '-' + $o.name
                     Write-Host $line
                     getourec($o)
                }
                else
                {
                    $line  = ("`t" * $i) + '-' + $o.name
                     Write-Host $line
                }
            }
        }
        getourec($rootou)
    }
    End
    {
    }
}


