Add-Type -Language CSharp @'
using System.ComponentModel;
using LiveCharts;
using System.Collections.ObjectModel;

public class DiskInfo
{
    public double TotalSize { get; set; }
    public double FreeSpace { get; set; }
    public double PercentFree {get; set; }
    public bool HasData {get; set; }
    public double UsedSpace { get; set; }

    public LiveCharts.ChartValues<double> UsedSpaceValues { get; set; }
    public LiveCharts.ChartValues<double> FreeSpaceValues { get; set; }

    public DiskInfo (double totalsize, double freespace)
    {
        if (totalsize != 0)
        {
            PercentFree = System.Math.Round((freespace / totalsize) * 100,2);
        }
        else
        {
            PercentFree = 0;
        }

        TotalSize = totalsize;
        FreeSpace = freespace;
        UsedSpace = totalsize - freespace;

        UsedSpaceValues = new LiveCharts.ChartValues<double>();
        FreeSpaceValues = new LiveCharts.ChartValues<double>();

        UsedSpaceValues.Add(totalsize - freespace);
        FreeSpaceValues.Add(freespace);
    }
}

public class ComputerListViewItem : INotifyPropertyChanged
    {
        private bool _ischecked;
        private DiskInfo _diskinfo;
        private ObservableCollection<System.Object> _loggedinuser;

        public string ComputerName { get; set; }
        public string IPAddress { get; set; }
        public string SerialNumber { get; set; }
        public string OperatingSystem { get; set; }
        public bool Online { get; set; }
        public ObservableCollection<System.Object> LoggedInUser
        {
            get {return _loggedinuser;}
            set{
                _loggedinuser = value;
                NotifyPropertyChanged("LoggedInUser");
            }
        }

        public DiskInfo diskInfo
        {
            get {return _diskinfo; }
            set
            {
                _diskinfo = value;
                NotifyPropertyChanged("diskInfo");
            }
        }
        public bool Scanned { get; set; }
        public bool IsChecked
        {
            get {return _ischecked; }
            set
            {
                _ischecked = value;
                NotifyPropertyChanged("IsChecked");
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        private void NotifyPropertyChanged(string property)
        {
            if (PropertyChanged != null)
            {
                PropertyChanged(this, new PropertyChangedEventArgs(property));
            }
        }

        public ComputerListViewItem (string computername, string OS, string IP, string sn, bool ischecked)
        {
            ComputerName = computername;
            OperatingSystem = OS;
            IPAddress = IP;
            SerialNumber = sn;
            IsChecked = ischecked;
            diskInfo = new DiskInfo(0, 0);
            LoggedInUser = new ObservableCollection<System.Object>();
        }
    }
'@ -ReferencedAssemblies (Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {$_.FullName})