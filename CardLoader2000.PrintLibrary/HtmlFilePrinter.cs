using System;
using System.IO;
using System.Printing;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;

namespace CardLoader2000.PrintLibrary
{
    public class HtmlFilePrinter
    {
        public static void PrintHtml(string path)
        {
            //TODO: Code cleanup.
        }
    }

    //OLD CODE SAMPLES BELOW:
    //namespace CardLoader2000.PrintLibrary.Objects
    //{
    //    /// <summary>
    //    /// http://tech.pro/tutorial/888/wpf-printing-part-2-pagination
    //    /// </summary>
    //    public class WebPaginator : DocumentPaginator
    //    {
    //        private readonly WebBrowser webBrowser;
    //        private readonly int pageScroll;
    //        private Size pageSize;

    //        public WebPaginator(WebBrowser webBrowser, int pageScroll, double pageHeight, double pageWidth)
    //        {
    //            this.webBrowser = webBrowser;
    //            this.pageScroll = pageScroll;
    //            pageSize = new Size(pageWidth, pageHeight);
    //        }

    //        public override DocumentPage GetPage(int pageNumber)
    //        {
    //            HTMLDocument htmlDoc = webBrowser.Document as HTMLDocument;
    //            if (htmlDoc != null) htmlDoc.parentWindow.scrollTo(0, pageScroll * pageNumber);
    //            Rect area = new Rect(pageSize);
    //            //webBrowser.

    //            //Awsomeum browser does not support scrolling.

    //            return new DocumentPage(webBrowser, pageSize, area, area);
    //        }

    //        public override bool IsPageCountValid
    //        {
    //            get { return true; }
    //        }

    //        /// <summary>
    //        /// Returns one less than actual length.
    //        /// Last page should be whitespace, used for scrolling.
    //        /// </summary>
    //        public override int PageCount
    //        {
    //            get
    //            {
    //                var doc = (IHTMLDocument2)webBrowser.Document;
    //                var height = ((IHTMLElement2)doc.body).scrollHeight;
    //                int tempVal = height * 10 / pageScroll;
    //                tempVal = tempVal % 10 == 0
    //                    ? Math.Max(height / pageScroll, 1)
    //                    : height / pageScroll + 1;
    //                return tempVal > 1 ? tempVal - 1 : tempVal;
    //            }
    //        }

    //        public override Size PageSize
    //        {
    //            get
    //            {
    //                return pageSize;
    //            }
    //            set
    //            {
    //                pageSize = value;
    //            }
    //        }

    //        /// <summary>
    //        /// Can be null.
    //        /// </summary>
    //        public override IDocumentPaginatorSource Source
    //        {
    //            get
    //            {
    //                return null;
    //            }
    //        }
    //    }
    //}
}