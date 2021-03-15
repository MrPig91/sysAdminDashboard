function Start-ComputerScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Computer
    )

    Process{
        #Create Cim Session
        try{
            $Session = New-CimSession -ComputerName $Computer.ComputerName -OperationTimeoutSec 1 -ErrorAction Stop
        }
        catch{
            try{
                $Session = New-CimSession -ComputerName $Computer.ComputerName -OperationTimeoutSec 1 -SessionOption (New-CimSessionOption -Protocol Dcom)
            }
            catch{
                return
            }
        }

        #Get Disk Info
        try{
            $DiskInfo = Get-CimInstance -Class win32_logicalDisk  -filter "drivetype=3 AND DeviceID='C:'" -CimSession $Session
            $DiskInfoClass = [DiskInfo]::new([math]::Round($diskInfo.size / 1gb,2),[math]::Round($diskInfo.FreeSpace / 1gb,2))
            $DiskInfoClass.HasData = $true
            $Computer.DiskInfo = $DiskInfoClass
        }
        catch{
            Write-Information "Unable to grab disk info."
        }

         try{
            $loggedinUsers = Get-pmLoggedInUser -ComputerName $computer.ComputerName
            $loggedinuserList = New-Object System.Collections.ObjectModel.ObservableCollection[System.Object]
            [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($loggedinuserList, [System.Object]::new())
            foreach ($user in $LoggedinUsers){
                $loggedinuserList.Add($user)
            }
            $Computer.LoggedInUser = $loggedinuserList
        }
        catch{
            Write-Information "Unable to grab logged in users"
        }

        #Computer Spec Groupbox
        try{
            $Bios = Get-CimInstance -ClassName Win32_BIOS -CimSession $Session
            $HardwareInfo = Get-CimInstance -Class win32_computersystem -CimSession $Session -Property TotalPhysicalMemory,Model,Name,Manufacturer,SystemSKUNumber,UserName |
                    Select-Object -Property @{n="RAM";e={$_.TotalPhysicalMemory / 1gb -as [int]}},Manufacturer,name,Model,SystemSKUNumber,Username
            $OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $Session -Property LastBootUpTime,Version
            $Processor = Get-CimInstance -Query "Select Name from win32_Processor" -CimSession $Session

            $Uptime = (Get-Date) - $OperatingSystem.LastBootUpTime
            if ($Uptime.Days -eq 0){
                $Uptime = $Uptime.ToString("hh' hours 'mm' minutes'")
            }
            else{
                $Uptime = $Uptime.ToString("dd' days 'hh' hours'")
            }
            
            $overview = [PSCustomObject]@{
                Bios = $Bios
                TotalRAM = $HardwareInfo.RAM
                Model = $HardwareInfo.Model
                Manufacturer = $HardwareInfo.Manufacturer
                CurrentUser = $HardwareInfo.UserName
                SKUNumber = $HardwareInfo.SystemSKUNumber
                LastBootUpTime = $OperatingSystem.LastBootUpTime.ToString("MM/dd/yy")
                Uptime = $Uptime
                Processor = $Processor.Name
            }

            $Computer.Overview = $overview
        }
        catch{
            Show-MessageBox "Unable to grab Computer Spec Info`n$($Error.Exception)"
        }
    }
}