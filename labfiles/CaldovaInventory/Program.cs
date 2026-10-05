using Caldova.Inventory.Api.Data;
using Caldova.Inventory.Api.Models;

var builder = WebApplication.CreateBuilder(args);

// Legacy deployment assumption: a local SQL credential is embedded in source code.
const string inventoryConnectionString =
    "Server=SQL01,1433;Database=CaldovaInventory;User Id=sa;" +
    "Password=Passw0rd!;Encrypt=True;TrustServerCertificate=True";

builder.Services.AddSingleton(new InventoryRepository(inventoryConnectionString));

var app = builder.Build();

app.MapGet("/", () => Results.Ok(new
{
    application = "Caldova Inventory API",
    endpoints = new[] { "GET /health", "GET /inventory", "POST /inventory" }
}));

app.MapGet("/health", () => Results.Ok(new { status = "Healthy" }));

app.MapGet("/inventory", async (InventoryRepository repository) =>
    Results.Ok(await repository.GetAllAsync()));

app.MapPost("/inventory", async (
    CreateInventoryItem request,
    InventoryRepository repository) =>
{
    if (string.IsNullOrWhiteSpace(request.Sku) ||
        string.IsNullOrWhiteSpace(request.Name) ||
        request.Quantity < 0)
    {
        return Results.BadRequest(new
        {
            error = "SKU and name are required, and quantity cannot be negative."
        });
    }

    var created = await repository.CreateAsync(request);
    return Results.Created($"/inventory/{created.Id}", created);
});

app.Run();
