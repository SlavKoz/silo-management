USE [SiloOps]
GO

/* Auxiliary dimension caches pulled from Franklin */
IF OBJECT_ID('dbo.CropYears', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CropYears (
        CropYearID INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(50) NOT NULL,
        Name NVARCHAR(200) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1
    );
    CREATE UNIQUE INDEX UX_CropYears_Code ON dbo.CropYears(Code);
END
GO

IF OBJECT_ID('dbo.Pools', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Pools (
        PoolID INT IDENTITY(1,1) PRIMARY KEY,
        PoolCode NVARCHAR(50) NOT NULL,
        PoolName NVARCHAR(200) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1
    );
    CREATE UNIQUE INDEX UX_Pools_PoolCode ON dbo.Pools(PoolCode);
END
GO
