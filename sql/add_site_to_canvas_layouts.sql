-- Add SiteID column to CanvasLayouts table
-- This links each layout to a specific site (one-to-one relationship)

-- Step 1: Add nullable SiteID column
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.CanvasLayouts')
               AND name = 'SiteID')
BEGIN
    ALTER TABLE dbo.CanvasLayouts
    ADD SiteID INT NULL;

    PRINT 'Added SiteID column to CanvasLayouts table';
END
ELSE
BEGIN
    PRINT 'SiteID column already exists in CanvasLayouts table';
END
GO

-- Step 2: Add foreign key constraint
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys
               WHERE name = 'FK_CanvasLayouts_Sites'
               AND parent_object_id = OBJECT_ID('dbo.CanvasLayouts'))
BEGIN
    ALTER TABLE dbo.CanvasLayouts
    ADD CONSTRAINT FK_CanvasLayouts_Sites
    FOREIGN KEY (SiteID) REFERENCES dbo.Sites(SiteID)
    ON DELETE SET NULL;  -- If site is deleted, set layout's SiteID to NULL

    PRINT 'Added FK_CanvasLayouts_Sites foreign key constraint';
END
ELSE
BEGIN
    PRINT 'FK_CanvasLayouts_Sites constraint already exists';
END
GO

PRINT 'Schema update completed successfully';
