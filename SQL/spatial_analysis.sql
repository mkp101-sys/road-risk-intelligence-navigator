-- =====================================================
--  SEVERITY + TIME FEATURES
-- =====================================================
ALTER TABLE accident_data1
ADD COLUMN IF NOT EXISTS severity_index DECIMAL(6,2);

UPDATE accident_data1
SET severity_index =
    CASE
        WHEN Total_Accident IS NULL OR Total_Accident = 0 THEN 0
        ELSE ROUND((Total_fatality::DECIMAL / Total_Accident) * 100, 2)
    END;

-- =====================================================
--  RISK LEVEL USING PERCENTILES
-- =====================================================
ALTER TABLE accident_data1
ADD COLUMN IF NOT EXISTS risk_level TEXT;

WITH severity_stats AS (
    SELECT
        percentile_cont(0.75) WITHIN GROUP (ORDER BY severity_index) AS high_threshold,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY severity_index) AS medium_threshold
    FROM accident_data1
)
UPDATE accident_data1 a
SET risk_level =
    CASE
        WHEN a.severity_index >= s.high_threshold THEN 'High'
        WHEN a.severity_index >= s.medium_threshold THEN 'Medium'
        ELSE 'Low'
    END
FROM severity_stats s;

-- =====================================================
-- HIGH-RISK BUFFER ZONES (200m FIXED BUFFER)
-- =====================================================
ALTER TABLE accident_data1
ADD COLUMN IF NOT EXISTS buffer_geom geometry(Polygon, 4326);

UPDATE accident_data1
SET buffer_geom = ST_Buffer(geom::geography, 200)::geometry;

CREATE INDEX IF NOT EXISTS idx_buffer_geom
ON accident_data1
USING GIST (buffer_geom);

-- =====================================================
--  LEAFLET VISUALIZATION SUPPORT
-- =====================================================

-- Color coding for map styling
ALTER TABLE accident_data1
ADD COLUMN IF NOT EXISTS buffer_color TEXT;

UPDATE accident_data1
SET buffer_color = CASE
    WHEN risk_level = 'High' THEN '#FF0000'
    WHEN risk_level = 'Medium' THEN '#FFA500'
    ELSE '#FFFF00'
END;


-- View for GeoJSON export (Leaflet ready)
CREATE OR REPLACE VIEW high_risk_accidents AS
SELECT
    id,
    city,
    area,
    location,
    severity_index,
    risk_level,
    buffer_color,
    geom,
    buffer_geom
FROM accident_data1
WHERE risk_level = 'High';
