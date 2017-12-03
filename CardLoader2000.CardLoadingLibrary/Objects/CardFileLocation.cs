
namespace CardLoader2000.CardLoadingLibrary.Objects
{
    public class CardFileLocation
    {
        public byte[] TargetBytes { get; set; }
        public long StartPosition { get; set; }
        public long Length { get; set; }
        public string Name { get; set; }
    }
}
