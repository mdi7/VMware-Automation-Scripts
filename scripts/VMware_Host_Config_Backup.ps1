# PowerShell script to backup and restore VMware ESXi host configuration

# Connect to ESXi host
$esxiHost = "esxi-host.example.com"
$esxiUsername = "root"
$esxiPassword = "password"
$backupLocation = "C:\ESXiBackups"

# Backup ESXi configuration
$backupFile = "$backupLocation\$esxiHost-Config-$(Get-Date -Format 'yyyyMMddHHmm').tgz"
Write-Host "Backing up $esxiHost configuration to $backupFile"
Backup-VMHost -VMHost $esxiHost -Destination $backupFile -Force

# Restore ESXi configuration (if needed)
# Restore-VMHost -VMHost $esxiHost -BackupFile $backupFile
