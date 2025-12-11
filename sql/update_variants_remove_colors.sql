-- sql/update_variants_remove_colors.sql
-- Remove color fields from VariantAttributes - variants only use patterns
-- Variants inherit color from their parent grain group

USE SiloOps;
GO

-- ============================================================================
-- Drop color columns from VariantAttributes
-- Variants will use Pattern only, color comes from grain group
-- ============================================================================

-- Check if BaseColour column exists and drop it
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.VariantAttributes')
           AND name = 'BaseColour')
BEGIN
    ALTER TABLE dbo.VariantAttributes
    DROP COLUMN BaseColour;

    PRINT 'BaseColour column dropped from VariantAttributes';
END
ELSE
BEGIN
    PRINT 'BaseColour column does not exist in VariantAttributes';
END
GO

-- Check if DefaultColour column exists and drop it
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.VariantAttributes')
           AND name = 'DefaultColour')
BEGIN
    ALTER TABLE dbo.VariantAttributes
    DROP COLUMN DefaultColour;

    PRINT 'DefaultColour column dropped from VariantAttributes';
END
ELSE
BEGIN
    PRINT 'DefaultColour column does not exist in VariantAttributes';
END
GO

-- Add Pattern column if it doesn't exist
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.VariantAttributes')
               AND name = 'Pattern')
BEGIN
    ALTER TABLE dbo.VariantAttributes
    ADD Pattern NVARCHAR(50) NULL;  -- e.g., 'solid', 'striped', 'dotted', 'checkered'

    PRINT 'Pattern column added to VariantAttributes';
END
ELSE
BEGIN
    PRINT 'Pattern column already exists in VariantAttributes';
END
GO

-- ============================================================================
-- Update the vw_Variants view to show grain group color instead
-- ============================================================================

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

    -- Variant attributes (pattern only, no color)
    va.Pattern,
    va.Notes,

    -- Get color from parent grain group (via view which computes it)
    gg.BaseColour AS GrainGroupColour,
    gg.ColourName AS GrainGroupColourName,
    gg.CommodityBaseColour,

    -- Use grain group color as the variant color
    gg.BaseColour AS EffectiveColour,

    -- Flag for variants missing pattern
    CASE WHEN va.Pattern IS NULL OR va.Pattern = '' THEN 1 ELSE 0 END AS MissingPattern,

    -- Keep the BaseColour flag for backwards compatibility (always 0 now since we don't store it)
    0 AS MissingBaseColour

FROM dbo.Variants v
LEFT JOIN dbo.VariantAttributes va ON v.VariantID = va.VariantID
LEFT JOIN dbo.vw_GrainGroups gg ON v.GrainGroup = gg.GrainGroupCode;
GO

-- ============================================================================
-- Update stored procedure for variant attributes
-- ============================================================================

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
        Notes = ISNULL(@Notes, Notes),
        ModifiedDate = GETDATE()
    WHERE VariantID = @VariantID;

    -- If no attributes record exists, create one
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO dbo.VariantAttributes (
            VariantID, Pattern, Notes, CreatedDate, ModifiedDate
        )
        VALUES (
            @VariantID, @Pattern, @Notes, GETDATE(), GETDATE()
        );
    END
END
GO

-- ============================================================================
-- Pattern types reference table (optional - for UI dropdowns)
-- ============================================================================

IF OBJECT_ID('dbo.PatternTypes', 'U') IS NOT NULL
    DROP TABLE dbo.PatternTypes;
GO

CREATE TABLE dbo.PatternTypes (
    PatternID       INT IDENTITY(1,1) PRIMARY KEY,
    PatternCode     NVARCHAR(50) NOT NULL UNIQUE,
    PatternName     NVARCHAR(100) NOT NULL,
    Description     NVARCHAR(500),
    DisplayOrder    INT,
    IsActive        BIT NOT NULL DEFAULT 1
);
GO

-- Insert standard pattern types
INSERT INTO dbo.PatternTypes (PatternCode, PatternName, Description, DisplayOrder) VALUES
('solid',              'Solid',                 'No pattern - solid fill',                          1),
('striped',            'Striped (Horizontal)',  'Horizontal stripes',                               2),
('v-striped',          'Striped (Vertical)',    'Vertical stripes',                                 3),
('diagonal',           'Striped (Diagonal)',    'Diagonal lines (45deg)',                           4),
('crosshatch',         'Crosshatch',            'Crossed diagonal lines',                           5),
('checkered',          'Checkered',             'Checkered/grid pattern',                           6),
('grid',               'Grid',                  'Even grid lines',                                  7),
('brick',              'Brick',                 'Brick-like offset pattern',                        8),
('plaid',              'Plaid',                 'Multi-directional stripes (tartan/plaid)',         9),
('chevron',            'Chevron',               'Chevron or V-shaped stripes',                      10),
('herringbone',        'Herringbone',           'V-shaped weaving pattern',                         11),
('zigzag',             'Zigzag',                'Zigzag pattern',                                   12),
('wavy',               'Wavy',                  'Wavy/undulating lines',                            13),
('dotted',             'Dotted (Fine)',         'Small dots/stippling',                             14),
('dotted-bold',        'Dotted (Bold)',         'Larger spaced dots',                               15),
('speckle',            'Speckle',               'Random speckled dots',                             16),
('honeycomb',          'Honeycomb',             'Hexagonal honeycomb pattern',                      17),
('triangle',           'Triangles',             'Repeating triangle tessellation',                  18),
('diamond',            'Diamonds',              'Diamond shapes pattern',                           19),
('circle',             'Circles',               'Repeating circles',                                20),
('square',             'Squares',               'Repeating squares',                                21),
('dash',               'Dashed',                'Short dashes',                                     22),
('dash-dot',           'Dash-Dot',              'Dash-dot sequence',                                23),
('weave',              'Weave',                 'Over-under weave texture',                         24);
GO

PRINT 'Variants updated - colors removed, patterns only';
PRINT 'Variants now inherit color from their parent grain group';
GO
