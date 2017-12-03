using System;
using System.Collections.Generic;
using CardLoader2000.DAL.Converters;
using CardLoader2000.DAL.Objects;
using CardLoader2000.WebAdapter;
using CardLoader2000.WebAdapter.Objects;
using System.Linq;

namespace CardLoader2000.DAL
{
    public class OrderDB
    {
        private static GenericFileDictionary<Order2> fileStore;

        private bool isSynchedWithWeb = false;
        private string lastUnpaidOrder;

        public OrderDB()
        {
            if (fileStore == null)
                fileStore =
                    new GenericFileDictionary<Order2>(
                        "C:\\Users\\mcb\\Dropbox\\Hobby stuff\\Card loader 2000\\CardLoader2000\\CardLoader2000.DAL\\Database\\OrderDB.dic", 
                        new Migrators.Migrator1());
        }

        public Order2 GetOrder(string orderNumber)
        {
            lock (fileStore)
            {
                return fileStore[orderNumber];
            }
        }

        public void SaveOrder(Order2 order)
        {
            lock (fileStore)
            {
                fileStore[order.OrderNumber] = order;
            }
        }

        public void DeleteOrder(string key)
        {
            lock (fileStore)
            {
                fileStore.Remove(key);
            }
        }

        public void CleanRedeemedPasswords()
        {
            lock (fileStore)
            {
                List<string> keys = fileStore.Keys;
                foreach (string key in keys)
                {
                    Order2 order = fileStore[key];
                    if (DateTime.Now - order.PasswordClaimed > TimeSpan.FromDays(30))
                        order.Password = "";

                    fileStore[key] = order;
                }
            }
        }

        private static readonly int[] knownHoleEnds = new int[] { 3, 3559 };
        private static readonly int[] knownHoleStarts = new int[] { 0, 51 };
        private void SynchWithWebsite()
        {
            //Get latest web order in database:
            lock (fileStore)
            {
                int lastWebOrder = 0;
                int holeIndex = 0;
                bool go = true;
                List<string> keys = fileStore.Keys;

                //Will not work.
                while (go)
                {
                    if (knownHoleStarts.Contains(lastWebOrder))
                    {
                        lastWebOrder = knownHoleEnds[holeIndex];
                        holeIndex++;
                    }

                    Order2 order = fileStore[OrderConverters.GetWebOrderNumber(lastWebOrder+1)];

                    if (order == null)
                        break;

                    if (order.WebOrder) //Should always be true... TODO: Better error handling...
                    {
                        lastWebOrder = Math.Max(order.WebId ?? 0, lastWebOrder);
                    }
                }

                WebOrder webOrder = WebApiConnector.GetWebOrderByNumber(lastWebOrder+1);
                Order2 newOrder;
                while (webOrder != null)
                {
                    if (webOrder == null)
                        break;

                    newOrder = OrderConverters.ConvertWebOrderToDbOrder(webOrder);
                    fileStore[newOrder.OrderNumber] = newOrder;

                    webOrder = WebApiConnector.GetWebOrderByNumber(webOrder.Id + 1);
                }
            }

            isSynchedWithWeb = true;
        }

        public Order2 GetNextPaidOrder()
        {
            if (!isSynchedWithWeb)
                SynchWithWebsite();

            lock (fileStore)
            {
                Order2 order = null; //= fileStore[OrderConverters.GetWebOrderNumber(4)];
                int lastWebOrder = 0;
                int holeIndex = 0;
                while (true)
                {
                    if (knownHoleStarts.Contains(lastWebOrder))
                    {
                        lastWebOrder = knownHoleEnds[holeIndex];
                        holeIndex++;
                    }

                    order = fileStore[OrderConverters.GetWebOrderNumber(lastWebOrder+1)];
                    lastWebOrder++;
                    if (order == null)
                        break;

                    if (order.OrderPaid != null && order.OrderSent == false)
                        return order;
                }
            }

            return null;
        }
    }
}
