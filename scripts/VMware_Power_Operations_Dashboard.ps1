# PowerShell script for VMware Power Operations Dashboard
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Dashboard Main Menu
function Show-DashboardMenu {
    cls
    Write-Host "-----------------------------------"
    Write-Host " VMware Power Operations Dashboard"
    Write-Host "-----------------------------------"
    Write-Host "1. List all VMs"
    Write-Host "2. View VM Details"
    Write-Host "3. Manage VM Resources"
    Write-Host "4. Exit"
    Write-Host "-----------------------------------"
    $choice = Read-Host "Enter your choice"
    return $choice
}

# Function to list all VMs and their states
function List-VMs {
    cls
    $vms = Get-VM
    Write-Host "Listing all VMs..."
    Write-Host "-----------------------------------"
    foreach ($vm in $vms) {
        Write-Host "$($vm.Name) - $($vm.PowerState)"
    }
    Write-Host "-----------------------------------"
    Read-Host "Press Enter to return to the main menu"
}

# Function to view detailed information for a selected VM
function View-VMDetails {
    cls
    $vmName = Read-Host "Enter the VM name to view details"
    $vm = Get-VM -Name $vmName
    if ($vm) {
        Write-Host "VM Name: $($vm.Name)"
        Write-Host "Power State: $($vm.PowerState)"
        Write-Host "CPU: $($vm.NumCpu) cores"
        Write-Host "Memory: $($vm.MemoryGB) GB"
        Write-Host "IP Address: $($vm.Guest.IPAddress)"
        Write-Host "-----------------------------------"
    } else {
        Write-Host "VM not found!"
    }
    Read-Host "Press Enter to return to the main menu"
}

# Function to manage resources (CPU and Memory) for a selected VM
function Manage-VMResources {
    cls
    $vmName = Read-Host "Enter the VM name to manage resources"
    $vm = Get-VM -Name $vmName
    if ($vm) {
        Write-Host "Current CPU: $($vm.NumCpu) cores"
        Write-Host "Current Memory: $($vm.MemoryGB) GB"
        $cpuChoice = Read-Host "Enter the number of CPUs to set (current: $($vm.NumCpu))"
        $memoryChoice = Read-Host "Enter the amount of memory in GB to set (current: $($vm.MemoryGB))"

        Set-VM -VM $vm -NumCpu $cpuChoice -MemoryGB $memoryChoice -Confirm:$false
        Write-Host "Resources updated: $($vm.Name) now has $cpuChoice CPUs and $memoryChoice GB of memory."
    } else {
        Write-Host "VM not found!"
    }
    Read-Host "Press Enter to return to the main menu"
}

# Main loop for dashboard interface
while ($true) {
    $choice = Show-DashboardMenu
    switch ($choice) {
        1 { List-VMs }
        2 { View-VMDetails }
        3 { Manage-VMResources }
        4 { break }
        default { Write-Host "Invalid choice, please try again." }
    }
}
# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false
