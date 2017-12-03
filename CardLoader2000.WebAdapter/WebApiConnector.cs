using System;
using System.Globalization;
using System.Net;
using System.Text;
using CardLoader2000.WebAdapter.Objects;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CardLoader2000.WebAdapter
{
    public static class WebApiConnector
    {
        public static WebOrder GetWebOrderByNumber(int number)
        {
            try
            {
                return null;
                if (number < 0)
                    return null;

                WebResponse res = null;
                try
                {
                    //Web request
                    WebRequest request = WebRequest.Create("http://.../" + number);
                    res = request.GetResponse();
                }
                catch (WebException webEx)
                {
                    return null; //No order for that number.
                }

                var stream = res.GetResponseStream();

                if (stream == null)
                    return null;

                byte[] buffer = new byte[res.ContentLength];
                stream.Read(buffer, 0, (int) res.ContentLength);
                res.Close();
                stream.Close();

                string response = Encoding.UTF8.GetString(buffer);
                //var json = JValue.Parse(response);
                var json = JsonConvert.DeserializeObject<JObject>(response);

                //Map object
                WebOrder order = new WebOrder
                {
                    Name = json.GetValue("name").ToSafeString(),
                    ApartmentOrUnit = json.GetValue("apartament").ToSafeString(),
                    City = json.GetValue("city").ToSafeString(),
                    Country = json.GetValue("country").ToSafeString(),
                    CreatedTime = json.GetValue("createdDate").ToSafeTime(),
                    EMail = json.GetValue("email").ToSafeString(),
                    Id = number,
                    IsPaid = "Paid".Equals(json.GetValue("statusString").ToSafeString()),
                    PaypalTransactionId = json.GetValue("transactionId").ToSafeString(),
                    RegionOrState = json.GetValue("state").ToSafeString(),
                    Street = json.GetValue("sreet").ToSafeString(),
                    ZipCode = json.GetValue("zipCode").ToSafeString()
                };

                //Return
                return order;
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        private static DateTime? ToSafeTime(this object o)
        {
            string s = o.ToSafeString();

            if (String.IsNullOrWhiteSpace(s))
                return null;

            DateTime parsedDate;
            if (DateTime.TryParseExact(s, "yyyy-MM-dd HH:mm:ss", null, DateTimeStyles.AssumeUniversal, out parsedDate))
            {
                return parsedDate.ToUniversalTime();
            }

            return null;
        }

        private static string ToSafeString(this object o)
        {
            return o != null ? o.ToString() : null;
        }
    }
}
