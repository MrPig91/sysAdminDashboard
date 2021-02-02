Add-Type -Language CSharp @'
using System.ComponentModel;
public class ComputerListViewItem : INotifyPropertyChanged
    {
        private bool _ischecked;
        public string ComputerName { get; set; }
        public string IPAddress { get; set; }
        public string SerialNumber { get; set; }
        public string OperatingSystem { get; set; }
        public bool Online { get; set; }
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
        }
    }
'@