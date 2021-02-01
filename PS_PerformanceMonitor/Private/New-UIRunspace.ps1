function New-UIRunspace{
    [powershell]::Create().AddScript{
        $ErrorActionPreference = "Stop"
        Add-Type -AssemblyName PresentationFramework
        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {Add-Type -Path $_.FullName}

        Try{
            $XAMLPath = Join-Path -Path $DataHash.WPF -ChildPath MainWindow.xaml
            $MainWindow = Import-Xaml -Path $XAMLPath
            $UIHash.MainWindow = $MainWindow
            $UIHash.MainTablControl = $MainWindow.FindName("MainTabControl")
            $UIHash.CPUTabPage = $MainWindow.FindName("CPUTabPage")
            $UIHash.AddComputerButton = $MainWindow.FindName("AddComputerButton")
            $UIHash.SelectAllButton = $MainWindow.FindName("SelectAllButton")
            $UIHash.DeSelectAllButton = $MainWindow.FindName("DeSelectAllButton")
            $UIHash.RemoveSelectedButton = $MainWindow.FindName("RemoveSelectedButton")
    
            $UIHash.MainWindow.ShowDialog()
        }
        catch{
            [System.Windows.MessageBox]::Show($_.Exception.Message)
            #Show-Messagebox -Text $_.Exception.Message
        }
    }
}