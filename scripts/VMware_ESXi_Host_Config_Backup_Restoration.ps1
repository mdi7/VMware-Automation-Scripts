# PowerShell script for VMware ESXi Host Configuration Backup and Restoration
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$esxiHostName = "esxi-host.example.com"  # Name of the ESXi host to backup or restore
$backupFolder = "C:\ESXi_Backups"  # Path where backups will be saved

# Function to backup ESXi host configuration
function Backup-ESXiHostConfig {
    $backupFile = "$backupFolder\$esxiHostName-Config-$(Get-Date -Format 'yyyyMMddHHmm').tgz"
    
    Write-Host "Backing up ESXi host configuration for host: $esxiHostName to $backupFile"

    # Connect to the ESXi host
    $esxiHost = Get-VMHost -Name $esxiHostName

    # Backup host configuration (networking, storage, security, etc.)
    Backup-VMHost -VMHost $esxiHost -Destination $backupFile -Force

    Write-Host "Backup completed successfully for ESXi host: $esxiHostName."
}

# Function to restore ESXi host configuration from backup
function Restore-ESXiHostConfig {
    $backupFile = Read-Host "Enter the backup file path for restoration"

    if (Test-Path $backupFile) {
        Write-Host "Restoring ESXi host configuration from $backupFile"

        # Restore the ESXi host configuration
        Restore-VMHost -VMHost (Get-VMHost -Name $esxiHostName) -BackupFile $backupFile

        Write-Host "Restoration completed successfully for ESXi host: $esxiHostName."
    } else {
        Write-Host "Backup file not found: $backupFile"
    }
}

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Show menu for backup or restoration
$action = Read-Host "Enter action: 'backup' to backup configuration or 'restore' to restore configuration"

if ($action -eq "backup") {
    Backup-ESXiHostConfig
} elseif ($action -eq "restore") {
    Restore-ESXiHostConfig
} else {
    Write-Host "Invalid action. Please enter either 'backup' or 'restore'."
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Operation completed."
