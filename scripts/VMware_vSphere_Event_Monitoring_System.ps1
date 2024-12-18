# PowerShell script for VMware vSphere Event Monitoring System
# Prerequisites: VMware PowerCLI module installed

# Define vCenter connection credentials
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"

# Define email settings for notifications
$emailRecipient = "admin@example.com"
$smtpServer = "smtp.example.com"
$fromEmail = "vmware-alerts@example.com"
$subject = "vSphere Event Alert"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Function to send email notifications
function Send-EmailNotification {
    param (
        [string]$Message
    )

    try {
        Send-MailMessage -To $emailRecipient -From $fromEmail -Subject $subject -Body $Message -SmtpServer $smtpServer
        Write-Host "Alert email sent to $emailRecipient."
    }
    catch {
        Write-Host "Error sending email: $_"
    }
}

# Function to handle events and take action based on event type
function Monitor-vSphereEvents {
    Write-Host "Monitoring vSphere events..."

    # Retrieve the latest events from vCenter
    $events = Get-VIEvent -MaxSamples 100

    foreach ($event in $events) {
        # Log the event to console for tracking
        Write-Host "Event: $($event.EventType) - $($event.FullFormattedMessage)"

        # Define event types to take action on
        if ($event.EventType -eq "VmPoweredOnEvent") {
            Write-Host "VM powered on: $($event.Vm.Name)"
            # Action to take when a VM is powered on
            Send-EmailNotification -Message "VM $($event.Vm.Name) has been powered on at $(Get-Date)."
        }
        elseif ($event.EventType -eq "VmPoweredOffEvent") {
            Write-Host "VM powered off: $($event.Vm.Name)"
            # Action to take when a VM is powered off
            Send-EmailNotification -Message "VM $($event.Vm.Name) has been powered off at $(Get-Date)."
        }
        elseif ($event.EventType -eq "HostDisconnectedEvent") {
            Write-Host "Host disconnected: $($event.Host.Name)"
            # Action to take when a host is disconnected
            Send-EmailNotification -Message "Host $($event.Host.Name) has been disconnected at $(Get-Date)."
        }
        elseif ($event.EventType -eq "DatastoreLowSpaceEvent") {
            Write-Host "Datastore low space warning: $($event.Datastore.Name)"
            # Action to take when a datastore is low on space
            Send-EmailNotification -Message "Datastore $($event.Datastore.Name) is low on space at $(Get-Date). Please check the storage."
        }
        elseif ($event.EventType -eq "HostMaintenanceModeEvent") {
            Write-Host "Host entered maintenance mode: $($event.Host.Name)"
            # Action to take when a host enters maintenance mode
            Send-EmailNotification -Message "Host $($event.Host.Name) has entered maintenance mode at $(Get-Date)."
        }
        elseif ($event.EventType -eq "VmMigratedEvent") {
            Write-Host "VM migrated: $($event.Vm.Name)"
            # Action to take when a VM is migrated
            Send-EmailNotification -Message "VM $($event.Vm.Name) has been migrated at $(Get-Date)."
        }
        else {
            Write-Host "Unrecognized event: $($event.EventType)"
        }
    }
}

# Run the event monitoring system in a loop
while ($true) {
    Monitor-vSphereEvents
    Start-Sleep -Seconds 60  # Check every 60 seconds for new events
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false
Write-Host "vSphere event monitoring completed."
