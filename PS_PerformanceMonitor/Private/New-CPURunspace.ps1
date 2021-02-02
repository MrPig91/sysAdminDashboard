function New-CPURunspace {
    [powershell]::Create().AddScript{
        Add-Type -AssemblyName PresentationFramework
        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {Add-Type -Path $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}
    
        try{
            $X = Get-Date
            #if ($CPUHash.RadioOFF.Checked){
                $UIHash.CPUDefaultCounterComboBox.Dispatcher.Invoke([action]{$DataHash.CPUCounter = $UIHash.CPUDefaultCounterComboBox.SelectedItem.Counter})
            #}
            #else{
             #  $Counters = $CPUHash.ListView.Items.Name
            #}
            $computers = $DataHash.addedComputers | where IsChecked -eq $true
            $UIHash.TimeIntervalSlider.Dispatcher.Invoke([action]{$DataHash.CPUIntervalX = $UIHash.TimeIntervalSlider.Value})
            $DataHash.X -= $DataHash.CPUIntervalX
    
            Get-Counter -Counter $DataHash.CPUCounter -Continuous -ComputerName $computers.ComputerName -SampleInterval $DataHash.CPUIntervalX -ErrorAction Stop -ErrorVariable ErrVar -OutVariable CPULogs |
            select -expandProperty CounterSamples |
             foreach -Begin {
                $CPUFilePrefix = Get-Date -Format "yyyyMMdd(s)"
             } -Process {
                if ($DataHash.SeriesCollectionTitles.Title -notcontains $_.Path){
                    $newRandomColor = ([System.Windows.Media.Colors] | gm -Static -MemberType Properties)[(Get-Random -Minimum 0 -Maximum 141)].Name
    
                    $plus1 = ($DataHash.SeriesCollectionTitles | Measure).Count + 1
                    $newIndex = [PSCustomObject]@{
                        Title = $_.Path
                        Index = $plus1
                    }
    
                    $DataHash.SeriesCollectionTitles.Add($newIndex)
                    $newCounterListViewItem = $DataHash.ListViewList[$plus1]
                    $newCounterListViewItem.Name = $_.Path
                    $newCounterListViewItem.Counter = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[1].split('(')[0])
                    $newCounterListViewItem.ComputerName = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[0])
                    $newCounterListViewItem.Instance =  ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[1].split('(')[1].trimend(')'))
                    $newCounterListViewItem.Units = ($_.Path.Split('\',[System.StringSplitOptions]::RemoveEmptyEntries)[2])
                    $newCounterListViewItem.Value = 0
                    $newCounterListViewItem.LineColor = $newRandomColor
                    $newCounterListViewItem.LineThickness = 2
                    $DataHash.ListViewItems.Add($newCounterListViewItem)
    
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
                    $Binding.Source = $DataHash.ListViewItems | where Name -eq $_.Path
                        [void][System.Windows.Data.BindingOperations]::SetBinding($UIHash.CPUChartSeries[$plus1],[LiveCharts.Wpf.LineSeries]::VisibilityProperty, $Binding)
                    })
                    
                }
                
                if ($X -lt $_.Timestamp){
                    $X = $_.Timestamp
                    $DataHash.X += $DataHash.CPUIntervalX
                }
    
                $CookedValue = [Math]::Round($_.CookedValue,2)
                $newPoint = [LiveCharts.Defaults.ObservablePoint]::new($DataHash.X,$CookedValue)
                #$CPUHash.Chart.Dispatcher.Invoke([action]{(($CPUHash.Chart.Series | where Title -eq $_.Path).Values.ADD($cookedValue))})
                $index = ($DataHash.SeriesCollectionTitles | where Title -eq $_.Path).Index
                $DataHash.CPUChartValues[$index].Add($newPoint)
    
                #$CookedValue = [Math]::Round($_.CookedValue,2)
    
                $Item = $DataHash.ListViewItems | where Name -eq $_.Path
                $Item.Value = $CookedValue
    
                #$CPUHash.ListView.Dispatcher.Invoke([action]{$CPUHash.ListView.Items.Refresh()})
                if ($CPUHash.Logging.Checked){
                    if (Test-Path $CPUHash.FilePath.Text){
                        $CPULogs | Export-Counter -Path "$($CPUHash.FilePath.Text.TrimEnd("\"))\$CPUFilePrefix-CPUCounterLogs.$($CPUHash.FileFormat.SelectedItem)" -FileFormat $CPUHash.FileFormat.SelectedItem -Force
                    }
                }
            }
        }
        catch{
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message)
            [System.Windows.Forms.MessageBox]::Show(($_ | out-string))
            $UIHash.CPUStopButton.Enabled = $false
            $UIHash.CPUStartButton.Enabled = $true
        }
    }
}