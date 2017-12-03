using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CardLoader2000.CardLoadingLibrary.Objects;
using CardLoader2000.Interfaces.Objects;

namespace CardLoader2000.CardLoadingLibrary
{
    public static class CardLoader
    {
        private static string loaderExePath = "C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.CardLoadingLibrary\\BCLoad.EXE";
        private static string compilerExePath = "C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.CardLoadingLibrary\\ZCMBasic.EXE";

        private static string cardSources =
            "C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.CardLoadingLibrary\\CardSource\\";
        
        /// <summary>
        /// Returns null at success and error message otherwise.
        /// </summary>
        public static string LoadCard(LoadSettings loadSettings)
        {
            string cardState = loadSettings.LockCard ? "Run" : "Test";

            //Manual page 125: How the compiler is called.
            CommandOutput result = CommandHelper.Execute('\"' + compilerExePath + '\"' + " " + '\"' + cardSources + "BitcoinCard.BAS" +
                '\"' + " -X -CF\"" + cardSources + "ZC75_D.zcf\" -S" + cardState +
                " -OI\"" + cardSources + "BitcoinCard.IMG\"", cardSources, 10000, 30, true);

            if (!String.IsNullOrWhiteSpace(result.error) || result.exitCode != 0)
                return "Compile error: " + result.error;

            result = CommandHelper.Execute('\"' + loaderExePath + "\" \"" + cardSources + "BitcoinCard.IMG\" -E\"" + cardSources + "BitcoinCard.ERR\" -S" + cardState + " -P103",
                    cardSources, 10000, 30, true);

            if (!String.IsNullOrWhiteSpace(result.error) || result.exitCode != 0)
                return "Load command error: " + result.error;

            if (File.Exists(cardSources + "BitcoinCard.ERR"))
            {
                string error = File.ReadAllText(cardSources + "BitcoinCard.ERR", Encoding.UTF8);
                return error;
            }

            /*Previous commands in card loader .BAT:
             @ECHO OFF
            :Start
            CD "C:\Users\mcb\Dropbox\Hobby stuff\75Branch\"
            @ECHO ON
            BCLoad BitcoinCard.img -E -STest -P103
            @ECHO OFF
            IF EXIST "BitcoinCard.ERR" ECHO ERROR OCCURED
            ECHO .
            ECHO Retry?
            Pause
            CLS
            GOTO Start
            */

            //Remove file with secret customer information after use:
            //File.Delete(cardSources + "SetupConstants.DEF");
            //File.Delete(cardSources + "BitcoinCard.IMG");

            return null; //OK
        }

        public static string DeleteCardFile(string path)
        {
            try
            {
                if (File.Exists(path))
                    File.Delete(path);
            }
            catch (Exception ex)
            {
                return "Failed to delete output path.\nERROR:" + ex.Message + "\nSTACK:" + ex.StackTrace;
            }
            return null;
        }
    }
}
