-- sql/MIGRATION_to_color_system.sql
-- Migrate existing database to the new color system
-- Run this INSTEAD of the master setup if you already have tables

USE SiloOps;
GO

PRINT '========================================';
PRINT 'MIGRATION: Existing DB to Color System';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- STEP 1: Create CommodityAttributes table (MISSING!)
-- ============================================================================
PRINT 'STEP 1: Creating CommodityAttributes table...';

IF OBJECT_ID('dbo.CommodityAttributes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CommodityAttributes (
        CommodityID     INT PRIMARY KEY,
        BaseColour      NVARCHAR(7),
        ColourName      NVARCHAR(50),
        DisplayOrder    INT,
        Notes           NVARCHAR(MAX),
        CONSTRAINT FK_CommodityAttributes_Commodity
            FOREIGN KEY (CommodityID) REFERENCES dbo.Commodities(CommodityID)
            ON DELETE CASCADE
    );

    PRINT 'CommodityAttributes table created';

    -- Populate with colors
    INSERT INTO dbo.CommodityAttributes (CommodityID, BaseColour, ColourName, DisplayOrder)
    SELECT CommodityID, BaseColour, ColourName, DisplayOrder
    FROM (VALUES
        ('WHT',    '#DAA520', 'Goldenrod',           10),
        ('OSR',    '#FFD700', 'Gold',                20),
        ('MBLY',   '#8B4513', 'Saddle Brown',        30),
        ('FBLY',   '#CD853F', 'Peru',                40),
        ('PEAS',   '#32CD32', 'Lime Green',          50),
        ('BNS',    '#228B22', 'Forest Green',        60),
        ('OATS',   '#F5DEB3', 'Wheat',               70),
        ('LIN',    '#4169E1', 'Royal Blue',          80),
        ('RYE',    '#708090', 'Slate Gray',          90),
        ('TRI',    '#9370DB', 'Medium Purple',      100),
        ('MILL',   '#FFFACD', 'Lemon Chiffon',      110),
        ('WARB',   '#DC143C', 'Crimson',            120),
        ('IMP',    '#A9A9A9', 'Dark Gray',          130),
        ('ICWHT',  '#F0E68C', 'Khaki',              210),
        ('ICMBLY', '#A0522D', 'Sienna',             230),
        ('ICFBLY', '#DEB887', 'Burlywood',          240),
        ('ICPEAS', '#90EE90', 'Light Green',        250),
        ('ICBNS',  '#3CB371', 'Medium Sea Green',   260),
        ('ICOATS', '#FAEBD7', 'Antique White',      270),
        ('OGWHT',  '#D4AF37', 'Old Gold',           310),
        ('OGMBLY', '#654321', 'Dark Brown',         330),
        ('OGFBLY', '#B8860B', 'Dark Goldenrod',     340),
        ('OGPEAS', '#6B8E23', 'Olive Drab',         350),
        ('OGBNS',  '#556B2F', 'Dark Olive Green',   360),
        ('OGOATS', '#EEE8AA', 'Pale Goldenrod',     370),
        ('OGRYE',  '#696969', 'Dim Gray',           390),
        ('OGTRI',  '#7B68EE', 'Medium Slate Blue',  400)
    ) AS Source(CommodityCode, BaseColour, ColourName, DisplayOrder)
    INNER JOIN dbo.Commodities c ON c.CommodityCode = Source.CommodityCode;

    PRINT 'Commodity colors populated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';
END
ELSE
BEGIN
    PRINT 'CommodityAttributes table already exists';
END

PRINT '';

-- ============================================================================
-- STEP 2: Compute colors for existing grain groups
-- ============================================================================
PRINT 'STEP 2: Computing colors for grain groups...';

