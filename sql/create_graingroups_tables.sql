-- sql/create_graingroups_tables.sql
-- Grain Groups tables: Main table from Franklin + Custom attributes in SiloOps

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
    LastSyncDate    DATETIME2,
    CreatedDate     DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate    DATETIME2,
    CONSTRAINT FK_GrainGroups_Commodity
        FOREIGN KEY (CommodityID) REFERENCES dbo.Commodities(CommodityID)
);
GO

-- ============================================================================
-- Grain Group Attributes table (custom attributes stored in SiloOps)
-- ============================================================================
IF OBJECT_ID('dbo.GrainGroupAttributes', 'U') IS NOT NULL
    DROP TABLE dbo.GrainGroupAttributes;
GO

CREATE TABLE dbo.GrainGroupAttributes (
    GrainGroupID    INT PRIMARY KEY,
    BaseColour      NVARCHAR(7),        -- Hex color code (shade of commodity color)
    ColourName      NVARCHAR(50),       -- Human-readable name
    DisplayOrder    INT,                -- Sort order for display
    Notes           NVARCHAR(MAX),
    CreatedDate     DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate    DATETIME2,
    CONSTRAINT FK_GrainGroupAttributes_GrainGroup
        FOREIGN KEY (GrainGroupID) REFERENCES dbo.GrainGroups(GrainGroupID)
        ON DELETE CASCADE
);
GO

-- ============================================================================
-- Convenient view joining GrainGroups + GrainGroupAttributes + Commodities
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
    gg.CreatedDate,
    gg.ModifiedDate,
    gga.BaseColour,
    gga.ColourName,
    gga.DisplayOrder,
    gga.Notes,
    CASE WHEN gga.BaseColour IS NULL OR gga.BaseColour = '' THEN 1 ELSE 0 END AS MissingColour
FROM dbo.GrainGroups gg
LEFT JOIN dbo.GrainGroupAttributes gga ON gg.GrainGroupID = gga.GrainGroupID
INNER JOIN dbo.Commodities c ON gg.CommodityID = c.CommodityID;
GO

-- ============================================================================
-- Insert grain groups from the variant data
-- Color scheme: Each grain group gets a shade of its commodity's base color
-- ============================================================================

-- Helper: Get CommodityID by code
DECLARE @WHT INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'WHT');
DECLARE @OSR INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OSR');
DECLARE @MBLY INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'MBLY');
DECLARE @FBLY INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'FBLY');
DECLARE @PEAS INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'PEAS');
DECLARE @BNS INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'BNS');
DECLARE @OATS INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OATS');
DECLARE @LIN INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'LIN');
DECLARE @RYE INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'RYE');
DECLARE @TRI INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'TRI');
DECLARE @MILL INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'MILL');
DECLARE @WARB INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'WARB');
DECLARE @IMP INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'IMP');

-- In-Country commodities
DECLARE @ICWHT INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'ICWHT');
DECLARE @ICMBLY INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'ICMBLY');
DECLARE @ICFBLY INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'ICFBLY');
DECLARE @ICPEAS INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'ICPEAS');
DECLARE @ICBNS INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'ICBNS');
DECLARE @ICOATS INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'ICOATS');

-- Organic commodities
DECLARE @OGWHT INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OGWHT');
DECLARE @OGMBLY INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OGMBLY');
DECLARE @OGFBLY INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OGFBLY');
DECLARE @OGPEAS INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OGPEAS');
DECLARE @OGBNS INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OGBNS');
DECLARE @OGOATS INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OGOATS');
DECLARE @OGRYE INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OGRYE');
DECLARE @OGTRI INT = (SELECT CommodityID FROM dbo.Commodities WHERE CommodityCode = 'OGTRI');

-- Wheat grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('GP1M',    'Group 1 Milling',     @WHT),
('GP2M',    'Group 2 Milling',     @WHT),
('GP3S',    'Group 3 Soft',        @WHT),
('GP4H',    'Group 4 Hard',        @WHT),
('GP4S',    'Group 4 Soft',        @WHT),
('FDWHT',   'Feed Wheat',          @WHT),
('WW',      'Winter Wheat',        @WHT),
('IMP',     'Import Wheat',        @IMP),
('WARB',    'Warburtons',          @WARB);

-- OSR grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('OSR',     'Standard OSR',        @OSR),
('HEAR',    'High Erucic Acid',    @OSR),
('HOLL',    'High Oleic Low Linolenic', @OSR);

