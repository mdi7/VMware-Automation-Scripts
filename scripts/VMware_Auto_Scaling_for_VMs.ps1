# PowerShell script for VMware Auto-Scaling for VMs
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$vmName = "VM-to-scale"  # Name of the VM to auto-scale
$cpuThreshold = 85  # CPU usage threshold (percentage)
$memoryThreshold = 85  # Memory usage threshold (percentage)
$maxCPU = 8  # Maximum number of CPUs allowed
$maxMemoryGB = 32  # Maximum memory in GB allowed
$minCPU = 1  # Minimum number of CPUs allowed
$minMemoryGB = 2  # Minimum memory in GB allowed

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get the VM to scale
$vm = Get-VM -Name $vmName

if ($vm) {
    Write-Host "Monitoring resource usage for VM: $vmName"

    # Get CPU and memory usage
    $cpuUsage = Get-Stat -Entity $vm -Stat "cpu.usage.average" -Start (Get-Date).AddMinutes(-5) -IntervalMins 5 | Select-Object -ExpandProperty Value
    $memoryUsage = Get-Stat -Entity $vm -Stat "mem.usage.average" -Start (Get-Date).AddMinutes(-5) -IntervalMins 5 | Select-Object -ExpandProperty Value

    # Check if CPU usage exceeds threshold and scale up/down accordingly
    if ($cpuUsage -gt $cpuThreshold) {
        $currentCpu = $vm.NumCpu
        $newCpu = [math]::Min($currentCpu + 1, $maxCPU)  # Scale up but don't exceed max limit
        if ($newCpu -ne $currentCpu) {
            Set-VM -VM $vm -NumCpu $newCpu -Confirm:$false
            Write-Host "CPU usage exceeded threshold. Increased CPU to $newCpu cores."
        }
    } elseif ($cpuUsage -lt $cpuThreshold - 10) {  # Allow some buffer for scaling down
        $currentCpu = $vm.NumCpu
        $newCpu = [math]::Max($currentCpu - 1, $minCPU)  # Scale down but don't go below min limit
        if ($newCpu -ne $currentCpu) {
            Set-VM -VM $vm -NumCpu $newCpu -Confirm:$false
            Write-Host "CPU usage is below threshold. Decreased CPU to $newCpu cores."
        }
    }

    # Check if memory usage exceeds threshold and scale up/down accordingly
    if ($memoryUsage -gt $memoryThreshold) {
        $currentMemory = $vm.MemoryGB
        $newMemory = [math]::Min($currentMemory + 2, $maxMemoryGB)  # Scale up but don't exceed max limit
        if ($newMemory -ne $currentMemory) {
            Set-VM -VM $vm -MemoryGB $newMemory -Confirm:$false
            Write-Host "Memory usage exceeded threshold. Increased memory to $newMemory GB."
        }
    } elseif ($memoryUsage -lt $memoryThreshold - 10) {  # Allow some buffer for scaling down
        $currentMemory = $vm.MemoryGB
        $newMemory = [math]::Max($currentMemory - 2, $minMemoryGB)  # Scale down but don't go below min limit
        if ($newMemory -ne $currentMemory) {
            Set-VM -VM $vm -MemoryGB $newMemory -Confirm:$false
            Write-Host "Memory usage is below threshold. Decreased memory to $newMemory GB."
        }
    }

} else {
    Write-Host "VM $vmName not found."
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Auto-scaling process completed."
