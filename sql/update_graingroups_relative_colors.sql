-- sql/update_graingroups_relative_colors.sql
-- Update GrainGroupAttributes to use relative color modifiers instead of absolute colors
-- This allows grain group colors to automatically adjust when commodity colors change

USE SiloOps;
GO

-- ============================================================================
-- Drop existing GrainGroupAttributes and recreate with relative color system
-- ============================================================================

IF OBJECT_ID('dbo.GrainGroupAttributes', 'U') IS NOT NULL
    DROP TABLE dbo.GrainGroupAttributes;
GO

CREATE TABLE dbo.GrainGroupAttributes (
    GrainGroupID        INT PRIMARY KEY,

    -- Relative color modifiers (grain group color = commodity color adjusted by these)
    LightnessModifier   DECIMAL(4,2) DEFAULT 1.0,  -- 0.5 to 1.5 range (0.8=darker, 1.2=lighter)
    SaturationModifier  DECIMAL(4,2) DEFAULT 1.0,  -- 0.5 to 1.5 range (lower=more gray)
    HueShift            INT DEFAULT 0,              -- -30 to +30 degrees (usually 0)

    -- Computed color (calculated from commodity + modifiers, can be cached)
    ComputedColour      NVARCHAR(7),                -- Cached result, recalculated when commodity changes
    ColourName          NVARCHAR(50),               -- Human-readable name

    DisplayOrder        INT,
    Notes               NVARCHAR(MAX),
    CreatedDate         DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate        DATETIME2,

    CONSTRAINT FK_GrainGroupAttributes_GrainGroup
        FOREIGN KEY (GrainGroupID) REFERENCES dbo.GrainGroups(GrainGroupID)
        ON DELETE CASCADE
);
GO

-- ============================================================================
-- Create function to compute grain group color from commodity color + modifiers
-- Converts hex -> RGB -> HSL -> adjust -> RGB -> hex
-- ============================================================================

