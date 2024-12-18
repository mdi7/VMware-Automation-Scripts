# PowerShell script to auto-scale VM resources based on CPU and Memory usage

# Connect to vCenter
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$cpuThreshold = 80 # CPU usage threshold in percentage
$memoryThreshold = 80 # Memory usage threshold in percentage

Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get list of all VMs
$vms = Get-VM

foreach ($vm in $vms) {
    # Get performance stats
    $cpuUsage = Get-Stat -Entity $vm -Stat cpu.usage.average -Start (Get-Date).AddMinutes(-5) -IntervalMins 5 | Select-Object -ExpandProperty Value
    $memoryUsage = Get-Stat -Entity $vm -Stat mem.usage.average -Start (Get-Date).AddMinutes(-5) -IntervalMins 5 | Select-Object -ExpandProperty Value

    # Scale up resources if necessary
    if ($cpuUsage -gt $cpuThreshold) {
        $currentCpu = (Get-VM -Name $vm.Name).NumCpu
        Set-VM -VM $vm -NumCpu ($currentCpu + 1) -Confirm:$false
        Write-Host "Scaled up CPU for VM $($vm.Name)"
    }

    if ($memoryUsage -gt $memoryThreshold) {
        $currentMemory = (Get-VM -Name $vm.Name).MemoryGB
        Set-VM -VM $vm -MemoryGB ($currentMemory + 2) -Confirm:$false
        Write-Host "Scaled up Memory for VM $($vm.Name)"
    }
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false
