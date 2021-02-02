function New-GetDefaultCountersRunspace {
    #CPU counters
    [powershell]::Create().AddScript{
        try{
            $CPUCounters = New-Object System.Collections.Generic.List[System.Object]
            $CPUCounters.ADD([PSCustomObject]@{
                Counter = "\processor(_total)\% processor time"
                FriendlyName = "(_total)\% processor time"
            })
            $CPUCounters.AddRange(((Get-Counter -ListSet Processor).Counter | foreach {
                [PSCustomObject]@{
                    Counter = $_
                    FriendlyName = $_.split('\')[2]
                }
            }))
            $UIHash.CPUDefaultCounterComboBox.Dispatcher.Invoke([action]{
                $UIHash.CPUDefaultCounterComboBox.ItemsSource = $CPUCounters
                $UIHash.CPUDefaultCounterComboBox.SelectedIndex = 0
            })
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title $_.Exception.GetType().BaseType -Icon Error
        }
    }

    #network counters
    [powershell]::Create().AddScript{
        Try{
            $NetworkCounters = (Get-Counter -ListSet "Network Interface").Counter | foreach {
            [PSCustomObject]@{
                Counter = $_
                FriendlyName = $_.split('\')[2]
            }
        }
        $UIHash.NetworkDefaultCounterComboBox.Dispatcher.Invoke([action]{$UIHash.NetworkDefaultCounterComboBox.ItemsSource = $NetworkCounters
            $UIHash.NetworkDefaultCounterComboBox.SelectedIndex = 0
            })
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title $_.Exception.GetType().BaseType -Icon Error
        }
    }

    #memory counters
    [powershell]::Create().AddScript{
        try{
            $MemoryCounters = (Get-Counter -ListSet Memory).Counter | foreach {
                [PSCustomObject]@{
                    Counter = $_
                    FriendlyName = $_.split('\')[2]
                }
            }
            $UIHash.MemoryDefaultCounterComboBox.Dispatcher.Invoke([action]{
                $UIHash.MemoryDefaultCounterComboBox.ItemsSource = $MemoryCounters
                $UIHash.MemoryDefaultCounterComboBox.SelectedIndex = 26
            })
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title $_.Exception.GetType().BaseType -Icon Error
        }
    }

    #disk counters
    [powershell]::Create().AddScript{
        try{
            $DiskCounters = (Get-Counter -ListSet PhysicalDisk).Counter | foreach {
                [PSCustomObject]@{
                    Counter = $_
                    FriendlyName = $_.split('\')[2]
                }
            }
            $UIHash.DiskDefaultCounterComboBox.Dispatcher.Invoke([action]{
                $UIHash.DiskDefaultCounterComboBox.ItemsSource = $DiskCounters
                $UIHash.DiskDefaultCounterComboBox.SelectedIndex = 1
            })
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title $_.Exception.GetType().BaseType -Icon Error
        }
    }
}