-- sql/create_graingroups_tables_v2.sql
-- Grain Groups tables: Simplified with both modifier AND computed color

USE SiloOps;
GO

-- ============================================================================
-- Main GrainGroups table (synced from Franklin or managed in SiloOps)
-- ============================================================================
IF OBJECT_ID('dbo.GrainGroups', 'U') IS NOT NULL
    DROP TABLE dbo.GrainGroups;
GO

CREATE TABLE dbo.GrainGroups (
    GrainGroupID    INT IDENTITY(1,1) PRIMARY KEY,
    GrainGroupCode  NVARCHAR(50) NOT NULL UNIQUE,  -- e.g., 'GP1M', 'OSR', 'FDBLY'
    GrainGroupName  NVARCHAR(200) NOT NULL,         -- e.g., 'Group 1 Milling', 'Oilseed Rape'
    CommodityID     INT NOT NULL,                   -- Parent commodity
    IsActive        BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_GrainGroups_Commodity
        FOREIGN KEY (CommodityID) REFERENCES dbo.Commodities(CommodityID)
);
GO

-- ============================================================================
-- Grain Group Attributes table
-- Stores BOTH the relative modifier AND the computed color (cached)
-- ============================================================================
IF OBJECT_ID('dbo.GrainGroupAttributes', 'U') IS NOT NULL
    DROP TABLE dbo.GrainGroupAttributes;
GO

CREATE TABLE dbo.GrainGroupAttributes (
    GrainGroupID        INT PRIMARY KEY,

    -- Relative color modifier (how this grain group relates to commodity color)
    LightnessModifier   DECIMAL(4,2) DEFAULT 1.0,  -- 0.5 to 1.5 range (0.8=darker, 1.2=lighter)

    -- Computed/cached color (recalculated when commodity color changes)
    ComputedColour      NVARCHAR(7),                -- Cached result, e.g., '#C89F10'
    ColourName          NVARCHAR(50),               -- Human-readable name, e.g., 'Dark Golden'

    DisplayOrder        INT,
    Notes               NVARCHAR(MAX),

    CONSTRAINT FK_GrainGroupAttributes_GrainGroup
        FOREIGN KEY (GrainGroupID) REFERENCES dbo.GrainGroups(GrainGroupID)
        ON DELETE CASCADE
);
GO

-- ============================================================================
-- Function to compute grain group color from commodity color + lightness modifier
-- ============================================================================

IF OBJECT_ID('dbo.fn_ComputeGrainGroupColour', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_ComputeGrainGroupColour;
GO

CREATE FUNCTION dbo.fn_ComputeGrainGroupColour
(
    @CommodityColourHex NVARCHAR(7),        -- e.g., '#DAA520'
    @LightnessModifier DECIMAL(4,2)         -- e.g., 1.2 for 20% lighter
)
RETURNS NVARCHAR(7)
AS
BEGIN
    DECLARE @R INT, @G INT, @B INT;
    DECLARE @NewR INT, @NewG INT, @NewB INT;
    DECLARE @Hex NVARCHAR(7);

    -- Remove # if present
    SET @CommodityColourHex = REPLACE(@CommodityColourHex, '#', '');

    -- Parse RGB from hex
    SET @R = CONVERT(INT, CONVERT(VARBINARY(1), SUBSTRING(@CommodityColourHex, 1, 2), 2));
    SET @G = CONVERT(INT, CONVERT(VARBINARY(1), SUBSTRING(@CommodityColourHex, 3, 2), 2));
    SET @B = CONVERT(INT, CONVERT(VARBINARY(1), SUBSTRING(@CommodityColourHex, 5, 2), 2));

    -- Apply lightness modifier
    -- If > 1.0: lighten (move towards white)
    -- If < 1.0: darken (scale down)
    SET @NewR = CASE
        WHEN @LightnessModifier > 1.0
        THEN @R + (255 - @R) * (@LightnessModifier - 1.0)
        ELSE @R * @LightnessModifier
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
-- View - uses cached ComputedColour (no recalculation on every read)
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

    -- Color attributes
    gga.LightnessModifier,
    gga.ColourName,
    gga.DisplayOrder,
    gga.Notes,

    -- Parent commodity color
    ca.BaseColour AS CommodityBaseColour,
    ca.ColourName AS CommodityColourName,

    -- Use cached computed color (no calculation needed!)
    -- Fallback to commodity color if no modifier exists
    COALESCE(gga.ComputedColour, ca.BaseColour) AS BaseColour,

    CASE WHEN gga.GrainGroupID IS NULL THEN 1 ELSE 0 END AS MissingColour

FROM dbo.GrainGroups gg
INNER JOIN dbo.Commodities c ON gg.CommodityID = c.CommodityID
LEFT JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID
LEFT JOIN dbo.GrainGroupAttributes gga ON gg.GrainGroupID = gga.GrainGroupID;
GO

-- ============================================================================
-- Stored procedure to recalculate grain group colors
-- Call this after changing a commodity color
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
            ISNULL(gga.LightnessModifier, 1.0)
        )
    FROM dbo.GrainGroupAttributes gga
    INNER JOIN dbo.GrainGroups gg ON gga.GrainGroupID = gg.GrainGroupID
    INNER JOIN dbo.Commodities c ON gg.CommodityID = c.CommodityID
    INNER JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID
    WHERE (@CommodityID IS NULL OR gg.CommodityID = @CommodityID)
      AND ca.BaseColour IS NOT NULL;

    DECLARE @RowCount INT = @@ROWCOUNT;
    PRINT 'Grain group colors recalculated: ' + CAST(@RowCount AS VARCHAR(10)) + ' records updated';

    RETURN @RowCount;
END;
GO

PRINT 'GrainGroups tables created successfully';
PRINT 'Colors are cached - call sp_RecalculateGrainGroupColours after changing commodity colors';
GO
