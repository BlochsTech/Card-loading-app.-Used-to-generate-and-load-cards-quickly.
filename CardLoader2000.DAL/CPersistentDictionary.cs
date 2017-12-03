using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
using System.Linq;
using CardLoader2000.DAL.Objects;
using Newtonsoft.Json;

namespace CardLoader2000.DAL
{
    public class CPersistentDictionary : IDisposable
    {
        private Dictionary<string, IndexObject> _lstIndexes = new Dictionary<string, IndexObject>(); //Contains values of "FileStream start position|value length" ordered by key.
        private SortedList<long, IndexObject> emptyFileSpots = new SortedList<long, IndexObject>(); //Empty file spots sorted by start position.
        private IndexObject lastFilledIndex; //Empty spots after this should be removed and the file itself should also end (use File.SetLength).
        private string typeInfo;

        private readonly FileStream _file;
        private readonly string _indexFile; //index file will be, GenericPersistentDictionary.dic.idx
        private readonly string _emptyFileSpots; //empty spots file will be, GenericPersistentDictionary.dic.idx2
        private readonly string _lastIndexFile; //last index file will be, GenericPersistentDictionary.dic.idx3
        private readonly string _averageLengthFile;//Average length file will be, GenericPersistentDictionary.dic.idx4
        private readonly string _typeFile; //Type of the JSON objects in the database. GenericPersistentDictionary.dic.idx5
        private const int _arrayOffset = 0;//always zero
        private const int defaultAverageElementLength = 2000;
        private int averageElementLength; //Save with indices, keep updated using lstIndexes.Count.

        protected CPersistentDictionary(string filename)
        {
            if (string.IsNullOrEmpty(filename))
                throw new Exception("Invalid initialization.");

            //_completeFilename = filename;

            //The index file(s).
            //TODO: Merge the index files inside the same file... maybe, why care?
            _indexFile = filename + ".idx";
            _emptyFileSpots = filename + ".idx2";
            _lastIndexFile = filename + ".idx3";
            _averageLengthFile = filename + ".idx4";
            _typeFile = filename + ".idx5";

            Directory.CreateDirectory(filename.Substring(0, filename.LastIndexOf("\\", StringComparison.InvariantCulture)));
            _file = new FileStream(filename, FileMode.OpenOrCreate, FileAccess.ReadWrite);
            Init();//Load the indexes
        }

