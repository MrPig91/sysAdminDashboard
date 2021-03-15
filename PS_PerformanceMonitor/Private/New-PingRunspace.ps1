function New-PingRunspace {
    [powershell]::Create().AddScript{
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Add-Type -AssemblyName System.Windows.Forms
        foreach ($Computer in $UIHash.ComputerListboxSelectedItems){
            if (Test-Connection $computer.ComputerName -Count 1 -Quiet){
                $computer.Online = $true
                $computer.OnOrOff = "Online"
                $computer.IsChecked = $true
                if (-not$Computer.Scanned){
                    $computer.Scanned = $true
                    Start-ComputerScan -Computer $computer
                }
            }
            else{
                $computer.OnOrOff = "Offline"
                $computer.Online = $false
                $computer.IsChecked = $false
            }
            #$UIHash.ComputerOverview.Dispatcher.Invoke([action]{$UIHash.ComputerOverview.Items.Add($computer)})
        } #foreach computer
    }
}