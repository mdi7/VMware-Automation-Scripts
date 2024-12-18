# PowerShell script to manage snapshots in VMware

# Connect to vCenter
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"

Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get list of all VMs
$vms = Get-VM

foreach ($vm in $vms) {
    # Check if snapshot exists
    $snapshots = Get-Snapshot -VM $vm
    if ($snapshots) {
        # Remove snapshots older than 7 days
        foreach ($snapshot in $snapshots) {
            if ($snapshot.Created -lt (Get-Date).AddDays(-7)) {
                Remove-Snapshot -Snapshot $snapshot -Confirm:$false
                Write-Host "Removed snapshot $($snapshot.Name) for VM $($vm.Name)"
            }
        }
    } else {
        Write-Host "No snapshots found for VM $($vm.Name)"
    }
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false