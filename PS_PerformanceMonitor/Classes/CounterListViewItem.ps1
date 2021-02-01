Add-Type -Language CSharp @'
using System.ComponentModel;
public class CounterListViewItem : INotifyPropertyChanged
    {
        private double _value;
        private bool _ischecked;
        private string _linecolor;
        private int _linethickness;
        public string Name { get; set; }
        public string Counter { get; set; }
        public string ComputerName { get; set; }
        public string Instance { get; set; }
        public string Units { get; set; }
        public int LineThickness
        {
            get {return _linethickness;}
            set
            {
                _linethickness = value;
                NotifyPropertyChanged("LineThickness");
            }
        }
        public bool IsChecked
        {
            get {return _ischecked; }
            set
            {
                _ischecked = value;
                NotifyPropertyChanged("IsChecked");
            }
        }
        public double Value
        {
            get { return _value; }
            set
            {
                _value = value;
                NotifyPropertyChanged("Value");
            }
        }

        
        public string LineColor
        {
            get { return _linecolor; }
            set
            {
                _linecolor = value;
                NotifyPropertyChanged("LineColor");
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
    }
'@