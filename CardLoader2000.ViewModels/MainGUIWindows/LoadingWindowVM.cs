using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using CardLoader2000.DAL;
using CardLoader2000.DAL.Objects;
using CardLoader2000.Interfaces.Objects;
using CardLoader2000.LoadProcessors;

namespace CardLoader2000.ViewModels.MainGUIWindows
{
    public class LoadingWindowVM
    {
        private Order2 waitingPaidOrder;
        private readonly Dictionary<string, string> postInfoMapping = new Dictionary<string, string>
        {
            { "Denmark", "Recommended/B - Dealer: John, 34 Strasse, Test test test Beiying (Notify by email)"}
        }; 

        public SimpleLoadResponse LoadClick(LoadSettings loadSettings)
        {
            //Pass call to model:
            return SimpleRandomLoader.ExecuteLoad(loadSettings, waitingPaidOrder);
        }

        public string WaitingCustomerName
        {
            get
            {
                if (waitingPaidOrder == null)
                    UpdateNextUnsentPaidOrder();

                return waitingPaidOrder != null ? waitingPaidOrder.Name : null;
            }
        }

        public string WaitingStreet
        {
            get
            {
                if (waitingPaidOrder == null)
                    UpdateNextUnsentPaidOrder();

                return waitingPaidOrder != null ? waitingPaidOrder.Street : null;
            }
        }

        public string WaitingCity
        {
            get
            {
                if (waitingPaidOrder == null)
                    UpdateNextUnsentPaidOrder();

                return waitingPaidOrder != null ? waitingPaidOrder.City : null;
            }
        }

        public string WaitingZip
        {
            get
            {
                if (waitingPaidOrder == null)
                    UpdateNextUnsentPaidOrder();

                return waitingPaidOrder != null ? waitingPaidOrder.ZipCode : null;
            }
        }

        public string WaitingCountry
        {
            get
            {
                if (waitingPaidOrder == null)
                    UpdateNextUnsentPaidOrder();

                return waitingPaidOrder != null ? waitingPaidOrder.Country : null;
            }
        }

        public string WaitingRegion
        {
            get
            {
                if (waitingPaidOrder == null)
                    UpdateNextUnsentPaidOrder();

                return waitingPaidOrder != null ? waitingPaidOrder.RegionOrState : null;
            }
        }

        public string WaitingPostInfo
        {
            get
            {
                if (waitingPaidOrder == null)
                    UpdateNextUnsentPaidOrder();

                string value;
                return waitingPaidOrder != null 
                    && postInfoMapping.TryGetValue(waitingPaidOrder.Country, out value) 
                    ? value : null;
            }
        }

        private void UpdateNextUnsentPaidOrder()
        {
            OrderDB db = new OrderDB();
            waitingPaidOrder = db.GetNextPaidOrder();
        }

        public void LastLoadedOrderPaidAndSent()
        {
            OrderDB db = new OrderDB();
            Order2 lastOrder = SimpleRandomLoader.GetLastLoadedOrder();
            Order2 paidWebOrder = db.GetNextPaidOrder();

            paidWebOrder.OrderSent = true;
            paidWebOrder.Address = lastOrder.Address;
            paidWebOrder.Password = lastOrder.Password;
            db.SaveOrder(paidWebOrder);
            db.DeleteOrder(lastOrder.OrderNumber);
            waitingPaidOrder = db.GetNextPaidOrder();
        }

        public string SearchOrder(string orderNumber)
        {
            if(orderNumber == null || orderNumber.Length != 8)
                return "Type an order number above...";

            OrderDB db = new OrderDB();
            Order2 order = db.GetOrder(orderNumber);
            
            if(order == null)
                return "Type an order number above...";

            db.CleanRedeemedPasswords();

            return "Addr: " + order.Address + "\n" +
                   "Mail: " + order.EMail + "\n" +
                   "Name: " + order.Name + "\n" +
                   "Password: " + order.Password + "\n" +
                   (order.PasswordClaimed != null ? "REDEEMED" : "");
        }

        public RedeemResponse Redeem(string orderNumber, string email)
        {
            OrderDB db = new OrderDB();
            Order2 order = db.GetOrder(orderNumber);

            if (order == null)
            {
                return new RedeemResponse
                {
                    Message = "",
                    Success = false
                };
            }
            else if (String.IsNullOrWhiteSpace(email) || !Regex.IsMatch(email, "[a-zA-Z0-9]*@[a-zA-Z0-9]*\\.{1}[a-zA-Z]{1,}"))
            {
                return new RedeemResponse
                {
                    Success = false,
                    Message = "Email required to redeem password."
                };
            }
            else if (order.EMail != null && !order.EMail.Equals(email))
            {
                return new RedeemResponse
                {
                    Success = false,
                    Message = "An email has already been set."
                };
            }

            order.EMail = email;

            if (order.PasswordClaimed == null)
            {
                order.PasswordClaimed = DateTime.Now;
                db.SaveOrder(order);
            }

            RedeemResponse resp = new RedeemResponse();

            resp.OrderInfoText = "Addr: " + order.Address + "\n" +
                   "Mail: " + order.EMail + "\n" +
                   "Name: " + order.Name + "\n" +
                   "Password: " + order.Password + "\n" +
                   (order.PasswordClaimed != null ? "REDEEMED" : "");

            resp.Success = true;

            resp.Message = "";

            return resp;
        }
    }
}
