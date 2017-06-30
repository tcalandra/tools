#===========================================================================
#Software Deployment Automation
#Author Thomas Calandra
#Date 01/12/2017
#Modified 06/30/2017 for GitHUB
#===========================================================================

# Set working location to the PSdrive for sitecode
Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location #based on sitecode

# Function to get deployment dates and deadlines
function getDates() {
    Write-Host "
======Enter Dates for Deployment and Deadline======" -ForegroundColor Magenta

    #set variable to start of maintenace window because MW is 2am 
    $start_time = [DateTime]::ParseExact("02:00", "hh:mm", $null)
    $start_time = $start_time.AddDays(1)
    #assign local variable to script variable for deployment day
    $script:depDay = $start_time
    write-host "depDay = $script:depDay"
    #assign local variable to script variable for deployment time (Software Updates still use a Time and Day variable seperated)
    $script:depTime = $start_time
    write-host "depTime = $script:depTime"
    $time_window = [DateTime]::ParseExact("02:15", "hh:mm", $null)
    $time_window = $time_window.AddDays(1)
    #assing local variable to script variable for deadline day
    $script:deadlineDay = $time_window
    write-host "deadlineDay = $script:deadlineDay"
    #assign local variable to script variable for deadline time (Software Updates still use a Time and Day variable seperated)
    $script:deadlineTime = $time_window
    write-host "deadlineTime = $script:deadlineTime"
    
    # prompt to check if deployment dates are set properly
    [String]$script:dateTimeQ = read-host -Prompt "Enter Y or N based on date times above"
    if (!($script:dateTimeQ.Equals("y") -or $script:dateTimeQ.Equals("Y"))) { 
    
        # prompt for deployment day
        [String]$script:depDay = read-host -Prompt "Enter Deployment Day (MM DD YYYY)"
        $depDayBool = [DateTime]::TryParseExact($script:depDay, 'MM dd yyyy', [System.Globalization.CultureInfo]::CurrentCulture, [System.Globalization.DateTimeStyles]::None, [ref]$script:depDay)
        if (!$depDayBool) { 
            Write-Host "Invalid DateTime"
            Exit
        }
        else {
            Write-Host "depDay is $script:depDay"
        }
 
        # prompt for deployment time
        [String]$script:depTime = read-host -Prompt "Enter Deployment Time (HH:mm)"
        $depTimeBool = [DateTime]::TryParseExact($script:depTime, 'HH:mm', [System.Globalization.CultureInfo]::CurrentCulture, [System.Globalization.DateTimeStyles]::None, [ref]$script:depTime)
        if (!$depTimeBool) { 
            Write-Host "Invalid DateTime"
            Exit
        }
        else {
            Write-Host "deploymentTime is $script:depTime"
        }
        # prompt for deployment deadline
        [String]$script:deadlineDay = read-host -Prompt "Enter Deployment Deadline Day (MM DD YYYY)"
        $deadlineDayBool = [DateTime]::TryParseExact($script:deadlineDay, 'MM dd yyyy', [System.Globalization.CultureInfo]::CurrentCulture, [System.Globalization.DateTimeStyles]::None, [ref]$script:deadlineDay)
        if (!$deadlineDayBool) { 
            Write-Host "Invalid DateTime"
            Exit
        }
        else {
            Write-Host "deadlineDay is $script:deadlineDay"
        }

        # prompt for deployment deadline
        [String]$script:deadlineTime = read-host -Prompt "Enter Deployment Deadline (HH:mm)"
        $deadlineTimeBool = [DateTime]::TryParseExact($script:deadlineTime, 'HH:mm', [System.Globalization.CultureInfo]::CurrentCulture, [System.Globalization.DateTimeStyles]::None, [ref]$script:deadlineTime)
        if (!$deadlineTimeBool) { 
            Write-Host "Invalid DateTime"
            Exit
        }
        else {
            Write-Host "deadlineTime is $script:deadlineTime"
        }
    }
}

# Function to set key value pairs for menu based script
# Uses hash tables with numbers as keys and values as SCCM objects for script
# each menu task calls this function

