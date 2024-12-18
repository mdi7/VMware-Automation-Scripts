# PowerShell script for VMware Automated Patching and Update Management
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$reportPath = "C:\Patching_Reports"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get all ESXi hosts
$esxiHosts = Get-VMHost

# Create report file
$reportFile = "$reportPath\Patching_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
New-Item -Path $reportFile -ItemType File -Force
Add-Content -Path $reportFile -Value "VMware ESXi Patching and Update Report - $(Get-Date)"
Add-Content -Path $reportFile -Value "--------------------------------------"

foreach ($host in $esxiHosts) {
    Write-Host "Checking patches for host: $($host.Name)"

    # Check if updates are available for the host
    $availablePatches = Get-VMHostPatch -VMHost $host | Where-Object {$_.Status -eq "Needed"}

    if ($availablePatches) {
        Write-Host "Patches found for host: $($host.Name)"
        Add-Content -Path $reportFile -Value "Host: $($host.Name) - Patches Found:"
        foreach ($patch in $availablePatches) {
            Add-Content -Path $reportFile -Value "  - $($patch.Name): $($patch.Description)"
        }

        # Install patches
        Write-Host "Applying patches to host: $($host.Name)"
        Install-VMHostPatch -VMHost $host -Patch $availablePatches -Confirm:$false

        # Reboot the host if necessary
        if ($host.State -eq 'Connected' -and $host.RebootRequired) {
            Write-Host "Rebooting host: $($host.Name) after patching"
            Restart-VMHost -VMHost $host -Confirm:$false
            Add-Content -Path $reportFile -Value "  - Host $($host.Name) rebooted after applying patches."
        }

        Add-Content -Path $reportFile -Value "Host: $($host.Name) - Patching completed."
    } else {
        Write-Host "No patches available for host: $($host.Name)"
        Add-Content -Path $reportFile -Value "Host: $($host.Name) - No patches found."
    }
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Patching process completed. Report saved to: $reportFile"