        protected void Add(string key, string value)
        {
            int valueUTF8Length = value.UTF8Length();

            //Update average:
            averageElementLength = ((value != null ? valueUTF8Length : 0) + averageElementLength*_lstIndexes.Count)/
                                   (1 + _lstIndexes.Count);

            //See if we already have a key,
            //If yes, this means, user wants to overwrite the
            //existing value

            IndexObject indexObject;
            bool removedFromTooSmallSpot = false;
            if (_lstIndexes.TryGetValue(key, out indexObject))
            {
                if (value == null || indexObject.FileSpotLength >= valueUTF8Length) //Update existing filespot with new element value
                {
                    WriteToFile(indexObject.FilePosition, value, indexObject.FileSpotLength);

                    indexObject.ElementLength = value != null ? valueUTF8Length : 0;
                    _lstIndexes[key] = indexObject;
                }
                else //Element already exists, but its filespot is too small for the new value.
                {
                    //1. Check emptySpots for extension options.
                    IndexObject emptySpot;
                    emptyFileSpots.TryGetValue(indexObject.FilePosition + indexObject.FileSpotLength, out emptySpot);

                    if (emptySpot != null && emptySpot.FileSpotLength + indexObject.FileSpotLength >= valueUTF8Length)
                    {
                        int newLen = -1;
                        //2A. Extend spot and update.
                        if (emptySpot.FileSpotLength + indexObject.FileSpotLength - valueUTF8Length * 2 < averageElementLength * 2) //Use whole spot.
                        {
                            newLen = indexObject.FileSpotLength + emptySpot.FileSpotLength;
                            emptyFileSpots.Remove(emptySpot.FilePosition);
                        }
                        else //Split empty spot.
                        {
                            newLen = Math.Max(valueUTF8Length * 2, averageElementLength * 2);
                            emptyFileSpots.Remove(emptySpot.FilePosition);

                            emptyFileSpots.Add(indexObject.FilePosition + newLen, new IndexObject
                            {
                                FilePosition = indexObject.FilePosition + newLen,
                                ElementLength = 0,
                                FileSpotLength = emptySpot.FileSpotLength + indexObject.FileSpotLength - newLen
                            });
                        }

                        indexObject.FileSpotLength = newLen;
                        indexObject.ElementLength = valueUTF8Length;
                        _lstIndexes[key] = indexObject; //Position and key unchanged.

                        WriteToFile(indexObject.FilePosition, value, indexObject.FileSpotLength);
                    }
                    else //No (suitable) empty spot for extension, move current spot.
                    {
                        //2B. Create empty spot from current spot.
                        emptyFileSpots.Add(indexObject.FilePosition, new IndexObject
                        {
                            ElementLength = 0,
                            FilePosition = indexObject.FilePosition,
                            FileSpotLength = indexObject.FileSpotLength
                        });

                        if (lastFilledIndex.FilePosition == indexObject.FilePosition)
                            lastFilledIndex = null;

                        ConcatenateEmptySlots();

                        //Clear old spot.
                        WriteToFile(indexObject.FilePosition, null, indexObject.FileSpotLength);

                        //3B. Move current spot in file. -> Happens in add new logic.
                        removedFromTooSmallSpot = true;
                    }
                }
            }
            
            if (!_lstIndexes.ContainsKey(key) || removedFromTooSmallSpot)
            {
                IndexObject availableEmpty = FindAndSplitExistingEmptySpot(value != null ? valueUTF8Length * 2 : 0, averageElementLength * 2);
                if (availableEmpty != null) //Move to bigger empty spot:
                {
                    //If first or moved update file index last filled value:
                    if (lastFilledIndex == null)
                        UpdateLastFilledIndex();

                    WriteToFile(availableEmpty.FilePosition, value, availableEmpty.FileSpotLength); //Write value to file.
                    availableEmpty.ElementLength = value != null ? valueUTF8Length : 0; //Update length from 0 to value length.
                    _lstIndexes[key] = availableEmpty; //Update file index with new index object.
                    emptyFileSpots.Remove(availableEmpty.FilePosition); //Remove now no longer empty spot from empty list.
                }
                else //Add new OR no available empty spot:
                {
                    //Make new index object:
                    IndexObject newIndex = new IndexObject
                    {
                        ElementLength = value != null ? valueUTF8Length : 0,
                        FilePosition = lastFilledIndex != null ? lastFilledIndex.FilePosition + lastFilledIndex.FileSpotLength : 0, //0 only in case of FIRST element.
                        FileSpotLength = Math.Max((value != null ? valueUTF8Length : 0) * 2, averageElementLength * 2)
                    };

                    //When adding to end of file we are always the lastFilled:
                    lastFilledIndex = newIndex;
                    _file.SetLength(lastFilledIndex != null ? lastFilledIndex.FilePosition + lastFilledIndex.FileSpotLength : 0);

                    WriteToFile(newIndex.FilePosition, value, newIndex.FileSpotLength); //Write value to file.
                    if (_lstIndexes.ContainsKey(key)) //Existing moved from old spot to entirely new:
                    {
                        _lstIndexes[key] = newIndex;
                    }
                    else //Entirely new value added:
                    {
                        _lstIndexes.Add(key, newIndex);
                    }
                }
            }

            UpdateIndexFiles();
        }

        //public bool Delete(string key)
        //{
        //    if (String.IsNullOrWhiteSpace(key))
        //        return false;

        //    IndexObject indexObject = null;
        //    if(_lstIndexes.TryGetValue(key, out indexObject))
        //    {
        //        _lstIndexes.Remove(key);

        //        emptyFileSpots.Add(indexObject.FilePosition, new IndexObject
        //        {
        //            ElementLength = 0,
        //            FilePosition = indexObject.FilePosition,
        //            FileSpotLength = indexObject.FileSpotLength
        //        });

        //        ConcatenateEmptySlots();

        //        //Clear old spot.
        //        WriteToFile(indexObject.FilePosition, null, indexObject.FileSpotLength);

        //        if (lastFilledIndex != null && lastFilledIndex.FilePosition == indexObject.FilePosition)
        //            lastFilledIndex = null;
        //    }

        //    if (lastFilledIndex == null)
        //        UpdateLastFilledIndex();

