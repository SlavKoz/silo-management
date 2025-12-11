-- sql/update_variants_add_patterns.sql
-- Add pattern/texture field to VariantAttributes for visual differentiation

USE SiloOps;
GO

-- ============================================================================
-- Add Pattern field to VariantAttributes
-- Patterns provide visual differentiation for variants within a grain group
-- ============================================================================

-- Add Pattern column if it doesn't exist
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.VariantAttributes')
               AND name = 'Pattern')
BEGIN
    ALTER TABLE dbo.VariantAttributes
    ADD Pattern NVARCHAR(50) NULL;  -- e.g., 'solid', 'striped', 'dotted', 'checkered', 'diagonal'

    PRINT 'Pattern column added to VariantAttributes';
END
ELSE
BEGIN
    PRINT 'Pattern column already exists in VariantAttributes';
END
GO

-- ============================================================================
-- Update the view to include Pattern
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
    v.LastSyncDate,
    va.BaseColour,
    va.DefaultColour,
    va.Pattern,
    va.Notes,
    -- Compute effective colour: BaseColour if set, otherwise DefaultColour, otherwise NULL
    COALESCE(va.BaseColour, va.DefaultColour) AS EffectiveColour,
    -- Flag for variants missing BaseColour
    CASE WHEN va.BaseColour IS NULL OR va.BaseColour = '' THEN 1 ELSE 0 END AS MissingBaseColour
FROM dbo.Variants v
LEFT JOIN dbo.VariantAttributes va ON v.VariantID = va.VariantID;
GO

-- ============================================================================
-- Pattern types reference
-- ============================================================================
-- Suggested pattern values for variants:
-- - 'solid'      : No pattern (default)
-- - 'striped'    : Horizontal stripes
-- - 'dotted'     : Dotted/stippled
-- - 'checkered'  : Checkered/grid pattern
-- - 'diagonal'   : Diagonal lines
-- - 'crosshatch' : Cross-hatched
-- - 'wavy'       : Wavy lines
-- - 'zigzag'     : Zigzag pattern

-- ============================================================================
-- Update variant attributes update procedure
-- ============================================================================
IF OBJECT_ID('dbo.sp_UpdateVariantAttributes', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateVariantAttributes;
GO

CREATE PROCEDURE dbo.sp_UpdateVariantAttributes
    @VariantID      INT,
    @BaseColour     NVARCHAR(7)  = NULL,
    @DefaultColour  NVARCHAR(7)  = NULL,
    @Pattern        NVARCHAR(50) = NULL,
    @Notes          NVARCHAR(MAX) = NULL
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
        BaseColour = ISNULL(@BaseColour, BaseColour),
        DefaultColour = ISNULL(@DefaultColour, DefaultColour),
        Pattern = ISNULL(@Pattern, Pattern),
        Notes = ISNULL(@Notes, Notes),
        ModifiedDate = GETDATE()
    WHERE VariantID = @VariantID;

    -- If no attributes record exists, it should have been created by the sync proc
    -- But handle it gracefully
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO dbo.VariantAttributes (
            VariantID, BaseColour, DefaultColour, Pattern, Notes, CreatedDate, ModifiedDate
        )
        VALUES (
            @VariantID, @BaseColour, @DefaultColour, @Pattern, @Notes, GETDATE(), GETDATE()
        );
    END
END
GO

PRINT 'Variants table updated with pattern support';
GO
