-- sql/fix_variants_structure.sql
-- Fix the VariantAttributes table structure after partial migration

USE SiloOps;
GO

PRINT '========================================';
PRINT 'Fixing Variants Table Structure';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- Step 1: Add Pattern column if missing
-- ============================================================================
PRINT 'Step 1: Adding Pattern column...';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'Pattern')
BEGIN
    ALTER TABLE dbo.VariantAttributes ADD Pattern NVARCHAR(50) NULL;
    PRINT 'Pattern column added to VariantAttributes';
END
ELSE
BEGIN
    PRINT 'Pattern column already exists';
END

PRINT '';

-- ============================================================================
-- Step 2: Drop DefaultColour column (with constraint)
-- ============================================================================
PRINT 'Step 2: Dropping DefaultColour column...';

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'DefaultColour')
BEGIN
    -- Find and drop the default constraint
    DECLARE @ConstraintName NVARCHAR(200);
    SELECT @ConstraintName = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE c.object_id = OBJECT_ID('dbo.VariantAttributes')
      AND c.name = 'DefaultColour';

    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(500) = 'ALTER TABLE dbo.VariantAttributes DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
        PRINT 'Default constraint dropped: ' + @ConstraintName;
    END

    -- Now drop the column
    ALTER TABLE dbo.VariantAttributes DROP COLUMN DefaultColour;
    PRINT 'DefaultColour column dropped from VariantAttributes';
END
ELSE
BEGIN
    PRINT 'DefaultColour column does not exist';
END

PRINT '';

-- ============================================================================
-- Step 3: Remove date columns if they exist
-- ============================================================================
PRINT 'Step 3: Removing date columns...';

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Variants') AND name = 'LastSyncDate')
BEGIN
    ALTER TABLE dbo.Variants DROP COLUMN LastSyncDate;
    PRINT 'LastSyncDate dropped from Variants';
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'CreatedDate')
BEGIN
    ALTER TABLE dbo.VariantAttributes DROP COLUMN CreatedDate;
    PRINT 'CreatedDate dropped from VariantAttributes';
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'ModifiedDate')
BEGIN
    ALTER TABLE dbo.VariantAttributes DROP COLUMN ModifiedDate;
    PRINT 'ModifiedDate dropped from VariantAttributes';
END

PRINT '';

-- ============================================================================
-- Step 4: Recreate vw_Variants view
-- ============================================================================
PRINT 'Step 4: Recreating vw_Variants view...';

IF OBJECT_ID('dbo.vw_Variants', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Variants;
GO

CREATE VIEW dbo.vw_Variants
AS
SELECT
    v.VariantID,
    v.VariantNo,
    v.GrainGroup,
    v.Commodity,
    v.IsActive,
    va.Pattern,
    va.Notes,
    gg.BaseColour AS GrainGroupColour,
    gg.ColourName AS GrainGroupColourName,
    gg.CommodityBaseColour,
    gg.BaseColour AS EffectiveColour,
    CASE WHEN va.Pattern IS NULL OR va.Pattern = '' THEN 1 ELSE 0 END AS MissingPattern,
    0 AS MissingBaseColour
FROM dbo.Variants v
LEFT JOIN dbo.VariantAttributes va ON v.VariantID = va.VariantID
LEFT JOIN dbo.vw_GrainGroups gg ON v.GrainGroup = gg.GrainGroupCode;
GO

PRINT 'vw_Variants view recreated successfully';
PRINT '';

-- ============================================================================
-- Step 5: Create or update stored procedure
-- ============================================================================
PRINT 'Step 5: Creating sp_UpdateVariantAttributes procedure...';

IF OBJECT_ID('dbo.sp_UpdateVariantAttributes', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateVariantAttributes;
GO

CREATE PROCEDURE dbo.sp_UpdateVariantAttributes
    @VariantID  INT,
    @Pattern    NVARCHAR(50) = NULL,
    @Notes      NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if variant exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Variants WHERE VariantID = @VariantID)
    BEGIN
        RAISERROR('Variant ID %d does not exist', 16, 1, @VariantID);
        RETURN;
    END

    -- Update attributes
    UPDATE dbo.VariantAttributes
    SET
        Pattern = ISNULL(@Pattern, Pattern),
        Notes = ISNULL(@Notes, Notes)
    WHERE VariantID = @VariantID;

    -- If no attributes record exists, create one
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO dbo.VariantAttributes (VariantID, Pattern, Notes)
        VALUES (@VariantID, @Pattern, @Notes);
    END
END;
GO

PRINT 'sp_UpdateVariantAttributes procedure created';
PRINT '';

-- ============================================================================
-- Step 6: Create PatternTypes reference table
-- ============================================================================
PRINT 'Step 6: Creating PatternTypes reference table...';

IF OBJECT_ID('dbo.PatternTypes', 'U') IS NOT NULL
    DROP TABLE dbo.PatternTypes;

CREATE TABLE dbo.PatternTypes (
    PatternID       INT IDENTITY(1,1) PRIMARY KEY,
    PatternCode     NVARCHAR(50) NOT NULL UNIQUE,
    PatternName     NVARCHAR(100) NOT NULL,
    Description     NVARCHAR(500),
    DisplayOrder    INT,
    IsActive        BIT NOT NULL DEFAULT 1
);

INSERT INTO dbo.PatternTypes (PatternCode, PatternName, Description, DisplayOrder) VALUES
('solid',       'Solid',            'No pattern - solid color fill',           1),
('striped',     'Striped',          'Horizontal stripes',                       2),
('v-striped',   'Vertical Striped', 'Vertical stripes',                         3),
('dotted',      'Dotted',           'Small dots/stippling',                     4),
('checkered',   'Checkered',        'Checkered/grid pattern',                   5),
('diagonal',    'Diagonal',         'Diagonal lines (45°)',                     6),
('crosshatch',  'Crosshatch',       'Crossed diagonal lines',                   7),
('wavy',        'Wavy',             'Wavy/undulating lines',                    8),
('zigzag',      'Zigzag',           'Zigzag pattern',                           9),
('herringbone', 'Herringbone',      'V-shaped weaving pattern',                 10),
('brick',       'Brick',            'Brick-like offset pattern',                11),
('honeycomb',   'Honeycomb',        'Hexagonal honeycomb pattern',              12);

PRINT 'PatternTypes table created with ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' pattern types';
PRINT '';

-- ============================================================================
-- Verification
-- ============================================================================
PRINT '========================================';
PRINT 'VERIFICATION';
PRINT '========================================';
PRINT '';

-- Check VariantAttributes structure
PRINT 'VariantAttributes columns:';
SELECT c.name AS ColumnName, t.name AS DataType, c.max_length, c.is_nullable
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.VariantAttributes')
ORDER BY c.column_id;

PRINT '';
PRINT 'Testing view with sample query:';
SELECT TOP 5
    VariantNo,
    GrainGroup,
    Commodity,
    Pattern,
    GrainGroupColour,
    EffectiveColour
FROM dbo.vw_Variants
WHERE Commodity = 'WHT'
ORDER BY VariantNo;

PRINT '';
PRINT '========================================';
PRINT 'FIX COMPLETE!';
PRINT '========================================';
PRINT '';
PRINT 'Variants table structure is now correct:';
PRINT '- Pattern column added';
PRINT '- DefaultColour column removed';
PRINT '- Date columns removed';
PRINT '- vw_Variants view working';
PRINT '- sp_UpdateVariantAttributes procedure ready';
PRINT '';

GO
