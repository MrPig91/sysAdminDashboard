function New-UIRunspace{
    [powershell]::Create().AddScript{
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName WindowsFormsIntegration

        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Assemblies | ForEach-Object {Add-Type -AssemblyName $_.FullName}

        $MainWindow = Import-Xaml -Path $DataHash.WPF\MainWindow.xaml
        $UIHash.MainWindow = $MainWindow
        $UIHash.MainTablControl = $MainWindow.FindName("MainTabControl")
        $UIHash.CPUTabPage = $MainWindow.FindName("CPUTabPage")
        $UIHash.AddComputerButton = $MainWindow.FindName("AddComputerButton")
        $UIHash.SelectAllButton = $MainWindow.FindName("SelectAllButton")
        $UIHash.DeSelectAllButton = $MainWindow.FindName("DeSelectAllButton")
        $UIHash.RemoveSelectedButton = $MainWindow.FindName("RemoveSelectedButton")
    }
}