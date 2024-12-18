# PowerShell script for VMware Host Network Configuration Automation
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$esxiHostName = "esxi-host.example.com"  # ESXi host to configure
$networkName = "vSwitch1"  # Name of the virtual switch to configure
$vlanID = 100  # VLAN ID to configure
$nicNames = @("vmnic0", "vmnic1")  # NICs to be added to the virtual switch
$vmkName = "vmk0"  # VMkernel adapter name
$ipAddress = "192.168.1.10"  # IP address for VMkernel adapter
$subnetMask = "255.255.255.0"  # Subnet mask
$gateway = "192.168.1.1"  # Gateway for VMkernel adapter

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get the ESXi host
$esxiHost = Get-VMHost -Name $esxiHostName

# Function to configure virtual switch (vSwitch)
function Configure-VSwitch {
    Write-Host "Configuring virtual switch: $networkName on host: $esxiHostName"
    
    # Create a new virtual switch if it does not exist
    $vSwitch = Get-VirtualSwitch -VMHost $esxiHost | Where-Object {$_.Name -eq $networkName}
    if (-not $vSwitch) {
        New-VirtualSwitch -VMHost $esxiHost -Name $networkName -Nic $nicNames[0] -Confirm:$false
        Write-Host "Created virtual switch: $networkName and added NIC: $($nicNames[0])"
    } else {
        Write-Host "Virtual switch $networkName already exists."
    }

    # Add the additional NICs to the virtual switch
    foreach ($nic in $nicNames[1..$nicNames.Length-1]) {
        Add-VirtualSwitchNic -VMHost $esxiHost -VirtualSwitch $vSwitch -Nic $nic -Confirm:$false
        Write-Host "Added NIC: $nic to virtual switch $networkName"
    }

    # Configure VLAN ID on the virtual switch
    Set-VirtualSwitch -VMHost $esxiHost -Name $networkName -VlanId $vlanID -Confirm:$false
    Write-Host "Set VLAN ID: $vlanID on virtual switch: $networkName"
}

# Function to configure VMkernel adapter (vmk) for management/network
function Configure-VMKernelAdapter {
    Write-Host "Configuring VMkernel adapter: $vmkName on host: $esxiHostName"
    
    # Get existing VMkernel adapter and remove if necessary
    $vmkAdapter = Get-VMKernelNetworkAdapter -VMHost $esxiHost | Where-Object {$_.Name -eq $vmkName}
    if ($vmkAdapter) {
        Remove-VMKernelNetworkAdapter -VMKernelNetworkAdapter $vmkAdapter -Confirm:$false
        Write-Host "Removed existing VMkernel adapter: $vmkName"
    }

    # Add new VMkernel adapter for management/network
    New-VMKernelNetworkAdapter -VMHost $esxiHost -VirtualSwitch $networkName -Name $vmkName -IP $ipAddress -SubnetMask $subnetMask -DefaultGateway $gateway -Confirm:$false
    Write-Host "Added VMkernel adapter: $vmkName with IP: $ipAddress, subnet mask: $subnetMask, and gateway: $gateway"
}

# Function to apply high availability network policies (optional)
function Apply-HighAvailabilityPolicies {
    Write-Host "Applying high availability network policies..."

    # Example: Configure network redundancy using NIC teaming
    $vSwitch = Get-VirtualSwitch -VMHost $esxiHost | Where-Object {$_.Name -eq $networkName}
    Set-VirtualSwitch -VMHost $esxiHost -Name $vSwitch.Name -NicTeamPolicy "LoadBalancing" -Confirm:$false
    Write-Host "Applied NIC teaming policy: LoadBalancing on virtual switch $networkName"

    # Optionally, configure failover settings, load balancing methods, etc.
}

# Run the network configuration functions
Configure-VSwitch
Configure-VMKernelAdapter
Apply-HighAvailabilityPolicies

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Network configuration completed for host: $esxiHostName."
