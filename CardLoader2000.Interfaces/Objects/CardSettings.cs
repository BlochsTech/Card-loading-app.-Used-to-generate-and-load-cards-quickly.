namespace CardLoader2000.Interfaces.Objects
{
    public class CardSettings
    {
        /// <summary>
        /// Card settings
        /// </summary>
        public byte[] PrivateKey { get; set; }

        /// <summary>
        /// Card settings
        /// </summary>
        public byte[] PublicKey
        {
            get
            {
                byte[] res = new byte[PublicKeyX.Length+PublicKeyY.Length];
                PublicKeyX.CopyTo(res, 0);
                PublicKeyY.CopyTo(res, PublicKeyX.Length);
                return res;
            }
        }
        /// <summary>
        /// Card settings
        /// </summary>
        public byte[] PublicKeyX { get; set; } //Card settings
        /// <summary>
        /// Card settings
        /// </summary>
        public byte[] PublicKeyY { get; set; } //Card settings
        /// <summary>
        /// Card settings
        /// </summary>
        public byte[] PublicKeyHash160 { get; set; } //Card settings

        //public byte[] AddressBytes { get; set; } //Card settings

        //public byte[] PinBytes { get; set; } //Card settings
        //public byte[] PukBytes { get; set; } //Card settings

        /// <summary>
        /// Card settings
        /// </summary>
        public string DisplayKeyAndVignereTable { get; set; } //Card Settings


        public int PinValue { get; set; } //Letter
        public int PukValue { get; set; } //Letter
        public string aesPassword { get; set; } //Email


        public string displayKeyString { get; set; } //In letter.
        public string AddressString { get; set; } //In letter.
        public string AESEncryptedPrivateKey { get; set; } //In letter.
        public char[][] VignereTable { get; set; } //In letter.
        public string OrderNumber { get; set; } //In letter.
        //TODO: VignereTable.
        //TODO: Remember/check how it worked.
    }
}
