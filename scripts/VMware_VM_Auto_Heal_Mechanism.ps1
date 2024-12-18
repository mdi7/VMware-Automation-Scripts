# PowerShell script for VMware Virtual Machine Auto-Heal Mechanism
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Function to check the health of VMs and perform remediation
function Check-VMHealthAndAutoHeal {
    Write-Host "Checking health of all VMs..."

    $vms = Get-VM

    foreach ($vm in $vms) {
        # Check if VM is powered on and its state
        $vmState = $vm.PowerState
        $vmToolsStatus = $vm.ExtensionData.Guest.ToolsStatus
        $vmName = $vm.Name

        Write-Host "Checking VM: $vmName"

        # Check if VM is powered on
        if ($vmState -eq "PoweredOff") {
            Write-Host "VM $vmName is powered off. Starting VM..."
            Start-VM -VM $vm -Confirm:$false
            Write-Host "VM $vmName started."
        }

        # Check if VMware Tools are outdated or missing
        if ($vmToolsStatus -ne "toolsOk") {
            Write-Host "VM $vmName has outdated or missing VMware Tools. Updating VMware Tools..."
            Update-VMGuest -VM $vm -Confirm:$false
            Write-Host "VMware Tools updated for VM $vmName."
        }

        # Check for VM crash or unresponsive state
        $vmHealth = Get-VM -Name $vmName | Select-Object -ExpandProperty PowerState
        if ($vmHealth -eq "PoweredOn") {
            # Perform a VM restart if the VM is unresponsive (e.g., not responding or hung)
            $vmStatus = Get-VM -Name $vmName | Get-Stat -Stat "cpu.usage.average" -Start (Get-Date).AddMinutes(-5) -IntervalMins 5
            $cpuUsage = $vmStatus.Value
            
            if ($cpuUsage -eq 0) {
                Write-Host "VM $vmName appears unresponsive. Restarting VM..."
                Restart-VM -VM $vm -Confirm:$false
                Write-Host "VM $vmName restarted."
            }
        }
    }
}

# Function to migrate non-healthy VMs to a different host (optional)
function Migrate-NonHealthyVMs {
    Write-Host "Migrating non-healthy VMs to another host..."

    $vms = Get-VM
    $hosts = Get-VMHost

    foreach ($vm in $vms) {
        # Check VM's health (similar checks can be added for crash or unresponsiveness)
        $vmToolsStatus = $vm.ExtensionData.Guest.ToolsStatus
        $vmState = $vm.PowerState
        if ($vmToolsStatus -ne "toolsOk" -or $vmState -eq "PoweredOff") {
            # Choose a target host (e.g., the first available host, excluding current host)
            $targetHost = $hosts | Where-Object { $_.Name -ne $vm.Host.Name } | Select-Object -First 1

            if ($targetHost) {
                Write-Host "Migrating VM $($vm.Name) to host $($targetHost.Name)..."
                Move-VM -VM $vm -Destination $targetHost -Confirm:$false
                Write-Host "VM $($vm.Name) migrated successfully to $($targetHost.Name)."
            } else {
                Write-Host "No suitable host found for migration of VM $($vm.Name)."
            }
        }
    }
}

# Run the health check and auto-heal mechanism
Check-VMHealthAndAutoHeal
Migrate-NonHealthyVMs

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "VM health check and auto-heal process completed."
