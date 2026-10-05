IF OBJECT_ID(N'dbo.InventoryItems', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.InventoryItems
    (
        Id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Sku nvarchar(32) NOT NULL UNIQUE,
        Name nvarchar(100) NOT NULL,
        Quantity int NOT NULL CHECK (Quantity >= 0)
    );
END;
GO

DELETE FROM dbo.InventoryItems;
DBCC CHECKIDENT (N'dbo.InventoryItems', RESEED, 0);
PRINT N'Azure SQL inventory schema initialization complete.';
GO