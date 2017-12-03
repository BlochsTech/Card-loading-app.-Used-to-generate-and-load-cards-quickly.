using System;
using System.Collections.Generic;
using System.Text;
using CardLoader2000.CryptoLibrary;
using CardLoader2000.DAL.Objects;
using CardLoader2000.WebAdapter.Objects;

namespace CardLoader2000.DAL.Converters
{
    public static class OrderConverters
    {
        public static Order2 ConvertWebOrderToDbOrder(WebOrder webOrder)
        {
            return new Order2
            {
                Address = null,
                ApartmentOrUnit = webOrder.ApartmentOrUnit,
                City = webOrder.City,
                Country = webOrder.Country,
                EMail = webOrder.EMail,
                Name = webOrder.Name,
                OrderNumber = GetWebOrderNumber(webOrder.Id),
                OrderPaid = webOrder.IsPaid ? DateTime.UtcNow : (DateTime?) null,
                OrderSent = false,
                OrderLostInMail = false,
                Promotion = false,
                Test = false,
                Comment = null,
                Password = null,
                PasswordClaimed = null,
                RegionOrState = webOrder.RegionOrState,
                Street = webOrder.Street,
                WebId = webOrder.Id,
                WebOrder = true,
                ZipCode = webOrder.ZipCode,
                DynamicProperties = new List<Tuple<string, string>>()
            };
        }

        public static string GetWebOrderNumber(int id)
        {
            string res = CryptoHelper.ByteArrayToHexString(CryptoHelper.SHA256(Encoding.UTF8.GetBytes(id.ToString())))
                    .Substring(0, 8);
            return res;
        }
    }
}
