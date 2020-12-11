Function Test-VPNConnection
{
<#
.SYNOPSIS
    Check to see if there is an active VPN connection.
    
.DESCRIPTION
    Check to see if there is an active VPN connection by using the Win32_NetworkAdapter and the
     Win32_NetworkAdapterConfiguration WMI classes.
    
.PARAMETER NotMatchAdapterDescription
    Excludes on the network adapter description field using regex matching. Precedence order: 0.
    Following WAN Miniport adapters are used for Microsoft Remote Access based VPN
     so are not excluded by default: L2TP, SSTP, IKEv2, PPTP
    
.PARAMETER LikeAdapterDescription
    Matches on the network adapter description field using wild card matching. Precedence order: 1.
    
.PARAMETER LikeAdapterDNSDomain
    Matches on the network adapter DNS Domain field using wild card matching. Precedence order: 2.
    
.PARAMETER LikeAdapterDHCPServer
    Matches on the network adapter DHCP Server field using wild card matching. Precedence order: 3.
    
.PARAMETER LikeAdapterDefaultGateway
    Matches on the network adapter Default Gateway field using wild card matching. Precedence order: 4.
    
.PARAMETER DisplayNetworkAdapterTable
    Logs the full list of network adapters and also the filterd list of possible VPN connection
     network adapters.
    
.EXAMPLE
    Test-VPNConnection
    
.NOTES
    $AllNetworkAdapterConfigTable contains all criteria for detecting VPN connections.
    Try to choose criteria that:
      1) Uniquely identifies the network(s) of interest.
      2) Try not to rely on networking data that may change in future. For example, default gateways
         and DNS and DHCP addresses may change over time or there may be too many to match on.
         Try to use wildcard or regular expression matches if there is an available pattern
         to match multiple values on.
