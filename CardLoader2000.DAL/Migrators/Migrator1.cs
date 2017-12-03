using System;
using System.Collections.Generic;
using CardLoader2000.DAL.Objects;
using Newtonsoft.Json;

namespace CardLoader2000.DAL.Migrators
{
    public class Migrator1 : IMigrator<Order2>
    {
        public Order2 Migrate(string jsonString)
        {
            try
            {
                Order original = String.IsNullOrWhiteSpace(jsonString) ? null : JsonConvert.DeserializeObject<Order>(jsonString);
                if (original == null)
                    throw new Exception("Null object deserialization.");

                return new Order2
                {
                    Address = original.Address,
                    ApartmentOrUnit = original.ApartmentOrUnit,
                    City = original.City,
                    Country = original.Country,
                    EMail = original.EMail,
                    Name = original.Name,
                    OrderNumber = original.OrderNumber,
                    OrderPaid = original.OrderPaid,
                    OrderSent = original.OrderSent,
                    OrderLostInMail = false,
                    Promotion = false,
                    Test = false,
                    Comment = null,
                    Password = original.Password,
                    PasswordClaimed = original.PasswordClaimed,
                    RegionOrState = original.RegionOrState,
                    Street = original.Street,
                    WebId = null,
                    WebOrder = false,
                    ZipCode = original.ZipCode,
                    DynamicProperties = new List<Tuple<string,string>>()
                };
            }
            catch (Exception ex)
            {
                throw new Exception("Could not read convert a database object. Json: " + jsonString, ex);
            }
        }
    }
}
