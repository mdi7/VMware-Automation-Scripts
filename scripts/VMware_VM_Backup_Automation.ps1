# PowerShell script to backup VMware VM
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$backupLocation = "C:\VMBackups"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get list of all VMs
$vms = Get-VM

# Backup each VM
foreach ($vm in $vms) {
    $vmName = $vm.Name
    $backupFile = "$backupLocation\$vmName\_$(Get-Date -Format 'yyyyMMddHHmm').vmdk"
    Write-Host "Backing up $vmName to $backupFile"

    # Create snapshot
    New-Snapshot -VM $vm -Name "BackupSnapshot" -Description "Backup Snapshot" -Memory -Quiesce

    # Export VM (in this case, a snapshot backup)
    Export-VApp -VM $vm -Destination $backupFile

    # Remove snapshot after backup is done
    Remove-Snapshot -VM $vm -Name "BackupSnapshot" -Confirm:$false
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false
