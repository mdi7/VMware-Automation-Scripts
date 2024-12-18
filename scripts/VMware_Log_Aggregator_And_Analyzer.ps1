# PowerShell script for VMware Log Aggregator and Analyzer
# Prerequisites: VMware PowerCLI module installed

# Define vCenter connection credentials
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"

# Define the alert threshold and email settings
$errorThreshold = 5  # Number of error logs required to trigger an alert
$warningThreshold = 10  # Number of warning logs to trigger an alert
$emailRecipient = "admin@example.com"  # Email recipient for alerts
$smtpServer = "smtp.example.com"  # SMTP server for sending alerts
$logDirectory = "C:\VMwareLogs"  # Directory to store aggregated logs

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Function to aggregate logs from multiple ESXi hosts
function Aggregate-VMwareLogs {
    Write-Host "Aggregating logs from ESXi hosts..."

    $hosts = Get-VMHost

    foreach ($host in $hosts) {
        Write-Host "Fetching logs from host: $($host.Name)..."
        
        # Get logs for the ESXi host, e.g., /var/log/vmware/hostd.log, /var/log/vmware/vpxa.log
        $logPaths = @("/var/log/vmware/hostd.log", "/var/log/vmware/vpxa.log")
        
        foreach ($logPath in $logPaths) {
            $localLogFile = Join-Path -Path $logDirectory -ChildPath "$($host.Name)_$($logPath.Split('/')[-1])"
            
            # Fetch and download logs to local machine
            Copy-VMHostFile -VMHost $host -SourceFile $logPath -DestinationFile $localLogFile
            Write-Host "Downloaded log file: $localLogFile"
        }
    }
}

# Function to analyze logs for patterns, warnings, or errors
function Analyze-Logs {
    Write-Host "Analyzing logs for warnings or errors..."

    $logFiles = Get-ChildItem -Path $logDirectory -Filter "*.log"

    $errorCount = 0
    $warningCount = 0
    $errorMessages = @()
    $warningMessages = @()

    foreach ($logFile in $logFiles) {
        $logContent = Get-Content $logFile.FullName

        foreach ($line in $logContent) {
            if ($line -match "error|fail|critical") {
                $errorCount++
                $errorMessages += $line
            }
            if ($line -match "warning|warn") {
                $warningCount++
                $warningMessages += $line
            }
        }
    }

    # Generate a report
    $report = "VMware Log Aggregation and Analysis Report - $(Get-Date)`n"
    $report += "--------------------------------------------------`n"
    $report += "Total Errors Found: $errorCount`n"
    $report += "Total Warnings Found: $warningCount`n"

    # Include the error/warning messages in the report
    $report += "`nError Messages:`n"
    $report += ($errorMessages | Select-Object -First 5) -join "`n"
    $report += "`nWarning Messages:`n"
    $report += ($warningMessages | Select-Object -First 5) -join "`n"

    # Save the report
    $reportPath = Join-Path -Path $logDirectory -ChildPath "VMware_Log_Analysis_Report.txt"
    $report | Out-File -FilePath $reportPath

    Write-Host "Log analysis complete. Report saved to $reportPath."

    # Return the count of errors and warnings to be used for alerting
    return [PSCustomObject]@{
        Errors   = $errorCount
        Warnings = $warningCount
    }
}

# Function to send an email alert if critical errors or warnings are found
function Send-Alert {
    param (
        [Parameter(Mandatory = $true)]
        $ErrorCount,
        [Parameter(Mandatory = $true)]
        $WarningCount
    )

    # Check if errors or warnings exceed the threshold
    if ($ErrorCount -ge $errorThreshold) {
        $subject = "Critical VMware Log Alert: Errors Detected"
        $body = "Critical errors have been detected in the VMware logs. Please review the logs immediately."
        Send-MailMessage -To $emailRecipient -From "vmware-alerts@example.com" -Subject $subject -Body $body -SmtpServer $smtpServer
        Write-Host "Critical error alert sent to $emailRecipient."
    }

    if ($WarningCount -ge $warningThreshold) {
        $subject = "VMware Log Warning Alert: Warnings Detected"
        $body = "Warnings have been detected in the VMware logs. Please review the logs for potential issues."
        Send-MailMessage -To $emailRecipient -From "vmware-alerts@example.com" -Subject $subject -Body $body -SmtpServer $smtpServer
        Write-Host "Warning alert sent to $emailRecipient."
    }
}

# Function to automate the entire log aggregation, analysis, and alerting process
function Run-LogAggregationAndAnalysis {
    Write-Host "Starting VMware Log Aggregation and Analysis..."

    # Aggregate logs from all ESXi hosts
    Aggregate-VMwareLogs

    # Analyze the logs for errors or warnings
    $logAnalysisResults = Analyze-Logs

    # Send alerts if critical errors or warnings are found
    Send-Alert -ErrorCount $logAnalysisResults.Errors -WarningCount $logAnalysisResults.Warnings

    Write-Host "Log aggregation and analysis completed."
}

# Run the log aggregation and analysis process
Run-LogAggregationAndAnalysis

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "VMware Log Aggregator and Analyzer completed."
