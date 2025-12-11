-- sql/create_commodities_tables_v2.sql
-- Commodities tables: Simplified structure without date tracking

USE SiloOps;
GO

-- ============================================================================
-- Main Commodities table (synced from Franklin or managed in SiloOps)
-- ============================================================================
IF OBJECT_ID('dbo.Commodities', 'U') IS NOT NULL
    DROP TABLE dbo.Commodities;
GO

CREATE TABLE dbo.Commodities (
    CommodityID     INT IDENTITY(1,1) PRIMARY KEY,
    CommodityCode   NVARCHAR(50) NOT NULL UNIQUE,  -- e.g., 'WHT', 'OSR', 'MBLY'
    CommodityName   NVARCHAR(200) NOT NULL,         -- e.g., 'Wheat', 'Oilseed Rape'
    IsActive        BIT NOT NULL DEFAULT 1
);
GO

-- ============================================================================
-- Commodity Attributes table (custom attributes stored in SiloOps)
-- ============================================================================
IF OBJECT_ID('dbo.CommodityAttributes', 'U') IS NOT NULL
    DROP TABLE dbo.CommodityAttributes;
GO

CREATE TABLE dbo.CommodityAttributes (
    CommodityID     INT PRIMARY KEY,
    BaseColour      NVARCHAR(7),        -- Hex color code, e.g., '#DAA520'
    ColourName      NVARCHAR(50),       -- Human-readable name, e.g., 'Golden'
    DisplayOrder    INT,                -- Sort order for display
    Notes           NVARCHAR(MAX),
    CONSTRAINT FK_CommodityAttributes_Commodity
        FOREIGN KEY (CommodityID) REFERENCES dbo.Commodities(CommodityID)
        ON DELETE CASCADE
);
GO

-- ============================================================================
-- Convenient view joining Commodities + CommodityAttributes
-- ============================================================================
IF OBJECT_ID('dbo.vw_Commodities', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Commodities;
GO

CREATE VIEW dbo.vw_Commodities
AS
SELECT
    c.CommodityID,
    c.CommodityCode,
    c.CommodityName,
    c.IsActive,
    ca.BaseColour,
    ca.ColourName,
    ca.DisplayOrder,
    ca.Notes,
    CASE WHEN ca.BaseColour IS NULL OR ca.BaseColour = '' THEN 1 ELSE 0 END AS MissingColour
FROM dbo.Commodities c
LEFT JOIN dbo.CommodityAttributes ca ON c.CommodityID = ca.CommodityID;
GO

-- ============================================================================
-- Insert base commodities with color coding
-- ============================================================================

-- Core commodities with distinct colors
INSERT INTO dbo.Commodities (CommodityCode, CommodityName, IsActive) VALUES
-- Primary grain commodities
('WHT',    'Wheat',              1),
('OSR',    'Oilseed Rape',       1),
('MBLY',   'Malting Barley',     1),
('FBLY',   'Feed Barley',        1),
('PEAS',   'Peas',               1),
('BNS',    'Beans',              1),
('OATS',   'Oats',               1),
('LIN',    'Linseed',            1),
('RYE',    'Rye',                1),
('TRI',    'Triticale',          1),
('MILL',   'Millet',             1),

-- In-Country (IC) commodities
('ICWHT',   'In-Country Wheat',           1),
('ICMBLY',  'In-Country Malting Barley',  1),
('ICFBLY',  'In-Country Feed Barley',     1),
('ICPEAS',  'In-Country Peas',            1),
('ICBNS',   'In-Country Beans',           1),
('ICOATS',  'In-Country Oats',            1),

-- Organic (OG) commodities
('OGWHT',   'Organic Wheat',              1),
('OGMBLY',  'Organic Malting Barley',     1),
('OGFBLY',  'Organic Feed Barley',        1),
('OGPEAS',  'Organic Peas',               1),
('OGBNS',   'Organic Beans',              1),
('OGOATS',  'Organic Oats',               1),
('OGRYE',   'Organic Rye',                1),
('OGTRI',   'Organic Triticale',          1),

-- Specialty
('WARB',    'Warburtons',         1),
('IMP',     'Import',             1);
GO

-- ============================================================================
-- Insert color attributes for commodities
-- ============================================================================

INSERT INTO dbo.CommodityAttributes (CommodityID, BaseColour, ColourName, DisplayOrder)
SELECT CommodityID, BaseColour, ColourName, DisplayOrder
FROM (VALUES
    -- Primary commodities - base colors
    ('WHT',    '#DAA520', 'Goldenrod',      10),
    ('OSR',    '#FFD700', 'Gold',           20),
    ('MBLY',   '#8B4513', 'Saddle Brown',   30),
    ('FBLY',   '#CD853F', 'Peru',           40),
    ('PEAS',   '#32CD32', 'Lime Green',     50),
    ('BNS',    '#228B22', 'Forest Green',   60),
    ('OATS',   '#F5DEB3', 'Wheat',          70),
    ('LIN',    '#4169E1', 'Royal Blue',     80),
    ('RYE',    '#708090', 'Slate Gray',     90),
    ('TRI',    '#9370DB', 'Medium Purple',  100),
    ('MILL',   '#FFFACD', 'Lemon Chiffon',  110),
    ('WARB',   '#DC143C', 'Crimson',        120),
    ('IMP',    '#A9A9A9', 'Dark Gray',      130),

    -- In-Country variants - lighter shades of base colors
    ('ICWHT',  '#F0E68C', 'Khaki',          210),
    ('ICMBLY', '#A0522D', 'Sienna',         230),
    ('ICFBLY', '#DEB887', 'Burlywood',      240),
    ('ICPEAS', '#90EE90', 'Light Green',    250),
    ('ICBNS',  '#3CB371', 'Medium Sea Green', 260),
    ('ICOATS', '#FAEBD7', 'Antique White',  270),

    -- Organic variants - muted/earthy tones of base colors
    ('OGWHT',  '#D4AF37', 'Old Gold',       310),
    ('OGMBLY', '#654321', 'Dark Brown',     330),
    ('OGFBLY', '#B8860B', 'Dark Goldenrod', 340),
    ('OGPEAS', '#6B8E23', 'Olive Drab',     350),
    ('OGBNS',  '#556B2F', 'Dark Olive Green', 360),
    ('OGOATS', '#EEE8AA', 'Pale Goldenrod', 370),
    ('OGRYE',  '#696969', 'Dim Gray',       390),
    ('OGTRI',  '#7B68EE', 'Medium Slate Blue', 400)
) AS Source(CommodityCode, BaseColour, ColourName, DisplayOrder)
INNER JOIN dbo.Commodities c ON c.CommodityCode = Source.CommodityCode;
GO

PRINT 'Commodities tables created and populated successfully';
GO
