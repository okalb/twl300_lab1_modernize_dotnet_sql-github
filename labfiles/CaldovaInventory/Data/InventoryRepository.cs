using Caldova.Inventory.Api.Models;
using Microsoft.Data.SqlClient;

namespace Caldova.Inventory.Api.Data;

public sealed class InventoryRepository(string connectionString)
{
    public async Task<IReadOnlyList<InventoryItem>> GetAllAsync()
    {
        const string query = """
            SELECT Id, Sku, Name, Quantity
            FROM dbo.InventoryItems
            ORDER BY Sku;
            """;

        var items = new List<InventoryItem>();

        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();
        await using var command = new SqlCommand(query, connection);
        await using var reader = await command.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            items.Add(new InventoryItem(
                reader.GetInt32(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetInt32(3)));
        }

        return items;
    }

    public async Task<InventoryItem> CreateAsync(CreateInventoryItem request)
    {
        const string commandText = """
            INSERT INTO dbo.InventoryItems (Sku, Name, Quantity)
            OUTPUT INSERTED.Id
            VALUES (@Sku, @Name, @Quantity);
            """;

        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();
        await using var command = new SqlCommand(commandText, connection);
        command.Parameters.AddWithValue("@Sku", request.Sku);
        command.Parameters.AddWithValue("@Name", request.Name);
        command.Parameters.AddWithValue("@Quantity", request.Quantity);

        var id = Convert.ToInt32(await command.ExecuteScalarAsync());
        return new InventoryItem(id, request.Sku, request.Name, request.Quantity);
    }
}
