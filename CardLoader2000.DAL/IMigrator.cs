
namespace CardLoader2000.DAL
{
    public interface IMigrator<T>
    {
        T Migrate(string jsonString);
    }
}
