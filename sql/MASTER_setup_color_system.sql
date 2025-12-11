-- sql/MASTER_setup_color_system.sql
-- Master script to set up the complete color coding system
-- Run this script to create all tables and populate initial data

USE SiloOps;
GO

PRINT '========================================';
PRINT 'MASTER SETUP: Color Coding System';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- STEP 1: Create SyncLog table
-- ============================================================================
PRINT 'STEP 1: Creating SyncLog table...';

IF OBJECT_ID('dbo.SyncLog', 'U') IS NOT NULL
    DROP TABLE dbo.SyncLog;

CREATE TABLE dbo.SyncLog (
    SyncID              INT IDENTITY(1,1) PRIMARY KEY,
    EntityType          NVARCHAR(50) NOT NULL,
    SyncStartTime       DATETIME2 NOT NULL,
    SyncEndTime         DATETIME2,
    RecordsProcessed    INT,
    RecordsAdded        INT,
    RecordsUpdated      INT,
    RecordsDeactivated  INT,
    Status              NVARCHAR(20) NOT NULL,
    ErrorMessage        NVARCHAR(MAX),
    SyncedBy            NVARCHAR(100)
);

CREATE NONCLUSTERED INDEX IX_SyncLog_EntityType_SyncStartTime
ON dbo.SyncLog (EntityType, SyncStartTime DESC);

PRINT 'SyncLog table created';
PRINT '';

-- ============================================================================
-- STEP 2: Create Commodities tables
-- ============================================================================
PRINT 'STEP 2: Creating Commodities tables...';

IF OBJECT_ID('dbo.CommodityAttributes', 'U') IS NOT NULL
    DROP TABLE dbo.CommodityAttributes;
IF OBJECT_ID('dbo.Commodities', 'U') IS NOT NULL
    DROP TABLE dbo.Commodities;

CREATE TABLE dbo.Commodities (
    CommodityID     INT IDENTITY(1,1) PRIMARY KEY,
    CommodityCode   NVARCHAR(50) NOT NULL UNIQUE,
    CommodityName   NVARCHAR(200) NOT NULL,
    IsActive        BIT NOT NULL DEFAULT 1
);

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

PRINT 'Commodities tables created';

-- Populate commodities
INSERT INTO dbo.Commodities (CommodityCode, CommodityName, IsActive) VALUES
('WHT',    'Wheat',                          1),
('OSR',    'Oilseed Rape',                   1),
('MBLY',   'Malting Barley',                 1),
('FBLY',   'Feed Barley',                    1),
('PEAS',   'Peas',                           1),
('BNS',    'Beans',                          1),
('OATS',   'Oats',                           1),
('LIN',    'Linseed',                        1),
('RYE',    'Rye',                            1),
('TRI',    'Triticale',                      1),
('MILL',   'Millet',                         1),
('ICWHT',  'In-Country Wheat',               1),
('ICMBLY', 'In-Country Malting Barley',      1),
('ICFBLY', 'In-Country Feed Barley',         1),
('ICPEAS', 'In-Country Peas',                1),
('ICBNS',  'In-Country Beans',               1),
('ICOATS', 'In-Country Oats',                1),
('OGWHT',  'Organic Wheat',                  1),
('OGMBLY', 'Organic Malting Barley',         1),
('OGFBLY', 'Organic Feed Barley',            1),
('OGPEAS', 'Organic Peas',                   1),
('OGBNS',  'Organic Beans',                  1),
('OGOATS', 'Organic Oats',                   1),
('OGRYE',  'Organic Rye',                    1),
('OGTRI',  'Organic Triticale',              1),
('WARB',   'Warburtons',                     1),
('IMP',    'Import',                         1);

PRINT 'Commodities populated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';

-- Populate commodity colors
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
PRINT '';

-- ============================================================================
-- STEP 3: Create GrainGroups tables with color computation function
-- ============================================================================
PRINT 'STEP 3: Creating GrainGroups tables...';

IF OBJECT_ID('dbo.GrainGroupAttributes', 'U') IS NOT NULL
    DROP TABLE dbo.GrainGroupAttributes;
IF OBJECT_ID('dbo.GrainGroups', 'U') IS NOT NULL
    DROP TABLE dbo.GrainGroups;