.LINK
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
        [string[]]$NotMatchAdapterDescription = ('^WAN Miniport \(PPPOE\)','^WAN Miniport \(IPv6\)','^WAN Miniport \(Network Monitor\)',
                                                 '^WAN Miniport \(IP\)','^Microsoft 6to4 Adapter','^Microsoft Virtual WiFi Miniport Adapter',
                                                 '^Microsoft WiFi Direct Virtual Adapter','^Microsoft ISATAP Adapter','^Direct Parallel',
                                                 '^Microsoft Kernel Debug Network Adapter','^Microsoft Teredo','^Packet Scheduler Miniport',
                                                 '^VMware Virtual','^vmxnet','VirtualBox','^Bluetooth Device','^RAS Async Adapter','USB'),
        
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
        [string[]]$LikeAdapterDescription = ('*vpn*','*juniper*','*check point*','*cisco anyconnect*'),
        
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
        [string[]]$LikeAdapterDNSDomain = ('*.*'),
        
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
        [string[]]$LikeAdapterDHCPServer,
        
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
        [string[]]$LikeAdapterDefaultGateway,
        
        [Parameter(Mandatory=$false)]
        [switch]$DisplayNetworkAdapterTable = $false
    )
    
    Begin
    {
        [scriptblock]$AdapterDescriptionFilter = {
            [CmdletBinding()]
            Param
            (
                [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
                $sbInputObject,
                
                [Parameter(Mandatory=$true,Position=1)]
                [string[]]$sbNotMatchAdapterDescription
            )
            
            $SendToPipeline = $true
            ForEach ($sbNotMatchDesc in $sbNotMatchAdapterDescription)
            {
                If ($sbInputObject.Description -imatch $sbNotMatchDesc)
                {
                    $SendToPipeline = $false
                    Break
                }
            }
            
            If ($SendToPipeline)
            {
                Write-Output $sbInputObject
            }
        }
    }
    Process
    {
        Try
        {
            [psobject[]]$AllNetworkAdapter           = Get-WmiObject Win32_NetworkAdapter -ErrorAction 'Stop' |
                                                       Select-Object -Property DeviceID, PNPDeviceID, Manufacturer
            
            [psobject[]]$AllNetworkAdapterConfigTemp = Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction 'Stop' |
                                                       Select-Object -Property @{L='DeviceID'; E={$_.Index}}, DNSDomain, DefaultIPGateway, DHCPServer, IPEnabled, PhysicalAdapter, Manufacturer, Description
            
            ForEach ($AdapterConfig in $AllNetworkAdapterConfigTemp)
            {
                ForEach ($Adapter in $AllNetworkAdapter)
                {
                    If ($AdapterConfig.DeviceID -eq $Adapter.DeviceID)
                    {
                        ## Note: We create our own custom PhysicalAdapter property b/c the one in the
                        ##       Win32_NetworkAdapter class is not accurate.
                        $AdapterConfig.PhysicalAdapter        = [boolean]($Adapter.PNPDeviceID -imatch '^PCI\\')
                        $AdapterConfig.Manufacturer           = $Adapter.Manufacturer
                        [psobject[]]$AllNetworkAdapterConfig += $AdapterConfig
                    }
                }
            }
            
            ## This table contains the major markers that might help user create the criteria for detecting VPN connections.
            [string]$AllNetworkAdapterConfigTable   = $AllNetworkAdapterConfig |
                                                      Format-Table DNSDomain, DefaultIPGateway, DHCPServer, IPEnabled, PhysicalAdapter, Manufacturer, Description -AutoSize -Wrap | Out-String
            
            ## Sanitize list of Network Adapters by removing:
            ##  a) physical adapters
            ##  b) adapters which we know are not VPN connections
            [psobject[]]$NetworkAdapterConfig       = $AllNetworkAdapterConfig |
                                                      Where-Object   { -not ($_.PhysicalAdapter) } |
                                                      ForEach-Object {
                                                                        &$AdapterDescriptionFilter -sbInputObject $_ -sbNotMatchAdapterDescription $NotMatchAdapterDescription
                                                                     }
            [string]$NetworkAdapterConfigTable      = $NetworkAdapterConfig |
                                                      Format-Table DNSDomain, DefaultIPGateway, DHCPServer, IPEnabled, PhysicalAdapter, Manufacturer, Description -AutoSize -Wrap | Out-String
            
            ## Sanitize list of Network Adapters by removing:
            ##  a) adapters which are not connected (IP Enabled)
            $NetworkAdapterConfig = $NetworkAdapterConfig | Where-Object { $_.IpEnabled }
            [string]$IpEnabledNetworkAdapterConfigTable = $NetworkAdapterConfig |
                                                          Format-Table DNSDomain, DefaultIPGateway, DHCPServer, IPEnabled, PhysicalAdapter, Manufacturer, Description -AutoSize -Wrap | Out-String
            
            ## Discover VPN Network Adapter by using multiple search criteria.
            ## Search stops at the first match using below precedence order.
            [string]$VPNMatchUsing = ''
            
            #  Precedence Order 1: Detect VPN connection based on key words in network adapter description field.
            If ($LikeAdapterDescription)
            {
                ForEach ($LikeDescription in $LikeAdapterDescription)
                {
                    If ([boolean]($NetworkAdapterConfig | Where-Object {($_ | Select-Object -ExpandProperty Description) -ilike $LikeDescription}))
                    {
                        $VPNMatchUsing = 'VPN Network Adapter matched on search criteria in parameter [-LikeAdapterDescription]'
                        Return $true
                    }
                }
            }
            
            #  Precedence Order 2: Detect VPN based on DNS domain (e.g.: contoso.com).
            If ($LikeAdapterDNSDomain)
            {
                ForEach ($LikeDNSDomain in $LikeAdapterDNSDomain)
                {
                    If ([boolean]($NetworkAdapterConfig | Where-Object {($_ | Select-Object -ExpandProperty DNSDomain) -ilike $LikeDNSDomain}))
                    {
                        $VPNMatchUsing = 'VPN Network Adapter matched on search criteria in parameter [-LikeAdapterDNSDomain]'
                        Return $true
                    }
                }
            }
            
            #  Precedence Order 3: Detect VPN connection based on the DHCP Server of the network adapter
            If ($LikeAdapterDHCPServer)
            {
                ForEach ($LikeDHCPServer in $LikeAdapterDHCPServer)
                {
                    If ([boolean]($NetworkAdapterConfig | Where-Object {($_ | Select-Object -ExpandProperty DHCPServer) -ilike $LikeDHCPServer}))
                    {
                        $VPNMatchUsing = 'VPN Network Adapter matched on search criteria in parameter [-LikeAdapterDHCPServer]'
                        Return $true
                    }
                }
            }
            
            #  Precedence Order 4: Detect VPN connection based on the default gateway for the network adapter.
            If ($LikeAdapterDefaultGateway)
            {
                ForEach ($LikeDefaultGateway in $LikeAdapterDefaultGateway)
                {
                    If ([boolean]($NetworkAdapterConfig | Where-Object {($_ | Select-Object -ExpandProperty DefaultIPGateway) -ilike $LikeDefaultGateway}))
                    {
                        $VPNMatchUsing = 'VPN Network Adapter matched on search criteria in parameter [-LikeAdapterDefaultGateway]'
                        Return $true
                    }
                }
            }
            Return $false
        }
        Catch
        {
            Return $false
        }
    }
    End
    {
        ## Display Network Adapter Tables
        If ($DisplayNetworkAdapterTable)
        {
            Write-Host "All network adapters: `n$AllNetworkAdapterConfigTable"                                         -ForegroundColor 'Magenta'
            Write-Host "Filtered to possible VPN network adapters: `n$NetworkAdapterConfigTable"                       -ForegroundColor 'Yellow'
            Write-Host "Filtered to possible VPN network adapters (IP Enabled): `n$IpEnabledNetworkAdapterConfigTable" -ForegroundColor 'Cyan'
            If (-not ([string]::IsNullOrEmpty($VPNMatchUsing)))
            {
                Write-Host "$VPNMatchUsing" -ForegroundColor 'White'
            }
        }
    }
}