        //    UpdateIndexFiles();

        //    return true;
        //}

        private void WriteToFile(long position, string value, int spotLength)
        {
            //Jump to the position
            _file.Seek(position, SeekOrigin.Begin);
            if (value != null)
                _file.Write(Encoding.UTF8.GetBytes(value), _arrayOffset, value.UTF8Length());

            var emptyLen = value != null
                ? spotLength - value.UTF8Length()
                : spotLength;
            _file.Write(Encoding.UTF8.GetBytes(new string('_', emptyLen)), 0, emptyLen);

            _file.Flush(true);
        }

        /// <summary>
        /// Method for finding the nearest to start empty slot. Otherwise returns null.
        /// Method will split slot if it is large.
        /// If the empty slots list is changed call concatenate empty slots method.
        /// </summary>
        private IndexObject FindAndSplitExistingEmptySpot(int minLength, int expectedUsageLength = -1)
        {
            if ((minLength <= 0 && expectedUsageLength <= 0) || emptyFileSpots == null) return null;

            int len = Math.Max(Math.Max(minLength, expectedUsageLength), averageElementLength);

            for (int i = 0; i < emptyFileSpots.Count; i++)
            {
                var tempValue = emptyFileSpots.ElementAt(i).Value;
                if (tempValue.FileSpotLength >= len)
                {
                    if (tempValue.FileSpotLength - len <= averageElementLength*2)
                    {
                        return tempValue;
                    }
                    else //Split large spot:
                    {
                        IndexObject newSpot = new IndexObject
                        {
                            FilePosition = tempValue.FilePosition + len,
                            ElementLength = 0,
                            FileSpotLength = tempValue.FileSpotLength - len
                        };
                        emptyFileSpots.Add(newSpot.FilePosition, newSpot);
                        tempValue.FileSpotLength = len;
                        emptyFileSpots[i] = tempValue;
                        return tempValue;
                    }
                }
            }

            return null;
        }

        /// <summary>
        /// Any adjacent empty slots are turned into one big slot.
        /// Empty slots after lastFilledIndex are removed.
        /// 
        /// Add method will have to split large empty slots.
        /// This method should be called after removing or moving an
        /// element.
        /// </summary>
        private void ConcatenateEmptySlots()
        {
            //Find adjacent spots and concatenate them:
            SortedList<long, IndexObject> newList = new SortedList<long, IndexObject>();
            IndexObject newIndexObject;

            //Edge case all should be removed:
            var keyValPair = emptyFileSpots.FirstOrDefault();
            if (keyValPair.Key >= lastFilledIndex.FilePosition)
            {
                emptyFileSpots = newList;
            }
            else //Normal case all should be removed:
            {
                int j = 1;
                for (int i = 0; i < emptyFileSpots.Count; i++)
                {
                    //Remove spot if after lastFilled and reset file length:
                    if (i+1 >= emptyFileSpots.Count || emptyFileSpots.ElementAt(i + 1).Key >= lastFilledIndex.FilePosition)
                    {
                        newList.Add(emptyFileSpots.ElementAt(i).Key, emptyFileSpots.ElementAt(i).Value);
                        //File length is reset in method "UpdateLastFilledIndex()".
                        break; //All else will be after file end and hence removed.
                    }

                    //Concatenation:
                    newIndexObject = emptyFileSpots.ElementAt(i).Value;
                    while (i + j < emptyFileSpots.Count
                           &&
                           newIndexObject.FilePosition + newIndexObject.FileSpotLength ==
                           emptyFileSpots.ElementAt(i + j).Key)
                    {
                        newIndexObject = new IndexObject
                        {
                            ElementLength = 0,
                            FilePosition = newIndexObject.FilePosition,
                            FileSpotLength =
                                newIndexObject.FileSpotLength + emptyFileSpots.ElementAt(i + j).Value.FileSpotLength,
                        };
                        j++;
                    }
                    i += j; //Skip the indices added to this one empty file spot.
                    j = 1; //Reset j.
                    newList.Add(newIndexObject.FilePosition, newIndexObject);
                }

                emptyFileSpots = newList;
            }
        }

