function Show-ProcessWindow {
    param(
        $SourceItems
    )
    $ProcessRunspace = [powershell]::Create().AddScript{
        Try{
            $ErrorActionPreference = "Stop"
            Add-Type -AssemblyName PresentationFramework
            Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
            Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {Add-Type -Path $_.FullName}
    
            $XAMLPath = Join-Path -Path $DataHash.WPF -ChildPath ProcessDataGridWindow.xaml
            $ProcessWindow = Import-Xaml -Path $XAMLPath
            $DataGrid = $ProcessWindow.FindName("ProcessesDataGrid")
            $SearchTextbox = $ProcessWindow.FindName("SearchTextBox")
            $FilterCombobox = $ProcessWindow.FindName("FilterComboBox")
            $ColumnCombobox = $ProcessWindow.FindName("ColumnCombobox")
            $FilterByCombobox = $ProcessWindow.FindName("FilterByCombobox")
    
            $DataGrid.ItemsSource = $DataHash.SourceItems
    
            $SearchTextbox.ADD_TextChanged({
                if ($_.Source.Text.Length -ge 1){
                    switch ($FilterByCombobox.SelectedItem.Text) {
                        "Contains" {$FilteredItems = $DataHash.SourceItems | where $ColumnCombobox.SelectedItem.Text -like "*$($_.Source.Text)*"}
                        "Starts With" {$FilteredItems = $DataHash.SourceItems | where $ColumnCombobox.SelectedItem.Text -like "*$($_.Source.Text)"}
                        "Ends With" {$FilteredItems = $DataHash.SourceItems | where $ColumnCombobox.SelectedItem.Text -like "$($_.Source.Text)*"}
                        "Exact Match" {$FilteredItems = $DataHash.SourceItems | where $ColumnCombobox.SelectedItem.Text -eq "$($_.Source.Text)"}
                    }
                    $DataGrid.ItemsSource = $FilteredItems
                }
                else{
                    $DataGrid.ItemsSource = $DataHash.SourceItems
                }
            })
    
            $ProcessWindow.ShowDialog()
        }
        catch{
            Show-Messagebox -Text "$($_.Exception.Message)`n`n$($_.InvocationInfo.PositionMessage)" -Title "Process Datagrid Runspace"
        }
    }
    $ProcessRunspace.RunspacePool = $ScriptsHash.RunspacePool
    [void]$ProcessRunspace.BeginInvoke()
}