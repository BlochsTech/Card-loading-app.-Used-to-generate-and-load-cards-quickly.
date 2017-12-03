using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CardLoader2000.DAL.Objects
{
    public class Order2
    {
        /// <summary>
        /// Used as file cache key.
        /// </summary>
        public string OrderNumber { get; set; }

        /// <summary>
        /// Must be deleted 1 month after claimed date!
        /// </summary>
        public string Password { get; set; }

        public string Address { get; set; }

        /// <summary>
        /// Password was claimed.
        /// </summary>
        public DateTime? PasswordClaimed { get; set; }

        public bool OrderSent { get; set; }
        
        public bool OrderLostInMail { get; set; }
        public bool Promotion { get; set; }
        public bool Test { get; set; }

        public string Comment { get; set; }

        /// <summary>
        /// Order was paid.
        /// </summary>
        public DateTime? OrderPaid { get; set; }

        /// <summary>
        /// If false all the address/order info is null.
        /// </summary>
        public bool WebOrder { get; set; }
        public int? WebId { get; set; }

        public string PaypalTransactionId { get; set; }

        public string EMail { get; set; }

        public string Name { get; set; }
        public string ApartmentOrUnit { get; set; }

        public string Street { get; set; }

        public string ZipCode { get; set; }
        public string City { get; set; }

        public string RegionOrState { get; set; }
        public string Country { get; set; }

        public List<Tuple<string,string>> DynamicProperties { get; set; }
    }
}
