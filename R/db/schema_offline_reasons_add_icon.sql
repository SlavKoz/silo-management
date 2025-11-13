-- Add Icon field to OfflineReasonTypes table
-- Run this in SQL Server Management Studio or Azure Data Studio

USE SiloOps;
GO

-- Add Icon column (nullable integer, references Icons table)
ALTER TABLE dbo.OfflineReasonTypes
ADD Icon INT NULL;
GO

-- Verify the changes
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'OfflineReasonTypes'
ORDER BY ORDINAL_POSITION;
GO
