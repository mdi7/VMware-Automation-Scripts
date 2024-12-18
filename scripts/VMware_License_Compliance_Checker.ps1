# PowerShell script for VMware License Compliance Checker
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$licenseCpuLimit = 32  # Set the maximum allowed CPUs for the license
$licenseMemoryLimitGB = 256  # Set the maximum allowed memory in GB for the license
$licenseStorageLimitGB = 1024  # Set the maximum allowed storage in GB for the license
$reportPath = "C:\License_Compliance_Reports"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Create a report file
$reportFile = "$reportPath\License_Compliance_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
New-Item -Path $reportFile -ItemType File -Force
Add-Content -Path $reportFile -Value "VMware License Compliance Report - $(Get-Date)"
Add-Content -Path $reportFile -Value "--------------------------------------"

# Get all ESXi hosts
$hosts = Get-VMHost

foreach ($host in $hosts) {
    Write-Host "Checking compliance for host: $($host.Name)"

    # Get host details
    $cpuCount = $host.NumCpu
    $memoryGB = $host.MemoryTotalMB / 1024  # Convert MB to GB
    $storageGB = (Get-Datastore -VMHost $host | Measure-Object -Property FreeSpaceGB -Sum).Sum  # Total free storage space in GB

    # Check compliance against the license limits
    $complianceIssues = @()

    if ($cpuCount -gt $licenseCpuLimit) {
        $complianceIssues += "CPU limit exceeded: $cpuCount CPUs (License allows $licenseCpuLimit CPUs)"
    }
    
    if ($memoryGB -gt $licenseMemoryLimitGB) {
        $complianceIssues += "Memory limit exceeded: $memoryGB GB (License allows $licenseMemoryLimitGB GB)"
    }
    
    if ($storageGB -gt $licenseStorageLimitGB) {
        $complianceIssues += "Storage limit exceeded: $storageGB GB (License allows $licenseStorageLimitGB GB)"
    }

    # Write the result to the report
    if ($complianceIssues.Count -gt 0) {
        Add-Content -Path $reportFile -Value "Host: $($host.Name) - Compliance Issues:"
        $complianceIssues | ForEach-Object { Add-Content -Path $reportFile -Value "  - $_" }
    } else {
        Add-Content -Path $reportFile -Value "Host: $($host.Name) - Compliant with license"
    }
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Compliance check completed. Report saved to: $reportFile"