function getSupVariables() {
    # create hash table for Software Update Groups
    $script:supGroupTable = $null
    $script:supGroupTable = @{}
    # populate hash table for Softwar Update Groups
    $supGroup = Get-CMSoftwareUpdateGroup | select -Expandproperty LocalizedDisplayName
    $key1 = 1
    foreach ($supGroupName in $supGroup) {
        $script:supGroupTable.Add($key1, $supGroupName)
        $key1 = $key1 + 1
    }

}

function setSupVariables() {
    # display hash table for Softwar Update Groups
    Write-Host "
Available Software Update Groups are listed below.
Please enter the number for the desired group when prompted" -ForegroundColor Magenta
    $script:supGroupTable.GetEnumerator() | Sort-Object Value | Format-Table -AutoSize
    $supSelection = Read-Host -Prompt "Please Enter Software Update Group number"
    $script:supGroupName = $script:supGroupTable.get_Item([int]$supSelection)
    # debug testing for correct selection key and value pair
    Write-Debug "supGroupName is $script:supGroupName"
    # prompt for deployment name
    $script:depName = Read-Host -Prompt "Please Enter Deployment Name"
    Write-Debug "depName is $script:depName"
}


# Function Menu for Software Updates
function setupSoftwareUpdates() {
    <#
Do {
    Write-Host "
======Select Deployment Method======
        1 - Desktop
        2 - Laptop
        3 - Special
====================================" -ForegroundColor Magenta

$method = Read-Host -Prompt "Enter number for the deployment method"
} until ($method -eq "1" -or $method -eq "2" -or $method -eq "3")
#>
#### This queries our colelctions base don the names I want to deploy to
####
    if ($script:colName -ieq "Test - SCCM Software Updates") {$method = "1"};
    if ($script:colName -ilike "*Laptops*") {$method = "2"};
    if ($script:colName -ilike "*No Sleep*") {$method = "3"};
    if ($script:colName -ilike "*Temp*") {$method = "3"};

    Switch ($method) {

        "1" {
            # call set variables function
            setSupVariables
            # deployment settings for Maintenance Window
            Write-Debug "Deployment Settings for Desktops"
            Start-CMSoftwareUpdateDeployment -DeploymentName $script:depName `
    -SoftwareUpdateGroupName $script:supGroupName `
    -CollectionName $script:colName -VerbosityLevel OnlySuccessAndErrorMessages `
    -DeploymentType Required -UserNotification DisplayAll -TimeBasedOn LocalTime `
    -DeploymentAvailableDay $script:depDay -DeploymentAvailableTime $script:depTime `
    -DeploymentExpireDay $script:deadlineDay -DeploymentExpireTime $script:deadlineTime `
    -AcceptEula -SendWakeupPacket $True -RestartWorkstation $True `
    -AllowUseMeteredNetwork $True -DownloadFromMicrosoftUpdate $True `
    -RestartServer $True -AllowRestart $False `
    -GenerateSuccessAlert $True -PercentSuccess 75 -TimeValue 7 -TimeUnit Days
            areYouSure
        }
        "2" {
            # call set variables function
            setSupVariables
            # deployment settings for Laptops
            Write-Debug "Deployment Settings for Laptops"
            Start-CMSoftwareUpdateDeployment -DeploymentName $script:depName `
    -SoftwareUpdateGroupName $script:supGroupName `
    -CollectionName $script:colName -VerbosityLevel OnlySuccessAndErrorMessages `
    -DeploymentType Required -UserNotification DisplayAll -TimeBasedOn LocalTime `
    -DeploymentAvailableDay $script:depDay -DeploymentAvailableTime $script:depTime `
    -DeploymentExpireDay $script:deadlineDay -DeploymentExpireTime $script:deadlineTime `
    -AcceptEula -SendWakeupPacket $True -RestartWorkstation $True `
    -RestartServer $True -AllowRestart $True `
    -PersistOnWriteFilterDevice $True -AllowUseMeteredNetwork $True `
    -SoftwareInstallation $True -DownloadFromMicrosoftUpdate $True `
    -GenerateSuccessAlert $True -PercentSuccess 75 -TimeValue 7 -TimeUnit Days
            areYouSure
        }
        "3" {
            # call set variables function
            setSupVariables
            # deployment settings for Maintenance Window
            Write-Debug "Deployment Settings for Special Cases"
            Start-CMSoftwareUpdateDeployment -DeploymentName $script:depName `
    -SoftwareUpdateGroupName $script:supGroupName `
    -CollectionName $script:colName -VerbosityLevel OnlySuccessAndErrorMessages `
    -DeploymentType Required -UserNotification DisplayAll -TimeBasedOn LocalTime `
    -DeploymentAvailableDay $script:depDay -DeploymentAvailableTime $script:depTime `
    -DeploymentExpireDay $script:deadlineDay -DeploymentExpireTime $script:deadlineTime `
    -AcceptEula -SendWakeupPacket $True -RestartWorkstation $True `
    -AllowUseMeteredNetwork $True -DownloadFromMicrosoftUpdate $True `
    -RestartServer $True -AllowRestart $False `
    -GenerateSuccessAlert $True -PercentSuccess 75 -TimeValue 7 -TimeUnit Days
            areYouSure
        }
    }
}