CREATE TABLE dbo.GrainGroups (
    GrainGroupID    INT IDENTITY(1,1) PRIMARY KEY,
    GrainGroupCode  NVARCHAR(50) NOT NULL UNIQUE,
    GrainGroupName  NVARCHAR(200) NOT NULL,
    CommodityID     INT NOT NULL,
    IsActive        BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_GrainGroups_Commodity
        FOREIGN KEY (CommodityID) REFERENCES dbo.Commodities(CommodityID)
);

CREATE TABLE dbo.GrainGroupAttributes (
    GrainGroupID        INT PRIMARY KEY,
    LightnessModifier   DECIMAL(4,2) DEFAULT 1.0,
    ComputedColour      NVARCHAR(7),
    ColourName          NVARCHAR(50),
    DisplayOrder        INT,
    Notes               NVARCHAR(MAX),
    CONSTRAINT FK_GrainGroupAttributes_GrainGroup
        FOREIGN KEY (GrainGroupID) REFERENCES dbo.GrainGroups(GrainGroupID)
        ON DELETE CASCADE
);

PRINT 'GrainGroups tables created';
PRINT '';

-- Create color computation function
PRINT 'Creating color computation function...';

IF OBJECT_ID('dbo.fn_ComputeGrainGroupColour', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_ComputeGrainGroupColour;
GO

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

    SET @CommodityColourHex = REPLACE(@CommodityColourHex, '#', '');

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

    RETURN UPPER('#' +
        RIGHT('0' + CONVERT(VARCHAR(2), CONVERT(VARBINARY(1), @NewR), 2), 2) +
        RIGHT('0' + CONVERT(VARCHAR(2), CONVERT(VARBINARY(1), @NewG), 2), 2) +
        RIGHT('0' + CONVERT(VARCHAR(2), CONVERT(VARBINARY(1), @NewB), 2), 2));
END;
GO

PRINT 'Color computation function created';
PRINT '';

-- ============================================================================
-- STEP 4: Populate GrainGroups (sample - you'll need to run full script)
-- ============================================================================
PRINT 'STEP 4: Populating GrainGroups (showing sample, run full populate script for all)...';

-- Helper variables
DECLARE @WHT INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'WHT');
DECLARE @OSR INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OSR');
DECLARE @MBLY INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'MBLY');
DECLARE @FBLY INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'FBLY');

-- Sample grain groups (wheat and OSR for demo)
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('GP1M',    'Group 1 Milling',     @WHT),
('GP2M',    'Group 2 Milling',     @WHT),
('GP3S',    'Group 3 Soft',        @WHT),
('GP4H',    'Group 4 Hard',        @WHT),
('GP4S',    'Group 4 Soft',        @WHT),
('FDWHT',   'Feed Wheat',          @WHT),
('OSR',     'Standard OSR',        @OSR),
('HEAR',    'High Erucic Acid',    @OSR),
('FDBLY',   'Feed Barley',         @FBLY);

PRINT 'Sample grain groups populated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';
PRINT '(Run create_graingroups_tables.sql for complete population)';
PRINT '';

-- ============================================================================
-- STEP 5: Populate GrainGroup lightness modifiers and compute colors
-- ============================================================================
PRINT 'STEP 5: Setting lightness modifiers and computing colors...';

-- Wheat grain groups
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('GP1M',    1.15,   'Bright Golden',    1),
    ('GP2M',    1.08,   'Light Golden',     2),
    ('GP3S',    1.00,   'Base Golden',      3),
    ('GP4H',    0.92,   'Medium Golden',    4),
    ('GP4S',    0.85,   'Dark Golden',      5),
    ('FDWHT',   1.22,   'Pale Golden',      6)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- OSR grain groups
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('OSR',     1.00,   'Base Yellow',      1),
    ('HEAR',    1.10,   'Light Yellow',     2)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Feed Barley
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, 1.05, 'Light Brown', 1
FROM dbo.GrainGroups gg WHERE gg.GrainGroupCode = 'FDBLY';

PRINT 'Lightness modifiers set: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';

-- Compute initial colors
UPDATE gga
SET ComputedColour = dbo.fn_ComputeGrainGroupColour(ca.BaseColour, gga.LightnessModifier)
FROM dbo.GrainGroupAttributes gga
INNER JOIN dbo.GrainGroups gg ON gga.GrainGroupID = gg.GrainGroupID
INNER JOIN dbo.Commodities c ON gg.CommodityID = c.CommodityID
INNER JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID;

