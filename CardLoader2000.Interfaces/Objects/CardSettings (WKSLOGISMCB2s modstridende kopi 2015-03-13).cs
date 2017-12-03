namespace CardLoader2000.Interfaces.Objects
{
    public class CardSettings
    {
        public byte[] PrivateKey { get; set; } //Card settings

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
        public byte[] PublicKeyX { get; set; } //Card settings
        public byte[] PublicKeyY { get; set; } //Card settings
        public byte[] PublicKeyHash160 { get; set; } //Card settings

        public byte[] AddressBytes { get; set; } //Card settings

        public byte[] PinBytes { get; set; } //Card settings
        public byte[] PukBytes { get; set; } //Card settings

        public byte[] DisplayKeyBytes { get; set; } //Card Settings

        public string aesPassword { get; set; } //Email

        public string AddressString { get; set; } //In letter.
        public string AESEncryptedPrivateKey { get; set; } //In letter.

        public int PinValue { get; set; } //Letter
        public int PukValue { get; set; } //Letter

        public string displayKeyString { get; set; } //In letter.
        public char[][] VignereTable { get; set; } //In letter. 10x10 always
    }
}
