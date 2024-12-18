# PowerShell script for VMware Storage Optimization and Cleanup Tool
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$datastoreName = "datastore1"  # Datastore to analyze
$cleanupThresholdGB = 10  # Minimum storage free space threshold (in GB)

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get the specified datastore
$datastore = Get-Datastore -Name $datastoreName

# Get the VM files associated with the datastore
$vmFiles = Get-VM -Datastore $datastore | Get-HardDisk

# Function to clean up orphaned files
function Cleanup-OrphanedFiles {
    $orphanedFiles = Get-VM -Datastore $datastore | Get-VMFile | Where-Object { $_.FileType -eq "orphaned" }

    if ($orphanedFiles) {
        Write-Host "Cleaning up orphaned files..."
        foreach ($file in $orphanedFiles) {
            Remove-VMFile -VMFile $file -Confirm:$false
            Write-Host "Removed orphaned file: $($file.Name)"
        }
    } else {
        Write-Host "No orphaned files found."
    }
}

# Function to identify underutilized storage and suggest migration
function Suggest-StorageOptimization {
    $datastoreUsage = $datastore | Get-DatastoreUsage

    $freeSpaceGB = [math]::round($datastoreUsage.FreeSpaceMB / 1024, 2)
    $totalSpaceGB = [math]::round($datastoreUsage.TotalSpaceMB / 1024, 2)
    $usedSpaceGB = $totalSpaceGB - $freeSpaceGB
    $usagePercentage = [math]::round(($usedSpaceGB / $totalSpaceGB) * 100, 2)

    Write-Host "Datastore usage details:"
    Write-Host "Total Space: $totalSpaceGB GB"
    Write-Host "Used Space: $usedSpaceGB GB"
    Write-Host "Free Space: $freeSpaceGB GB"
    Write-Host "Usage Percentage: $usagePercentage%"

    if ($usagePercentage -gt 85) {
        Write-Host "Warning: Datastore usage is above 85%. Consider migrating VMs to a different datastore."
    }

    if ($freeSpaceGB -lt $cleanupThresholdGB) {
        Write-Host "Warning: Available free space on datastore is less than $cleanupThresholdGB GB. Consider optimizing or migrating data."
    }
}

# Function to clean up unused VM files
function Cleanup-UnusedVMFiles {
    foreach ($file in $vmFiles) {
        $vmName = $file.VM.Name
        $fileSizeGB = [math]::round($file.CapacityKB / 1024 / 1024, 2)

        if ($fileSizeGB -gt 1) {  # Only clean up files larger than 1GB
            Remove-HardDisk -HardDisk $file -Confirm:$false
            Write-Host "Removed unused file: $($file.Name) of size $fileSizeGB GB"
        }
    }
}

# Run cleanup for orphaned files and unused VM files
Cleanup-OrphanedFiles
Cleanup-UnusedVMFiles

# Suggest storage optimization or migration if needed
Suggest-StorageOptimization

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Storage optimization and cleanup completed."
