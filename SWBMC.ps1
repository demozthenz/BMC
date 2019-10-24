#Swimage Boot Media Creator v2.0

#Elevate to admin if not running as already 
#if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Begin{
#Menus
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$SWBMC                           = New-Object system.Windows.Forms.Form
$SWBMC.ClientSize                = '533,454'
$SWBMC.text                      = "Swimage Boot Media Creator"
$SWBMC.TopMost                   = $false

$NewOnlineMedia                  = New-Object system.Windows.Forms.Button
$NewOnlineMedia.text             = "Create New Online Media"
$NewOnlineMedia.width            = 188
$NewOnlineMedia.height           = 45
$NewOnlineMedia.location         = New-Object System.Drawing.Point(212,394)
$NewOnlineMedia.Font             = 'Microsoft Sans Serif,10'

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Swimage Boot Media Creator (SWBMC) Must be Run with Elevated Prileges"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(15,26)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "with an FRP exception"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(15,44)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$Label3                          = New-Object system.Windows.Forms.Label
$Label3.text                     = ""
$Label3.AutoSize                 = $true
$Label3.width                    = 25
$Label3.height                   = 10
$Label3.location                 = New-Object System.Drawing.Point(15,63)
$Label3.Font                     = 'Microsoft Sans Serif,10'

$RemoveReadOnly                 = New-Object system.Windows.Forms.Button
$RemoveReadOnly.text            = "Remove Read-Only"
$RemoveReadOnly.width           = 188
$RemoveReadOnly.height          = 46
$RemoveReadOnly.location        = New-Object System.Drawing.Point(10,394)
$RemoveReadOnly.Font            = 'Microsoft Sans Serif,10'

$ExitTool                        = New-Object system.Windows.Forms.Button
$ExitTool.text                   = "Exit"
$ExitTool.width                  = 60
$ExitTool.height                 = 30
$ExitTool.location               = New-Object System.Drawing.Point(464,410)
$ExitTool.Font                   = 'Microsoft Sans Serif,10'

$ListDrives                      = New-Object system.Windows.Forms.DataGridView
$ListDrives.width                = 514
$ListDrives.height               = 200
$ListDrives.location             = New-Object System.Drawing.Point(10,84)

$DriveSelect                     = New-Object system.Windows.Forms.ComboBox
$DriveSelect.width               = 100
$DriveSelect.height              = 20
$DriveSelect.location            = New-Object System.Drawing.Point(10,303)
$DriveSelect.Font                = 'Microsoft Sans Serif,10'

$Label4                          = New-Object system.Windows.Forms.Label
$Label4.text                     = "Select a drive from the dropdown and select an option below."
$Label4.AutoSize                 = $true
$Label4.width                    = 25
$Label4.height                   = 10
$Label4.location                 = New-Object System.Drawing.Point(10,338)
$Label4.Font                     = 'Microsoft Sans Serif,12'

$ReadOnlyCheck                   = New-Object system.Windows.Forms.CheckBox
$ReadOnlyCheck.text              = "Read Only"
$ReadOnlyCheck.AutoSize          = $false
$ReadOnlyCheck.width             = 110
$ReadOnlyCheck.height            = 20
$ReadOnlyCheck.location          = New-Object System.Drawing.Point(124,307)
$ReadOnlyCheck.Font              = 'Microsoft Sans Serif,11'

$RefreshDrives                   = New-Object system.Windows.Forms.Button
$RefreshDrives.text              = "Refresh"
$RefreshDrives.width             = 85
$RefreshDrives.height            = 30
$RefreshDrives.location          = New-Object System.Drawing.Point(439,294)
$RefreshDrives.Font              = 'Microsoft Sans Serif,10'

$SWBMC.controls.AddRange(@($NewOnlineMedia,$Label1,$Label2,$Label3,$RemoveReadOnly,$ExitTool,$ListDrives,$DriveSelect,$Label4,$ReadOnlyCheck,$RefreshDrives))

$NewOnlineMedia.Add_Click({ 
    formatdisk
    CreateOnlineMedia
 })

 #This is hella broken, dawg. Make it remove read only from the disk.
$RemoveReadOnly.Add_Click({ 
    removereadonly
 })

$DriveSelect.Add_DropDown({  })

$RefreshDrives.Add_Click({  
    refreshdrivelist
})

$ExitTool.Add_Click({ 
    leavescript
})






#Supporting Functions

function refreshdrivelist{
    $Script:drivetable = New-Object System.Collections.ArrayList
    $drives = get-disk | Where-Object BusType -eq USB | get-partition | get-volume

    get-disk | Where-Object BusType -eq USB | get-partition | get-volume | % {$Null = $Script:drivetable.Add((New-Object -TypeName psobject -property @{
        'Drive Letter'=$_.DriveLetter;
        'Size (GB)'=[math]::round(($_.Size / 1GB),2);
        'Drive Type'=$_.DriveType;
        
        })
    )}
    $ListDrives.DataSource = $Script:drivetable

    $DriveSelect.Items.Clear()
    foreach ($d in $drives){
        $DriveSelect.Items.Add($d.DriveLetter)
    }
}

function formatdisk{
    $driveLetter = $driveSelect.SelectedItem
    $disknumber = (Get-Volume -DriveLetter $driveletter | Get-Partition | Get-Disk).Number
    $rocheck = (get-disk $disknumber).IsReadOnly
    Write-Host "Checking for Read only..."
    if ($rocheck){
        Write-Host "Disk is Read Only."
        Set-Disk $disknumber -IsReadOnly $false
        Write-Host "Read only has been removed."
    }
    else{
        Write-Host "Disk is NOT Read Only"
    }
    Write-Host "Disk is being formatted..."
    Get-Disk $disknumber | Clear-Disk -RemoveData -Confirm:$false
    New-Partition -DiskNumber $disknumber -UseMaximumSize -IsActive -DriveLetter $driveLetter | Format-Volume -FileSystem FAT32 -NewFileSystemLabel Swim_Deploy
    
    Write-Host "Disk is formatted for Swimage."
}

function makereadonly {
    $driveLetter = $driveSelect.SelectedItem
    $disknumber = (Get-Volume -DriveLetter $driveletter | Get-Partition | Get-Disk).Number
    if ($ReadOnlyCheck.Checked -eq $true){
        Set-Disk $disknumber -IsReadOnly $true
        Write-Host "Disk has been made read-only."
    }
    else {
        Write-Host "Disk is HAS NOT been made read only."
    }
        
}

function removereadonly {
    $driveLetter = $driveSelect.SelectedItem
    $disknumber = (Get-Volume -DriveLetter $driveletter | Get-Partition | Get-Disk).Number
    Set-Disk $disknumber -IsReadOnly $false
    Write-Host "Disk is no longer read-only"
}

function createonlinemedia{
    #Write-Host $DriveSelect.SelectedItem
    $writePath = $DriveSelect.SelectedItem + ":\"
    $NetworkISO = gci \\scrubbed\path2 | Where-Object Name -Like "Network Deploy Media*.ISO" | sort LastWriteTime | Select -last 1
    Write-Host "Extracting ISO to $driveletter" + ":\"
    \\Scrubbed\path\max_c\tools\7z\7-Zip\7zG.exe x -y \\scrubbed\path2\$NetworkISO  "-o$writePath"
    Wait-Process -Name 7zG

    \\scrubbed\path\max_c\Scripts

    makereadonly
}

function createofflinemedia{
    Write-Host "This is in development..."
}

function leavescript{
    $SWBMC.Close()
}

refreshdrivelist
[void]$SWBMC.ShowDialog()

}  #End of Begin Block
