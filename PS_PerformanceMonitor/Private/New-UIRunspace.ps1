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

            $UIHash.CPUStartButton = $MainWindow.FindName("cpuStartButton")
            $UIHash.CPUStopButton = $MainWindow.FindName("cpuStopButton")
            $UIHash.CPURemoveCountersButton = $MainWindow.FindName("cpuRemoveSelectedButton")

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

            $allColors = ([System.Windows.Media.Colors] | Get-Member -Static -MemberType Properties).Name
            $UIHash.CPUCombo = $MainWindow.FindName("cpuLineColor")
            $UIHash.CPUCombo.ItemsSource = $allColors
            $UIHash.CPUCombo.ADD_SelectionChanged({
                if ($UIHash.CPUListView.SelectionIndex -ne -1 -and $UIHash.CPUListView.SelectedItem.LineColor -ne $UIHash.CPUCombo.SelectedItem){
                    $UIHash.CPUListView.SelectedItem.LineColor = $UIHash.CPUCombo.SelectedItem

                    $Index = ($DataHash.SeriesCollectionTitles | where Title -eq $UIHash.CPUListView.SelectedItem.Name).Index
                    $CloneStrokeColor = $UIHash.CPUChartSeries[$Index].Stroke.Clone()
                    $CloneFillColor = $UIHash.CPUChartSeries[$Index].Fill.Clone()
                    $CloneFillColor.Color = [System.Windows.Media.Colors]::($UIHash.CPUCombo.SelectedItem)
                    $UIHash.CPUChartSeries[$Index].Fill = $CloneFillColor
                    $CloneStrokeColor.Color = [System.Windows.Media.Colors]::($UIHash.CPUCombo.SelectedItem)
                    $UIHash.CPUChartSeries[$Index].Stroke = $CloneStrokeColor
                }
            })


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
            $DataHash.ListViewItems = $cpuListViewItems
            $UIHash.CPUListView.ItemsSource = $DataHash.ListViewItems
            $UIHash.CPUListView.ADD_SelectionChanged({
                if ($UIHash.CPUListView.SelectionIndex -ne -1){
                    $UIHash.CPUCombo.SelectedItem = $UIHash.CPUListView.SelectedItem.LineColor
                    $UIHash.CPUSlider.Value = $UIHash.CPUListView.SelectedItem.LineThickness
                }
            })

            $DataHash.ListViewList = New-Object System.Collections.Generic.List[System.Object]
            1.. 30 | foreach {
                $newCounterListViewItem = [CounterListViewItem]::new()
                $newCounterListViewItem.IsChecked = $true
                $DataHash.ListViewList.Add($newCounterListViewItem)
            }

            #Checkboxes
            $UIHash.EnabledCheckBox = $MainWindow.FindName("LogCheckbox")

            #Slider
            $UIHash.TimeIntervalSlider = $MainWindow.FindName("timeIntervalTrack")
            $UIHash.CPUSlider = $MainWindow.FindName("cpulineThickness")
            $UIHash.CPUSlider.Add_ValueChanged({
                if ($UIHash.CPUListView.SelectionIndex -ne -1 -and $UIHash.CPUListView.SelectedItem.LineThickness -ne $UIHash.CPUSlider.Value){
                    $UIHash.CPUListView.SelectedItem.LineThickness = $UIHash.CPUSlider.Value

                    $Index = ($DataHash.SeriesCollectionTitles | where Title -eq $UIHash.CPUListView.SelectedItem.Name).Index
                    $UIHash.CPUChartSeries[$index].StrokeThickness = $UIHash.CPUSlider.Value
                }
            })

            #Line Charts
            $UIHash.CPULineChart = $MainWindow.FindName("CPULineChart")
            $CPUSeriesCollection = [LiveCharts.SeriesCollection]::new()
            $UIHash.CPULineChart.Series = $CPUSeriesCollection
            $UIHash.CPUChartSeries = $UIHash.CPULineChart.Series
            $DataHash.SeriesCollectionTitles = [System.Collections.ArrayList]::new()
            $DataHash.CPUChartValues = New-Object System.Collections.Generic.List[System.Object]
            $newLineSeries = 1..30 | foreach {
                $newLineSeries = [LiveCharts.Wpf.LineSeries]::new()
                $chartValues = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservablePoint]]::new()
                [System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($chartValues, [System.Object]::new())
                $newLineSeries.Values = $chartValues
                $UIHash.CPULineChart.Series.Add($newLineSeries)
                $DataHash.CPUChartValues.Add($chartValues)
            }

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

            $UIHash.CPUStartButton.ADD_Click({
                $UIHash.CPURemoveCountersButton.IsEnabled = $false
                $DataHash.X = 0
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
                $checkedItems = $DataHash.ListViewItems | where IsChecked -eq $true
                foreach ($item in $checkedItems){
                    $index = $DataHash.SeriesCollectionTitles | where Title -eq $item.Name
                    $UIHash.CPULineChart.Series[$index.Index].Title = $Null
                    $DataHash.CPUChartValues[$index.Index].Clear()
                    $IndexIndex = $DataHash.SeriesCollectionTitles.IndexOf($index)
                    $DataHash.SeriesCollectionTitles[$IndexIndex].Title = $null
                    $DataHash.ListViewItems.Remove($item)
                }
            })
            
            #Launch App
            $UIHash.MainWindow.ShowDialog()
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title "CPU Runspace"
        }
    }
}