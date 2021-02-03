function New-ThermalRunspace {
    [powershell]::Create().AddScript{
        Add-Type -AssemblyName PresentationFramework
        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {Add-Type -Path $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}
    
        try{
            $X = Get-Date

            $UIHash.ThermalDefaultCounterComboBox.Dispatcher.Invoke([action]{$DataHash.ThermalCounter = $UIHash.ThermalDefaultCounterComboBox.SelectedItem.Counter})

            $computers = $DataHash.addedComputers | where IsChecked -eq $true
            $UIHash.TimeIntervalSlider.Dispatcher.Invoke([action]{$DataHash.ThermalIntervalX = $UIHash.TimeIntervalSlider.Value})
            $DataHash.ThermalX -= $DataHash.ThermalIntervalX
    
            Get-Counter -Counter $DataHash.ThermalCounter -Continuous -ComputerName $computers.ComputerName -SampleInterval $DataHash.ThermalIntervalX -ErrorAction Stop -ErrorVariable ErrVar -OutVariable ThermalLogs |
            select -expandProperty CounterSamples |
             foreach -Begin {
                $ThermalFilePrefix = Get-Date -Format "yyyyMMdd(s)"
             } -Process {
                if ($DataHash.ThermalSeriesCollectionTitles.Title -notcontains $_.Path){
                    $newRandomColor = ([System.Windows.Media.Colors] | gm -Static -MemberType Properties)[(Get-Random -Minimum 0 -Maximum 141)].Name
    
                    $plus1 = ($DataHash.ThermalSeriesCollectionTitles | Measure).Count + 1
                    $newIndex = [PSCustomObject]@{
                        Title = $_.Path
                        Index = $plus1
                    }
    
                    $DataHash.ThermalSeriesCollectionTitles.Add($newIndex)
                    $newCounterListViewItem = $DataHash.ThermalListViewList[$plus1]
                    $newCounterListViewItem.Name = $_.Path
                    $newCounterListViewItem.Counter = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[1].split('(')[0])
                    $newCounterListViewItem.ComputerName = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[0])
                    $newCounterListViewItem.Instance = $_.InstanceName
                    $newCounterListViewItem.Units = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[2])
                    $newCounterListViewItem.Value = 0
                    $newCounterListViewItem.LineColor = $newRandomColor
                    $newCounterListViewItem.LineThickness = 2
                    $DataHash.ThermalListViewItems.Add($newCounterListViewItem)
    
                    $UIHash.ThermalLineChart.Dispatcher.Invoke([action]{
                    $UIHash.ThermalChartSeries[$plus1].Title = $_.Path
                    $UIHash.ThermalChartSeries[$plus1].PointGeometrySize = 2
                    $UIHash.ThermalChartSeries[$plus1].LineSmoothness = .2
                    $CloneStrokeColor = $UIHash.ThermalChartSeries[$plus1].Stroke.Clone()
                    $CloneFillColor = $UIHash.ThermalChartSeries[$plus1].Fill.Clone()
                    $CloneFillColor.Color = [System.Windows.Media.Colors]::$newRandomColor
                    $UIHash.ThermalChartSeries[$plus1].Fill = $CloneFillColor
                    $CloneStrokeColor.Color = [System.Windows.Media.Colors]::$newRandomColor
                    $UIHash.ThermalChartSeries[$plus1].Stroke = $CloneStrokeColor
    
                    #Set Line Series Visibility to the listviewItem checkbox status
                    $Binding = New-Object System.Windows.Data.Binding
                    $Binding.Path = [System.Windows.PropertyPath]::new("IsChecked")
                    $Binding.Converter = [System.Windows.Controls.BooleanToVisibilityConverter]::new()
                    $Binding.Source = $DataHash.ThermalListViewItems | where Name -eq $_.Path
                        [void][System.Windows.Data.BindingOperations]::SetBinding($UIHash.ThermalChartSeries[$plus1],[LiveCharts.Wpf.LineSeries]::VisibilityProperty, $Binding)
                    })
                    
                }
                
                if ($X -lt $_.Timestamp){
                    $X = $_.Timestamp
                    $DataHash.ThermalX += $DataHash.ThermalIntervalX
                }
    
                $CookedValue = [Math]::Round($_.CookedValue,2)
                $newPoint = [LiveCharts.Defaults.ObservablePoint]::new($DataHash.ThermalX,$CookedValue)

                $index = ($DataHash.ThermalSeriesCollectionTitles | where Title -eq $_.Path).Index
                $DataHash.ThermalChartValues[$index].Add($newPoint)
    
                $Item = $DataHash.ThermalListViewItems | where Name -eq $_.Path
                $Item.Value = $CookedValue
    
                if ($ThermalHash.Logging.Checked){
                    if (Test-Path $ThermalHash.FilePath.Text){
                        $ThermalLogs | Export-Counter -Path "$($ThermalHash.FilePath.Text.TrimEnd("\"))\$ThermalFilePrefix-ThermalCounterLogs.$($ThermalHash.FileFormat.SelectedItem)" -FileFormat $ThermalHash.FileFormat.SelectedItem -Force
                    }
                }
            }
        }
        catch{
            Show-Messagebox -Title "Thermal Runspace" -Text "$($_.Exception.Message)" -Icon Error
            $UIHash.ThermalStopButton.Dispatcher.Invoke([action]{$UIHash.ThermalStopButton.Enabled = $false})
            $UIHash.ThermalStartButton.Dispatcher.Invoke([action]{$UIHash.ThermalStartButton.Enabled = $true})
        }
    }
}