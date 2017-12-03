using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using CardLoader2000.Interfaces.Objects;
using System.Security.Cryptography;
using System.IO;
using Org.BouncyCastle.Math.EC;
using Org.BouncyCastle.Math;
using System.Text.RegularExpressions;

namespace CardLoader2000.CryptoLibrary
{
    //Add support for redeeming later. Then merge to redeeming only scheme.
    //Use manual system - register with order numbers and passwords, email info@blochstech.com for
    //redeeming?
    public static class CryptoHelper
    {
        private static RNGCryptoServiceProvider randomGen = new RNGCryptoServiceProvider();
        public static CardSettings GetRandomSettings()
        {
            byte[] privateKey = GetRandomBytes(32);
            byte[] aesPassword = GetRandomPassword();
            var pubKey = GetSecp256k1PublicKey(privateKey);
            byte[] hash160 = Hash160(pubKey.Item1, pubKey.Item2);
            string address = CreateBitcoinAddress(hash160);
            int pin = GetRandomSmallInt(10000);
            int puk = GetRandomSmallInt(100000);
            int vignereTable = GetRandomSmallInt(10);
            string displayKey = GetRandomNumberString(6);

            CardSettings result = new CardSettings
            {
                PrivateKey = privateKey,
                aesPassword = GetPasswordString(aesPassword),
                AESEncryptedPrivateKey = ByteArrayToHexString(AESEncryption(aesPassword, privateKey)),
                PublicKeyX = pubKey.Item1,
                PublicKeyY = pubKey.Item2,
                PublicKeyHash160 = hash160,
                AddressString = address,
                OrderNumber = CreateOrderNumber(),
                PinValue = pin,
                PukValue = puk,
                VignereTable = CreateVignereTable(vignereTable),
                displayKeyString = displayKey,
                DisplayKeyAndVignereTable = displayKey + vignereTable
            };

            return result;
        }

        public static char[][] CreateVignereTable(int tableIdentifier)
        {
            char[][] res = new char[10][];
            char[] ciphers = "ABCDEFGHIJ".ToCharArray();
            int t;

            for (int y = 0; y < 10; y++)
            {
                res[y] = new char[10];
                for (int x = 0; x < 10; x++)
                {
                    t = (y + x)%10;
                    if (t < tableIdentifier)
                    {
                        res[y][x] = ciphers[t];
                    }
                    else
                    {
                        res[y][x] = ciphers[9 - t + tableIdentifier];
                    }
                }
            }
            return res;
        }

        public static string GetRandomNumberString(int length)
        {
            string res = null;
            for (int i = 0; i < length; i++)
            {
                res += GetRandomSmallInt(10);
            }
            return res;
        }

        public static int GetRandomSmallInt(int roof)
        {
            var val = GetRandomBytes(3, false);
            return (val[2]*256*256 + val[1]*256 + val[0]) % roof;
        }

        public static byte[] IntToBytes(int value, int minBytes)
        {
            List<byte> res = new List<byte>();
            for (int i = 0; i < Math.Log(value, 256)+1; i++)
            {
                res.Add((byte) ((value%Math.Pow(256, i + 1))/Math.Pow(256, i)));
            }
            while (res.Count > minBytes && res.ElementAt(res.Count - 1) == 0)
            {
                res.RemoveAt(res.Count - 1);
            }
            while (res.Count < minBytes)
            {
                res.Add(0);
            }
            return res.ToArray();
        }

        public static string CreateOrderNumber()
        {
            return ByteArrayToHexString(GetRandomBytes(4, false));
        }

        public static string CreateBitcoinAddress(byte[] hash160Bytes, bool isPubKeyHash = true)
        {
            byte[] hashingBytes = new byte[hash160Bytes.Length + 1];
            Array.Copy(hash160Bytes, 0, hashingBytes, 1, hash160Bytes.Length);
            hashingBytes[0] = isPubKeyHash ? (byte)0 : (byte)5;
            byte[] checkHash = SHA256(SHA256(hashingBytes));
            byte[] newBytes = new byte[hash160Bytes.Length + 4 + 1];

            for (int i = 0; i < hashingBytes.Length + 4; i++)
            {
                if (i < hashingBytes.Length)
                {
                    newBytes[i] = hashingBytes[i];
                }
                else
                {
                    newBytes[i] = checkHash[i - hashingBytes.Length];
                }
            }
            return ByteArrayToBase58(newBytes);
        }

