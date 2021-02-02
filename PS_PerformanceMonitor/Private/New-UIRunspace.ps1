function New-UIRunspace{
    [powershell]::Create().AddScript{
        $ErrorActionPreference = "Stop"
        Add-Type -AssemblyName PresentationFramework
        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {Add-Type -Path $_.FullName}

        Try{
            $XAMLPath = Join-Path -Path $DataHash.WPF -ChildPath MainWindow.xaml
            $MainWindow = Import-Xaml -Path $XAMLPath
            $UIHash.MainWindow = $MainWindow

            #Tabs
            $UIHash.MainTablControl = $MainWindow.FindName("MainTabControl")
            $UIHash.CPUTabPage = $MainWindow.FindName("CPUTabPage")

            #Buttons
            $UIHash.AddComputerButton = $MainWindow.FindName("AddComputerButton")
            $UIHash.SelectAllButton = $MainWindow.FindName("SelectAllButton")
            $UIHash.DeSelectAllButton = $MainWindow.FindName("DeSelectAllButton")
            $UIHash.RemoveSelectedButton = $MainWindow.FindName("RemoveSelectedButton")

            #Textboxes
            $UIHash.computerSearchbox = $MainWindow.FindName("computerSearchbox")
            $UIHash.ComputerSearchbox.IsEnabled = $false
            $UIHash.FilePathBox = $MainWindow.FindName("LogPathTextbox")
            $UIHash.FilePathBox.Text = "$ENV:USERPROFILE\Downloads"

            #Comboboxes
            $UIHash.CPUDefaultCounterComboBox = $MainWindow.FindName("defaultCPUCounterCombobox")
            $UIHash.CPUDefaultCounterComboBox.DisplayMemberPath = "FriendlyName"
            $UIHash.NetworkDefaultCounterComboBox = $MainWindow.FindName("defaultNetworkCounterCombobox")
            $UIHash.NetworkDefaultCounterComboBox.DisplayMemberPath = "FriendlyName"
            $UIHash.DiskDefaultCounterComboBox = $MainWindow.FindName("defaultDiskCounterCombobox")
            $UIHash.DiskDefaultCounterComboBox.DisplayMemberPath = "FriendlyName"
            $UIHash.MemoryDefaultCounterComboBox = $MainWindow.FindName("defaultMemoryCounterCombobox")
            $UIHash.MemoryDefaultCounterComboBox.DisplayMemberPath = "FriendlyName"
            $UIHash.ThermalsDefaultCountersCombo = $MainWindow.FindName("defaultThermalCounterCombobox")
            $UIHash.ThermalsDefaultCountersCombo.DisplayMemberPath = "FriendlyName"
            $ThermalsCounters = New-Object System.Collections.Generic.List[System.Object]
            $ThermalsCounters.ADD([PSCustomObject]@{
                Counter = "\Thermal Zone Information(*cpu*)\High Precision Temperature"
                FriendlyName = "(cpu)\High Precision Temperature"
            })
            $ThermalsCounters.Add([PSCustomObject]@{
                Counter = "\Thermal Zone Information(*)\High Precision Temperature"
                FriendlyName = "(*)\High Precision Temperature"
            })
            $UIHash.ThermalsDefaultCountersCombo.ItemsSource = $ThermalsCounters
            $UIHash.ThermalsDefaultCountersCombo.SelectedIndex = 0

            $ScriptsHash.DefaultCounters | foreach {$_.BeginInvoke()}


            #Listboxes
            $UIHash.computerListbox = $MainWindow.FindName("computerListbox")
            $DataHash.AllComputers = New-Object System.Collections.ObjectModel.ObservableCollection[System.Object]
            [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($DataHash.AllComputers, [System.Object]::new())
            $UIHash.ComputerListbox.ItemsSource = $DataHash.AllComputers
            $UIHash.ComputerListboxSelectedItems = $UIHash.ComputerListbox.SelectedItems
            $UIHash.computerListbox.DisplayMemberPath = "ComputerName"

            #ListViews
            $UIHash.ComputerListView = $MainWindow.FindName("ComputerListView")
            $DataHash.addedComputers =  New-Object System.Collections.ObjectModel.ObservableCollection[System.Object]
            [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($DataHash.addedComputers, [System.Object]::new())
            $UIHash.ComputerListView.ItemsSource = $DataHash.addedComputers
            $UIHash.ListgridView = $MainWindow.FindName("ListViewGrid")

            $ListViewColumnHeaderProperties = "ComputerName","IPAddress","OperatingSystem","SerialNumber"
            $ListViewColumnHeaderProperties | foreach {
                $gridViewColumn = [System.Windows.Controls.GridViewColumn]::new()
                $gridViewColumn.Header = $_
                $Binding = [System.Windows.Data.Binding]::new($_)
                $Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
                $gridViewColumn.DisplayMemberBinding = $Binding
                $UIHash.ListgridView.Columns.Add($gridViewColumn)
            }
            $UIHash.ComputerListView.View = $UIHash.ListgridView

            #Checkboxes
            $UIHash.EnabledCheckBox = $MainWindow.FindName("LogCheckbox")

            #Slider
            $UIHash.TimeIntervalSlider = $MainWindow.FindName("timeIntervalTrack")

            #Button Click Events
            $UIHash.AddComputerButton.ADD_Click({
                $ScriptsHash.Ping.BeginInvoke()
            })

            $UIHash.SelectAllButton.ADD_Click({
                foreach ($computer in $DataHash.addedComputers){
                    if (-not$Computer.IsChecked){
                        $Computer.IsChecked = $true
                    }
                }
            })
            
            $UIHash.DeSelectAllButton.ADD_Click({
                foreach ($computer in $DataHash.addedComputers){
                    if ($Computer.IsChecked){
                        $Computer.IsChecked = $false
                    }
                }
            })

            $UIHash.RemoveSelectedButton.ADD_Click({
                foreach ($computer in ($DataHash.addedComputers | where {$_.IsChecked})){
                    $DataHash.addedComputers.Remove($computer)
                }
            })
            
            #Launch App
            $UIHash.MainWindow.ShowDialog()
        }
        catch{
            [System.Windows.MessageBox]::Show($_.Exception.Message)
            #Show-Messagebox -Text $_.Exception.Message
        }
    }
}