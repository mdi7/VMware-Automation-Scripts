# PowerShell script for VMware Cluster Load Balancing & Distributed Resource Scheduler (DRS) Automation
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Function to check resource utilization across the cluster and adjust resources
function Check-ClusterResourceUsage {
    Write-Host "Checking resource utilization for the cluster..."

    $clusters = Get-Cluster

    foreach ($cluster in $clusters) {
        $hosts = Get-VMHost -Cluster $cluster
        $cpuUsage = ($hosts | Measure-Object -Property CpuUsageMhz -Sum).Sum
        $memoryUsage = ($hosts | Measure-Object -Property MemoryUsageMB -Sum).Sum

        $totalCpu = ($hosts | Measure-Object -Property CpuTotalMhz -Sum).Sum
        $totalMemory = ($hosts | Measure-Object -Property MemoryTotalMB -Sum).Sum

        $cpuUsagePercentage = [math]::round(($cpuUsage / $totalCpu) * 100, 2)
        $memoryUsagePercentage = [math]::round(($memoryUsage / $totalMemory) * 100, 2)

        Write-Host "Cluster: $($cluster.Name) - CPU Usage: $cpuUsagePercentage% - Memory Usage: $memoryUsagePercentage%"

        # Adjust host resources if CPU or Memory usage exceeds 80%
        if ($cpuUsagePercentage -gt 80) {
            Write-Host "CPU usage exceeds threshold. Adjusting resource allocation..."
            Adjust-ClusterHostResources -Cluster $cluster
        }

        if ($memoryUsagePercentage -gt 80) {
            Write-Host "Memory usage exceeds threshold. Adjusting resource allocation..."
            Adjust-ClusterHostResources -Cluster $cluster
        }
    }
}

# Function to adjust host resources (add/remove hosts, adjust memory/CPU limits)
function Adjust-ClusterHostResources {
    param (
        [Parameter(Mandatory = $true)]
        $Cluster
    )

    # Example: Add hosts to the cluster if resources are stretched (this part can be adjusted as needed)
    $hosts = Get-VMHost -Cluster $Cluster
    $availableHost = $hosts | Where-Object { $_.State -eq "Disconnected" }

    if ($availableHost) {
        Write-Host "Adding host $($availableHost.Name) to the cluster..."
        Add-VMHost -VMHost $availableHost -Cluster $Cluster -Confirm:$false
    }

    # Adjust CPU and Memory resources based on current usage (modify as needed)
    foreach ($host in $hosts) {
        if ($host.CpuUsageMhz / $host.CpuTotalMhz -gt 0.8) {
            Set-VMHost -VMHost $host -CpuLimitMhz ($host.CpuTotalMhz * 0.9) -Confirm:$false
            Write-Host "Reduced CPU limit on host $($host.Name)"
        }
        if ($host.MemoryUsageMB / $host.MemoryTotalMB -gt 0.8) {
            Set-VMHost -VMHost $host -MemoryLimitMB ($host.MemoryTotalMB * 0.9) -Confirm:$false
            Write-Host "Reduced memory limit on host $($host.Name)"
        }
    }
}

# Function to handle DRS recommendations and optimize VM placement
function Apply-DRSRecommendations {
    Write-Host "Checking and applying DRS recommendations..."

    $clusters = Get-Cluster

    foreach ($cluster in $clusters) {
        $drsRecommendations = Get-DRSRecommendation -Cluster $cluster

        if ($drsRecommendations) {
            foreach ($recommendation in $drsRecommendations) {
                if ($recommendation.Type -eq "Migrate") {
                    Write-Host "Applying DRS migration recommendation: Migrating VM $($recommendation.VM.Name)"
                    Move-VM -VM $recommendation.VM -Destination $recommendation.DestinationHost -Confirm:$false
                }
            }
        } else {
            Write-Host "No DRS recommendations for cluster $($cluster.Name)"
        }
    }
}

# Function to balance the load of VMs across the cluster
function Balance-VMPlacement {
    Write-Host "Balancing VM placement across the cluster..."

    $clusters = Get-Cluster

    foreach ($cluster in $clusters) {
        $vms = Get-VM -Cluster $cluster
        $hosts = Get-VMHost -Cluster $cluster

        # Example logic: Move VMs to hosts with the lowest load (you can adjust the criteria for placement)
        foreach ($vm in $vms) {
            $hostWithLowestLoad = $hosts | Sort-Object { $_.CpuUsageMhz / $_.CpuTotalMhz + $_.MemoryUsageMB / $_.MemoryTotalMB } | Select-Object -First 1
            if ($vm.Host.Name -ne $hostWithLowestLoad.Name) {
                Move-VM -VM $vm -Destination $hostWithLowestLoad -Confirm:$false
                Write-Host "Migrated VM $($vm.Name) to host $($hostWithLowestLoad.Name)"
            }
        }
    }
}

# Run the cluster load balancing and DRS automation functions
Check-ClusterResourceUsage
Apply-DRSRecommendations
Balance-VMPlacement

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "VMware Cluster Load Balancing and DRS Automation completed."
