using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows;

namespace CardLoader2000
{
    /// <summary>
    /// Interaction logic for PrintWindow.xaml
    /// </summary>
    public partial class PrintWindow : Window
    {
        private string path;
        /// <summary>
        /// IMPORTANT - The html doc should contain the following or have it inserted:
        /// <style type="text/css">html{overflow:hidden;}</style>
        /// </summary>
        public PrintWindow(string path)
        {
            InitializeComponent();

            this.path = path;

            //FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read);
            //webBrowser.NavigateToStream(fs);

            webBrowser.Source = new Uri(path);
            //webBrowser.Loaded += On_loaded;
            ContentRendered += OnContentRendered;
        }

        private void OnContentRendered(object sender, EventArgs eventArgs)
        {
            try
            {
                // NOTE: this works only when the document as been loaded
                IOleServiceProvider sp = webBrowser.Document as IOleServiceProvider;
                if (sp != null)
                {
                    Guid IID_IWebBrowserApp = new Guid("0002DF05-0000-0000-C000-000000000046");
                    Guid IID_IWebBrowser2 = new Guid("D30C1661-CDAF-11d0-8A3E-00C04FC9E26E");
                    const int OLECMDID_PRINT = 6;
                    const int OLECMDEXECOPT_DONTPROMPTUSER = 2;

                    dynamic wb; // will be of IWebBrowser2 type, but dynamic is cool
                    sp.QueryService(IID_IWebBrowserApp, IID_IWebBrowser2, out wb);
                    if (wb != null)
                    {
                        // note: this will send to the default printer, if any
                        wb.ExecWB(OLECMDID_PRINT, OLECMDEXECOPT_DONTPROMPTUSER, null, null);
                    }
                }

                //Remove secret customer info from disk:
                //File.Delete(path);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Printing failed. Error: " + ex.Message);
            }

            Close();
        }

        [ComImport, Guid("6D5140C1-7436-11CE-8034-00AA006009FA"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        private interface IOleServiceProvider
        {
            [PreserveSig]
            int QueryService([MarshalAs(UnmanagedType.LPStruct)] Guid guidService, [MarshalAs(UnmanagedType.LPStruct)]  Guid riid, [MarshalAs(UnmanagedType.IDispatch)] out object ppvObject);
        }

        //OLD CODE:
        //Code sample:
        //var doc = (IHTMLDocument2)webBrowser.Document;
        //var height = ((IHTMLElement2)doc.body).scrollHeight;
        //HTMLDocument htmlDoc = webBrowser.Document as HTMLDocument;
        //int len = htmlDoc.parentWindow.length;

        //PrintDialog pd = new PrintDialog
        //{
        //    PrintTicket = new PrintTicket
        //    {
        //        Duplexing = Duplexing.TwoSidedLongEdge,
        //        OutputColor = OutputColor.Monochrome,
        //        PageOrientation = PageOrientation.Portrait,
        //        PageMediaSize = new PageMediaSize(794, 1122),
        //        InputBin = InputBin.AutoSelect
        //    }
        //};

        //Ok, final TODO: Page only renders what is on the PC screen...
        //WebPaginator paginator = new WebPaginator(webBrowser, 1089, 1122, 794);

        //pd.PrintDocument(paginator, "CustomerLetter");
    }
}