IF OBJECT_ID('dbo.fn_ComputeGrainGroupColour', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_ComputeGrainGroupColour;
GO

CREATE FUNCTION dbo.fn_ComputeGrainGroupColour
(
    @CommodityColourHex NVARCHAR(7),        -- e.g., '#DAA520'
    @LightnessModifier DECIMAL(4,2),        -- e.g., 1.2 for 20% lighter
    @SaturationModifier DECIMAL(4,2),       -- e.g., 0.9 for 10% less saturated
    @HueShift INT                           -- e.g., 0 for no shift
)
RETURNS NVARCHAR(7)
AS
BEGIN
    -- For simplicity, we'll use a basic RGB lightness adjustment
    -- More sophisticated HSL conversion can be added later if needed

    DECLARE @R INT, @G INT, @B INT;
    DECLARE @NewR INT, @NewG INT, @NewB INT;
    DECLARE @Hex NVARCHAR(7);

    -- Remove # if present
    SET @CommodityColourHex = REPLACE(@CommodityColourHex, '#', '');

    -- Parse RGB from hex
    SET @R = CONVERT(INT, CONVERT(VARBINARY(1), SUBSTRING(@CommodityColourHex, 1, 2), 2));
    SET @G = CONVERT(INT, CONVERT(VARBINARY(1), SUBSTRING(@CommodityColourHex, 3, 2), 2));
    SET @B = CONVERT(INT, CONVERT(VARBINARY(1), SUBSTRING(@CommodityColourHex, 5, 2), 2));

    -- Apply lightness modifier (simple linear adjustment)
    -- For more accurate results, should convert to HSL, adjust L, convert back
    -- But this approximation works reasonably well
    SET @NewR = CASE
        WHEN @LightnessModifier > 1.0
        THEN @R + (255 - @R) * (@LightnessModifier - 1.0)  -- Lighten: move towards white
        ELSE @R * @LightnessModifier                        -- Darken: scale down
    END;

    SET @NewG = CASE
        WHEN @LightnessModifier > 1.0
        THEN @G + (255 - @G) * (@LightnessModifier - 1.0)
        ELSE @G * @LightnessModifier
    END;

    SET @NewB = CASE
        WHEN @LightnessModifier > 1.0
        THEN @B + (255 - @B) * (@LightnessModifier - 1.0)
        ELSE @B * @LightnessModifier
    END;

    -- Clamp to 0-255 range
    SET @NewR = CASE WHEN @NewR < 0 THEN 0 WHEN @NewR > 255 THEN 255 ELSE @NewR END;
    SET @NewG = CASE WHEN @NewG < 0 THEN 0 WHEN @NewG > 255 THEN 255 ELSE @NewG END;
    SET @NewB = CASE WHEN @NewB < 0 THEN 0 WHEN @NewB > 255 THEN 255 ELSE @NewB END;

    -- Convert back to hex
    SET @Hex = '#' +
        RIGHT('0' + CONVERT(VARCHAR(2), CONVERT(VARBINARY(1), @NewR), 2), 2) +
        RIGHT('0' + CONVERT(VARCHAR(2), CONVERT(VARBINARY(1), @NewG), 2), 2) +
        RIGHT('0' + CONVERT(VARCHAR(2), CONVERT(VARBINARY(1), @NewB), 2), 2);

    RETURN UPPER(@Hex);
END;
GO

-- ============================================================================
-- Update view to compute colors on the fly
-- ============================================================================

IF OBJECT_ID('dbo.vw_GrainGroups', 'V') IS NOT NULL
    DROP VIEW dbo.vw_GrainGroups;
GO

CREATE VIEW dbo.vw_GrainGroups
AS
SELECT
    gg.GrainGroupID,
    gg.GrainGroupCode,
    gg.GrainGroupName,
    gg.CommodityID,
    c.CommodityCode,
    c.CommodityName,
    gg.IsActive,
    gg.LastSyncDate,
    gg.CreatedDate AS GrainGroupCreatedDate,
    gg.ModifiedDate AS GrainGroupModifiedDate,

    -- Color attributes
    gga.LightnessModifier,
    gga.SaturationModifier,
    gga.HueShift,
    gga.ColourName,
    gga.DisplayOrder,
    gga.Notes,

    -- Parent commodity color
    ca.BaseColour AS CommodityBaseColour,
    ca.ColourName AS CommodityColourName,

    -- Computed grain group color (use cached or compute on the fly)
    COALESCE(
        gga.ComputedColour,
        dbo.fn_ComputeGrainGroupColour(
            ca.BaseColour,
            ISNULL(gga.LightnessModifier, 1.0),
            ISNULL(gga.SaturationModifier, 1.0),
            ISNULL(gga.HueShift, 0)
        ),
        ca.BaseColour  -- Fallback to commodity color if no modifiers
    ) AS BaseColour,

    CASE WHEN gga.GrainGroupID IS NULL THEN 1 ELSE 0 END AS MissingColour

FROM dbo.GrainGroups gg
INNER JOIN dbo.Commodities c ON gg.CommodityID = c.CommodityID
LEFT JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID
LEFT JOIN dbo.GrainGroupAttributes gga ON gg.GrainGroupID = gga.GrainGroupID;
GO

-- ============================================================================
-- Populate relative color modifiers for grain groups
-- Each grain group gets modifiers relative to its commodity base color
-- ============================================================================

-- Wheat grain groups - Range from lighter (1.3) to darker (0.7)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('GP1M',    1.15,   'Bright Golden',    1),
    ('GP2M',    1.08,   'Light Golden',     2),
    ('GP3S',    1.00,   'Base Golden',      3),
    ('GP4H',    0.92,   'Medium Golden',    4),
    ('GP4S',    0.85,   'Dark Golden',      5),
    ('FDWHT',   1.22,   'Pale Golden',      6),
    ('WW',      0.95,   'Winter Wheat',     7),
    ('IMP',     0.88,   'Import',           8),
    ('WARB',    1.00,   'Warburtons',       9)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- OSR grain groups - Subtle variations
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('OSR',     1.00,   'Base Yellow',      1),
    ('HEAR',    1.10,   'Light Yellow',     2),
    ('HOLL',    1.05,   'Bright Yellow',    3)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Malting Barley - Spread from light to dark brown
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('CONCERTO',        1.12,   'Light Brown',      1),
    ('PLANET',          1.00,   'Base Brown',       2),
    ('LAUREATE',        1.08,   'Tan',              3),
    ('PROPINO',         0.82,   'Dark Brown',       4),
    ('ODYSSEY',         0.98,   'Medium Brown',     5),
    ('CRAFT',           1.15,   'Pale Brown',       6),
    ('DIABLO',          0.75,   'Chocolate',        7),
    ('QUENCH',          0.95,   'Medium-Dark',      8),
    ('VENTURE',         1.05,   'Light-Medium',     9),
    ('TALISMAN',        0.92,   'Walnut',           10),
    ('WESTMINSTER (BLY)', 1.18, 'Camel',           11)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Feed Barley - Slightly lighter than malting
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, 1.05, 'Light Brown', 1
FROM dbo.GrainGroups gg WHERE gg.GrainGroupCode = 'FDBLY';

-- Peas - Light and dark green
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('FDPEAS',      1.00,   'Lime Green',       1),
    ('PEAS - HC',   1.15,   'Bright Green',     2)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Beans - Dark green variations
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('FDBNS',       1.00,   'Base Green',       1),
    ('SPBNS',       1.10,   'Spring Green',     2),
    ('WINBNS',      0.85,   'Dark Green',       3)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Oats - Cream variations
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('MILLINGOATS', 1.00,   'Wheat',            1),
    ('MASCANI',     1.08,   'Light Cream',      2),
    ('SPRINGOATS',  1.12,   'Pale Cream',       3)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Single-group commodities - Use base color
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, 1.0, 'Base', 1
FROM dbo.GrainGroups gg
WHERE gg.GrainGroupCode IN ('LIN', 'RYE', 'TRI', 'MILLET');

-- In-Country Wheat - Lighter variations (already lighter base commodity)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('ICGP4H',      1.00,   'IC Base',          1),
    ('IC GP1M',     1.12,   'IC Light',         2),
    ('ICGP2M',      1.08,   'IC Medium-Light',  3),
    ('ICGP4S',      0.95,   'IC Medium',        4),
    ('ICFDWHT',     1.15,   'IC Pale',          5)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- In-Country other commodities
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('IC OATS',             1.00,   'IC Oats',      1),
    ('IC FDBLY',            1.00,   'IC Feed Bly',  2),
    ('IC LAUREATE',         1.05,   'IC Laureate',  3),
    ('IC PLANET',           1.00,   'IC Planet',    4),
    ('IC PEAS - HC',        1.00,   'IC Peas',      5),
    ('IC WESTMINSTER (BLY)',1.00,   'IC Westminster', 6),
    ('ICFDBNS',             1.00,   'IC Beans',     7)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Organic Wheat - Use base (commodity already has muted color)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, LightnessModifier, ColourName, DisplayOrder
FROM (VALUES
    ('OG GP1M',     1.08,   'OG Bright',        1),
    ('OG GP2M',     1.04,   'OG Light',         2),
    ('OG GP3S',     1.00,   'OG Base',          3),
    ('OG GP4H',     0.96,   'OG Medium',        4),
    ('OG GP4S',     0.92,   'OG Dark',          5),
    ('OG FDWHT',    1.12,   'OG Pale',          6)
) AS Source(GrainGroupCode, LightnessModifier, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Organic other commodities - Use base color (commodity handles the earthiness)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, 1.0, 'OG Base', ROW_NUMBER() OVER (ORDER BY gg.GrainGroupCode)
FROM dbo.GrainGroups gg
WHERE gg.GrainGroupCode LIKE 'OG %'
  AND NOT EXISTS (SELECT 1 FROM dbo.GrainGroupAttributes gga WHERE gga.GrainGroupID = gg.GrainGroupID);

-- For any remaining grain groups, use parent commodity color (modifier = 1.0)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, LightnessModifier, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, 1.0, 'Default', 999
FROM dbo.GrainGroups gg
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.GrainGroupAttributes gga
    WHERE gga.GrainGroupID = gg.GrainGroupID
);

GO

-- ============================================================================
-- Stored procedure to recalculate all grain group colors
-- Run this whenever a commodity color is changed
-- ============================================================================

IF OBJECT_ID('dbo.sp_RecalculateGrainGroupColours', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecalculateGrainGroupColours;
GO

CREATE PROCEDURE dbo.sp_RecalculateGrainGroupColours
    @CommodityID INT = NULL  -- NULL = recalculate all, or specify commodity
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE gga
    SET
        ComputedColour = dbo.fn_ComputeGrainGroupColour(
            ca.BaseColour,
            ISNULL(gga.LightnessModifier, 1.0),
            ISNULL(gga.SaturationModifier, 1.0),
            ISNULL(gga.HueShift, 0)
        ),
        ModifiedDate = GETDATE()
    FROM dbo.GrainGroupAttributes gga
    INNER JOIN dbo.GrainGroups gg ON gga.GrainGroupID = gg.GrainGroupID
    INNER JOIN dbo.Commodities c ON gg.CommodityID = c.CommodityID
    INNER JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID
    WHERE (@CommodityID IS NULL OR gg.CommodityID = @CommodityID)
      AND ca.BaseColour IS NOT NULL;

    PRINT 'Grain group colors recalculated: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' records updated';
END;
GO

-- Initial calculation of all grain group colors
EXEC dbo.sp_RecalculateGrainGroupColours;
GO

PRINT 'Grain groups updated with relative color system';
PRINT 'Commodity colors can now be changed and grain groups will automatically adjust';
PRINT 'Run EXEC dbo.sp_RecalculateGrainGroupColours after changing commodity colors';
GO
