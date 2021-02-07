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

                #Add All Events for Item Control UI Elements
               <#  $UIHash.MainWindow.Dispatcher.Invoke([action]{
                     $presenter = $UIHash.ComputerOverview.ItemContainerGenerator.ContainerFromIndex(0)

                    $UIHash.ADButton = $UIHash.ComputerOverview.ItemContainerGenerator.ContainerFromIndex(0).ContentTemplate.FindName("ADButton",$presenter)
                    $UIHash.LoggedInUsers = $UIHash.ComputerOverview.ItemContainerGenerator.ContainerFromIndex(0).ContentTemplate.FindName("LoggedInUsers",$presenter)
                    $UIHash.LogOffUserButton = $UIHash.ComputerOverview.ItemContainerGenerator.ContainerFromIndex(0).ContentTemplate.FindName("LogOffUserButton",$presenter)

                    $UIHash.ADButton.Add_MouseDoubleClick({
                        Show-Object $this
                    })

                    $UIHash.LoggedInUsers.ADD_SelectionChanged({
                        if ($_.AddedItems){
                            $DataHash.LoggedInUsersSelectedItem = $_.AddedItems
                            #$UIHash.LogOffUserButton.Dispatcher.Invoke([action]{$UIHash.LogOffUserButton.IsEnabled = $true})
                        }
                        else{
                            $UIHash.LogOffUserButton.IsEnabled = $false
                        }
                    })

                    $UIHash.LoggedInUsers.ADD_MouseDoubleClick({
                        try{
                            # launch user window
                        }
                        catch{
                            Show-Messagebox -Text $_.Exception.Message -Title "Double Click Logged In User Box Error" -Icon Error
                        }
                    })

                    $UIHash.LogOffUserButton.Add_Click({
                        try{
                            $DataHash.LoggedInUsersSelectedItem.LogOffUser()
                            $UIHash.LoggedInUser.Items.Remove($DataHash.LoggedInUsersSelectedItem)
                        }
                        catch{
                            Show-Messagebox -Text $_.Exception.Message -Title "Log Off User" -Icon Information
                        }
                    })

                }) #>
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