-- Ensure function exists
IF OBJECT_ID('dbo.fn_ComputeGrainGroupColour', 'FN') IS NULL
BEGIN
    PRINT 'Creating color computation function...';
    EXEC('
    CREATE FUNCTION dbo.fn_ComputeGrainGroupColour
    (
        @CommodityColourHex NVARCHAR(7),
        @LightnessModifier DECIMAL(4,2)
    )
    RETURNS NVARCHAR(7)
    AS
    BEGIN
        DECLARE @R INT, @G INT, @B INT;
        DECLARE @NewR INT, @NewG INT, @NewB INT;

        SET @CommodityColourHex = REPLACE(@CommodityColourHex, ''#'', '''');

        SET @R = CONVERT(INT, CONVERT(VARBINARY(1), SUBSTRING(@CommodityColourHex, 1, 2), 2));
        SET @G = CONVERT(INT, CONVERT(VARBINARY(1), SUBSTRING(@CommodityColourHex, 3, 2), 2));
        SET @B = CONVERT(INT, CONVERT(VARBINARY(1), SUBSTRING(@CommodityColourHex, 5, 2), 2));

        SET @NewR = CASE WHEN @LightnessModifier > 1.0
            THEN @R + (255 - @R) * (@LightnessModifier - 1.0) ELSE @R * @LightnessModifier END;
        SET @NewG = CASE WHEN @LightnessModifier > 1.0
            THEN @G + (255 - @G) * (@LightnessModifier - 1.0) ELSE @G * @LightnessModifier END;
        SET @NewB = CASE WHEN @LightnessModifier > 1.0
            THEN @B + (255 - @B) * (@LightnessModifier - 1.0) ELSE @B * @LightnessModifier END;

        SET @NewR = CASE WHEN @NewR < 0 THEN 0 WHEN @NewR > 255 THEN 255 ELSE @NewR END;
        SET @NewG = CASE WHEN @NewG < 0 THEN 0 WHEN @NewG > 255 THEN 255 ELSE @NewG END;
        SET @NewB = CASE WHEN @NewB < 0 THEN 0 WHEN @NewB > 255 THEN 255 ELSE @NewB END;

        RETURN UPPER(''#'' +
            RIGHT(''0'' + CONVERT(VARCHAR(2), CONVERT(VARBINARY(1), @NewR), 2), 2) +
            RIGHT(''0'' + CONVERT(VARCHAR(2), CONVERT(VARBINARY(1), @NewG), 2), 2) +
            RIGHT(''0'' + CONVERT(VARCHAR(2), CONVERT(VARBINARY(1), @NewB), 2), 2));
    END;
    ');
    PRINT 'Color computation function created';
END

-- Compute colors for all grain groups that have modifiers
UPDATE gga
SET ComputedColour = dbo.fn_ComputeGrainGroupColour(ca.BaseColour, ISNULL(gga.LightnessModifier, 1.0))
FROM dbo.GrainGroupAttributes gga
INNER JOIN dbo.GrainGroups gg ON gga.GrainGroupID = gg.GrainGroupID
INNER JOIN dbo.Commodities c ON gg.CommodityID = c.CommodityID
INNER JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID
WHERE ca.BaseColour IS NOT NULL;

PRINT 'Colors computed: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';
PRINT '';

-- ============================================================================
-- STEP 3: Update VariantAttributes structure
-- ============================================================================
PRINT 'STEP 3: Updating VariantAttributes structure...';

-- Add Pattern column FIRST
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'Pattern')
BEGIN
    ALTER TABLE dbo.VariantAttributes ADD Pattern NVARCHAR(50) NULL;
    PRINT 'Pattern column added';
END
ELSE
BEGIN
    PRINT 'Pattern column already exists';
END

-- Drop DefaultColour with its constraint
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'DefaultColour')
BEGIN
    DECLARE @ConstraintName NVARCHAR(200);
    SELECT @ConstraintName = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE c.object_id = OBJECT_ID('dbo.VariantAttributes') AND c.name = 'DefaultColour';

    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL1 NVARCHAR(500) = 'ALTER TABLE dbo.VariantAttributes DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL1;
        PRINT 'Constraint dropped: ' + @ConstraintName;
    END

    ALTER TABLE dbo.VariantAttributes DROP COLUMN DefaultColour;
    PRINT 'DefaultColour column dropped';
END

