# PowerShell script for VMware VDI (Virtual Desktop Infrastructure) Provisioning Automation
# Prerequisites: VMware PowerCLI and VMware Horizon PowerShell modules installed

# Connect to vCenter and Horizon Server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$horizonServer = "horizon.example.com" # VMware Horizon server
$horizonUsername = "admin@vsphere.local"
$horizonPassword = "password"
$desktopPoolName = "VDI-DesktopPool"  # Name of the desktop pool
$desktopTemplate = "Windows-10-Template"  # Template to use for provisioning
$userGroup = "VDI-Users"  # User group for assigning desktops
$numberOfDesktops = 10  # Number of desktops to provision

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Connect to VMware Horizon Server
Add-PSSnapin VMware.VimAutomation.Horizon
Connect-HVServer -Server $horizonServer -User $horizonUsername -Password $horizonPassword

# Function to create and configure desktop pool
function Create-DesktopPool {
    Write-Host "Creating desktop pool: $desktopPoolName..."

    # Create a new desktop pool based on the template
    New-HVPool -Name $desktopPoolName -PoolType "Automated" -DesktopTemplate $desktopTemplate -MaxNumberOfDesktops $numberOfDesktops

    # Configure the desktop pool settings
    Set-HVPool -Name $desktopPoolName -UserGroup $userGroup -Confirm:$false
    Write-Host "Desktop pool $desktopPoolName created and configured with user group $userGroup."
}

# Function to provision virtual desktops
function Provision-VirtualDesktops {
    Write-Host "Provisioning $numberOfDesktops desktops for pool: $desktopPoolName..."

    for ($i = 1; $i -le $numberOfDesktops; $i++) {
        $desktopName = "$desktopPoolName-Desktop$i"
        
        # Provision a virtual desktop for the pool
        New-HVDesktop -PoolName $desktopPoolName -DesktopName $desktopName -Confirm:$false
        Write-Host "Provisioned desktop $desktopName."
    }
}

# Function to configure user profiles for the desktop pool
function Configure-UserProfiles {
    Write-Host "Configuring user profiles for desktop pool: $desktopPoolName..."
    
    # Example: Set up a user profile for all users in the pool
    $userProfiles = Get-HVUserProfile -UserGroup $userGroup
    foreach ($userProfile in $userProfiles) {
        Set-HVUserProfile -UserProfile $userProfile -ProfileType "Roaming" -Confirm:$false
        Write-Host "Configured roaming profile for user: $($userProfile.UserName)"
    }
}

# Function to automate desktop assignment
function Assign-DesktopsToUsers {
    Write-Host "Assigning desktops to users in group: $userGroup..."

    $users = Get-HVUser -UserGroup $userGroup

    for ($i = 0; $i -lt $users.Count; $i++) {
        $desktopName = "$desktopPoolName-Desktop$($i + 1)"
        $user = $users[$i]

        # Assign desktop to user
        Set-HVUserDesktop -User $user -DesktopName $desktopName -Confirm:$false
        Write-Host "Assigned desktop $desktopName to user $($user.UserName)"
    }
}

# Run provisioning and configuration tasks
Create-DesktopPool
Provision-VirtualDesktops
Configure-UserProfiles
Assign-DesktopsToUsers

# Disconnect from vCenter and Horizon Server
Disconnect-VIServer -Server $vcServer -Confirm:$false
Disconnect-HVServer -Server $horizonServer -Confirm:$false

Write-Host "VDI provisioning and configuration completed."