        public static string ByteArrayToBase58(byte[] ba)
        {
            Org.BouncyCastle.Math.BigInteger addrremain = new Org.BouncyCastle.Math.BigInteger(1, ba);

            Org.BouncyCastle.Math.BigInteger big0 = new Org.BouncyCastle.Math.BigInteger("0");
            Org.BouncyCastle.Math.BigInteger big58 = new Org.BouncyCastle.Math.BigInteger("58");

            string b58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

            string rv = "";

            while (addrremain.CompareTo(big0) > 0)
            {
                int d = Convert.ToInt32(addrremain.Mod(big58).ToString());
                addrremain = addrremain.Divide(big58);
                rv = b58.Substring(d, 1) + rv;
            }

            // handle leading zeroes
            foreach (byte b in ba)
            {
                if (b != 0) break;
                rv = "1" + rv;

            }
            return rv;
        }

        public static byte[] Hash160(byte[] pubKeyX, byte[] pubKeyY)
        {
            byte[] concatenated = new byte[pubKeyX.Length + pubKeyY.Length+1];
            concatenated[0] = 4;
            for (int i = 0; i < pubKeyX.Length + pubKeyY.Length; i++)
            {
                if (i < pubKeyX.Length)
                {
                    concatenated[i+1] = pubKeyX[i];
                }
                else
                {
                    concatenated[i+1] = pubKeyY[i - pubKeyX.Length];
                }
            }
            return RipeMD160(SHA256(concatenated));
        }

        public static Tuple<byte[], byte[]> GetSecp256k1PublicKey(byte[] privateKey)
        {
            //Secp256k1 curve variables - https://en.bitcoin.it/wiki/Secp256k1
            var privKeyInt = new BigInteger(+1, privateKey);
            var a = new BigInteger("0");
            var b = new BigInteger("7");
            var GX = new BigInteger(+1, HexStringToByteArray("79BE667E F9DCBBAC 55A06295 CE870B07 029BFCDB 2DCE28D9 59F2815B 16F81798"));
            var GY = new BigInteger(+1, HexStringToByteArray("483ADA77 26A3C465 5DA4FBFC 0E1108A8 FD17B448 A6855419 9C47D08F FB10D4B8"));
            //var n = new BigInteger(+1, HexStringToByteArray("FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFE BAAEDCE6 AF48A03B BFD25E8C D0364141"));
            //var h = new BigInteger("1");
            var p = new BigInteger(+1, HexStringToByteArray("FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFE FFFFFC2F"));
            //var q = h.Multiply(n).Mod(p); //Is this right???
            //- http://en.wikipedia.org/wiki/Elliptic_curve_cryptography

            ECCurve curve = new Org.BouncyCastle.Math.EC.FpCurve(p, a, b);
            ECPoint G = new Org.BouncyCastle.Math.EC.FpPoint(curve, new FpFieldElement(p, GX), new FpFieldElement(p, GY));
            
            var Qa = G.Multiply(privKeyInt);

            byte[] PubKeyX = Qa.X.ToBigInteger().ToByteArrayUnsigned();
            byte[] PubKeyY = Qa.Y.ToBigInteger().ToByteArrayUnsigned();

            return Tuple.Create(PubKeyX, PubKeyY);
        }

        public static byte[] HexStringToByteArray(string hex)
        {
            if(String.IsNullOrWhiteSpace(hex))
                return new byte[0];

            hex = Regex.Replace(hex, "[\\s-\\{}]", "");

            if (hex.Length % 2 == 1)
                throw new Exception("The binary key cannot have an odd number of digits.");
            
            if (!Regex.IsMatch(hex, "(^|\\A)[0-9A-Fa-f]*(\\Z|$)"))
                throw new Exception("Not hex.");

            byte[] arr = new byte[hex.Length >> 1];

            hex = hex.ToUpper();

            for (int i = 0; i < hex.Length >> 1; ++i)
            {
                arr[i] = (byte)((GetHexVal(hex[i << 1]) << 4) + (GetHexVal(hex[(i << 1) + 1])));
            }

            return arr;
        }

        private static int GetHexVal(char hex)
        {
            int val = hex;
            //For uppercase A-F letters:
            return val - (val < 58 ? 48 : 55);
        }

