function New-GetDefaultCountersRunspace {
    #CPU counters
    [powershell]::Create().AddScript{
        try{
            $CPUCounters = New-Object System.Collections.Generic.List[System.Object]
            $CPUCounters.ADD([PSCustomObject]@{
                Counter = "\processor(_total)\% processor time"
                FriendlyName = "(_total)\% processor time"
            })
            $CPUCounters.AddRange(((Get-Counter -ListSet Processor -OutVariable CPUToolTip).Counter | foreach {
                [PSCustomObject]@{
                    Counter = $_
                    FriendlyName = $_.split('\')[2]
                }
            }))
            $UIHash.CPUDefaultCounterComboBox.Dispatcher.Invoke([action]{
                $UIHash.CPUDefaultCounterComboBox.ItemsSource = $CPUCounters
                $UIHash.CPUDefaultCounterComboBox.SelectedIndex = 0
                $UIHash.CPUDefaultCounterComboBox.ToolTip = $CPUToolTip.Description
            })
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title $_.Exception.GetType().BaseType -Icon Error
        }
    }

    #network counters
    [powershell]::Create().AddScript{
        Try{
            $NetworkCounters = (Get-Counter -ListSet "Network Interface" -OutVariable NetToolTip).Counter | foreach {
            [PSCustomObject]@{
                Counter = $_
                FriendlyName = $_.split('\')[2]
            }
        }
        $UIHash.NetworkDefaultCounterComboBox.Dispatcher.Invoke([action]{$UIHash.NetworkDefaultCounterComboBox.ItemsSource = $NetworkCounters
            $UIHash.NetworkDefaultCounterComboBox.SelectedIndex = 0
            $UIHash.NetworkDefaultCounterComboBox.ToolTip = $NetToolTip.Description
            })
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title $_.Exception.GetType().BaseType -Icon Error
        }
    }

    #memory counters
    [powershell]::Create().AddScript{
        try{
            $MemoryCounters = (Get-Counter -ListSet Memory -OutVariable MemoryToolTip).Counter | foreach {
                [PSCustomObject]@{
                    Counter = $_
                    FriendlyName = $_.split('\')[2]
                }
            }
            $UIHash.MemoryDefaultCounterComboBox.Dispatcher.Invoke([action]{
                $UIHash.MemoryDefaultCounterComboBox.ItemsSource = $MemoryCounters
                $UIHash.MemoryDefaultCounterComboBox.SelectedIndex = 26
                $UIHash.MemoryDefaultCounterComboBox.ToolTip = $MemoryToolTip.Description
            })
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title $_.Exception.GetType().BaseType -Icon Error
        }
    }

    #disk counters
    [powershell]::Create().AddScript{
        try{
            $DiskCounters = (Get-Counter -ListSet PhysicalDisk -OutVariable DiskToolTip).Counter | foreach {
                [PSCustomObject]@{
                    Counter = $_
                    FriendlyName = $_.split('\')[2]
                }
            }
            $UIHash.DiskDefaultCounterComboBox.Dispatcher.Invoke([action]{
                $UIHash.DiskDefaultCounterComboBox.ItemsSource = $DiskCounters
                $UIHash.DiskDefaultCounterComboBox.SelectedIndex = 1
                $UIHash.DiskDefaultCounterComboBox.ToolTip = $DiskToolTip.Description
            })
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title $_.Exception.GetType().BaseType -Icon Error
        }
    }
}