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
    }
}