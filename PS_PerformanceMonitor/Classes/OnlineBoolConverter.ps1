<# Add-Type @'
using System;
using System.Windows;
using System.Windows.Data;

public class OnlineBooleanConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
    {
        switch(value.ToString().ToLower())
        {
            case "Online":
                return true;
            case "Offline":
                return false;
        }
        return false;
    }

    public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
    {
        if(value is bool)
        {
            if((bool)value == true)
                return "Online";
            else
                return "Offline";
        }
        return "no";
    }
}
'@ -ReferencedAssemblies PresentationFramework #>