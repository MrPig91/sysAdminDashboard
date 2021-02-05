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
            $UIHash.CPUTabPage = $MainWindow.FindName("NetworkTabPage")
            $UIHash.CPUTabPage = $MainWindow.FindName("MemoryTabPage")
            $UIHash.CPUTabPage = $MainWindow.FindName("DiskTabPage")
            $UIHash.CPUTabPage = $MainWindow.FindName("ThermalTabPage")

            #Buttons
            $UIHash.AddComputerButton = $MainWindow.FindName("AddComputerButton")
            $UIHash.SelectAllButton = $MainWindow.FindName("SelectAllButton")
            $UIHash.DeSelectAllButton = $MainWindow.FindName("DeSelectAllButton")
            $UIHash.RemoveSelectedButton = $MainWindow.FindName("RemoveSelectedButton")
            $UIHash.FolderExplorerButton = $MainWindow.FindName("FolderExplorerButton")

            $UIHash.CPUStartButton = $MainWindow.FindName("cpuStartButton")
            $UIHash.CPUStopButton = $MainWindow.FindName("cpuStopButton")
            $UIHash.CPURemoveCountersButton = $MainWindow.FindName("cpuRemoveSelectedButton")

            $UIHash.NetworkStartButton = $MainWindow.FindName("NetworkStartButton")
            $UIHash.NetworkStopButton = $MainWindow.FindName("NetworkStopButton")
            $UIHash.NetworkRemoveCountersButton = $MainWindow.FindName("NetworkRemoveSelectedButton")

            $UIHash.MemoryStartButton = $MainWindow.FindName("MemoryStartButton")
            $UIHash.MemoryStopButton = $MainWindow.FindName("MemoryStopButton")
            $UIHash.MemoryRemoveCountersButton = $MainWindow.FindName("MemoryRemoveSelectedButton")

            $UIHash.DiskStartButton = $MainWindow.FindName("DiskStartButton")
            $UIHash.DiskStopButton = $MainWindow.FindName("DiskStopButton")
            $UIHash.DiskRemoveCountersButton = $MainWindow.FindName("DiskRemoveSelectedButton")

            $UIHash.ThermalStartButton = $MainWindow.FindName("ThermalStartButton")
            $UIHash.ThermalStopButton = $MainWindow.FindName("ThermalStopButton")
            $UIHash.ThermalRemoveCountersButton = $MainWindow.FindName("ThermalRemoveSelectedButton")

            #Textboxes
            $UIHash.computerSearchbox = $MainWindow.FindName("computerSearchbox")
            $UIHash.ComputerSearchbox.IsEnabled = $false
            $UIHash.FilePathBox = $MainWindow.FindName("LogPathTextbox")
            $UIHash.FilePathBox.Text = "$ENV:USERPROFILE\Downloads"

            #Textbox Actions
            $UIHash.computerSearchbox.ADD_TextChanged({
                $DataHash.FilteredComputers.Clear()
                if ($_.Source.Text.Length -ge 1){
                    $DataHash.AllComputers | where ComputerName -like "$($_.Source.Text)*" | foreach {
                        $DataHash.FilteredComputers.Add($_)
                    }
                }
                else{
                    $DataHash.AllComputers | foreach {
                        $DataHash.FilteredComputers.Add($_)
                    }
                }
            })

            #Item Control
            $UIHash.ComputerOverview = $MainWindow.FindName("ComputerOverview")

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
            $UIHash.ThermalsDefaultCountersCombo.ToolTip = "The Thermal Zone Information performance counter set consists of counters that measure aspects of each thermal zone in
            the system."

            $ScriptsHash.DefaultCounters | foreach {$_.BeginInvoke()}

            #line color comboboxes
            $allColors = ([System.Windows.Media.Colors] | Get-Member -Static -MemberType Properties).Name

            $UIHash.CPUCombo = $MainWindow.FindName("cpuLineColor")
            $UIHash.CPUCombo.ItemsSource = $allColors
            $UIHash.CPUCombo.ADD_SelectionChanged({
                if ($UIHash.CPUListView.SelectedItem -ne $null -and $UIHash.CPUListView.SelectedItem.LineColor -ne $UIHash.CPUCombo.SelectedItem){
                    try{
                        $UIHash.CPUListView.SelectedItem.LineColor = $UIHash.CPUCombo.SelectedItem

                        $Index = ($DataHash.CPUSeriesCollectionTitles | where Title -eq $UIHash.CPUListView.SelectedItem.Name).Index
                        $CloneStrokeColor = $UIHash.CPUChartSeries[$Index].Stroke.Clone()
                        $CloneFillColor = $UIHash.CPUChartSeries[$Index].Fill.Clone()
                        $CloneFillColor.Color = [System.Windows.Media.Colors]::($UIHash.CPUCombo.SelectedItem)
                        $UIHash.CPUChartSeries[$Index].Fill = $CloneFillColor
                        $CloneStrokeColor.Color = [System.Windows.Media.Colors]::($UIHash.CPUCombo.SelectedItem)
                        $UIHash.CPUChartSeries[$Index].Stroke = $CloneStrokeColor
                    }
                    catch{
                        Show-Messagebox -Title "Color Change Error" -Text $_.Exception.Message -Icon Error
                    }
                }
            })

            $UIHash.NetworkCombo = $MainWindow.FindName("NetworkLineColor")
            $UIHash.NetworkCombo.ItemsSource = $allColors
            $UIHash.NetworkCombo.ADD_SelectionChanged({
                if ($UIHash.NetworkListView.SelectedItem -ne $null -and $UIHash.NetworkListView.SelectedItem.LineColor -ne $UIHash.NetworkCombo.SelectedItem){
                    Try{
                        $UIHash.NetworkListView.SelectedItem.LineColor = $UIHash.NetworkCombo.SelectedItem

                        $Index = ($DataHash.NetworkSeriesCollectionTitles | where Title -eq $UIHash.NetworkListView.SelectedItem.Name).Index
                        $CloneStrokeColor = $UIHash.NetworkChartSeries[$Index].Stroke.Clone()
                        $CloneFillColor = $UIHash.NetworkChartSeries[$Index].Fill.Clone()
                        $CloneFillColor.Color = [System.Windows.Media.Colors]::($UIHash.NetworkCombo.SelectedItem)
                        $UIHash.NetworkChartSeries[$Index].Fill = $CloneFillColor
                        $CloneStrokeColor.Color = [System.Windows.Media.Colors]::($UIHash.NetworkCombo.SelectedItem)
                        $UIHash.NetworkChartSeries[$Index].Stroke = $CloneStrokeColor
                    }
                    catch{
                        Show-Messagebox -Title "Color Change Error" -Text $_.Exception.Message -Icon Error
                    }
                }
            })

            $UIHash.MemoryCombo = $MainWindow.FindName("MemoryLineColor")
            $UIHash.MemoryCombo.ItemsSource = $allColors
            $UIHash.MemoryCombo.ADD_SelectionChanged({
                if ($UIHash.MemoryListView.SelectedItem -ne $null -and $UIHash.MemoryListView.SelectedItem.LineColor -ne $UIHash.MemoryCombo.SelectedItem){
                    try{
                        $UIHash.MemoryListView.SelectedItem.LineColor = $UIHash.MemoryCombo.SelectedItem

                        $Index = ($DataHash.MemorySeriesCollectionTitles | where Title -eq $UIHash.MemoryListView.SelectedItem.Name).Index
                        $CloneStrokeColor = $UIHash.MemoryChartSeries[$Index].Stroke.Clone()
                        $CloneFillColor = $UIHash.MemoryChartSeries[$Index].Fill.Clone()
                        $CloneFillColor.Color = [System.Windows.Media.Colors]::($UIHash.MemoryCombo.SelectedItem)
                        $UIHash.MemoryChartSeries[$Index].Fill = $CloneFillColor
                        $CloneStrokeColor.Color = [System.Windows.Media.Colors]::($UIHash.MemoryCombo.SelectedItem)
                        $UIHash.MemoryChartSeries[$Index].Stroke = $CloneStrokeColor
                    }
                    catch{
                        Show-Messagebox -Title "Color Change Error" -Text $_.Exception.Message -Icon Error

                    }
                }
            })

            $UIHash.DiskCombo = $MainWindow.FindName("DiskLineColor")
            $UIHash.DiskCombo.ItemsSource = $allColors
            $UIHash.DiskCombo.ADD_SelectionChanged({
                if ($UIHash.DiskListView.SelectedItem -ne $null -and $UIHash.DiskListView.SelectedItem.LineColor -ne $UIHash.DiskCombo.SelectedItem){
                    try{
                        $UIHash.DiskListView.SelectedItem.LineColor = $UIHash.DiskCombo.SelectedItem

                        $Index = ($DataHash.DiskSeriesCollectionTitles | where Title -eq $UIHash.DiskListView.SelectedItem.Name).Index
                        $CloneStrokeColor = $UIHash.DiskChartSeries[$Index].Stroke.Clone()
                        $CloneFillColor = $UIHash.DiskChartSeries[$Index].Fill.Clone()
                        $CloneFillColor.Color = [System.Windows.Media.Colors]::($UIHash.DiskCombo.SelectedItem)
                        $UIHash.DiskChartSeries[$Index].Fill = $CloneFillColor
                        $CloneStrokeColor.Color = [System.Windows.Media.Colors]::($UIHash.DiskCombo.SelectedItem)
                        $UIHash.DiskChartSeries[$Index].Stroke = $CloneStrokeColor
                    }
                    catch{
                        Show-Messagebox -Title "Color Change Error" -Text $_.Exception.Message -Icon Error
                    }
                }
            })

            $UIHash.ThermalCombo = $MainWindow.FindName("ThermalLineColor")
            $UIHash.ThermalCombo.ItemsSource = $allColors
            $UIHash.ThermalCombo.ADD_SelectionChanged({
                if ($UIHash.ThermalListView.SelectedItem -ne $null -and $UIHash.ThermalListView.SelectedItem.LineColor -ne $UIHash.ThermalCombo.SelectedItem){
                    try{
                        $UIHash.ThermalListView.SelectedItem.LineColor = $UIHash.ThermalCombo.SelectedItem

                        $Index = ($DataHash.ThermalSeriesCollectionTitles | where Title -eq $UIHash.ThermalListView.SelectedItem.Name).Index
                        $CloneStrokeColor = $UIHash.ThermalChartSeries[$Index].Stroke.Clone()
                        $CloneFillColor = $UIHash.ThermalChartSeries[$Index].Fill.Clone()
                        $CloneFillColor.Color = [System.Windows.Media.Colors]::($UIHash.ThermalCombo.SelectedItem)
                        $UIHash.ThermalChartSeries[$Index].Fill = $CloneFillColor
                        $CloneStrokeColor.Color = [System.Windows.Media.Colors]::($UIHash.ThermalCombo.SelectedItem)
                        $UIHash.ThermalChartSeries[$Index].Stroke = $CloneStrokeColor
                    }
                    catch{
                        Show-Messagebox -Title "Color Change Error" -Text $_.Exception.Message -Icon Error
                    }
                }
            })


            #Listboxes
            $UIHash.computerListbox = $MainWindow.FindName("computerListbox")
            $DataHash.AllComputers = New-Object System.Collections.ObjectModel.ObservableCollection[System.Object]
            [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($DataHash.AllComputers, [System.Object]::new())
            $DataHash.FilteredComputers = New-Object System.Collections.ObjectModel.ObservableCollection[System.Object]
            [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($DataHash.FilteredComputers, [System.Object]::new())
            $UIHash.ComputerListbox.ItemsSource = $DataHash.FilteredComputers
            $UIHash.ComputerListboxSelectedItems = $UIHash.ComputerListbox.SelectedItems
            $UIHash.computerListbox.DisplayMemberPath = "ComputerName"
            $UIHash.computerListbox.ADD_SelectionChanged({
                if ($UIHash.computerListbox.SelectedItem -ne $null){
                    try{
                        $UIHash.AddComputerButton.IsEnabled = $false
                        $ScriptsHash.Ping.BeginInvoke()
                    }
                    catch{
                        Show-Messagebox -Text $_.Exception.Message -Icon Error -Title "List Box Selection Change Event"
                    }
                }
            })

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

            #cpu
            $UIHash.CPUListView = $MainWindow.FindName("cpuListView")
            $UIHash.CPUListView.SelectionMode = [System.Windows.Controls.SelectionMode]::Single
            $UIHash.CPUGridView = $MainWindow.FindName("cpuGridView")

            $cpuListViewProperties = "Counter","ComputerName","Instance","Units","Value","LineColor"

            $cpuListViewProperties | foreach {
                $gridViewColumn = [System.Windows.Controls.GridViewColumn]::new()
                $gridViewColumn.Header = $_
                $Binding = [System.Windows.Data.Binding]::new($_)
                $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
                $gridViewColumn.DisplayMemberBinding = $Binding
                $UIHash.CPUGridView.Columns.Add($gridViewColumn)
            }

            $cpuListViewItems = New-Object -TypeName System.Collections.ObjectModel.ObservableCollection[System.Object]
            [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($cpuListViewItems ,[System.Object]::new())
            $DataHash.CPUListViewItems = $cpuListViewItems
            $UIHash.CPUListView.ItemsSource = $DataHash.CPUListViewItems
            $UIHash.CPUListView.ADD_SelectionChanged({
                if ($_.Source.SelectedIndex -ne -1){
                    $UIHash.CPUCombo.SelectedItem = $UIHash.CPUListView.SelectedItem.LineColor
                    $UIHash.CPUSlider.Value = $UIHash.CPUListView.SelectedItem.LineThickness
                }
            })

            $DataHash.CPUListViewList = New-Object System.Collections.Generic.List[System.Object]
            1.. 30 | foreach {
                $newCounterListViewItem = [CounterListViewItem]::new()
                $newCounterListViewItem.IsChecked = $true
                $DataHash.CPUListViewList.Add($newCounterListViewItem)
            }

            #Network
            $UIHash.NetworkListView = $MainWindow.FindName("NetworkListView")
            $UIHash.NetworkListView.SelectionMode = [System.Windows.Controls.SelectionMode]::Single
            $UIHash.NetworkGridView = $MainWindow.FindName("NetworkGridView")

            $NetworkListViewProperties = "Counter","ComputerName","Instance","Units","Value","LineColor"

            $NetworkListViewProperties | foreach {
                $gridViewColumn = [System.Windows.Controls.GridViewColumn]::new()
                $gridViewColumn.Header = $_
                $Binding = [System.Windows.Data.Binding]::new($_)
                $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
                $gridViewColumn.DisplayMemberBinding = $Binding
                $UIHash.NetworkGridView.Columns.Add($gridViewColumn)
            }

            $NetworkListViewItems = New-Object -TypeName System.Collections.ObjectModel.ObservableCollection[System.Object]
            [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($NetworkListViewItems ,[System.Object]::new())
            $DataHash.NetworkListViewItems = $NetworkListViewItems
            $UIHash.NetworkListView.ItemsSource = $DataHash.NetworkListViewItems
            $UIHash.NetworkListView.ADD_SelectionChanged({
                if ($_.Source.SelectedIndex -ne -1){
                    $UIHash.NetworkCombo.SelectedItem = $UIHash.NetworkListView.SelectedItem.LineColor
                    $UIHash.NetworkSlider.Value = $UIHash.NetworkListView.SelectedItem.LineThickness
                }
            })

            $DataHash.NetworkListViewList = New-Object System.Collections.Generic.List[System.Object]
            1.. 30 | foreach {
                $newCounterListViewItem = [CounterListViewItem]::new()
                $newCounterListViewItem.IsChecked = $true
                $DataHash.NetworkListViewList.Add($newCounterListViewItem)
            }

            #Memory
            $UIHash.MemoryListView = $MainWindow.FindName("MemoryListView")
            $UIHash.MemoryListView.SelectionMode = [System.Windows.Controls.SelectionMode]::Single
            $UIHash.MemoryGridView = $MainWindow.FindName("MemoryGridView")

            $MemoryListViewProperties = "Counter","ComputerName","Instance","Units","Value","LineColor"

            $MemoryListViewProperties | foreach {
                $gridViewColumn = [System.Windows.Controls.GridViewColumn]::new()
                $gridViewColumn.Header = $_
                $Binding = [System.Windows.Data.Binding]::new($_)
                $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
                $gridViewColumn.DisplayMemberBinding = $Binding
                $UIHash.MemoryGridView.Columns.Add($gridViewColumn)
            }

            $MemoryListViewItems = New-Object -TypeName System.Collections.ObjectModel.ObservableCollection[System.Object]
            [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($MemoryListViewItems ,[System.Object]::new())
            $DataHash.MemoryListViewItems = $MemoryListViewItems
            $UIHash.MemoryListView.ItemsSource = $DataHash.MemoryListViewItems
            $UIHash.MemoryListView.ADD_SelectionChanged({
                if ($_.Source.SelectedIndex -ne -1){
                    $UIHash.MemoryCombo.SelectedItem = $UIHash.MemoryListView.SelectedItem.LineColor
                    $UIHash.MemorySlider.Value = $UIHash.MemoryListView.SelectedItem.LineThickness
                }
            })

            $DataHash.MemoryListViewList = New-Object System.Collections.Generic.List[System.Object]
            1.. 30 | foreach {
                $newCounterListViewItem = [CounterListViewItem]::new()
                $newCounterListViewItem.IsChecked = $true
                $DataHash.MemoryListViewList.Add($newCounterListViewItem)
            }

            #Disk
            $UIHash.DiskListView = $MainWindow.FindName("DiskListView")
            $UIHash.DiskListView.SelectionMode = [System.Windows.Controls.SelectionMode]::Single
            $UIHash.DiskGridView = $MainWindow.FindName("DiskGridView")

            $DiskListViewProperties = "Counter","ComputerName","Instance","Units","Value","LineColor"

            $DiskListViewProperties | foreach {
                $gridViewColumn = [System.Windows.Controls.GridViewColumn]::new()
                $gridViewColumn.Header = $_
                $Binding = [System.Windows.Data.Binding]::new($_)
                $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
                $gridViewColumn.DisplayMemberBinding = $Binding
                $UIHash.DiskGridView.Columns.Add($gridViewColumn)
            }

            $DiskListViewItems = New-Object -TypeName System.Collections.ObjectModel.ObservableCollection[System.Object]
            [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($DiskListViewItems ,[System.Object]::new())
            $DataHash.DiskListViewItems = $DiskListViewItems
            $UIHash.DiskListView.ItemsSource = $DataHash.DiskListViewItems
            $UIHash.DiskListView.ADD_SelectionChanged({
                if ($_.Source.SelectedIndex -ne -1){
                    $UIHash.DiskCombo.SelectedItem = $UIHash.DiskListView.SelectedItem.LineColor
                    $UIHash.DiskSlider.Value = $UIHash.DiskListView.SelectedItem.LineThickness
                }
            })

            $DataHash.DiskListViewList = New-Object System.Collections.Generic.List[System.Object]
            1.. 30 | foreach {
                $newCounterListViewItem = [CounterListViewItem]::new()
                $newCounterListViewItem.IsChecked = $true
                $DataHash.DiskListViewList.Add($newCounterListViewItem)
            }

            #Thermal
            $UIHash.ThermalListView = $MainWindow.FindName("ThermalListView")
            $UIHash.ThermalListView.SelectionMode = [System.Windows.Controls.SelectionMode]::Single
            $UIHash.ThermalGridView = $MainWindow.FindName("ThermalGridView")

            $ThermalListViewProperties = "Counter","ComputerName","Instance","Units","Value","LineColor"

            $ThermalListViewProperties | foreach {
                $gridViewColumn = [System.Windows.Controls.GridViewColumn]::new()
                $gridViewColumn.Header = $_
                $Binding = [System.Windows.Data.Binding]::new($_)
                $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
                $gridViewColumn.DisplayMemberBinding = $Binding
                $UIHash.ThermalGridView.Columns.Add($gridViewColumn)
            }

            $ThermalListViewItems = New-Object -TypeName System.Collections.ObjectModel.ObservableCollection[System.Object]
            [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($ThermalListViewItems ,[System.Object]::new())
            $DataHash.ThermalListViewItems = $ThermalListViewItems
            $UIHash.ThermalListView.ItemsSource = $DataHash.ThermalListViewItems
            $UIHash.ThermalListView.ADD_SelectionChanged({
                if ($_.Source.SelectedIndex -ne -1){
                    $UIHash.ThermalCombo.SelectedItem = $UIHash.ThermalListView.SelectedItem.LineColor
                    $UIHash.ThermalSlider.Value = $UIHash.ThermalListView.SelectedItem.LineThickness
                }
            })

            $DataHash.ThermalListViewList = New-Object System.Collections.Generic.List[System.Object]
            1.. 30 | foreach {
                $newCounterListViewItem = [CounterListViewItem]::new()
                $newCounterListViewItem.IsChecked = $true
                $DataHash.ThermalListViewList.Add($newCounterListViewItem)
            }

            #Checkboxes
            $UIHash.EnabledCheckBox = $MainWindow.FindName("LogCheckbox")

            #Slider
            $UIHash.CPUTimeTimeSlider = $MainWindow.FindName("CPUTimeSlider")
            $UIHash.NetworkTimeSlider = $MainWindow.FindName("NetworkTimeSlider")
            $UIHash.MemoryTimeSlider = $MainWindow.FindName("MemoryTimeSlider")
            $UIHash.DiskTimeSlider = $MainWindow.FindName("DiskTimeSlider")
            $UIHash.ThermalTimeSlider = $MainWindow.FindName("ThermalTimeSlider")

            $UIHash.CPUSlider = $MainWindow.FindName("cpulineThickness")
            $UIHash.CPUSlider.Add_ValueChanged({
                if ($UIHash.CPUListView.SelectionIndex -ne -1 -and $UIHash.CPUListView.SelectedItem.LineThickness -ne $UIHash.CPUSlider.Value){
                    $UIHash.CPUListView.SelectedItem.LineThickness = $UIHash.CPUSlider.Value

                    $Index = ($DataHash.CPUSeriesCollectionTitles | where Title -eq $UIHash.CPUListView.SelectedItem.Name).Index
                    $UIHash.CPUChartSeries[$index].StrokeThickness = $UIHash.CPUSlider.Value
                }
            })

            $UIHash.NetworkSlider = $MainWindow.FindName("NetworklineThickness")
            $UIHash.NetworkSlider.Add_ValueChanged({
                if ($UIHash.NetworkListView.SelectionIndex -ne -1 -and $UIHash.NetworkListView.SelectedItem.LineThickness -ne $UIHash.NetworkSlider.Value){
                    $UIHash.NetworkListView.SelectedItem.LineThickness = $UIHash.NetworkSlider.Value

                    $Index = ($DataHash.NetworkSeriesCollectionTitles | where Title -eq $UIHash.NetworkListView.SelectedItem.Name).Index
                    $UIHash.NetworkChartSeries[$index].StrokeThickness = $UIHash.NetworkSlider.Value
                }
            })

            $UIHash.MemorySlider = $MainWindow.FindName("MemorylineThickness")
            $UIHash.MemorySlider.Add_ValueChanged({
                if ($UIHash.MemoryListView.SelectionIndex -ne -1 -and $UIHash.MemoryListView.SelectedItem.LineThickness -ne $UIHash.MemorySlider.Value){
                    $UIHash.MemoryListView.SelectedItem.LineThickness = $UIHash.MemorySlider.Value

                    $Index = ($DataHash.MemorySeriesCollectionTitles | where Title -eq $UIHash.MemoryListView.SelectedItem.Name).Index
                    $UIHash.MemoryChartSeries[$index].StrokeThickness = $UIHash.MemorySlider.Value
                }
            })

            $UIHash.DiskSlider = $MainWindow.FindName("DisklineThickness")
            $UIHash.DiskSlider.Add_ValueChanged({
                if ($UIHash.DiskListView.SelectionIndex -ne -1 -and $UIHash.DiskListView.SelectedItem.LineThickness -ne $UIHash.DiskSlider.Value){
                    $UIHash.DiskListView.SelectedItem.LineThickness = $UIHash.DiskSlider.Value

                    $Index = ($DataHash.DiskSeriesCollectionTitles | where Title -eq $UIHash.DiskListView.SelectedItem.Name).Index
                    $UIHash.DiskChartSeries[$index].StrokeThickness = $UIHash.DiskSlider.Value
                }
            })

            $UIHash.ThermalSlider = $MainWindow.FindName("ThermallineThickness")
            $UIHash.ThermalSlider.Add_ValueChanged({
                if ($UIHash.ThermalListView.SelectionIndex -ne -1 -and $UIHash.ThermalListView.SelectedItem.LineThickness -ne $UIHash.ThermalSlider.Value){
                    $UIHash.ThermalListView.SelectedItem.LineThickness = $UIHash.ThermalSlider.Value

                    $Index = ($DataHash.ThermalSeriesCollectionTitles | where Title -eq $UIHash.ThermalListView.SelectedItem.Name).Index
                    $UIHash.ThermalChartSeries[$index].StrokeThickness = $UIHash.ThermalSlider.Value
                }
            })

            #Line Charts
            $UIHash.CPULineChart = $MainWindow.FindName("CPULineChart")
            $CPUSeriesCollection = [LiveCharts.SeriesCollection]::new()
            $UIHash.CPULineChart.Series = $CPUSeriesCollection
            $UIHash.CPUChartSeries = $UIHash.CPULineChart.Series
            $DataHash.CPUSeriesCollectionTitles = [System.Collections.ArrayList]::new()
            $DataHash.CPUChartValues = New-Object System.Collections.Generic.List[System.Object]
            $newLineSeries = 1..30 | foreach {
                $newLineSeries = [LiveCharts.Wpf.LineSeries]::new()
                $chartValues = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservablePoint]]::new()
                [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($chartValues, [System.Object]::new())
                $newLineSeries.Values = $chartValues
                $UIHash.CPULineChart.Series.Add($newLineSeries)
                $DataHash.CPUChartValues.Add($chartValues)
            }

            $UIHash.NetworkLineChart = $MainWindow.FindName("NetworkLineChart")
            $NetworkSeriesCollection = [LiveCharts.SeriesCollection]::new()
            $UIHash.NetworkLineChart.Series = $NetworkSeriesCollection
            $UIHash.NetworkChartSeries = $UIHash.NetworkLineChart.Series
            $DataHash.NetworkSeriesCollectionTitles = [System.Collections.ArrayList]::new()
            $DataHash.NetworkChartValues = New-Object System.Collections.Generic.List[System.Object]
            $newLineSeries = 1..30 | foreach {
                $newLineSeries = [LiveCharts.Wpf.LineSeries]::new()
                $chartValues = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservablePoint]]::new()
                [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($chartValues, [System.Object]::new())
                $newLineSeries.Values = $chartValues
                $UIHash.NetworkLineChart.Series.Add($newLineSeries)
                $DataHash.NetworkChartValues.Add($chartValues)
            }

            $UIHash.MemoryLineChart = $MainWindow.FindName("MemoryLineChart")
            $MemorySeriesCollection = [LiveCharts.SeriesCollection]::new()
            $UIHash.MemoryLineChart.Series = $MemorySeriesCollection
            $UIHash.MemoryChartSeries = $UIHash.MemoryLineChart.Series
            $DataHash.MemorySeriesCollectionTitles = [System.Collections.ArrayList]::new()
            $DataHash.MemoryChartValues = New-Object System.Collections.Generic.List[System.Object]
            $newLineSeries = 1..30 | foreach {
                $newLineSeries = [LiveCharts.Wpf.LineSeries]::new()
                $chartValues = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservablePoint]]::new()
                [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($chartValues, [System.Object]::new())
                $newLineSeries.Values = $chartValues
                $UIHash.MemoryLineChart.Series.Add($newLineSeries)
                $DataHash.MemoryChartValues.Add($chartValues)
            }

            $UIHash.DiskLineChart = $MainWindow.FindName("DiskLineChart")
            $DiskSeriesCollection = [LiveCharts.SeriesCollection]::new()
            $UIHash.DiskLineChart.Series = $DiskSeriesCollection
            $UIHash.DiskChartSeries = $UIHash.DiskLineChart.Series
            $DataHash.DiskSeriesCollectionTitles = [System.Collections.ArrayList]::new()
            $DataHash.DiskChartValues = New-Object System.Collections.Generic.List[System.Object]
            $newLineSeries = 1..30 | foreach {
                $newLineSeries = [LiveCharts.Wpf.LineSeries]::new()
                $chartValues = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservablePoint]]::new()
                [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($chartValues, [System.Object]::new())
                $newLineSeries.Values = $chartValues
                $UIHash.DiskLineChart.Series.Add($newLineSeries)
                $DataHash.DiskChartValues.Add($chartValues)
            }

            $UIHash.ThermalLineChart = $MainWindow.FindName("ThermalLineChart")
            $ThermalSeriesCollection = [LiveCharts.SeriesCollection]::new()
            $UIHash.ThermalLineChart.Series = $ThermalSeriesCollection
            $UIHash.ThermalChartSeries = $UIHash.ThermalLineChart.Series
            $DataHash.ThermalSeriesCollectionTitles = [System.Collections.ArrayList]::new()
            $DataHash.ThermalChartValues = New-Object System.Collections.Generic.List[System.Object]
            $newLineSeries = 1..30 | foreach {
                $newLineSeries = [LiveCharts.Wpf.LineSeries]::new()
                $chartValues = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservablePoint]]::new()
                [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($chartValues, [System.Object]::new())
                $newLineSeries.Values = $chartValues
                $UIHash.ThermalLineChart.Series.Add($newLineSeries)
                $DataHash.ThermalChartValues.Add($chartValues)
            }

            #Button Click Events
            $UIHash.AddComputerButton.ADD_Click({
                if ($DataHash.addedComputers -notcontains $Computer){
                    $DataHash.addedComputers.Add($UIHash.ComputerListbox.SelectedItem)
                }
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

            $UIHash.FolderExplorerButton.ADD_Click({
                $FolderDialogBox = [Ookii.Dialogs.Wpf.VistaFolderBrowserDialog]::new()
                $FolderDialogBox.Description = "Destination folder for counter logs"
                $FolderDialogBox.UseDescriptionForTitle = $true
                if ($FolderDialogBox.ShowDialog()){
                    $UIHash.FilePathBox.Text = $FolderDialogBox.SelectedPath
                }
            })


            #CPU
            $UIHash.CPUStartButton.ADD_Click({
                $UIHash.CPURemoveCountersButton.IsEnabled = $false
                $DataHash.CPUX = 0
                $DataHash.CPUChartValues | foreach {
                    $_.Clear()
                }
                $ScriptsHash.CPURunspace.BeginInvoke()
                $UIHash.CPUStartButton.IsEnabled = $false
                $UIHash.CPUStopButton.IsEnabled = $true
            })

            $UIHash.CPUStopButton.IsEnabled = $false
            $UIHash.CPUStopButton.ADD_Click({
                $ScriptsHash.CPURunspace.Stop()
                $UIHash.CPUStopButton.IsEnabled = $false
                $UIHash.CPUStartButton.IsEnabled = $true
                $UIHash.CPURemoveCountersButton.IsEnabled = $true
            })

            $UIHash.CPURemoveCountersButton.ADD_Click({
                $checkedItems = $DataHash.CPUListViewItems | where IsChecked -eq $true
                foreach ($item in $checkedItems){
                    $index = $DataHash.CPUSeriesCollectionTitles | where Title -eq $item.Name
                    $UIHash.CPULineChart.Series[$index.Index].Title = $Null
                    $DataHash.CPUChartValues[$index.Index].Clear()
                    $IndexIndex = $DataHash.CPUSeriesCollectionTitles.IndexOf($index)
                    $DataHash.CPUSeriesCollectionTitles[$IndexIndex].Title = $null
                    $DataHash.CPUListViewItems.Remove($item)
                }
            })

            #Network
            $UIHash.NetworkStartButton.ADD_Click({
                $UIHash.NetworkRemoveCountersButton.IsEnabled = $false
                $DataHash.NetworkX = 0
                $DataHash.NetworkChartValues | foreach {
                    $_.Clear()
                }
                $ScriptsHash.NetworkRunspace.BeginInvoke()
                $UIHash.NetworkStartButton.IsEnabled = $false
                $UIHash.NetworkStopButton.IsEnabled = $true
            })

            $UIHash.NetworkStopButton.IsEnabled = $false
            $UIHash.NetworkStopButton.ADD_Click({
                $ScriptsHash.NetworkRunspace.Stop()
                $UIHash.NetworkStopButton.IsEnabled = $false
                $UIHash.NetworkStartButton.IsEnabled = $true
                $UIHash.NetworkRemoveCountersButton.IsEnabled = $true
            })

            $UIHash.NetworkRemoveCountersButton.ADD_Click({
                $checkedItems = $DataHash.NetworkListViewItems | where IsChecked -eq $true
                foreach ($item in $checkedItems){
                    $index = $DataHash.NetworkSeriesCollectionTitles | where Title -eq $item.Name
                    $UIHash.NetworkLineChart.Series[$index.Index].Title = $Null
                    $DataHash.NetworkChartValues[$index.Index].Clear()
                    $IndexIndex = $DataHash.NetworkSeriesCollectionTitles.IndexOf($index)
                    $DataHash.NetworkSeriesCollectionTitles[$IndexIndex].Title = $null
                    $DataHash.NetworkListViewItems.Remove($item)
                }
            })

            $UIHash.MemoryStartButton.ADD_Click({
                $UIHash.MemoryRemoveCountersButton.IsEnabled = $false
                $DataHash.MemoryX = 0
                $DataHash.MemoryChartValues | foreach {
                    $_.Clear()
                }
                $ScriptsHash.MemoryRunspace.BeginInvoke()
                $UIHash.MemoryStartButton.IsEnabled = $false
                $UIHash.MemoryStopButton.IsEnabled = $true
            })

            $UIHash.MemoryStopButton.IsEnabled = $false
            $UIHash.MemoryStopButton.ADD_Click({
                $ScriptsHash.MemoryRunspace.Stop()
                $UIHash.MemoryStopButton.IsEnabled = $false
                $UIHash.MemoryStartButton.IsEnabled = $true
                $UIHash.MemoryRemoveCountersButton.IsEnabled = $true
            })

            $UIHash.MemoryRemoveCountersButton.ADD_Click({
                $checkedItems = $DataHash.MemoryListViewItems | where IsChecked -eq $true
                foreach ($item in $checkedItems){
                    $index = $DataHash.MemorySeriesCollectionTitles | where Title -eq $item.Name
                    $UIHash.MemoryLineChart.Series[$index.Index].Title = $Null
                    $DataHash.MemoryChartValues[$index.Index].Clear()
                    $IndexIndex = $DataHash.MemorySeriesCollectionTitles.IndexOf($index)
                    $DataHash.MemorySeriesCollectionTitles[$IndexIndex].Title = $null
                    $DataHash.MemoryListViewItems.Remove($item)
                }
            })

            $UIHash.DiskStartButton.ADD_Click({
                $UIHash.DiskRemoveCountersButton.IsEnabled = $false
                $DataHash.DiskX = 0
                $DataHash.DiskChartValues | foreach {
                    $_.Clear()
                }
                $ScriptsHash.DiskRunspace.BeginInvoke()
                $UIHash.DiskStartButton.IsEnabled = $false
                $UIHash.DiskStopButton.IsEnabled = $true
            })

            $UIHash.DiskStopButton.IsEnabled = $false
            $UIHash.DiskStopButton.ADD_Click({
                $ScriptsHash.DiskRunspace.Stop()
                $UIHash.DiskStopButton.IsEnabled = $false
                $UIHash.DiskStartButton.IsEnabled = $true
                $UIHash.DiskRemoveCountersButton.IsEnabled = $true
            })

            $UIHash.DiskRemoveCountersButton.ADD_Click({
                $checkedItems = $DataHash.DiskListViewItems | where IsChecked -eq $true
                foreach ($item in $checkedItems){
                    $index = $DataHash.DiskSeriesCollectionTitles | where Title -eq $item.Name
                    $UIHash.DiskLineChart.Series[$index.Index].Title = $Null
                    $DataHash.DiskChartValues[$index.Index].Clear()
                    $IndexIndex = $DataHash.DiskSeriesCollectionTitles.IndexOf($index)
                    $DataHash.DiskSeriesCollectionTitles[$IndexIndex].Title = $null
                    $DataHash.DiskListViewItems.Remove($item)
                }
            })

            $UIHash.ThermalStartButton.ADD_Click({
                $UIHash.ThermalRemoveCountersButton.IsEnabled = $false
                $DataHash.ThermalX = 0
                $DataHash.ThermalChartValues | foreach {
                    $_.Clear()
                }
                $ScriptsHash.ThermalRunspace.BeginInvoke()
                $UIHash.ThermalStartButton.IsEnabled = $false
                $UIHash.ThermalStopButton.IsEnabled = $true
            })

            $UIHash.ThermalStopButton.IsEnabled = $false
            $UIHash.ThermalStopButton.ADD_Click({
                $ScriptsHash.ThermalRunspace.Stop()
                $UIHash.ThermalStopButton.IsEnabled = $false
                $UIHash.ThermalStartButton.IsEnabled = $true
                $UIHash.ThermalRemoveCountersButton.IsEnabled = $true
            })

            $UIHash.ThermalRemoveCountersButton.ADD_Click({
                $checkedItems = $DataHash.ThermalListViewItems | where IsChecked -eq $true
                foreach ($item in $checkedItems){
                    $index = $DataHash.ThermalSeriesCollectionTitles | where Title -eq $item.Name
                    $UIHash.ThermalLineChart.Series[$index.Index].Title = $Null
                    $DataHash.ThermalChartValues[$index.Index].Clear()
                    $IndexIndex = $DataHash.ThermalSeriesCollectionTitles.IndexOf($index)
                    $DataHash.ThermalSeriesCollectionTitles[$IndexIndex].Title = $null
                    $DataHash.ThermalListViewItems.Remove($item)
                }
            })
            
            #Launch App
            $UIHash.MainWindow.ShowDialog()
        }
        catch{
            Show-Messagebox -Text "$($_.Exception.Message)`n`n$($_.InvocationInfo.PositionMessage)" -Title "UI Runspace"
        }
    }
}