using System;
using System.Windows;
using CardLoader2000.ViewModels;
using System.Windows.Media;
using CardLoader2000.Interfaces.Objects;
using CardLoader2000.ViewModels.MainGUIWindows;

namespace CardLoader2000
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        ////Page singleton pattern:
        //private static MainWindow instance;

        //internal static MainWindow Instance
        //{
        //    get
        //    {
        //        if (instance == null)
        //        {
        //            instance = new MainWindow();
        //        }
        //        else
        //        {
        //            instance.OnNavigatedTo();
        //        }
        //        return instance;
        //    }
        //}
        ////End of page singleton pattern. LATER NOT NOW

        private readonly LoadingWindowVM VM = new LoadingWindowVM();

        public MainWindow()
        {
            InitializeComponent();

            Loaded += MainWindow_Loaded;
        }

        private void MainWindow_Loaded(object sender, RoutedEventArgs e)
        {
            OrderInfoTextBox.Text = "Type an order number above...";
            OrderNumberTextBox.Text = "";

            KeyTextBox.IsEnabled = false;

            UpdateWaitingPaidOrder();

            UpdateLayout();
        }

        private void UpdateWaitingPaidOrder()
        {
            CustomerNameLabel.Content = "Name: " + VM.WaitingCustomerName;
            StreetLabel.Content = "Street: " + VM.WaitingStreet;
            CityLabel.Content = "City: " + VM.WaitingZip + " - " + VM.WaitingCity;
            CountryLabel.Content = "Country: " + VM.WaitingRegion + " - " + VM.WaitingCountry;
            
            PostStampsLabel.Content = VM.WaitingPostInfo != null && VM.WaitingPostInfo.Length > 50
                ? VM.WaitingPostInfo.Substring(0, VM.WaitingPostInfo.IndexOf(" ", 45, StringComparison.InvariantCultureIgnoreCase))
                + "\n" + VM.WaitingPostInfo.Substring(VM.WaitingPostInfo.IndexOf(" ", 45, StringComparison.InvariantCultureIgnoreCase)).Trim() 
                : VM.WaitingPostInfo;

            //TODO: Get each piece of information from VM, don't mess with Order2 objects here.
        }

        private void LoadButton_Click(object sender, RoutedEventArgs e)
        {
            LoadButton.IsEnabled = false;

            LoadSettings loadSettings = new LoadSettings
            {
                CardFee = CardFeeTextBox.Text,
                ExpireFee = ExpireFeeCheckBox.IsChecked ?? false,
                LockCard = LockCardCheckBox.IsChecked ?? false,
                TestSettings = TestSettingsCheckBox.IsChecked ?? false
            };

            //Call VM:
            var res = VM.LoadClick(loadSettings);

            //UPDATE ERROR CODES:
            if (res != null && res.Success)
            {
                ErrorLabel.Foreground = Brushes.DarkGreen;
                if (!loadSettings.TestSettings)
                {
                    PrintWindow printWindow =
                        new PrintWindow("C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.PrintLibrary\\CustomerLetter.html");
                    printWindow.Show();
                }
                ErrorLabel.Content = "Card loaded and letter sent to printer. " + DateTime.Now.ToString("yyyy/MM/dd  HH:mm:ss");
            }
            else
            {
                ErrorLabel.Foreground = Brushes.Red;
                ErrorLabel.Content = res != null ? res.ErrorMessage : "Unknown error occured. Stop doing anything. " + DateTime.Now.ToString("yyyy/MM/dd  HH:mm:ss");
            }

            LoadButton.IsEnabled = true;
        }

        private void OrderNumberTextBox_KeyUp(object sender, System.Windows.Input.KeyEventArgs e)
        {
            OrderInfoTextBox.Text = VM.SearchOrder(OrderNumberTextBox.Text);

            UpdateLayout();
        }

        private void RedeemButton_Click(object sender, RoutedEventArgs e)
        {
            RedeemResponse resp = VM.Redeem(OrderNumberTextBox.Text, EmailTextBox.Text);

            if (resp != null)
            {
                if (!String.IsNullOrWhiteSpace(resp.Message))
                {
                    ErrorLabel.Foreground = resp.Success ? Brushes.DarkGreen : Brushes.Red;

                    ErrorLabel.Content = resp.Message + DateTime.Now.ToString("yyyy/MM/dd  HH:mm:ss");
                }

                if(resp.Success)
                    OrderInfoTextBox.Text = resp.OrderInfoText;

                UpdateLayout();
            }
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            VM.LastLoadedOrderPaidAndSent();
            UpdateWaitingPaidOrder();
            UpdateLayout();
        }

        //private void OnNavigatedTo()
        //{
        //}
    }
}
