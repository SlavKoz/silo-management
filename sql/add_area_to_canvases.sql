-- Add AreaID column to Canvases table
-- This links each canvas background to a specific area (or NULL for ALL areas)

-- Step 1: Add nullable AreaID column
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.Canvases')
               AND name = 'AreaID')
BEGIN
    ALTER TABLE dbo.Canvases
    ADD AreaID INT NULL;

    PRINT 'Added AreaID column to Canvases table';
END
ELSE
BEGIN
    PRINT 'AreaID column already exists in Canvases table';
END
GO

-- Step 2: Add foreign key constraint
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys
               WHERE name = 'FK_Canvases_SiteAreas'
               AND parent_object_id = OBJECT_ID('dbo.Canvases'))
BEGIN
    ALTER TABLE dbo.Canvases
    ADD CONSTRAINT FK_Canvases_SiteAreas
    FOREIGN KEY (AreaID) REFERENCES dbo.SiteAreas(AreaID)
    ON DELETE SET NULL;  -- If area is deleted, set canvas's AreaID to NULL (becomes ALL)

    PRINT 'Added FK_Canvases_SiteAreas foreign key constraint';
END
ELSE
BEGIN
    PRINT 'FK_Canvases_SiteAreas constraint already exists';
END
GO

PRINT 'Schema update completed successfully';
PRINT 'Note: Canvases with AreaID = NULL represent backgrounds for ALL areas';
