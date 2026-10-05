IF DB_ID(N'CaldovaInventory') IS NULL
BEGIN
    CREATE DATABASE CaldovaInventory;
END;
GO

USE CaldovaInventory;
GO

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

INSERT INTO dbo.InventoryItems (Sku, Name, Quantity)
VALUES
    (N'CAL-100', N'Pressure controller', 12),
    (N'CAL-200', N'Industrial gateway', 7),
    (N'CAL-300', N'Safety relay', 25);
GO

PRINT N'CaldovaInventory initialization complete.';
GO
