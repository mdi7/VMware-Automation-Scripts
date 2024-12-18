# PowerShell script for automating VMware VM migration
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$targetHost = "esxi-host-target.example.com"
$reportPath = "C:\VM_Migration_Reports"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get source and target hosts
$sourceHost = Get-VMHost -Name "esxi-host-source.example.com"
$targetHost = Get-VMHost -Name $targetHost

# Check available storage on the target host
$targetDatastore = Get-Datastore -VMHost $targetHost | Sort-Object FreeSpaceGB | Select-Object -First 1
Write-Host "Target Host: $($targetHost.Name), Available Storage: $($targetDatastore.FreeSpaceGB) GB"

# Ensure enough free storage on the target datastore
$thresholdStorageGB = 10
if ($targetDatastore.FreeSpaceGB -lt $thresholdStorageGB) {
    Write-Host "Not enough free storage on target host. Available: $($targetDatastore.FreeSpaceGB) GB"
    exit
}

# Get all VMs running on the source host
$vmsToMigrate = Get-VM -VMHost $sourceHost

# Create migration report file
$reportFile = "$reportPath\Migration_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
New-Item -Path $reportFile -ItemType File -Force
Add-Content -Path $reportFile -Value "VM Migration Report - $(Get-Date)"
Add-Content -Path $reportFile -Value "--------------------------------------"

# Iterate over each VM and migrate
foreach ($vm in $vmsToMigrate) {
    Write-Host "Migrating VM: $($vm.Name)"

    # Check network compatibility (you can customize this check based on your environment)
    $sourceNetwork = Get-NetworkAdapter -VM $vm | Select-Object -First 1
    $targetNetwork = Get-NetworkAdapter -VMHost $targetHost | Select-Object -First 1
    if ($sourceNetwork.NetworkName -ne $targetNetwork.NetworkName) {
        Add-Content -Path $reportFile -Value "Network mismatch for VM: $($vm.Name). Skipping migration."
        Write-Host "Network mismatch for VM: $($vm.Name). Skipping migration."
        continue
    }

    # Perform the migration
    try {
        Move-VM -VM $vm -Destination $targetHost -Datastore $targetDatastore
        Add-Content -Path $reportFile -Value "VM $($vm.Name) migrated successfully from $($sourceHost.Name) to $($targetHost.Name)."
        Write-Host "VM $($vm.Name) migrated successfully."
    } catch {
        Add-Content -Path $reportFile -Value "Failed to migrate VM: $($vm.Name) from $($sourceHost.Name) to $($targetHost.Name). Error: $_"
        Write-Host "Failed to migrate VM: $($vm.Name). Error: $_"
    }
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Migration process completed. Report saved to: $reportFile"
