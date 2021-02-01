function Show-PerformanceMonitor {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName WindowsFormsIntegration

    $UIHash = [hashtable]::Synchronized(@{})
    $DataHash = [hashtable]::Synchronized(@{})
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $UISync = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("UIHash", $UIHash, $Null)
    $DataSync = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("DataHash", $DataHash, $Null)
    $InitialSessionState.Variables.Add($UISync)
    $InitialSessionState.Variables.Add($DataSync)
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1,5,$InitialSessionState,$Host)
    $RunspacePool.ApartmentState = "STA"
    $RunspacePool.ThreadOptions = "ReuseThread"
    $RunspacePool.open()

    $DataHash.ModuleRoot = $MyInvocation.MyCommand.Module.ModuleBase
    $DataHash.PrivateFunctions = Join-Path -Path $DataHash.ModuleRoot -ChildPath "Private"
    $DataHash.Assemblies = Join-Path -Path $DataHash.ModuleRoot -ChildPath "Assemblies"

    Get-childItem -Path $DataHash.PrivateFunctions | ForEach-Object {Import-Module $_.FullName}
    Get-childItem -Path $DataHash.Assemblies | ForEach-Object {Add-Type -AssemblyName $_.FullName}
}