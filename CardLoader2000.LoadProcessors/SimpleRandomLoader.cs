using CardLoader2000.Interfaces.Objects;
using CardLoader2000.CryptoLibrary;
using CardLoader2000.CardLoadingLibrary;
using CardLoader2000.DAL;
using CardLoader2000.DAL.Objects;
using CardLoader2000.PrintLibrary;

namespace CardLoader2000.LoadProcessors
{
    public static class SimpleRandomLoader
    {
        private static Order2 lastLoaded;

        public static Order2 GetLastLoadedOrder()
        {
            return lastLoaded;
        }

        public static SimpleLoadResponse ExecuteLoad(LoadSettings loadSettings, Order2 waitingPaidOrder)
        {
            //1. Generate crypto values:
            CardSettings settings = CryptoHelper.GetRandomSettings();

            //2. Fill letter:
            string errorMessage = HtmlDocumentCreator.ModifyHtmlFile(settings, waitingPaidOrder);
            if (errorMessage != null)
            {
                lastLoaded = null;
                return new SimpleLoadResponse {ErrorMessage = errorMessage};
            }

            //3. Send to printer:
            //Happens automatically in main window on ExecuteLoad success.

            //4. Email requires pre-known address... type-able to begin with? Will consider... it IS a lot to insert bits and send an email.
            //TODO

            //5. Insert variables into card image file:
            errorMessage = CardFileCreator.ModifyCardFile(settings, loadSettings);
            if (errorMessage != null)
            {
                lastLoaded = null;
                return new SimpleLoadResponse {ErrorMessage = errorMessage};
            }
            

            //6. Load card:
            errorMessage = CardLoader.LoadCard(loadSettings);
            if (errorMessage != null)
            {
                lastLoaded = null;
                return new SimpleLoadResponse { ErrorMessage = errorMessage };
            }

            //7 Delete the generated card settings file containing the private key:
            errorMessage = CardLoader.DeleteCardFile(CardFileCreator.outputPath);
            if (errorMessage != null)
            {
                lastLoaded = null;
                return new SimpleLoadResponse { ErrorMessage = errorMessage };
            }

            //8. Save order to simple database.
            if (!loadSettings.TestSettings)
            {
                OrderDB db = new OrderDB();
                Order2 order = new Order2
                {
                    OrderNumber = settings.OrderNumber,
                    Password = settings.aesPassword,
                    Address = settings.AddressString,
                    WebOrder = false
                };
                db.SaveOrder(order);
                lastLoaded = order;
            }

            return new SimpleLoadResponse
            {
                Success = true,
                ErrorMessage = null
            };
        }
    }
}
