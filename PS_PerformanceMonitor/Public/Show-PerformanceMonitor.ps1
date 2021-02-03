function Show-PerformanceMonitor {
    Add-Type -AssemblyName PresentationFramework

    $Global:UIHash = [hashtable]::Synchronized(@{})
    $Global:DataHash = [hashtable]::Synchronized(@{})
    $ScriptsHash = [hashtable]::Synchronized(@{})
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $UISync = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("UIHash", $UIHash, $Null)
    $DataSync = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("DataHash", $DataHash, $Null)
    $ScriptsSync = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("ScriptsHash", $ScriptsHash, $Null)
    $InitialSessionState.Variables.Add($UISync)
    $InitialSessionState.Variables.Add($DataSync)
    $InitialSessionState.Variables.Add($ScriptsSync)
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1,5,$InitialSessionState,$Host)
    $RunspacePool.ApartmentState = "STA"
    $RunspacePool.ThreadOptions = "ReuseThread"
    $RunspacePool.open()

    #DataHash Adding Properties
    $DataHash.ModuleRoot = $MyInvocation.MyCommand.Module.ModuleBase
    $DataHash.PrivateFunctions = Join-Path -Path $DataHash.ModuleRoot -ChildPath "Private"
    $DataHash.Assemblies = Join-Path -Path $DataHash.ModuleRoot -ChildPath "Assemblies"
    $DataHash.WPF = Join-Path -Path $DataHash.ModuleRoot -ChildPath "WPF"
    $DataHash.Classes = Join-Path -Path $DataHash.ModuleRoot -ChildPath "Classes"

    #Import required assemblies and private functions
    Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
    Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {Add-Type -Path $_.FullName}

    #DefaultCounters Thread
    $DefaultCounterRunspaces = New-GetDefaultCountersRunspace
    $DefaultCounterRunspaces | foreach {
        $_.RunspacePool = $RunspacePool
    }
    $ScriptsHash.DefaultCounters = $DefaultCounterRunspaces

    #Create UI Thread
    $UIRunspace = New-UIRunspace
    $UIRunspace.RunspacePool = $RunspacePool
    [void]$UIRunspace.BeginInvoke()

    #Create grabbing computers from AD Thread
    $GetComputersRunspace = New-GetComputerRunspace
    $GetComputersRunspace.RunspacePool = $RunspacePool
    [void]$GetComputersRunspace.BeginInvoke()

    #Add Ping Script To RunspacePool
    $PingRunspace = New-PingRunspace
    $PingRunspace.RunspacePool = $RunspacePool
    $ScriptsHash.Ping = $PingRunspace

    #Add CPU Script To RunspacePool
    $CPURunspace = New-CPURunspace
    $CPURunspace.RunspacePool = $RunspacePool
    $ScriptsHash.CPURunspace = $CPURunspace

    #Add Network Script To RunspacePool
    $NetworkRunspace = New-NetworkRunspace
    $NetworkRunspace.RunspacePool = $RunspacePool
    $ScriptsHash.NetworkRunspace = $NetworkRunspace

    #Add Memory Script To RunspacePool
    $MemoryRunspace = New-MemoryRunspace
    $MemoryRunspace.RunspacePool = $RunspacePool
    $ScriptsHash.MemoryRunspace = $MemoryRunspace

    #Add Disk Script To RunspacePool
    $DiskRunspace = New-DiskRunspace
    $DiskRunspace.RunspacePool = $RunspacePool
    $ScriptsHash.DiskRunspace = $DiskRunspace

    #Add Thermal Script To RunspacePool
    $ThermalRunspace = New-ThermalRunspace
    $ThermalRunspace.RunspacePool = $RunspacePool
    $ScriptsHash.ThermalRunspace = $ThermalRunspace
}