function getAppVariables() {
    # create hash table for Appliactions to deploy
    $script:appGroupTable = $null
    $script:appGroupTable = @{}
    # populate hash table for Softwar Update Groups
    # These queries are based on items we are doing as 3rd party group updates in future I would like to make this easier and more robost.
    $fGroup = Get-CMApplication -Name *firefox* | select -Expandproperty LocalizedDisplayName
    $jGroup = Get-CMApplication -Name *java* | select -Expandproperty LocalizedDisplayName
    $cGroup = Get-CMApplication -Name *chrome* | select -Expandproperty LocalizedDisplayName
    $iGroup = Get-CMApplication -Name *itunes* | select -Expandproperty LocalizedDisplayName
    $aGroup = Get-CMApplication -Name *acrobat* | select -ExpandProperty LocalizedDisplayName
    $afGroup = Get-CMApplication -Name *Flash* | select -ExpandProperty LocalizedDisplayName
    $appGroup = $fGroup + $jGroup + $cGroup + $iGroup + $agroup + $afGroup
    $key3 = 1
    foreach ($appGroupName in $appGroup) {
        $script:appGroupTable.Add($key3, $appGroupName)
        $key3 = $key3 + 1
    }
}

function setAppVariables() {
    # display hash table for Softwar Update Groups
    Write-Host "
Available 3rd Party Applications are listed below.
Please enter the number for the desired group when prompted" -ForegroundColor Magenta
    $script:appGroupTable.GetEnumerator() | Sort-Object Value | Format-Table -AutoSize
    # prompt for Application Selection
    $appSelection = Read-Host -Prompt "Please Enter Application number"
    $script:appGroupName = $script:appGroupTable.get_Item([int]$appSelection)
    # debug testing for correct selection key and value pair
    Write-Debug "appGroupName is $script:appGroupName"
}

