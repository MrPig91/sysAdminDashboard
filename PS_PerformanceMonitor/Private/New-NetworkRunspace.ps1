function New-NetworkRunspace {
    [powershell]::Create().AddScript{
        Add-Type -AssemblyName PresentationFramework
        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {Add-Type -Path $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}
    
        try{
            $X = Get-Date

            $UIHash.NetworkDefaultCounterComboBox.Dispatcher.Invoke([action]{$DataHash.NetworkCounter = $UIHash.NetworkDefaultCounterComboBox.SelectedItem.Counter})

            $computers = $DataHash.addedComputers | where IsChecked -eq $true
            $UIHash.NetworkTimeSlider.Dispatcher.Invoke([action]{$DataHash.NetworkIntervalX = $UIHash.NetworkTimeSlider.Value})
            $DataHash.NetworkX -= $DataHash.NetworkIntervalX
    
            Get-Counter -Counter $DataHash.NetworkCounter -Continuous -ComputerName $computers.ComputerName -SampleInterval $DataHash.NetworkIntervalX -ErrorAction Stop -ErrorVariable ErrVar -OutVariable NetworkLogs |
            select -expandProperty CounterSamples |
             foreach -Begin {
                $NetworkFilePrefix = Get-Date -Format "yyyyMMdd(s)"
             } -Process {
                if ($DataHash.NetworkSeriesCollectionTitles.Title -notcontains $_.Path){
                    $newRandomColor = ([System.Windows.Media.Colors] | gm -Static -MemberType Properties)[(Get-Random -Minimum 0 -Maximum 141)].Name
    
                    $plus1 = ($DataHash.NetworkSeriesCollectionTitles | Measure).Count + 1
                    $newIndex = [PSCustomObject]@{
                        Title = $_.Path
                        Index = $plus1
                    }
    
                    $DataHash.NetworkSeriesCollectionTitles.Add($newIndex)
                    $newCounterListViewItem = $DataHash.NetworkListViewList[$plus1]
                    $newCounterListViewItem.Name = $_.Path
                    $newCounterListViewItem.Counter = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[1].split('(')[0])
                    $newCounterListViewItem.ComputerName = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[0])
                    $newCounterListViewItem.Instance =  $_.InstanceName
                    $newCounterListViewItem.Units = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[2])
                    $newCounterListViewItem.Value = 0
                    $newCounterListViewItem.LineColor = $newRandomColor
                    $newCounterListViewItem.LineThickness = 2
                    $DataHash.NetworkListViewItems.Add($newCounterListViewItem)
    
                    $UIHash.NetworkLineChart.Dispatcher.Invoke([action]{
                    $UIHash.NetworkChartSeries[$plus1].Title = $_.Path
                    $UIHash.NetworkChartSeries[$plus1].PointGeometrySize = 2
                    $UIHash.NetworkChartSeries[$plus1].LineSmoothness = .2
                    $CloneStrokeColor = $UIHash.NetworkChartSeries[$plus1].Stroke.Clone()
                    $CloneFillColor = $UIHash.NetworkChartSeries[$plus1].Fill.Clone()
                    $CloneFillColor.Color = [System.Windows.Media.Colors]::$newRandomColor
                    $UIHash.NetworkChartSeries[$plus1].Fill = $CloneFillColor
                    $CloneStrokeColor.Color = [System.Windows.Media.Colors]::$newRandomColor
                    $UIHash.NetworkChartSeries[$plus1].Stroke = $CloneStrokeColor
    
                    #Set Line Series Visibility to the listviewItem checkbox status
                    $Binding = New-Object System.Windows.Data.Binding
                    $Binding.Path = [System.Windows.PropertyPath]::new("IsChecked")
                    $Binding.Converter = [System.Windows.Controls.BooleanToVisibilityConverter]::new()
                    $Binding.Source = $DataHash.NetworkListViewItems | where Name -eq $_.Path
                        [void][System.Windows.Data.BindingOperations]::SetBinding($UIHash.NetworkChartSeries[$plus1],[LiveCharts.Wpf.LineSeries]::VisibilityProperty, $Binding)
                    })
                    
                }
                
                if ($X -lt $_.Timestamp){
                    $X = $_.Timestamp
                    $DataHash.NetworkX += $DataHash.NetworkIntervalX
                }
    
                $CookedValue = [Math]::Round($_.CookedValue,2)
                $newPoint = [LiveCharts.Defaults.ObservablePoint]::new($DataHash.NetworkX,$CookedValue)
                $index = ($DataHash.NetworkSeriesCollectionTitles | where Title -eq $_.Path).Index
                $DataHash.NetworkChartValues[$index].Add($newPoint)
    
    
                $Item = $DataHash.NetworkListViewItems | where Name -eq $_.Path
                $Item.Value = $CookedValue

                if ($NetworkHash.Logging.Checked){
                    if (Test-Path $NetworkHash.FilePath.Text){
                        $NetworkLogs | Export-Counter -Path "$($NetworkHash.FilePath.Text.TrimEnd("\"))\$NetworkFilePrefix-NetworkCounterLogs.$($NetworkHash.FileFormat.SelectedItem)" -FileFormat $NetworkHash.FileFormat.SelectedItem -Force
                    }
                }
            }
        }
        catch{
            Show-Messagebox -Title "Network Runspace" -Text "$($_.Exception.Message)" -Icon Error
            $UIHash.NetworkStopButton.Dispatcher.Invoke([action]{$UIHash.NetworkStopButton.Enabled = $false})
            $UIHash.NetworkStartButton.Dispatcher.Invoke([action]{$UIHash.NetworkStartButton.Enabled = $true})
        }
    }
}