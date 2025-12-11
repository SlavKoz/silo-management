-- sql/populate_graingroup_colors.sql
-- Populate color attributes for grain groups
-- Each grain group gets a shade of its parent commodity's base color

USE SiloOps;
GO

-- ============================================================================
-- Color strategy:
-- - Each grain group within a commodity gets a distinct shade
-- - Shades range from lighter to darker versions of the commodity color
-- - Pattern: Add variations in lightness/saturation
-- ============================================================================

-- Wheat grain groups - Shades of Golden (#DAA520)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    ('GP1M',    '#FFD700', 'Gold',                  1),
    ('GP2M',    '#F0C420', 'Light Golden',          2),
    ('GP3S',    '#DAA520', 'Goldenrod',             3),
    ('GP4H',    '#C89F10', 'Dark Golden',           4),
    ('GP4S',    '#B8860B', 'Dark Goldenrod',        5),
    ('FDWHT',   '#EEDD82', 'Light Goldenrod',       6),
    ('WW',      '#D4AF37', 'Metallic Gold',         7),
    ('IMP',     '#BDB76B', 'Dark Khaki',            8),
    ('WARB',    '#DC143C', 'Crimson',               9)
) AS Source(GrainGroupCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- OSR grain groups - Shades of Yellow (#FFD700)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    ('OSR',     '#FFD700', 'Gold',                  1),
    ('HEAR',    '#FFEC8B', 'Light Yellow',          2),
    ('HOLL',    '#FFE135', 'Bright Yellow',         3)
) AS Source(GrainGroupCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Malting Barley - Shades of Brown (#8B4513)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    ('CONCERTO',        '#A0522D', 'Sienna',        1),
    ('PLANET',          '#8B4513', 'Saddle Brown',  2),
    ('LAUREATE',        '#A0826D', 'Light Brown',   3),
    ('PROPINO',         '#654321', 'Dark Brown',    4),
    ('ODYSSEY',         '#92674A', 'Medium Brown',  5),
    ('CRAFT',           '#B8956A', 'Tan Brown',     6),
    ('DIABLO',          '#7B3F00', 'Chocolate',     7),
    ('QUENCH',          '#9B7653', 'Beaver',        8),
    ('VENTURE',         '#A67B5B', 'Cafe Au Lait',  9),
    ('TALISMAN',        '#8B7355', 'Burlywood Brown', 10),
    ('WESTMINSTER (BLY)', '#C19A6B', 'Camel',       11)
) AS Source(GrainGroupCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Feed Barley - Lighter brown (#CD853F)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, '#CD853F', 'Peru', 1
FROM dbo.GrainGroups gg
WHERE gg.GrainGroupCode = 'FDBLY';

-- Peas - Shades of Green (#32CD32)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    ('FDPEAS',      '#32CD32', 'Lime Green',       1),
    ('PEAS - HC',   '#00FF00', 'Lime',             2)
) AS Source(GrainGroupCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Beans - Shades of Dark Green (#228B22)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    ('FDBNS',       '#228B22', 'Forest Green',     1),
    ('SPBNS',       '#2E8B57', 'Sea Green',        2),
    ('WINBNS',      '#006400', 'Dark Green',       3)
) AS Source(GrainGroupCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Oats - Shades of Cream (#F5DEB3)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    ('MILLINGOATS', '#F5DEB3', 'Wheat',            1),
    ('MASCANI',     '#FFE4B5', 'Moccasin',         2),
    ('SPRINGOATS',  '#FFEFD5', 'Papaya Whip',     3)
) AS Source(GrainGroupCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Linseed - Blue (#4169E1)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, '#4169E1', 'Royal Blue', 1
FROM dbo.GrainGroups gg
WHERE gg.GrainGroupCode = 'LIN';

-- Rye - Gray (#708090)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, '#708090', 'Slate Gray', 1
FROM dbo.GrainGroups gg
WHERE gg.GrainGroupCode = 'RYE';

-- Triticale - Purple (#9370DB)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, '#9370DB', 'Medium Purple', 1
FROM dbo.GrainGroups gg
WHERE gg.GrainGroupCode = 'TRI';

-- Millet - Light Yellow (#FFFACD)
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, '#FFFACD', 'Lemon Chiffon', 1
FROM dbo.GrainGroups gg
WHERE gg.GrainGroupCode = 'MILLET';

-- In-Country Wheat - Lighter shades
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    ('ICGP4H',      '#F0E68C', 'Khaki',            1),
    ('IC GP1M',     '#FAFAD2', 'Light Goldenrod Yellow', 2),
    ('ICGP2M',      '#EEE8AA', 'Pale Goldenrod',   3),
    ('ICGP4S',      '#F5DEB3', 'Wheat',            4),
    ('ICFDWHT',     '#FFE4B5', 'Moccasin',         5)
) AS Source(GrainGroupCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- In-Country other commodities
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    ('IC OATS',     '#FAEBD7', 'Antique White',    1),
    ('IC FDBLY',    '#DEB887', 'Burlywood',        2),
    ('IC LAUREATE', '#D2B48C', 'Tan',              3),
    ('IC PLANET',   '#BC8F8F', 'Rosy Brown',       4),
    ('IC PEAS - HC','#90EE90', 'Light Green',      5),
    ('IC WESTMINSTER (BLY)', '#C0C0C0', 'Silver',  6),
    ('ICFDBNS',     '#8FBC8F', 'Dark Sea Green',   7)
) AS Source(GrainGroupCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Organic Wheat - Earthy/muted tones
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    ('OG GP1M',     '#D4AF37', 'Old Gold',         1),
    ('OG GP2M',     '#C9AE5D', 'Vegas Gold',       2),
    ('OG GP3S',     '#B8A16F', 'Khaki',            3),
    ('OG GP4H',     '#AA9556', 'Brass',            4),
    ('OG GP4S',     '#9C8B4E', 'Olive',            5),
    ('OG FDWHT',    '#E1CC9A', 'Pale Gold',        6)
) AS Source(GrainGroupCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- Organic other commodities
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT gg.GrainGroupID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    ('OG OATS',         '#EEE8AA', 'Pale Goldenrod',   1),
    ('OG FDBLY',        '#B8860B', 'Dark Goldenrod',   2),
    ('OG LAUREATE',     '#8B7355', 'Burlywood Brown',  3),
    ('OG PLANET',       '#6B5D4F', 'Umber',            4),
    ('OG PROPINO',      '#7B6651', 'Coffee',           5),
    ('OG QUENCH',       '#8B7765', 'Shadow',           6),
    ('OG TALISMAN',     '#9B8B7E', 'Grullo',           7),
    ('OG VENTURE',      '#8E7C6D', 'Pale Taupe',       8),
    ('OG WESTMINSTER',  '#7E6F5C', 'Olive Gray',       9),
    ('OG WESTMINSTER (BLY)', '#8D7F6C', 'Warm Gray',  10),
    ('OGMB',            '#654321', 'Dark Brown',      11),
    ('OG ODYSSEY',      '#7B5C3D', 'Raw Umber',       12),
    ('OG OVATION (BLY)','#9A8065', 'Shadow Brown',    13),
    ('OG MATROS',       '#A88F6F', 'Ecru',            14),
    ('OG DIABLO',       '#8B6F47', 'Shadow Gray',     15),
    ('OG PEAS',         '#6B8E23', 'Olive Drab',      16),
    ('OG SPGBNS',       '#556B2F', 'Dark Olive Green', 17),
    ('OG FDBNS',        '#4A5D23', 'Army Green',      18),
    ('OG WINBNS',       '#3F4F1F', 'Rifle Green',     19),
    ('OG BNS',          '#49653C', 'Fern Green',      20),
    ('OG RYE',          '#696969', 'Dim Gray',        21),
    ('OGTRI',           '#7B68EE', 'Medium Slate Blue', 22)
) AS Source(GrainGroupCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.GrainGroups gg ON gg.GrainGroupCode = Source.GrainGroupCode;

-- For any remaining grain groups not assigned colors, use parent commodity color
INSERT INTO dbo.GrainGroupAttributes (GrainGroupID, BaseColour, ColourName, DisplayOrder)
SELECT
    gg.GrainGroupID,
    ca.BaseColour,
    'Default (' + ca.ColourName + ')',
    999
FROM dbo.GrainGroups gg
INNER JOIN dbo.Commodities c ON gg.CommodityID = c.CommodityID
INNER JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.GrainGroupAttributes gga
    WHERE gga.GrainGroupID = gg.GrainGroupID
);

GO

PRINT 'Grain group colors populated successfully';
GO