function setupApplications() {
    <#
    Do {
        Write-Host "
======Select Deployment Method======
        1 - Desktop
        2 - Laptop
        3 - Special
====================================" -ForegroundColor Magenta

    $method = Read-Host -Prompt "Enter number for the deployment method"
    } until ($method -eq "1" -or $method -eq "2" -or $method -eq "3")
#>
    if ($script:colName -ieq "Test - SCCM Software Updates") {$method = "1"};
    if ($script:colName -ilike "*Laptops*") {$method = "2"};
    if ($script:colName -ilike "*No Sleep*") {$method = "3"};
    if ($script:colName -ilike "*Temp*") {$method = "3"};

    Switch ($method) {
        "1" {
            # call set variables function
            setAppVariables
            Start-CMApplicationDeployment -CollectionName $script:colName -DeployPurpose Required `
    -Name $script:appGroupName -AvailableDateTime $script:depDay `
    -DeadlineDateTime $script:deadlineDay -TimeBaseOn LocalTime -DeployAction Install `
    -PersistOnWriteFilterDevice $True -PreDeploy $True -RebootOutsideServiceWindow $False `
    -UserNotification DisplayAll -UseMeteredNetwork $True  -SendWakeupPacket $True
            areYouSure
        }
        "2" {
            # call set variables function
            setAppVariables
            Start-CMApplicationDeployment -CollectionName $script:colName -DeployPurpose Required `
    -Name $script:appGroupName -AvailableDateTime $script:depDay `
    -DeadlineDateTime $script:deadlineDay -TimeBaseOn LocalTime -DeployAction Install `
    -PersistOnWriteFilterDevice $True -PreDeploy $True -RebootOutsideServiceWindow $False `
    -UserNotification DisplayAll -UseMeteredNetwork $True  -SendWakeupPacket $True -OverrideServiceWindow $True
            areYouSure
        }
        "3" {
            # call set variables function
            setAppVariables
            Start-CMApplicationDeployment -CollectionName $script:colName -DeployPurpose Required `
    -Name $script:appGroupName -AvailableDateTime $script:depDay `
    -DeadlineDateTime $script:deadlineDay -TimeBaseOn LocalTime -DeployAction Install `
    -PersistOnWriteFilterDevice $True -PreDeploy $True -RebootOutsideServiceWindow $False `
    -UserNotification DisplayAll -UseMeteredNetwork $True  -SendWakeupPacket $True
            areYouSure
        }
    }
}

# Collection Selection Menu
function getCollections() {
    # create hash table for Software Update Collections
    $script:colGroupTable = $null
    $script:colGroupTable = @{}
    # populate hash table for Software Update Collections
    $colGroup = Get-CMCollection -Name *Softw* | select -ExpandProperty Name
    $key4 = 1
    ForEach ($colName in $colGroup) {
        $script:colGroupTable.Add($key4, $colName)
        $key4 = $key4 + 1
        
    }    
}

function setCollections() {
    # display hash table for Software Update Collections
    Write-Host "
Target Collections listed below.
Please enter the number of the desired collection when prompted" -ForegroundColor Magenta
    $script:colGroupTable.getEnumerator() | Sort-Object Value | Format-Table -AutoSize
    # prompt for Collection Selection
    $colSelection = Read-Host -Prompt "Please Enter Collection number"
    $script:colName = $script:colGroupTable.get_Item([int]$colSelection)
    # debug testing for correct selection key and value pair
    Write-Debug "colName is $script:colName"
    # call get deployment function
    getDeployment
}

# Deployment Type Menu
function getDeployment() {
    Do {    
        Write-Host "
======Select Deployment Type========
        1 - Application
        2 - Software Update
====================================" -ForegroundColor Magenta

        $type = Read-Host -Prompt "Enter number for the deployment type"
    }
    until ($type -eq "1" -or $type -eq "2")

    Switch ($type) {

        "1" {
            Write-Debug "Application Deployment"
            # call functions
            setupApplications
        }
        "2" {
            Write-Debug "Software Update Deployment"
            # call functions
            setupSoftwareUpdates
        }
    }
}
# Continue or quit menu
function areYouSure() {
    Do {    
        Write-Host "
======Select Next Action================
        1 - Application Deploy
        2 - Software Update Deploy
        3 - Select another Collection
        4 - Exit (Re - Run if new dates)
========================================" -ForegroundColor Magenta

        $type = Read-Host -Prompt "Enter number correlating to the task"
    }
    until ($type -eq "1" -or $type -eq "2" -or $type -eq "3" -or $type -eq "4")

    Switch ($type) {

        "1" {
            Write-Debug "Application Deployment"
            # call functions
            setupApplications
        }
        "2" {
            Write-Debug "Software Update Deployment"
            # call functions
            setupSoftwareUpdates
        }
        "3" {
            # select colelction
            setCollections
        }
        "4" {
            # exit script
            # rocket
            Exit
        }
    }
}

# Main menu
function main() {
    getDates
    getCollections
    getAppVariables
    getSupVariables
    setCollections
}

#==========================#
#### Call Main Function ####
#==========================#
main
