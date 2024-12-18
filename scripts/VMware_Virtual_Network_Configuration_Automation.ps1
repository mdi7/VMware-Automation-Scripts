# PowerShell script for VMware Virtual Network Configuration Automation
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$hostName = "esxi-host.example.com"  # Specify the ESXi host where you want to apply configurations
$vSwitchName = "vSwitch1"  # Name for the new virtual switch
$vlanID = 10  # VLAN ID to associate with the vSwitch
$networkAdapterName = "vmnic0"  # Network adapter name to add to the vSwitch
$reportPath = "C:\Network_Configuration_Reports"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get the ESXi host
$esxiHost = Get-VMHost -Name $hostName

# Create a new virtual switch (vSwitch)
Write-Host "Creating new virtual switch: $vSwitchName on host $hostName"
$vswitch = New-VirtualSwitch -VMHost $esxiHost -Name $vSwitchName -Nic $networkAdapterName -Confirm:$false

# Assign a VLAN to the virtual switch
Write-Host "Assigning VLAN $vlanID to virtual switch: $vSwitchName"
$vswitch | Set-VirtualSwitch -VlanId $vlanID

# Verify network adapter and VLAN configuration
Write-Host "Verifying network configuration..."
$vswitch = Get-VirtualSwitch -VMHost $esxiHost -Name $vSwitchName
$adapter = Get-VirtualNetworkAdapter -VMHost $esxiHost | Where-Object {$_.Name -eq $networkAdapterName}

# Create the report file
$reportFile = "$reportPath\Network_Configuration_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
New-Item -Path $reportFile -ItemType File -Force
Add-Content -Path $reportFile -Value "VMware Network Configuration Report - $(Get-Date)"
Add-Content -Path $reportFile -Value "--------------------------------------"

# Report the network configuration details
Add-Content -Path $reportFile -Value "Host: $hostName"
Add-Content -Path $reportFile -Value "Virtual Switch: $vSwitchName"
Add-Content -Path $reportFile -Value "VLAN ID: $vlanID"
Add-Content -Path $reportFile -Value "Network Adapter: $networkAdapterName"
Add-Content -Path $reportFile -Value "Adapter's IP Address: $($adapter.IPAddress)"

Write-Host "Network configuration details have been saved to $reportFile"

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Network configuration completed successfully."
