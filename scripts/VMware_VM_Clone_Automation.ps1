# PowerShell script for VMware VM Clone Automation
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$vmNameToClone = "VM-to-clone"  # Name of the VM to clone
$cloneName = "Cloned-VM"  # Name of the new cloned VM
$cpuCount = 4  # Number of CPUs for the cloned VM
$memoryGB = 16  # Memory (in GB) for the cloned VM
$datastoreName = "datastore1"  # Datastore where the clone will be stored
$networkName = "VM Network"  # Network adapter name for the cloned VM
$cloneFolder = "VM_Folder"  # Folder in which to place the cloned VM
$resourcePool = "ResourcePool1"  # Resource Pool for the cloned VM

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get the VM to clone
$vmToClone = Get-VM -Name $vmNameToClone

if ($vmToClone) {
    # Clone the VM
    Write-Host "Cloning VM: $($vmToClone.Name) to $cloneName"

    $clone = New-VM -Name $cloneName -VM $vmToClone -ResourcePool $resourcePool -Datastore $datastoreName -Folder $cloneFolder -Confirm:$false

    # Customize clone settings (CPU, Memory, Network, etc.)
    Set-VM -VM $clone -NumCpu $cpuCount -MemoryGB $memoryGB -Confirm:$false
    Write-Host "Clone created with $cpuCount CPUs and $memoryGB GB of memory."

    # Get the network adapter of the original VM and set it for the cloned VM
    $networkAdapter = Get-NetworkAdapter -VM $vmToClone | Where-Object { $_.NetworkName -eq $networkName }
    Set-NetworkAdapter -VM $clone -NetworkName $networkName -AdapterType $networkAdapter.AdapterType -Confirm:$false
    Write-Host "Network adapter configured to $networkName."

    # Check for disk configuration and resize if needed
    $disk = Get-HardDisk -VM $vmToClone | Select-Object -First 1
    if ($disk) {
        $newDiskSize = $disk.CapacityGB + 10  # Example: Increase disk size by 10 GB
        Set-HardDisk -HardDisk $disk -CapacityGB $newDiskSize -Confirm:$false
        Write-Host "Disk size increased to $newDiskSize GB."
    }

    # Power on the cloned VM
    Start-VM -VM $clone
    Write-Host "VM clone named $cloneName has been powered on."

    # Disconnect from vCenter
    Disconnect-VIServer -Server $vcServer -Confirm:$false
} else {
    Write-Host "VM $vmNameToClone not found."
}
