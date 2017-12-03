using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using CardLoader2000.CryptoLibrary;
using CardLoader2000.Interfaces.Objects;

namespace CardLoader2000.CardLoadingLibrary
{

    public static class CardFileCreator
    {
        private static string settingsPath = "C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.CardLoadingLibrary\\CardSource\\SetupConstantsTemplate.DEF";
        private static string settingsPathTest = "C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.CardLoadingLibrary\\CardSource\\SetupConstantsTest.DEF";
        public static string outputPath = "C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.CardLoadingLibrary\\CardSource\\SetupConstants.DEF";

        /// <summary>
        /// Returns error message or null at success.
        /// </summary>
        public static string ModifyCardFile(CardSettings settings, LoadSettings loadSettings)
        {
            if (loadSettings.TestSettings)
            {
                try
                {
                    File.Copy(settingsPathTest, outputPath, true);
                }
                catch (Exception ex)
                {
                    return "Failed to copy test settings for test load. Ex.: " + ex.Message + " " + ex.StackTrace;
                }
            }
            else
            {
                byte[] file = File.ReadAllBytes(settingsPath);
                string fileString = Encoding.UTF8.GetString(file);

                string errorMsg = null;

                errorMsg = InsertString(out fileString, fileString, settings.DisplayKeyAndVignereTable, "DisplayKey");
                if (errorMsg != null)
                    return errorMsg;

                errorMsg = InsertString(out fileString, fileString, settings.PinValue, "Pin");
                if (errorMsg != null)
                    return errorMsg;

                errorMsg = InsertString(out fileString, fileString, settings.PrivateKey, "PrivateKey");
                if (errorMsg != null)
                    return errorMsg;

                errorMsg = InsertString(out fileString, fileString, settings.PublicKey, "PublicKey");
                if (errorMsg != null)
                    return errorMsg;

                errorMsg = InsertString(out fileString, fileString, settings.PublicKeyHash160, "PublicKeyHash160");
                if (errorMsg != null)
                    return errorMsg;

                errorMsg = InsertString(out fileString, fileString, settings.PukValue, "Puk");
                if (errorMsg != null)
                    return errorMsg;

                errorMsg = InsertString(out fileString, fileString, settings.AddressString, "Address");
                if (errorMsg != null)
                    return errorMsg;

                errorMsg = InsertString(out fileString, fileString, loadSettings.CardFee, "CardFee");
                if (errorMsg != null)
                    return errorMsg;

                errorMsg = InsertString(out fileString, fileString, loadSettings.ExpireFee ? "183" : "0",
                    "ExpireUsageTimes");
                if (errorMsg != null)
                    return errorMsg;

                file = Encoding.UTF8.GetBytes(fileString);
                FileStream fileStream = new FileStream(outputPath, FileMode.Create);
                fileStream.Write(file, 0, file.Length);
                fileStream.SetLength(file.Length);
                fileStream.Flush(true);
                fileStream.Close();
            }

            return null;
        }

        public static string InsertString(out string outString, string fileString, long insertValue, string id)
        {
            return InsertString(out outString, fileString, insertValue.ToString(), id);
        }

        public static string InsertString(out string outString, string fileString, string insertValue, string id)
        {
            try
            {
                outString = Regex.Replace(fileString, "\\["+id+"]", insertValue, RegexOptions.Singleline);
                return null;
            }
            catch (Exception ex)
            {
                outString = null;
                return ("Insert error: "+ex.Message);
            }
        }

        public static string InsertString(out string outString, string fileString, byte[] insertBytes, string id)
        {
            string insertValue = "Chr$(";
            for (int i = 0; i < insertBytes.Length; i++)
            {
                if (i > 0)
                    insertValue = insertValue + ", ";

                insertValue = insertValue + "&H" + CryptoHelper.ByteToHex(insertBytes[i]);
            }
            insertValue = insertValue + ")";

            return InsertString(out outString, fileString, insertValue, id);
        }
    }
}
