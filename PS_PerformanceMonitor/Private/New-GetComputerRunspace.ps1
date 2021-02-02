function New-GetComputerRunspace {

    [powershell]::Create().AddScript{
        Add-Type -AssemblyName PresentationFramework
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}
        
        $ErrorActionPreference = "Stop"
        $AllComputers = New-Object System.Collections.ObjectModel.ObservableCollection[System.Object]
        try {
            $AllComputers = Get-ADComputer -Filter * -Properties IPv4Address,OperatingSystem,SerialNumber -ErrorAction Stop | select @{n="ComputerName";e={$_.Name}},@{n="IPAddress";e={$_.IPv4Address}},SerialNumber,OperatingSystem
            foreach ($computer in $AllComputers){
                $DataHash.AllComputers.Add($computer)
            }

            $UIHash.ComputerListbox.Dispatcher.Invoke([action]{$UIHash.ComputerListbox.ItemsSource = $DataHash.AllComputers})
            $UIHash.ComputerSearchBox.Dispatcher.Invoke([action]{$UIHash.ComputerSearchBox.IsEnabled = $true})
        }
        catch{
            Try{
                $SerialNumber = (Get-CimInstance -ClassName Win32_Bios).SerialNumber
                $OS = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
                try{
                    $IP =  (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred -PrefixOrigin Dhcp).IPAddress
                }
                catch{
                    $IP = $Null
                }
                $Computers = [ComputerListViewItem]::new($ENV:COMPUTERNAME,$OS,$IP,$SerialNumber,$true)
                $DataHash.AllComputers.Add($Computers)
                $UIHash.ComputerSearchBox.Dispatcher.Invoke([action]{$UIHash.ComputerSearchBox.IsEnabled = $true})
            }
            catch{
                Show-MessageBox -Text $_.Exception.Message -Icon Error -Title $_.Exception.GetType().BaseType
            }
        }
    }
}