        /// <summary>
        /// Overwrites the old file location with spaces.
        /// Moves the old Index to the empty indices list.
        /// Checks if lastFilledIndex should be updated/does it.
        /// 
        /// Saves all indexing information to disk via the update
        /// indexes method.
        /// </summary>
        public virtual void Remove(string key)
        {
            //Requires logic
            IndexObject indexObject;
            if (String.IsNullOrEmpty(key) || !_lstIndexes.TryGetValue(key, out indexObject))
                return; //Maintain silence.

            _lstIndexes.Remove(key);

            //Update the position of the index/length in the list:
            emptyFileSpots.Add(indexObject.FilePosition,
                new IndexObject
                {
                    ElementLength = 0,
                    FilePosition = indexObject.FilePosition,
                    FileSpotLength = indexObject.FileSpotLength
                });

            ConcatenateEmptySlots();

            if (lastFilledIndex != null && lastFilledIndex.FilePosition == indexObject.FilePosition)
                lastFilledIndex = null;

            if (lastFilledIndex == null)
                UpdateLastFilledIndex();

            UpdateIndexFiles();

            //Clear old spot.
            WriteToFile(indexObject.FilePosition, null, indexObject.FileSpotLength);
        }

        /// <summary>
        /// Sets the lastFilledIndex to be equal to the item in lstIndexes with the maximum file position.
        /// This method is heavy, cycling through all lstIndexes elements.
        /// </summary>
        private void UpdateLastFilledIndex()
        {
            if (_lstIndexes == null || _lstIndexes.Count == 0)
            {
                lastFilledIndex = null;
            }
            else
            {
                long newLastPosition = Int64.MinValue;
                IndexObject newLast = null;
                foreach (var keyIndexPair in _lstIndexes)
                {
                    if (keyIndexPair.Value.FilePosition > newLastPosition)
                    {
                        newLast = keyIndexPair.Value;
                        newLastPosition = keyIndexPair.Value.FilePosition;
                    }
                }
                lastFilledIndex = newLast;
                _file.SetLength(lastFilledIndex != null ? lastFilledIndex.FilePosition + lastFilledIndex.FileSpotLength : 0);
            }
        }

        private string Read(string key)
        {
            if (!_lstIndexes.ContainsKey(key))
                return null;//Keep silence.

            int len = _lstIndexes[key].ElementLength;
            
            if (len <= 0)
                return null; //Do we care that the empty string cannot be saved?

            //Jump to the position
            _file.Seek(_lstIndexes[key].FilePosition, SeekOrigin.Begin);

            var bytesRead = new byte[len];

            //Read bytes
            _file.Read(bytesRead, 0, len);

            //Convert bytes into string
            string val = Encoding.UTF8.GetString(bytesRead);

            return val;
        }

        public List<string> Keys
        {
            get { return _lstIndexes.Keys.ToList(); }
        }

        public string TypeInfo
        {
            get { return typeInfo; }
            set
            {
                typeInfo = value;
                UpdateIndexFiles();
            }
        }

        /// <summary>
        /// Saves all indexing files. Should be called at each change to file.
        /// File itself is always live modified.
        /// </summary>
        private void UpdateIndexFiles()
        {
            if (_lstIndexes == null || _lstIndexes.Count == 0)
            {
                File.Delete(_indexFile);
            }
            else
            {
                using (FileStream fs = new FileStream(_indexFile, FileMode.OpenOrCreate, FileAccess.ReadWrite))
                {
                    BinaryFormatter bin = new BinaryFormatter();
                    bin.Serialize(fs, JsonConvert.SerializeObject(_lstIndexes));
                }
            }

            if (emptyFileSpots == null || emptyFileSpots.Count == 0)
            {
                File.Delete(_emptyFileSpots);
            }
            else
            {
                using (FileStream fs = new FileStream(_emptyFileSpots, FileMode.OpenOrCreate, FileAccess.ReadWrite))
                {
                    BinaryFormatter bin = new BinaryFormatter();
                    bin.Serialize(fs, JsonConvert.SerializeObject(emptyFileSpots));
                }
            }

            if (lastFilledIndex == null)
            {
                File.Delete(_lastIndexFile);
            }
            else
            {
                using (FileStream fs = new FileStream(_lastIndexFile, FileMode.OpenOrCreate, FileAccess.ReadWrite))
                {
                    BinaryFormatter bin = new BinaryFormatter();
                    bin.Serialize(fs, JsonConvert.SerializeObject(lastFilledIndex));
                }
            }

            averageElementLength = averageElementLength <= 0 ? defaultAverageElementLength : averageElementLength;
            using (FileStream fs = new FileStream(_averageLengthFile, FileMode.OpenOrCreate, FileAccess.ReadWrite))
            {
                BinaryFormatter bin = new BinaryFormatter();
                bin.Serialize(fs, JsonConvert.SerializeObject(averageElementLength));
            }

            if (typeInfo != null)
            {
                using (FileStream fs = new FileStream(_typeFile, FileMode.OpenOrCreate, FileAccess.ReadWrite))
                {
                    BinaryFormatter bin = new BinaryFormatter();
                    bin.Serialize(fs, typeInfo);
                }
            }
        }

