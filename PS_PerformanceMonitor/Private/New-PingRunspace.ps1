function New-PingRunspace {
    [powershell]::Create().AddScript{
        Add-Type -AssemblyName System.Windows.Forms
        foreach ($Computer in $UIHash.ComputerListboxSelectedItems){
            if (Test-Connection $computer.ComputerName -Count 1 -Quiet){
                $computer.Online = $true
                $computer.IsChecked = $true
            }
            else{
                $computer.Online = $false
                $computer.IsChecked = $false
            }

            $DataHash.addedComputers.Add($Computer)

            $UIHash.MainWindow.Dispatcher.Invoke([action]{$UIHash.ComputerListView.Items.Refresh()},"Send")
        } #foreach computer
    }
}