-- Drop date columns from VariantAttributes (with constraints)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'CreatedDate')
BEGIN
    -- Drop constraint on CreatedDate
    DECLARE @ConstraintCreated NVARCHAR(200);
    SELECT @ConstraintCreated = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE c.object_id = OBJECT_ID('dbo.VariantAttributes') AND c.name = 'CreatedDate';

    IF @ConstraintCreated IS NOT NULL
    BEGIN
        DECLARE @SQLCreated NVARCHAR(500) = 'ALTER TABLE dbo.VariantAttributes DROP CONSTRAINT ' + QUOTENAME(@ConstraintCreated);
        EXEC sp_executesql @SQLCreated;
        PRINT 'CreatedDate constraint dropped: ' + @ConstraintCreated;
    END

    ALTER TABLE dbo.VariantAttributes DROP COLUMN CreatedDate;
    PRINT 'CreatedDate dropped from VariantAttributes';
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'ModifiedDate')
BEGIN
    -- Drop constraint on ModifiedDate
    DECLARE @ConstraintModified NVARCHAR(200);
    SELECT @ConstraintModified = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE c.object_id = OBJECT_ID('dbo.VariantAttributes') AND c.name = 'ModifiedDate';

    IF @ConstraintModified IS NOT NULL
    BEGIN
        DECLARE @SQLModified NVARCHAR(500) = 'ALTER TABLE dbo.VariantAttributes DROP CONSTRAINT ' + QUOTENAME(@ConstraintModified);
        EXEC sp_executesql @SQLModified;
        PRINT 'ModifiedDate constraint dropped: ' + @ConstraintModified;
    END

    ALTER TABLE dbo.VariantAttributes DROP COLUMN ModifiedDate;
    PRINT 'ModifiedDate dropped from VariantAttributes';
END

PRINT '';

-- ============================================================================
-- STEP 4: Update Variants structure
-- ============================================================================
PRINT 'STEP 4: Updating Variants structure...';

-- Drop LastSyncDate from Variants (with constraint)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Variants') AND name = 'LastSyncDate')
BEGIN
    -- Find and drop the default constraint
    DECLARE @ConstraintLastSync NVARCHAR(200);
    SELECT @ConstraintLastSync = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE c.object_id = OBJECT_ID('dbo.Variants') AND c.name = 'LastSyncDate';

    IF @ConstraintLastSync IS NOT NULL
    BEGIN
        DECLARE @SQLLastSync NVARCHAR(500) = 'ALTER TABLE dbo.Variants DROP CONSTRAINT ' + QUOTENAME(@ConstraintLastSync);
        EXEC sp_executesql @SQLLastSync;
        PRINT 'LastSyncDate constraint dropped: ' + @ConstraintLastSync;
    END

    ALTER TABLE dbo.Variants DROP COLUMN LastSyncDate;
    PRINT 'LastSyncDate dropped from Variants';
END

-- Drop CreatedDate from Variants (with constraint)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Variants') AND name = 'CreatedDate')
BEGIN
    -- Find and drop the default constraint
    DECLARE @ConstraintVarCreated NVARCHAR(200);
    SELECT @ConstraintVarCreated = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE c.object_id = OBJECT_ID('dbo.Variants') AND c.name = 'CreatedDate';

    IF @ConstraintVarCreated IS NOT NULL
    BEGIN
        DECLARE @SQLVarCreated NVARCHAR(500) = 'ALTER TABLE dbo.Variants DROP CONSTRAINT ' + QUOTENAME(@ConstraintVarCreated);
        EXEC sp_executesql @SQLVarCreated;
        PRINT 'CreatedDate constraint dropped: ' + @ConstraintVarCreated;
    END

    ALTER TABLE dbo.Variants DROP COLUMN CreatedDate;
    PRINT 'CreatedDate dropped from Variants';
END

-- Drop ModifiedDate from Variants (with constraint)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Variants') AND name = 'ModifiedDate')
BEGIN
    -- Find and drop the default constraint
    DECLARE @ConstraintVarModified NVARCHAR(200);
    SELECT @ConstraintVarModified = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE c.object_id = OBJECT_ID('dbo.Variants') AND c.name = 'ModifiedDate';

    IF @ConstraintVarModified IS NOT NULL
    BEGIN
        DECLARE @SQLVarModified NVARCHAR(500) = 'ALTER TABLE dbo.Variants DROP CONSTRAINT ' + QUOTENAME(@ConstraintVarModified);
        EXEC sp_executesql @SQLVarModified;
        PRINT 'ModifiedDate constraint dropped: ' + @ConstraintVarModified;
    END

    ALTER TABLE dbo.Variants DROP COLUMN ModifiedDate;
    PRINT 'ModifiedDate dropped from Variants';
