# PowerShell script for VMware Cluster Health and Optimization Tool
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$clusterName = "Cluster-Name"  # Replace with the desired cluster name

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get the specified cluster
$cluster = Get-Cluster -Name $clusterName
if (-not $cluster) {
    Write-Host "Cluster not found: $clusterName"
    exit
}

# Get the hosts in the cluster
$hosts = Get-VMHost -Cluster $cluster

# Check CPU and memory usage for optimization
Write-Host "Checking resource usage across hosts in cluster: $($cluster.Name)"
Write-Host "------------------------------------------------------------"
$cpuUsage = @()
$memoryUsage = @()

foreach ($host in $hosts) {
    $cpuUsage += [PSCustomObject]@{
        HostName   = $host.Name
        CPUUsage   = ($host.CpuUsageMhz / $host.CpuTotalMhz) * 100  # CPU usage percentage
        CPUCapacity = $host.CpuTotalMhz
    }
    $memoryUsage += [PSCustomObject]@{
        HostName   = $host.Name
        MemoryUsage = ($host.MemoryUsageMB / $host.MemoryTotalMB) * 100  # Memory usage percentage
        MemoryCapacity = $host.MemoryTotalMB
    }
}

# Display CPU and memory usage summary
Write-Host "CPU and Memory Usage Summary:"
$cpuUsage | Format-Table -AutoSize
$memoryUsage | Format-Table -AutoSize

# Check for DRS (Distributed Resource Scheduler) recommendations
Write-Host "Checking DRS recommendations..."
$drsRecommendations = Get-Cluster $cluster | Get-DRSRecommendation

if ($drsRecommendations) {
    Write-Host "DRS Recommendations:"
    $drsRecommendations | Format-Table -AutoSize
} else {
    Write-Host "No DRS recommendations found."
}

# Check VM distribution across hosts in the cluster
Write-Host "Checking VM distribution across hosts..."
$vmDistribution = Get-VM -Location $cluster | Group-Object -Property VMHost | Select-Object Name, Count

Write-Host "VM Distribution Across Hosts:"
$vmDistribution | Format-Table -AutoSize

# Rebalancing suggestion based on CPU and memory usage
Write-Host "Rebalancing Suggestions:"
foreach ($host in $hosts) {
    if (($host.CpuUsageMhz / $host.CpuTotalMhz) * 100 -gt 85) {
        Write-Host "Host $($host.Name) is over-utilized in CPU. Consider migrating VMs."
    }
    if (($host.MemoryUsageMB / $host.MemoryTotalMB) * 100 -gt 85) {
        Write-Host "Host $($host.Name) is over-utilized in memory. Consider migrating VMs."
    }
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Cluster Health Check and Optimization completed."