-- Malting Barley grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('ASTEROID',        'Asteroid',         @MBLY),
('BELGRAVIA',       'Belgravia',        @MBLY),
('BUCCANEER',       'Buccaneer',        @MBLY),
('CARAT',           'Carat',            @MBLY),
('CASSATA',         'Cassata',          @MBLY),
('CBSCORE',         'CB Score',         @MBLY),
('CHACHA',          'Cha Cha',          @MBLY),
('CHANSON',         'Chanson',          @MBLY),
('CHAPEAU',         'Chapeau',          @MBLY),
('CHEERIO',         'Cheerio',          @MBLY),
('CONCERTO',        'Concerto',         @MBLY),
('COSMOPOLITAN',    'Cosmopolitan',     @FBLY),
('CRAFT',           'Craft',            @MBLY),
('DIABLO',          'Diablo',           @MBLY),
('DIOPTRIC',        'Dioptric',         @MBLY),
('ELECTRUM',        'Electrum',         @MBLY),
('EXPLORER',        'Explorer',         @MBLY),
('FAIRING',         'Fairing',          @MBLY),
('FLAGON',          'Flagon',           @MBLY),
('IRINA',           'Irina',            @MBLY),
('LAUREATE',        'Laureate',         @MBLY),
('MARIS OTTER',     'Maris Otter',      @MBLY),
('MATROS',          'Matros',           @MBLY),
('MERIDIAN',        'Meridian',         @MBLY),
('OCTAVIA',         'Octavia',          @MBLY),
('ODYSSEY',         'Odyssey',          @MBLY),
('OLYMPUS',         'Olympus',          @MBLY),
('OPERA',           'Opera',            @MBLY),
('PLANET',          'Planet',           @MBLY),
('PROPINO',         'Propino',          @MBLY),
('QUENCH',          'Quench',           @MBLY),
('ROSE',            'Rose',             @MBLY),
('SANETTE',         'Sanette',          @MBLY),
('SASSY',           'Sassy',            @MBLY),
('SBLY',            'Spring Barley',    @MBLY),
('SIENNA',          'Sienna',           @MBLY),
('SKYWAY',          'Skyway',           @MBLY),
('SPRINGBLY',       'Spring Barley',    @MBLY),
('TALISMAN',        'Talisman',         @MBLY),
('TIPPLE',          'Tipple',           @MBLY),
('VENTURE',         'Venture',          @MBLY),
('WESTMINSTER (BLY)', 'Westminster',    @MBLY);

-- Feed Barley grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('FDBLY',           'Feed Barley',      @FBLY);

-- Peas grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('FDPEAS',          'Feed Peas',        @PEAS),
('PEAS - HC',       'Peas - Human Consumption', @PEAS);

-- Beans grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('FDBNS',           'Feed Beans',       @BNS),
('SPBNS',           'Spring Beans',     @BNS),
('WINBNS',          'Winter Beans',     @BNS);

-- Oats grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('MILLINGOATS',     'Milling Oats',     @OATS),
('MASCANI',         'Mascani',          @OATS),
('SPRINGOATS',      'Spring Oats',      @OATS);

-- Linseed grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('LIN',             'Linseed',          @LIN);

-- Rye grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('RYE',             'Rye',              @RYE);

-- Triticale grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('TRI',             'Triticale',        @TRI);

-- Millet grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('MILLET',          'Millet',           @MILL);

-- In-Country Wheat grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('ICGP4H',          'IC Group 4 Hard',  @ICWHT),
('IC GP1M',         'IC Group 1 Milling', @ICWHT),
('ICGP2M',          'IC Group 2 Milling', @ICWHT),
('ICGP4S',          'IC Group 4 Soft', @ICWHT),
('ICFDWHT',         'IC Feed Wheat',    @ICWHT);

-- In-Country other grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('IC OATS',         'IC Oats',          @ICOATS),
('IC FDBLY',        'IC Feed Barley',   @ICFBLY),
('IC LAUREATE',     'IC Laureate',      @ICMBLY),
('IC PLANET',       'IC Planet',        @ICMBLY),
('IC PEAS - HC',    'IC Peas - HC',     @ICPEAS),
('IC WESTMINSTER (BLY)', 'IC Westminster', @ICFBLY),
('ICFDBNS',         'IC Feed Beans',    @ICBNS);

-- Organic Wheat grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('OG GP1M',         'Organic Group 1',  @OGWHT),
('OG GP2M',         'Organic Group 2',  @OGWHT),
('OG GP3S',         'Organic Group 3 Soft', @OGWHT),
('OG GP4H',         'Organic Group 4 Hard', @OGWHT),
('OG GP4S',         'Organic Group 4 Soft', @OGWHT),
('OG FDWHT',        'Organic Feed Wheat', @OGWHT);

-- Organic other grain groups
INSERT INTO dbo.GrainGroups (GrainGroupCode, GrainGroupName, CommodityID) VALUES
('OG OATS',         'Organic Oats',     @OGOATS),
('OG FDBLY',        'Organic Feed Barley', @OGFBLY),
('OG LAUREATE',     'Organic Laureate', @OGMBLY),
('OG PLANET',       'Organic Planet',   @OGMBLY),
('OG PROPINO',      'Organic Propino',  @OGMBLY),
('OG QUENCH',       'Organic Quench',   @OGMBLY),
('OG TALISMAN',     'Organic Talisman', @OGMBLY),
('OG VENTURE',      'Organic Venture',  @OGMBLY),
('OG WESTMINSTER',  'Organic Westminster', @OGMBLY),
('OG WESTMINSTER (BLY)', 'Organic Westminster Barley', @OGMBLY),
('OGMB',            'Organic Malting Barley', @OGMBLY),
('OG ODYSSEY',      'Organic Odyssey',  @OGMBLY),
('OG OVATION (BLY)', 'Organic Ovation', @OGFBLY),
('OG MATROS',       'Organic Matros',   @OGFBLY),
('OG DIABLO',       'Organic Diablo',   @OGFBLY),
('OG PEAS',         'Organic Peas',     @OGPEAS),
('OG SPGBNS',       'Organic Spring Beans', @OGBNS),
('OG FDBNS',        'Organic Feed Beans', @OGBNS),
('OG WINBNS',       'Organic Winter Beans', @OGBNS),
('OG BNS',          'Organic Beans',    @OGBNS),
('OG RYE',          'Organic Rye',      @OGRYE),
('OGTRI',           'Organic Triticale', @OGTRI);

GO

PRINT 'GrainGroups tables created and populated successfully';
GO
