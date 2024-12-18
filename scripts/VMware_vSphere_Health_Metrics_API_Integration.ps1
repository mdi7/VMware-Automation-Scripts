# PowerShell script for VMware vSphere Health Metrics API Integration
# Prerequisites: VMware PowerCLI module installed
# Slack or Microsoft Teams webhook URL must be configured beforehand

# Define the vCenter Server credentials
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"

# Define the third-party integration webhook URL (Slack or Teams)
$slackWebhookUrl = "https://hooks.slack.com/services/your/webhook/url"
# Or, for Teams
#$teamsWebhookUrl = "https://outlook.office.com/webhook/your/webhook/url"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Function to fetch and send health metrics to Slack/Teams
function Send-HealthMetricsToAPI {
    Write-Host "Fetching health metrics from vCenter..."

    # Fetch the health metrics for ESXi hosts
    $hosts = Get-VMHost

    $hostHealth = @()

    foreach ($host in $hosts) {
        # Get CPU, memory, and storage health metrics for the host
        $cpuUsage = $host.CpuUsageMhz
        $memoryUsage = $host.MemoryUsageMB
        $storageUsage = $host.StorageTotalMB - $host.StorageFreeMB

        # Create a custom object for health data
        $hostHealth += [PSCustomObject]@{
            HostName = $host.Name
            CPUUsage = "$([math]::round(($cpuUsage / $host.CpuTotalMhz) * 100, 2))%"
            MemoryUsage = "$([math]::round(($memoryUsage / $host.MemoryTotalMB) * 100, 2))%"
            StorageUsage = "$([math]::round(($storageUsage / $host.StorageTotalMB) * 100, 2))%"
        }
    }

    # Create a message with health data
    $message = "vSphere Health Metrics Report:`n"
    $hostHealth | ForEach-Object {
        $message += "`nHost: $($_.HostName)`n"
        $message += "CPU Usage: $($_.CPUUsage)`n"
        $message += "Memory Usage: $($_.MemoryUsage)`n"
        $message += "Storage Usage: $($_.StorageUsage)`n"
        $message += "----------------------"
    }

    # Prepare the payload for Slack/Teams
    $payload = @{
        text = $message
    } | ConvertTo-Json

    # Send data to Slack or Teams via webhook
    try {
        # Uncomment the correct line depending on the service you are using
        Invoke-RestMethod -Uri $slackWebhookUrl -Method Post -ContentType "application/json" -Body $payload
        # Invoke-RestMethod -Uri $teamsWebhookUrl -Method Post -ContentType "application/json" -Body $payload
        Write-Host "Health metrics sent to Slack/Teams successfully."
    }
    catch {
        Write-Host "Error sending health metrics: $_"
    }
}

# Function to monitor for health issues and send alerts
function Monitor-HealthIssues {
    Write-Host "Monitoring for health issues..."

    # Fetch the hosts and check for critical health issues
    $hosts = Get-VMHost
    $criticalIssues = @()

    foreach ($host in $hosts) {
        $healthStatus = $host.ExtensionData.Summary.OverallStatus
        if ($healthStatus -eq "yellow" -or $healthStatus -eq "red") {
            $criticalIssues += [PSCustomObject]@{
                HostName = $host.Name
                HealthStatus = $healthStatus
            }
        }
    }

    if ($criticalIssues.Count -gt 0) {
        $message = "vSphere Critical Health Alerts:`n"
        $criticalIssues | ForEach-Object {
            $message += "`nHost: $($_.HostName)`n"
            $message += "Health Status: $($_.HealthStatus)`n"
            $message += "----------------------"
        }

        # Prepare the payload for Slack/Teams
        $payload = @{
            text = $message
        } | ConvertTo-Json

        try {
            # Send data to Slack or Teams via webhook
            Invoke-RestMethod -Uri $slackWebhookUrl -Method Post -ContentType "application/json" -Body $payload
            # Invoke-RestMethod -Uri $teamsWebhookUrl -Method Post -ContentType "application/json" -Body $payload
            Write-Host "Critical health issues reported to Slack/Teams."
        }
        catch {
            Write-Host "Error sending health alerts: $_"
        }
    } else {
        Write-Host "No critical health issues detected."
    }
}

# Fetch and send health metrics
Send-HealthMetricsToAPI

# Monitor health issues
Monitor-HealthIssues

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "vSphere health metrics and alerts completed."
