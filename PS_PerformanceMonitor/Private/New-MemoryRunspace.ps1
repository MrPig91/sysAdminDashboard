function New-MemoryRunspace {
    [powershell]::Create().AddScript{
        Add-Type -AssemblyName PresentationFramework
        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {Add-Type -Path $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}
    
        try{
            $X = Get-Date

            $UIHash.MemoryDefaultCounterComboBox.Dispatcher.Invoke([action]{$DataHash.MemoryCounter = $UIHash.MemoryDefaultCounterComboBox.SelectedItem.Counter})

            $computers = $DataHash.addedComputers | where IsChecked -eq $true
            $UIHash.TimeIntervalSlider.Dispatcher.Invoke([action]{$DataHash.MemoryIntervalX = $UIHash.TimeIntervalSlider.Value})
            $DataHash.MemoryX -= $DataHash.MemoryIntervalX
    
            Get-Counter -Counter $DataHash.MemoryCounter -Continuous -ComputerName $computers.ComputerName -SampleInterval $DataHash.MemoryIntervalX -ErrorAction Stop -ErrorVariable ErrVar -OutVariable MemoryLogs |
            select -expandProperty CounterSamples |
             foreach -Begin {
                $MemoryFilePrefix = Get-Date -Format "yyyyMMdd(s)"
             } -Process {
                if ($DataHash.MemorySeriesCollectionTitles.Title -notcontains $_.Path){
                    $newRandomColor = ([System.Windows.Media.Colors] | gm -Static -MemberType Properties)[(Get-Random -Minimum 0 -Maximum 141)].Name
    
                    $plus1 = ($DataHash.MemorySeriesCollectionTitles | Measure).Count + 1
                    $newIndex = [PSCustomObject]@{
                        Title = $_.Path
                        Index = $plus1
                    }
    
                    $DataHash.MemorySeriesCollectionTitles.Add($newIndex)
                    $newCounterListViewItem = $DataHash.MemoryListViewList[$plus1]
                    $newCounterListViewItem.Name = $_.Path
                    $newCounterListViewItem.Counter = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[1].split('(')[0])
                    $newCounterListViewItem.ComputerName = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[0])
                    $newCounterListViewItem.Instance =  ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[1].split('(')[1].trimend(')'))
                    $newCounterListViewItem.Units = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[2])
                    $newCounterListViewItem.Value = 0
                    $newCounterListViewItem.LineColor = $newRandomColor
                    $newCounterListViewItem.LineThickness = 2
                    $DataHash.MemoryListViewItems.Add($newCounterListViewItem)
    
                    $UIHash.MemoryLineChart.Dispatcher.Invoke([action]{
                    $UIHash.MemoryChartSeries[$plus1].Title = $_.Path
                    $UIHash.MemoryChartSeries[$plus1].PointGeometrySize = 2
                    $UIHash.MemoryChartSeries[$plus1].LineSmoothness = .2
                    $CloneStrokeColor = $UIHash.MemoryChartSeries[$plus1].Stroke.Clone()
                    $CloneFillColor = $UIHash.MemoryChartSeries[$plus1].Fill.Clone()
                    $CloneFillColor.Color = [System.Windows.Media.Colors]::$newRandomColor
                    $UIHash.MemoryChartSeries[$plus1].Fill = $CloneFillColor
                    $CloneStrokeColor.Color = [System.Windows.Media.Colors]::$newRandomColor
                    $UIHash.MemoryChartSeries[$plus1].Stroke = $CloneStrokeColor
    
                    #Set Line Series Visibility to the listviewItem checkbox status
                    $Binding = New-Object System.Windows.Data.Binding
                    $Binding.Path = [System.Windows.PropertyPath]::new("IsChecked")
                    $Binding.Converter = [System.Windows.Controls.BooleanToVisibilityConverter]::new()
                    $Binding.Source = $DataHash.MemoryListViewItems | where Name -eq $_.Path
                        [void][System.Windows.Data.BindingOperations]::SetBinding($UIHash.MemoryChartSeries[$plus1],[LiveCharts.Wpf.LineSeries]::VisibilityProperty, $Binding)
                    })
                    
                }
                
                if ($X -lt $_.Timestamp){
                    $X = $_.Timestamp
                    $DataHash.MemoryX += $DataHash.MemoryIntervalX
                }
    
                $CookedValue = [Math]::Round($_.CookedValue,2)
                $newPoint = [LiveCharts.Defaults.ObservablePoint]::new($DataHash.MemoryX,$CookedValue)

                $index = ($DataHash.MemorySeriesCollectionTitles | where Title -eq $_.Path).Index
                $DataHash.MemoryChartValues[$index].Add($newPoint)
    
                $Item = $DataHash.MemoryListViewItems | where Name -eq $_.Path
                $Item.Value = $CookedValue
    
                if ($MemoryHash.Logging.Checked){
                    if (Test-Path $MemoryHash.FilePath.Text){
                        $MemoryLogs | Export-Counter -Path "$($MemoryHash.FilePath.Text.TrimEnd("\"))\$MemoryFilePrefix-MemoryCounterLogs.$($MemoryHash.FileFormat.SelectedItem)" -FileFormat $MemoryHash.FileFormat.SelectedItem -Force
                    }
                }
            }
        }
        catch{
            Show-Messagebox -Title "Memory Runspace" -Text "$($_.Exception.Message)" -Icon Error
            $UIHash.MemoryStopButton.Enabled = $false
            $UIHash.MemoryStartButton.Enabled = $true
        }
    }
}