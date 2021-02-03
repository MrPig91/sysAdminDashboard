function New-CPURunspace {
    [powershell]::Create().AddScript{
        Add-Type -AssemblyName PresentationFramework
        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {Add-Type -Path $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}
    
        try{
            $X = Get-Date

            $UIHash.CPUDefaultCounterComboBox.Dispatcher.Invoke([action]{$DataHash.CPUCounter = $UIHash.CPUDefaultCounterComboBox.SelectedItem.Counter})

            $computers = $DataHash.addedComputers | where IsChecked -eq $true
            $UIHash.TimeIntervalSlider.Dispatcher.Invoke([action]{$DataHash.CPUIntervalX = $UIHash.TimeIntervalSlider.Value})
            $DataHash.CPUX -= $DataHash.CPUIntervalX
    
            Get-Counter -Counter $DataHash.CPUCounter -Continuous -ComputerName $computers.ComputerName -SampleInterval $DataHash.CPUIntervalX -ErrorAction Stop -ErrorVariable ErrVar -OutVariable CPULogs |
            select -expandProperty CounterSamples |
             foreach -Begin {
                $CPUFilePrefix = Get-Date -Format "yyyyMMdd(s)"
             } -Process {
                if ($DataHash.CPUSeriesCollectionTitles.Title -notcontains $_.Path){
                    $newRandomColor = ([System.Windows.Media.Colors] | gm -Static -MemberType Properties)[(Get-Random -Minimum 0 -Maximum 141)].Name
    
                    $plus1 = ($DataHash.CPUSeriesCollectionTitles | Measure).Count + 1
                    $newIndex = [PSCustomObject]@{
                        Title = $_.Path
                        Index = $plus1
                    }
    
                    $DataHash.CPUSeriesCollectionTitles.Add($newIndex)
                    $newCounterListViewItem = $DataHash.CPUListViewList[$plus1]
                    $newCounterListViewItem.Name = $_.Path
                    $newCounterListViewItem.Counter = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[1].split('(')[0])
                    $newCounterListViewItem.ComputerName = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[0])
                    $newCounterListViewItem.Instance =  $_.InstanceName
                    $newCounterListViewItem.Units = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[2])
                    $newCounterListViewItem.Value = 0
                    $newCounterListViewItem.LineColor = $newRandomColor
                    $newCounterListViewItem.LineThickness = 2
                    $DataHash.CPUListViewItems.Add($newCounterListViewItem)
    
                    $UIHash.CPULineChart.Dispatcher.Invoke([action]{
                    $UIHash.CPUChartSeries[$plus1].Title = $_.Path
                    $UIHash.CPUChartSeries[$plus1].PointGeometrySize = 2
                    $UIHash.CPUChartSeries[$plus1].LineSmoothness = .2
                    $CloneStrokeColor = $UIHash.CPUChartSeries[$plus1].Stroke.Clone()
                    $CloneFillColor = $UIHash.CPUChartSeries[$plus1].Fill.Clone()
                    $CloneFillColor.Color = [System.Windows.Media.Colors]::$newRandomColor
                    $UIHash.CPUChartSeries[$plus1].Fill = $CloneFillColor
                    $CloneStrokeColor.Color = [System.Windows.Media.Colors]::$newRandomColor
                    $UIHash.CPUChartSeries[$plus1].Stroke = $CloneStrokeColor
    
                    #Set Line Series Visibility to the listviewItem checkbox status
                    $Binding = New-Object System.Windows.Data.Binding
                    $Binding.Path = [System.Windows.PropertyPath]::new("IsChecked")
                    $Binding.Converter = [System.Windows.Controls.BooleanToVisibilityConverter]::new()
                    $Binding.Source = $DataHash.CPUListViewItems | where Name -eq $_.Path
                        [void][System.Windows.Data.BindingOperations]::SetBinding($UIHash.CPUChartSeries[$plus1],[LiveCharts.Wpf.LineSeries]::VisibilityProperty, $Binding)
                    })
                    
                }
                
                if ($X -lt $_.Timestamp){
                    $X = $_.Timestamp
                    $DataHash.CPUX += $DataHash.CPUIntervalX
                }
    
                $CookedValue = [Math]::Round($_.CookedValue,2)
                $newPoint = [LiveCharts.Defaults.ObservablePoint]::new($DataHash.CPUX,$CookedValue)

                $index = ($DataHash.CPUSeriesCollectionTitles | where Title -eq $_.Path).Index
                $DataHash.CPUChartValues[$index].Add($newPoint)
    
                $Item = $DataHash.CPUListViewItems | where Name -eq $_.Path
                $Item.Value = $CookedValue
    
                if ($CPUHash.Logging.Checked){
                    if (Test-Path $CPUHash.FilePath.Text){
                        $CPULogs | Export-Counter -Path "$($CPUHash.FilePath.Text.TrimEnd("\"))\$CPUFilePrefix-CPUCounterLogs.$($CPUHash.FileFormat.SelectedItem)" -FileFormat $CPUHash.FileFormat.SelectedItem -Force
                    }
                }
            }
        }
        catch{
            Show-Messagebox -Title "CPU Runspace" -Text "$($_.Exception.Message)" -Icon Error
            $UIHash.CPUStopButton.Dispatcher.Invoke([action]{$UIHash.CPUStopButton.Enabled = $false})
            $UIHash.CPUStartButton.Dispatcher.Invoke([action]{$UIHash.CPUStartButton.Enabled = $true})
        }
    }
}