        public static string ByteArrayToHexString(byte[] ba)
        {
            StringBuilder hex = new StringBuilder(ba.Length * 2);
            foreach (byte b in ba)
                hex.AppendFormat("{0:x2}", b); //https://msdn.microsoft.com/en-us/library/dwhawy9k(v=vs.110).aspx
            return hex.ToString();
        }

        public static string ByteToHex(byte value)
        {
            StringBuilder hex = new StringBuilder(2);

            hex.AppendFormat("{0:x2}", value); //https://msdn.microsoft.com/en-us/library/dwhawy9k(v=vs.110).aspx
            
            return hex.ToString();
        }

        public static byte[] RipeMD160(byte[] bytes)
        {
            RIPEMD160Managed ripeProvider = new RIPEMD160Managed();
            return ripeProvider.ComputeHash(bytes);
        }

        public static byte[] SHA256(byte[] bytes)
        {
            SHA256CryptoServiceProvider shaProvider = new SHA256CryptoServiceProvider();
            return shaProvider.ComputeHash(bytes);
        }

        /// <summary>
        /// Uses 000... as initialization vector. Uses CBC mode. No padding.
        /// Uses SHA256 of password bytes as key.
        /// Compatible with the BlochsTech crypto tool in other words.
        /// </summary>
        public static byte[] AESEncryption(byte[] password, byte[] data)
        {
            byte[] iv = new byte[16]; //Blocks are only 128 bit in AES even though key is 256. 
            //Don't worry its secure http://en.wikipedia.org/wiki/Block_size_%28cryptography%29
            
            for (int i = 0; i < iv.Length; i++)
            {
                iv[i] = 0;
            }
            
            byte[] shaKey = SHA256(password);

            using (AesManaged  aesCrypter = new AesManaged ())
            {
                aesCrypter.BlockSize = 128;
                aesCrypter.Mode = CipherMode.CBC;
                aesCrypter.IV = iv;
                aesCrypter.KeySize = 256;
                aesCrypter.Padding = PaddingMode.None;
                aesCrypter.Key = shaKey;

                var crypter = aesCrypter.CreateEncryptor();

                // Encrypt the string to an array of bytes. 
                using (MemoryStream msEncrypt = new MemoryStream())
                {
                    using (CryptoStream csEncrypt = new CryptoStream(msEncrypt, crypter, CryptoStreamMode.Write))
                    {
                        using (BinaryWriter bwEncrypt = new BinaryWriter(csEncrypt))
                        {
                            //Write all data to the stream.
                            bwEncrypt.Write(data);
                        }
                        return msEncrypt.ToArray();
                    }
                }
            }
        }

        private static string GetPasswordString(byte[] value = null)
        {
            if (value != null)
                return Encoding.UTF8.GetString(value);
            
            return Encoding.UTF8.GetString(GetRandomPassword());
        }

        private static byte[] GetRandomPassword()
        {
            byte[] rawBytes = GetRandomBytes(8, false);
            byte tmpByte;
            bool inRange = false;
            for (int i = 0; i < 8; i++)
            {
                tmpByte = rawBytes[i];
                inRange = tmpByte >= 33 && tmpByte <= 127;
                while (!inRange)
                {
                    tmpByte = GetRandomBytes(1)[0];
                    inRange = tmpByte >= 33 && tmpByte <= 127;
                }
                rawBytes[i] = tmpByte;
            }
            return rawBytes;
        }

        private static byte[] GetRandomBytes(int numberOfBytes, bool useSalt = true)
        {
            byte[] randomBytes = new byte[numberOfBytes];
            randomGen.GetBytes(randomBytes);
            if(useSalt)
                randomBytes = Saltify(randomBytes);
            return randomBytes;
        }

        private static byte[] Saltify(byte[] value)
        {
            byte[] saltBytes = new byte[]{ 0, 255, 34, 78, 1, 90 };
            Random simpleRandomGen = new Random();
            int saltUsed = 0;
            byte[] newResult = new byte[value.Count()];

            for (int i = 0; i < value.Count(); i++)
            {
                if (simpleRandomGen.Next(100) > 50)
                {
                    if (saltUsed < saltBytes.Count())
                    {
                        newResult[i] = saltBytes[saltUsed];
                        saltUsed++;
                        continue;
                    }
                }
                newResult[i] = value[i];
            }
            return newResult;
        }
    }
}