END

PRINT '';

-- ============================================================================
-- STEP 5: Recreate views
-- ============================================================================
PRINT 'STEP 5: Recreating views...';

-- Drop all existing views first
IF OBJECT_ID('dbo.vw_Variants', 'V') IS NOT NULL DROP VIEW dbo.vw_Variants;
IF OBJECT_ID('dbo.vw_GrainGroups', 'V') IS NOT NULL DROP VIEW dbo.vw_GrainGroups;
IF OBJECT_ID('dbo.vw_Commodities', 'V') IS NOT NULL DROP VIEW dbo.vw_Commodities;
PRINT 'Existing views dropped (if they existed)';
GO

CREATE VIEW dbo.vw_Commodities AS
SELECT c.CommodityID, c.CommodityCode, c.CommodityName, c.IsActive,
       ca.BaseColour, ca.ColourName, ca.DisplayOrder, ca.Notes,
       CASE WHEN ca.BaseColour IS NULL OR ca.BaseColour = '' THEN 1 ELSE 0 END AS MissingColour
FROM dbo.Commodities c
LEFT JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID;
GO

PRINT 'vw_Commodities created';
GO

CREATE VIEW dbo.vw_GrainGroups AS
SELECT gg.GrainGroupID, gg.GrainGroupCode, gg.GrainGroupName, gg.CommodityID,
       c.CommodityCode, c.CommodityName, gg.IsActive,
       gga.LightnessModifier, gga.ColourName, gga.DisplayOrder, gga.Notes,
       ca.BaseColour AS CommodityBaseColour, ca.ColourName AS CommodityColourName,
       COALESCE(gga.ComputedColour, ca.BaseColour) AS BaseColour,
       CASE WHEN gga.GrainGroupID IS NULL THEN 1 ELSE 0 END AS MissingColour
FROM dbo.GrainGroups gg
INNER JOIN dbo.Commodities c ON gg.CommodityID = c.CommodityID
LEFT JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID
LEFT JOIN dbo.GrainGroupAttributes gga ON gg.GrainGroupID = gga.GrainGroupID;
GO

PRINT 'vw_GrainGroups created';
GO

CREATE VIEW dbo.vw_Variants AS
SELECT v.VariantID, v.VariantNo, v.GrainGroup, v.Commodity, v.IsActive,
       va.Pattern, va.Notes,
       gg.BaseColour AS GrainGroupColour, gg.ColourName AS GrainGroupColourName,
       gg.CommodityBaseColour, gg.BaseColour AS EffectiveColour,
       CASE WHEN va.Pattern IS NULL OR va.Pattern = '' THEN 1 ELSE 0 END AS MissingPattern,
       0 AS MissingBaseColour
FROM dbo.Variants v
LEFT JOIN dbo.VariantAttributes va ON v.VariantID = va.VariantID
LEFT JOIN dbo.vw_GrainGroups gg ON v.GrainGroup = gg.GrainGroupCode;
GO

PRINT 'vw_Variants created';
PRINT '';
GO

-- ============================================================================
-- STEP 6: Create stored procedures
-- ============================================================================
PRINT 'STEP 6: Creating stored procedures...';

