using System;
using System.Collections.Generic;
using Newtonsoft.Json;

namespace CardLoader2000.DAL
{
    /// <summary>
    /// File persisted dictionary.
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public class GenericFileDictionary<T> : CPersistentDictionary where T : class, new()
    {
        public GenericFileDictionary(string fileName, IMigrator<T> migrator = null) : base(fileName)
        {
            string dbType = typeof (T).ToString();
            bool typeMismatch = !dbType.Equals(base.TypeInfo);
            if (typeMismatch && migrator == null)
            {
                throw new Exception("Wrong DB type and no migrator specified.");
            }
            else if (typeMismatch)
            {
                List<string> keys = base.Keys;
                foreach (string key in keys)
                {
                    string objectString = base[key] as string;
                    Add(key, migrator.Migrate(objectString));
                }
                base.TypeInfo = typeof(T).ToString();
            }
        }

        public void Add(string key, T value)
        {
            //StringBuilder objectString = new StringBuilder();
            //if (value != null)
            //{
            //    var writer = new StringWriter(objectString);
            //    XmlSerializer xmlSerializer = new XmlSerializer(typeof(T));
            //    xmlSerializer.Serialize(writer, value);
            //}

            //base.Add(key, value == null ? string.Empty : objectString.ToString()); 

            base.Add(key, JsonConvert.SerializeObject(value));
        }

        private T ReadObject(string key)
        {
            if (String.IsNullOrEmpty(key))
                return null;

            string objectString = base[key] as string;

            try
            {
                return String.IsNullOrWhiteSpace(objectString) ? null : JsonConvert.DeserializeObject<T>(objectString);
            }
            catch (Exception ex)
            {
                throw new Exception("Could not read value for key: "+key+".\n Could not deserialize the json string: '" + (objectString ?? "[NULL]") + "'.", ex);
            }

            //var reader = new StringReader(objectString);
            //XmlSerializer stringXmlSerializer = new XmlSerializer(typeof(T));
            //return stringXmlSerializer.Deserialize(reader) as T;
        }

        //Emulate to be the of this file-hashtable
        public new T this[string key] //New keyword means we intend to override/hide the base implementation of this[string key].
        {
            get 
            { 
                return ReadObject(key);
            }
            set 
            {
                Add(key, value);
            }
        }
    }
}
