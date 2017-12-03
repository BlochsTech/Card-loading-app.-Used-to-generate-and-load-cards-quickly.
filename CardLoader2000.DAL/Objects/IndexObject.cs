namespace CardLoader2000.DAL.Objects
{
    public class IndexObject
    {
        /// <summary>
        /// Position in file that element starts. Also file spot start position.
        /// </summary>
        public long FilePosition { get; set; }

        /// <summary>
        /// Length of element as it is now.
        /// </summary>
        public int ElementLength { get; set; }

        /// <summary>
        /// Length of the file spot, IE the number of bytes reserved for this
        /// element in the file. Unused bytes should be empty spaces.
        /// </summary>
        public int FileSpotLength { get; set; }
    }
}
