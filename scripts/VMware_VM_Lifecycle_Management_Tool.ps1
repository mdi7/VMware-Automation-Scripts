# PowerShell script for VMware VM Lifecycle Management Tool
# Prerequisites: VMware PowerCLI module installed

# Define vCenter connection credentials
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"

# Define VM lifecycle parameters
$vmTemplate = "Windows-10-Template"  # Template to use for VM creation
$vmNamePrefix = "VM-"  # Prefix for VM names
$inactivePeriodDays = 30  # Number of days after which an inactive VM will be decommissioned
$patchingDay = 7  # Day of the week to apply security patches (1 = Sunday, 7 = Saturday)
$decommissionDay = 30  # Days after which a VM is decommissioned if inactive

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Function to create a new VM from a template
function Create-NewVM {
    param (
        [Parameter(Mandatory = $true)]
        $VMName
    )

    Write-Host "Creating VM: $VMName from template $vmTemplate..."
    New-VM -Name $VMName -Template $vmTemplate -Datastore "datastore1" -Cluster "cluster1" -ResourcePool "resourcePool1"
    Write-Host "VM $VMName created successfully."
}

# Function to apply security patches to a VM
function Apply-SecurityPatches {
    Write-Host "Applying security patches to all VMs..."

    $vms = Get-VM
    foreach ($vm in $vms) {
        Write-Host "Patching VM: $($vm.Name)"
        
        # Simulate applying patches (this would integrate with an actual patching system)
        # Assuming the VM has VMware Tools installed and is running an OS that can be patched
        Update-VMGuest -VM $vm -Confirm:$false
        Write-Host "Applied patches to VM: $($vm.Name)"
    }
}

# Function to deactivate unused VMs based on inactivity
function Deactivate-InactiveVMs {
    Write-Host "Checking for inactive VMs..."

    $vms = Get-VM
    foreach ($vm in $vms) {
        $lastPoweredOn = $vm.PowerStateChanged
        $inactivePeriod = (New-TimeSpan -Start $lastPoweredOn -End (Get-Date)).Days

        if ($inactivePeriod -gt $inactivePeriodDays) {
            Write-Host "VM $($vm.Name) is inactive for $inactivePeriod days. Deactivating..."
            Stop-VM -VM $vm -Confirm:$false
            Write-Host "VM $($vm.Name) deactivated."
        }
    }
}

# Function to delete VMs that have been inactive for a specified period
function Delete-InactiveVMs {
    Write-Host "Checking for VMs to delete..."

    $vms = Get-VM
    foreach ($vm in $vms) {
        $lastPoweredOn = $vm.PowerStateChanged
        $inactivePeriod = (New-TimeSpan -Start $lastPoweredOn -End (Get-Date)).Days

        if ($inactivePeriod -gt $decommissionDay) {
            Write-Host "VM $($vm.Name) is inactive for $inactivePeriod days. Deleting..."
            Remove-VM -VM $vm -DeletePermanently -Confirm:$false
            Write-Host "VM $($vm.Name) deleted."
        }
    }
}

# Function to monitor VM lifecycle tasks
function Manage-VMsLifecycle {
    Write-Host "Managing VM lifecycle..."

    # Create a new VM (example)
    $newVMName = "$vmNamePrefix" + (Get-Date -Format "yyyyMMddHHmm")
    Create-NewVM -VMName $newVMName

    # Apply security patches to all VMs
    Apply-SecurityPatches

    # Deactivate VMs that have been inactive for more than the specified period
    Deactivate-InactiveVMs

    # Delete VMs that have been inactive for a longer period
    Delete-InactiveVMs
}

# Run the VM lifecycle management process
Manage-VMsLifecycle

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "VM lifecycle management completed."
