using System;
using System.Drawing.Imaging;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using CardLoader2000.Interfaces.Objects;
using Gma.QrCodeNet.Encoding;
using Gma.QrCodeNet.Encoding.Windows.Render;
using System.Drawing;
using CardLoader2000.DAL.Objects;

namespace CardLoader2000.PrintLibrary
{
    public static class HtmlDocumentCreator
    {
        private static string originalPath = "C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.PrintLibrary\\CustomerLetterOriginal.html";
        private static string outputPath = "C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.PrintLibrary\\CustomerLetter.html";
        private static string qrPath = "C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.PrintLibrary\\CustomerQR.png";

        /// <summary>
        /// Returns null at success otherwise errormessage.
        /// </summary>
        public static string ModifyHtmlFile(CardSettings settings, Order2 waitingPaidOrder)
        {
            byte[] file = System.IO.File.ReadAllBytes(originalPath);
            string fileString = Encoding.UTF8.GetString(file);

            string errorMsg = InsertString(out fileString, fileString, settings.AddressString, "address");
            if (errorMsg != null || fileString == null)
                return errorMsg ?? "No insert result error.";

            errorMsg = UpdateQRImage(settings.AddressString);
            if (errorMsg != null)
                return errorMsg;

            errorMsg = InsertString(out fileString, fileString, settings.AESEncryptedPrivateKey, "privatekey");
            if (errorMsg != null || fileString == null)
                return errorMsg ?? "No insert result error.";

            errorMsg = InsertString(out fileString, fileString, settings.displayKeyString, "vignerekey");
            if (errorMsg != null || fileString == null)
                return errorMsg ?? "No insert result error.";

            errorMsg = InsertString(out fileString, fileString, 
                waitingPaidOrder != null ? waitingPaidOrder.OrderNumber : settings.OrderNumber, 
                "ordernumber");
            if (errorMsg != null || fileString == null)
                return errorMsg ?? "No insert result error.";

            errorMsg = InsertString(out fileString, fileString, settings.PinValue.ToString(), "pin");
            if (errorMsg != null || fileString == null)
                return errorMsg ?? "No insert result error.";

            errorMsg = InsertString(out fileString, fileString, settings.PukValue.ToString(), "puk");
            if (errorMsg != null || fileString == null)
                return errorMsg ?? "No insert result error.";

            errorMsg = InsertString(out fileString, fileString, DateTime.Now.ToString("dd-MM-yyyy"), "date");
            if (errorMsg != null || fileString == null)
                return errorMsg ?? "No insert result error.";

            for (int y = 0; y < settings.VignereTable.Length; y++)
            {
                for (int x = 0; x < settings.VignereTable[y].Length; x++)
                {
                    errorMsg = InsertString(out fileString, fileString, settings.VignereTable[y][x].ToString(), "x"+x+"y"+y);
                    if (errorMsg != null || fileString == null)
                        return errorMsg ?? "No insert result error.";
                }
            }

            string testString = null;
            while (testString == null || testString.Contains(">>"))
            {
                FileStream fs = new FileStream(outputPath, FileMode.OpenOrCreate);
                file = Encoding.UTF8.GetBytes(fileString);
                fs.Write(file, 0, file.Length);
                fs.SetLength(file.Length);
                fs.Flush(true);
                fs.Close();
                file = File.ReadAllBytes(outputPath);
                testString = Encoding.UTF8.GetString(file);
            }

            return null;
        }

        public static string InsertString(out string outString, string fileString, string insertValue, string id)
        {
            try
            {
                outString = Regex.Replace(fileString, "id=\"" + id + "\"[^\\<]*?\\>[^\\<]*?\\<",
                    "id=\"" + id + "\">" + insertValue + "<", RegexOptions.Singleline);
                return null;
            }
            catch (Exception ex)
            {
                outString = null;
                return ("Insert error: "+ex.Message);
            }
        }

        public static string UpdateQRImage(string content)
        {
            try
            {
                QrEncoder encoder = new QrEncoder();
                QrCode qrCode = encoder.Encode(content);

                FileStream stream = new FileStream(qrPath, FileMode.Create);

                var renderer = new GraphicsRenderer(new FixedCodeSize(220, QuietZoneModules.Zero), Brushes.Black,
                    Brushes.White);
                renderer.WriteToStream(qrCode.Matrix, ImageFormat.Png, stream);

                stream.Flush();
                stream.Dispose();
                return null;
            }
            catch (Exception ex)
            {
                return "QR code error: " + ex.Message;
            }
        }
    }
}
