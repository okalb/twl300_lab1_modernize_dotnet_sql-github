namespace Caldova.Inventory.Api.Models;

public sealed record InventoryItem(int Id, string Sku, string Name, int Quantity);

public sealed record CreateInventoryItem(string Sku, string Name, int Quantity);
