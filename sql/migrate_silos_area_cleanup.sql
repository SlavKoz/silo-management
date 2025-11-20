-- Migrate legacy Silos.Area (text) to Silos.AreaID (FK)
-- Run this to clean up Area/AreaID duplication

USE SiloOps;
GO

-- Step 1: Show current state
SELECT
    COUNT(*) AS TotalSilos,
    COUNT(Area) AS HasAreaText,
    COUNT(AreaID) AS HasAreaID,
    COUNT(CASE WHEN Area IS NOT NULL AND AreaID IS NULL THEN 1 END) AS OnlyAreaText,
    COUNT(CASE WHEN Area IS NULL AND AreaID IS NOT NULL THEN 1 END) AS OnlyAreaID,
    COUNT(CASE WHEN Area IS NOT NULL AND AreaID IS NOT NULL THEN 1 END) AS BothAreaFields
FROM dbo.Silos;
GO

-- Step 2: Find unique Area text values not yet in SiteAreas
SELECT DISTINCT
    s.Area,
    s.SiteID,
    sa.AreaID AS ExistingAreaID
FROM dbo.Silos s
LEFT JOIN dbo.SiteAreas sa ON s.SiteID = sa.SiteID AND s.Area = sa.AreaCode
WHERE s.Area IS NOT NULL
  AND s.AreaID IS NULL
ORDER BY s.Area;
GO

-- Step 3: FOR EACH unique Area value that needs migration:
-- Manually create SiteAreas entry (requires SiteID + unique AreaCode/AreaName)
--
-- INSERT INTO dbo.SiteAreas (SiteID, AreaCode, AreaName, RowVer)
-- VALUES (?, 'CODE', 'Name', DEFAULT);
--
-- Then update Silos:
-- UPDATE dbo.Silos
-- SET AreaID = ?
-- WHERE Area = 'OLD_TEXT_VALUE' AND SiteID = ?;

-- Step 4: After migration, optionally deprecate Area column
-- (DO NOT drop yet - check dependencies first)
--
-- Add computed column to show warning:
-- ALTER TABLE dbo.Silos ADD AreaTextLegacy AS Area PERSISTED;
--
-- Then eventually:
-- ALTER TABLE dbo.Silos DROP COLUMN Area;

-- Step 5: Update queries to use vw_SilosWithStatus instead of raw Silos table
-- This view properly joins to SiteAreas.AreaCode and AreaName