using System;

namespace CardLoader2000.WebAdapter.Objects
{
    public class WebOrder
    {
        public int Id { get; set; }

        public DateTime? CreatedTime { get; set; }

        public bool IsPaid { get; set; }

        public string PaypalTransactionId { get; set; }

        public string EMail { get; set; }

        public string Name { get; set; }
        public string ApartmentOrUnit { get; set; }

        public string Street { get; set; }

        public string ZipCode { get; set; }
        public string City { get; set; }

        public string RegionOrState { get; set; }
        public string Country { get; set; }
    }
}
