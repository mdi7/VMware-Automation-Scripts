# PowerShell script for VMware Compliance and Audit Reporting
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$reportPath = "C:\Compliance_Reports"  # Directory where the report will be saved

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Create the report file
$reportFile = "$reportPath\Compliance_Audit_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
New-Item -Path $reportFile -ItemType File -Force
Add-Content -Path $reportFile -Value "VMware Compliance and Audit Report - $(Get-Date)"
Add-Content -Path $reportFile -Value "--------------------------------------"

# Function to check VM versions and ensure they are supported
function Check-VMVersions {
    Write-Host "Checking VM versions..."
    $vms = Get-VM
    foreach ($vm in $vms) {
        $vmVersion = $vm.Version
        # Assume supported version is 13 (for example, modify according to actual supported versions)
        $supportedVersion = 13
        if ($vmVersion -lt $supportedVersion) {
            Add-Content -Path $reportFile -Value "VM $($vm.Name) is using an unsupported version: $vmVersion"
            Write-Host "VM $($vm.Name) is using an unsupported version: $vmVersion"
        } else {
            Write-Host "VM $($vm.Name) is using a supported version: $vmVersion"
        }
    }
}

# Function to check if backups are in place
function Check-Backups {
    Write-Host "Checking for backups..."
    $vms = Get-VM
    foreach ($vm in $vms) {
        # For simplicity, assume VMs with snapshots indicate backups (modify as needed)
        $snapshots = Get-Snapshot -VM $vm
        if ($snapshots.Count -gt 0) {
            Write-Host "VM $($vm.Name) has snapshots (backup available)."
            Add-Content -Path $reportFile -Value "VM $($vm.Name) has snapshots (backup available)."
        } else {
            Write-Host "VM $($vm.Name) does not have snapshots (no backup)."
            Add-Content -Path $reportFile -Value "VM $($vm.Name) does not have snapshots (no backup)."
        }
    }
}

# Function to check security settings
function Check-SecuritySettings {
    Write-Host "Checking security settings..."
    $vms = Get-VM
    foreach ($vm in $vms) {
        $vmToolsStatus = $vm.ExtensionData.Guest.ToolsStatus
        if ($vmToolsStatus -ne "toolsOk") {
            Write-Host "VM $($vm.Name) has outdated or missing VMware Tools."
            Add-Content -Path $reportFile -Value "VM $($vm.Name) has outdated or missing VMware Tools."
        } else {
            Write-Host "VM $($vm.Name) has up-to-date VMware Tools."
        }

        # Check if the VM is using a secure network adapter (e.g., VMXNET3)
        $networkAdapter = Get-NetworkAdapter -VM $vm
        foreach ($adapter in $networkAdapter) {
            if ($adapter.AdapterType -ne "vmxnet3") {
                Write-Host "VM $($vm.Name) is using an insecure network adapter: $($adapter.AdapterType)"
                Add-Content -Path $reportFile -Value "VM $($vm.Name) is using an insecure network adapter: $($adapter.AdapterType)"
            } else {
                Write-Host "VM $($vm.Name) is using a secure network adapter: vmxnet3."
            }
        }
    }
}

# Function to check for DRS (Distributed Resource Scheduler) compliance
function Check-DRSCompliance {
    Write-Host "Checking DRS compliance..."
    $clusters = Get-Cluster
    foreach ($cluster in $clusters) {
        $drsEnabled = $cluster.DrsEnabled
        if ($drsEnabled -eq $true) {
            Write-Host "Cluster $($cluster.Name) has DRS enabled."
            Add-Content -Path $reportFile -Value "Cluster $($cluster.Name) has DRS enabled."
        } else {
            Write-Host "Cluster $($cluster.Name) does not have DRS enabled."
            Add-Content -Path $reportFile -Value "Cluster $($cluster.Name) does not have DRS enabled."
        }
    }
}

# Run compliance checks
Check-VMVersions
Check-Backups
Check-SecuritySettings
Check-DRSCompliance

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Compliance and audit process completed. Report saved to: $reportFile"
