USE [SiloOps]
GO

/*
  Sync auxiliary dimension values (Crop Year, Pool) from Franklin.
  Data volume is tiny (~20-30 items) and changes infrequently, so we cache locally
  and soft-deactivate anything no longer present.
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.sp_SyncAuxDataFromFranklin
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* ---------- Crop Years ---------- */
        WITH src AS (
            SELECT
                [Code] COLLATE DATABASE_DEFAULT AS Code,
                [Name] COLLATE DATABASE_DEFAULT AS Name
            FROM Franklin.dbo.[Operations$Dimension Value]
            WHERE [Dimension Code] = 'CROP YEAR'
        )
        MERGE dbo.CropYears AS target
        USING src AS source
          ON target.Code = source.Code
        WHEN MATCHED THEN
            UPDATE SET
                target.Name = ISNULL(NULLIF(target.Name, ''), source.Name),
                target.IsActive = 1
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (Code, Name, IsActive)
            VALUES (source.Code, source.Name, 1)
        WHEN NOT MATCHED BY SOURCE THEN
            UPDATE SET IsActive = 0;

        /* ---------- Pools ---------- */
        WITH src AS (
            SELECT
                [Code] COLLATE DATABASE_DEFAULT AS PoolCode,
                [Name] COLLATE DATABASE_DEFAULT AS PoolName
            FROM Franklin.dbo.[Operations$Dimension Value]
            WHERE [Dimension Code] = 'Pool'
        )
        MERGE dbo.Pools AS target
        USING src AS source
          ON target.PoolCode = source.PoolCode
        WHEN MATCHED THEN
            UPDATE SET
                target.PoolName = ISNULL(NULLIF(target.PoolName, ''), source.PoolName),
                target.IsActive = 1
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (PoolCode, PoolName, IsActive)
            VALUES (source.PoolCode, source.PoolName, 1)
        WHEN NOT MATCHED BY SOURCE THEN
            UPDATE SET IsActive = 0;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