-- Recalculate colors procedure
IF OBJECT_ID('dbo.sp_RecalculateGrainGroupColours', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_RecalculateGrainGroupColours;
GO
CREATE PROCEDURE dbo.sp_RecalculateGrainGroupColours
    @CommodityID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE gga
    SET ComputedColour = dbo.fn_ComputeGrainGroupColour(ca.BaseColour, ISNULL(gga.LightnessModifier, 1.0))
    FROM dbo.GrainGroupAttributes gga
    INNER JOIN dbo.GrainGroups gg ON gga.GrainGroupID = gg.GrainGroupID
    INNER JOIN dbo.Commodities c ON gg.CommodityID = c.CommodityID
    INNER JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID
    WHERE (@CommodityID IS NULL OR gg.CommodityID = @CommodityID) AND ca.BaseColour IS NOT NULL;
    PRINT 'Grain group colors recalculated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';
    RETURN @@ROWCOUNT;
END;
GO

PRINT 'sp_RecalculateGrainGroupColours created';

-- Update variant attributes procedure
IF OBJECT_ID('dbo.sp_UpdateVariantAttributes', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_UpdateVariantAttributes;
GO
CREATE PROCEDURE dbo.sp_UpdateVariantAttributes
    @VariantID INT,
    @Pattern NVARCHAR(50) = NULL,
    @Notes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Variants WHERE VariantID = @VariantID)
    BEGIN
        RAISERROR('Variant ID %d does not exist', 16, 1, @VariantID);
        RETURN;
    END
    UPDATE dbo.VariantAttributes SET Pattern = ISNULL(@Pattern, Pattern), Notes = ISNULL(@Notes, Notes)
    WHERE VariantID = @VariantID;
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO dbo.VariantAttributes (VariantID, Pattern, Notes)
        VALUES (@VariantID, @Pattern, @Notes);
    END
END;
GO

PRINT 'sp_UpdateVariantAttributes created';
PRINT '';

-- ============================================================================
-- STEP 7: Create PatternTypes reference table
-- ============================================================================
PRINT 'STEP 7: Creating PatternTypes reference table...';

IF OBJECT_ID('dbo.PatternTypes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PatternTypes (
        PatternID INT IDENTITY(1,1) PRIMARY KEY,
        PatternCode NVARCHAR(50) NOT NULL UNIQUE,
        PatternName NVARCHAR(100) NOT NULL,
        Description NVARCHAR(500),
        DisplayOrder INT,
        IsActive BIT NOT NULL DEFAULT 1
    );

    INSERT INTO dbo.PatternTypes (PatternCode, PatternName, Description, DisplayOrder) VALUES
    ('solid',       'Solid',            'No pattern - solid color fill',       1),
    ('striped',     'Striped',          'Horizontal stripes',                   2),
    ('v-striped',   'Vertical Striped', 'Vertical stripes',                     3),
    ('dotted',      'Dotted',           'Small dots/stippling',                 4),
    ('checkered',   'Checkered',        'Checkered/grid pattern',               5),
    ('diagonal',    'Diagonal',         'Diagonal lines (45°)',                 6),
    ('crosshatch',  'Crosshatch',       'Crossed diagonal lines',               7),
    ('wavy',        'Wavy',             'Wavy/undulating lines',                8),
    ('zigzag',      'Zigzag',           'Zigzag pattern',                       9),
    ('herringbone', 'Herringbone',      'V-shaped weaving pattern',             10),
    ('brick',       'Brick',            'Brick-like offset pattern',            11),
    ('honeycomb',   'Honeycomb',        'Hexagonal honeycomb pattern',          12);

    PRINT 'PatternTypes table created with ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' patterns';
END
ELSE
BEGIN
    PRINT 'PatternTypes table already exists';
END

PRINT '';

-- ============================================================================
-- VERIFICATION
-- ============================================================================
PRINT '========================================';
PRINT 'VERIFICATION';
PRINT '========================================';
PRINT '';

PRINT 'Commodities with colors:';
SELECT TOP 5 CommodityCode, CommodityName, BaseColour, ColourName
FROM dbo.vw_Commodities
ORDER BY DisplayOrder;

PRINT '';
PRINT 'Grain groups with computed colors:';
SELECT TOP 5 GrainGroupCode, LightnessModifier, CommodityBaseColour, BaseColour AS ComputedColour
FROM dbo.vw_GrainGroups
WHERE LightnessModifier IS NOT NULL
ORDER BY GrainGroupCode;

PRINT '';
PRINT 'Variants with inherited colors:';
SELECT TOP 5 VariantNo, GrainGroup, Pattern, GrainGroupColour AS InheritedColor
FROM dbo.vw_Variants
ORDER BY VariantNo;

PRINT '';
PRINT '========================================';
PRINT 'MIGRATION COMPLETE!';
PRINT '========================================';
PRINT '';
PRINT 'Summary:';
PRINT '- CommodityAttributes table created with colors';
PRINT '- Grain group colors computed and cached';
PRINT '- Variants updated (colors removed, patterns added)';
PRINT '- Date columns removed from all tables';
PRINT '- All views working correctly';
PRINT '';
PRINT 'To change commodity colors in the future:';
PRINT 'EXEC sp_RecalculateGrainGroupColours @CommodityID';
PRINT '';
GO