PRINT 'Colors computed: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records';
PRINT '';

-- ============================================================================
-- STEP 6: Update Variants table structure (remove colors, keep patterns)
-- ============================================================================
PRINT 'STEP 6: Updating Variants table structure...';

-- Add Pattern column FIRST (before dropping other columns)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'Pattern')
BEGIN
    ALTER TABLE dbo.VariantAttributes ADD Pattern NVARCHAR(50) NULL;
    PRINT 'Pattern column added to VariantAttributes';
END
ELSE
BEGIN
    PRINT 'Pattern column already exists';
END

-- Drop BaseColour column if it exists
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'BaseColour')
BEGIN
    ALTER TABLE dbo.VariantAttributes DROP COLUMN BaseColour;
    PRINT 'BaseColour column dropped from VariantAttributes';
END

-- Drop DefaultColour column (must drop default constraint first)
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
        EXEC('ALTER TABLE dbo.VariantAttributes DROP CONSTRAINT ' + @ConstraintName);
        PRINT 'Default constraint dropped: ' + @ConstraintName;
    END

    -- Now drop the column
    ALTER TABLE dbo.VariantAttributes DROP COLUMN DefaultColour;
    PRINT 'DefaultColour column dropped from VariantAttributes';
END

-- Remove date columns from Variants if they exist
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Variants') AND name = 'LastSyncDate')
BEGIN
    ALTER TABLE dbo.Variants DROP COLUMN LastSyncDate;
    PRINT 'LastSyncDate column dropped from Variants';
END

-- Remove date columns from VariantAttributes if they exist
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'CreatedDate')
BEGIN
    ALTER TABLE dbo.VariantAttributes DROP COLUMN CreatedDate;
    PRINT 'CreatedDate column dropped from VariantAttributes';
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.VariantAttributes') AND name = 'ModifiedDate')
BEGIN
    ALTER TABLE dbo.VariantAttributes DROP COLUMN ModifiedDate;
    PRINT 'ModifiedDate column dropped from VariantAttributes';
END

PRINT '';

-- ============================================================================
-- STEP 7: Create views and procedures
-- ============================================================================
PRINT 'STEP 7: Creating views and procedures...';

-- Commodities view
IF OBJECT_ID('dbo.vw_Commodities', 'V') IS NOT NULL DROP VIEW dbo.vw_Commodities;
GO
CREATE VIEW dbo.vw_Commodities AS
SELECT c.CommodityID, c.CommodityCode, c.CommodityName, c.IsActive,
       ca.BaseColour, ca.ColourName, ca.DisplayOrder, ca.Notes,
       CASE WHEN ca.BaseColour IS NULL OR ca.BaseColour = '' THEN 1 ELSE 0 END AS MissingColour
FROM dbo.Commodities c
LEFT JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID;
GO

-- GrainGroups view
IF OBJECT_ID('dbo.vw_GrainGroups', 'V') IS NOT NULL DROP VIEW dbo.vw_GrainGroups;
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

-- Variants view
IF OBJECT_ID('dbo.vw_Variants', 'V') IS NOT NULL DROP VIEW dbo.vw_Variants;
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

-- Recalculate procedure
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

PRINT 'Views and procedures created';
PRINT '';

-- ============================================================================
-- COMPLETION
-- ============================================================================
PRINT '========================================';
PRINT 'SETUP COMPLETE!';
PRINT '========================================';
PRINT '';
PRINT 'Summary:';
PRINT '- Commodities: 27 commodities with colors';
PRINT '- GrainGroups: Sample populated (run full script for complete set)';
PRINT '- Variants: Structure updated (colors removed, patterns added)';
PRINT '- SyncLog: Created for tracking sync operations';
PRINT '';
PRINT 'Next steps:';
PRINT '1. Run create_graingroups_tables.sql for complete grain group population';
PRINT '2. Verify data: SELECT * FROM vw_Commodities';
PRINT '3. Verify colors: SELECT * FROM vw_GrainGroups';
PRINT '4. When changing commodity colors, run: EXEC sp_RecalculateGrainGroupColours';
PRINT '';
GO