        private void Init()
        {
            bool needsSave = false;
            using (FileStream fs = new FileStream(_indexFile, FileMode.OpenOrCreate, FileAccess.ReadWrite))
            {
                if (fs.Length < 1)
                {
                    _lstIndexes = new Dictionary<string, IndexObject>();
                    needsSave = true;
                }
                else
                {
                    BinaryFormatter bin = new BinaryFormatter();
                    _lstIndexes = JsonConvert.DeserializeObject<Dictionary<string, IndexObject>>(bin.Deserialize(fs) as string);
                }
            }
            
            using (FileStream fs = new FileStream(_emptyFileSpots, FileMode.OpenOrCreate, FileAccess.ReadWrite))
            {
                if (fs.Length < 1)
                {
                    emptyFileSpots = new SortedList<long, IndexObject>();
                    needsSave = true;
                }
                else
                {
                    BinaryFormatter bin = new BinaryFormatter();
                    emptyFileSpots = JsonConvert.DeserializeObject<SortedList<long, IndexObject>>(bin.Deserialize(fs) as string);
                }
            }

            using (FileStream fs = new FileStream(_lastIndexFile, FileMode.OpenOrCreate, FileAccess.ReadWrite))
            {
                if (fs.Length < 1)
                {
                    UpdateLastFilledIndex();
                    needsSave = true;
                }
                else
                {
                    BinaryFormatter bin = new BinaryFormatter();
                    lastFilledIndex = JsonConvert.DeserializeObject<IndexObject>(bin.Deserialize(fs) as string);
                }
            }

            using (FileStream fs = new FileStream(_averageLengthFile, FileMode.OpenOrCreate, FileAccess.ReadWrite))
            {
                if (fs.Length < 1)
                {
                    averageElementLength = defaultAverageElementLength;
                    needsSave = true;
                }
                else
                {
                    BinaryFormatter bin = new BinaryFormatter();
                    averageElementLength = JsonConvert.DeserializeObject<int?>(bin.Deserialize(fs) as string) ?? defaultAverageElementLength;
                }
            }

            using (FileStream fs = new FileStream(_typeFile, FileMode.OpenOrCreate, FileAccess.ReadWrite))
            {
                if (fs.Length < 1)
                {
                    typeInfo = null;
                }
                else
                {
                    BinaryFormatter bin = new BinaryFormatter();
                    typeInfo = bin.Deserialize(fs) as string;
                }
            }

            if (needsSave)
                UpdateIndexFiles();
        }

        //Emulate to be the of this file-hashtable
        protected object this[string key] { get { return Read(key); } set { Add(key, value == null ? string.Empty : value.ToString()); } }

        //Count
        public int Count { get { return _lstIndexes.Count; } }

        //ContainsKey
        public bool ContainsKey(string key)
        {
            return _lstIndexes.ContainsKey(key);
        }

        //protected KeyValuePair<string, string> this[int index] { get { return _lstIndexes.ElementAt(index); } } Never used, if needed should be changed to 
        //return Value and not the <key,index>-pair.

        #region IDisposable Members

        public void Dispose()
        {
            _file.Close();
            _file.Dispose();

            _lstIndexes.Clear();
            _lstIndexes = null;

            emptyFileSpots.Clear();
            emptyFileSpots = null;

            lastFilledIndex = null;
        }

        #endregion
    }

    internal static class HelpExtensions
    {
        internal static int UTF8Length(this string value)
        {
            if (value == null)
                return 0;

            byte[] res = Encoding.UTF8.GetBytes(value);
            return res.Length;
        }
    }
}