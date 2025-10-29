-- Icons table schema for icon browser
-- Run this if the table doesn't exist or needs to be recreated

-- Drop existing table if needed (comment out if you want to keep data)
-- DROP TABLE IF EXISTS Icons;

-- Create Icons table with appropriate column sizes
CREATE TABLE Icons (
    id INT IDENTITY(1,1) PRIMARY KEY,
    icon_name NVARCHAR(100) NOT NULL,
    primary_color VARCHAR(7) NULL,  -- #RRGGBB format
    svg NVARCHAR(MAX) NOT NULL,     -- SVG content can be large
    png_32_b64 VARBINARY(MAX) NULL, -- PNG as binary
    created_at DATETIME2 DEFAULT SYSUTCDATETIME()
);

-- Create index for faster queries
CREATE INDEX IX_Icons_IconName ON Icons(icon_name);
CREATE INDEX IX_Icons_CreatedAt ON Icons(created_at DESC);

-- Verify table structure
SELECT
    c.name AS column_name,
    t.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Icons')
ORDER BY c.column_id;
