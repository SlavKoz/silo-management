-- sql/create_sync_log_table.sql
-- Global sync tracking table for all Franklin sync operations

USE SiloOps;
GO

-- ============================================================================
-- Global SyncLog table - tracks all sync operations
-- ============================================================================

IF OBJECT_ID('dbo.SyncLog', 'U') IS NOT NULL
    DROP TABLE dbo.SyncLog;
GO

CREATE TABLE dbo.SyncLog (
    SyncID          INT IDENTITY(1,1) PRIMARY KEY,
    EntityType      NVARCHAR(50) NOT NULL,      -- e.g., 'Variants', 'Commodities', 'GrainGroups'
    SyncStartTime   DATETIME2 NOT NULL,
    SyncEndTime     DATETIME2,
    RecordsProcessed INT,
    RecordsAdded    INT,
    RecordsUpdated  INT,
    RecordsDeactivated INT,
    Status          NVARCHAR(20) NOT NULL,      -- 'Running', 'Success', 'Failed'
    ErrorMessage    NVARCHAR(MAX),
    SyncedBy        NVARCHAR(100)               -- User or 'System' or 'Scheduled Job'
);
GO

-- Index for quick lookups
CREATE NONCLUSTERED INDEX IX_SyncLog_EntityType_SyncStartTime
ON dbo.SyncLog (EntityType, SyncStartTime DESC);
GO

-- ============================================================================
-- View to get latest sync info for each entity type
-- ============================================================================

IF OBJECT_ID('dbo.vw_LatestSyncStatus', 'V') IS NOT NULL
    DROP VIEW dbo.vw_LatestSyncStatus;
GO

CREATE VIEW dbo.vw_LatestSyncStatus
AS
WITH LatestSync AS (
    SELECT
        EntityType,
        MAX(SyncID) AS LatestSyncID
    FROM dbo.SyncLog
    GROUP BY EntityType
)
SELECT
    sl.SyncID,
    sl.EntityType,
    sl.SyncStartTime,
    sl.SyncEndTime,
    sl.RecordsProcessed,
    sl.RecordsAdded,
    sl.RecordsUpdated,
    sl.RecordsDeactivated,
    sl.Status,
    sl.ErrorMessage,
    sl.SyncedBy,
    DATEDIFF(SECOND, sl.SyncStartTime, ISNULL(sl.SyncEndTime, GETDATE())) AS DurationSeconds
FROM dbo.SyncLog sl
INNER JOIN LatestSync ls ON sl.SyncID = ls.LatestSyncID;
GO

-- ============================================================================
-- Helper procedure to log sync operations
-- ============================================================================

IF OBJECT_ID('dbo.sp_LogSyncStart', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_LogSyncStart;
GO

CREATE PROCEDURE dbo.sp_LogSyncStart
    @EntityType NVARCHAR(50),
    @SyncedBy NVARCHAR(100) = 'System',
    @SyncID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.SyncLog (EntityType, SyncStartTime, Status, SyncedBy)
    VALUES (@EntityType, GETDATE(), 'Running', @SyncedBy);

    SET @SyncID = SCOPE_IDENTITY();
END;
GO

IF OBJECT_ID('dbo.sp_LogSyncEnd', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_LogSyncEnd;
GO

CREATE PROCEDURE dbo.sp_LogSyncEnd
    @SyncID INT,
    @RecordsProcessed INT = 0,
    @RecordsAdded INT = 0,
    @RecordsUpdated INT = 0,
    @RecordsDeactivated INT = 0,
    @Status NVARCHAR(20) = 'Success',
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.SyncLog
    SET
        SyncEndTime = GETDATE(),
        RecordsProcessed = @RecordsProcessed,
        RecordsAdded = @RecordsAdded,
        RecordsUpdated = @RecordsUpdated,
        RecordsDeactivated = @RecordsDeactivated,
        Status = @Status,
        ErrorMessage = @ErrorMessage
    WHERE SyncID = @SyncID;
END;
GO

PRINT 'SyncLog table and procedures created successfully';
GO
