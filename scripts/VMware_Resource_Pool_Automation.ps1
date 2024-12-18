# PowerShell script for VMware Resource Pool Automation
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$cpuThreshold = 85  # CPU usage threshold for resizing resource pools (percentage)
$memoryThreshold = 85  # Memory usage threshold for resizing resource pools (percentage)
$minCPU = 1  # Minimum number of CPUs for a resource pool
$maxCPU = 8  # Maximum number of CPUs for a resource pool
$minMemoryGB = 2  # Minimum memory (in GB) for a resource pool
$maxMemoryGB = 32  # Maximum memory (in GB) for a resource pool

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Function to check resource pool CPU and memory usage
function Check-ResourcePoolUsage {
    Write-Host "Checking resource pool usage..."

    $resourcePools = Get-ResourcePool

    foreach ($pool in $resourcePools) {
        # Get resource pool usage (CPU and memory)
        $cpuUsage = ($pool.CpuUsageMhz / $pool.CpuLimitMhz) * 100  # CPU usage percentage
        $memoryUsage = ($pool.MemoryUsageMB / $pool.MemoryLimitMB) * 100  # Memory usage percentage

        Write-Host "Resource Pool: $($pool.Name) - CPU Usage: $([math]::round($cpuUsage, 2))% - Memory Usage: $([math]::round($memoryUsage, 2))%"

        # Resize resource pool based on CPU usage
        if ($cpuUsage -gt $cpuThreshold) {
            $newCPU = [math]::Min($pool.CpuLimitMhz + 1, $maxCPU)
            Set-ResourcePool -ResourcePool $pool -CpuLimitMhz $newCPU
            Write-Host "CPU usage exceeded threshold. Increased CPU limit to $newCPU MHz for resource pool $($pool.Name)."
        } elseif ($cpuUsage -lt ($cpuThreshold - 10)) {
            $newCPU = [math]::Max($pool.CpuLimitMhz - 1, $minCPU)
            Set-ResourcePool -ResourcePool $pool -CpuLimitMhz $newCPU
            Write-Host "CPU usage below threshold. Decreased CPU limit to $newCPU MHz for resource pool $($pool.Name)."
        }

        # Resize resource pool based on memory usage
        if ($memoryUsage -gt $memoryThreshold) {
            $newMemory = [math]::Min($pool.MemoryLimitMB + 1024, $maxMemoryGB * 1024)  # Convert GB to MB
            Set-ResourcePool -ResourcePool $pool -MemoryLimitMB $newMemory
            Write-Host "Memory usage exceeded threshold. Increased memory limit to $([math]::round($newMemory / 1024, 2)) GB for resource pool $($pool.Name)."
        } elseif ($memoryUsage -lt ($memoryThreshold - 10)) {
            $newMemory = [math]::Max($pool.MemoryLimitMB - 1024, $minMemoryGB * 1024)  # Convert GB to MB
            Set-ResourcePool -ResourcePool $pool -MemoryLimitMB $newMemory
            Write-Host "Memory usage below threshold. Decreased memory limit to $([math]::round($newMemory / 1024, 2)) GB for resource pool $($pool.Name)."
        }
    }
}

# Function to add or remove VMs based on resource usage
function Adjust-VMsInResourcePool {
    Write-Host "Adjusting VMs in resource pools based on resource usage..."

    $resourcePools = Get-ResourcePool

    foreach ($pool in $resourcePools) {
        $vmsInPool = Get-VM -ResourcePool $pool

        foreach ($vm in $vmsInPool) {
            # Get CPU and memory usage for the VM
            $vmCpuUsage = (Get-Stat -Entity $vm -Stat "cpu.usage.average" -Start (Get-Date).AddMinutes(-5) -IntervalMins 5).Value
            $vmMemoryUsage = (Get-Stat -Entity $vm -Stat "mem.usage.average" -Start (Get-Date).AddMinutes(-5) -IntervalMins 5).Value

            Write-Host "VM: $($vm.Name) - CPU Usage: $([math]::round($vmCpuUsage, 2))% - Memory Usage: $([math]::round($vmMemoryUsage, 2))%"

            # Migrate VMs with high CPU or memory usage to another pool or resize
            if ($vmCpuUsage -gt $cpuThreshold -or $vmMemoryUsage -gt $memoryThreshold) {
                # Example: Migrate to a different pool (this logic can be expanded to specific pools)
                $targetPool = Get-ResourcePool | Where-Object {$_.Name -ne $pool.Name} | Select-Object -First 1
                Move-VM -VM $vm -ResourcePool $targetPool
                Write-Host "VM $($vm.Name) migrated from $($pool.Name) to $($targetPool.Name) due to high resource usage."
            }
        }
    }
}

# Function to resize resource pools based on overall usage (optional)
function Resize-ResourcePools {
    Write-Host "Resizing resource pools based on overall usage..."

    $resourcePools = Get-ResourcePool

    foreach ($pool in $resourcePools) {
        # Example: Resize the pool based on total CPU usage or memory usage
        $totalUsage = $pool.CpuUsageMhz + $pool.MemoryUsageMB  # Combine CPU and memory usage

        if ($totalUsage -gt 80) {
            # Increase resource pool size
            Set-ResourcePool -ResourcePool $pool -CpuLimitMhz ($pool.CpuLimitMhz + 1) -MemoryLimitMB ($pool.MemoryLimitMB + 1024)
            Write-Host "Resource pool $($pool.Name) resized based on total usage."
        }
    }
}

# Run resource pool automation functions
Check-ResourcePoolUsage
Adjust-VMsInResourcePool
Resize-ResourcePools

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Resource pool automation completed."
