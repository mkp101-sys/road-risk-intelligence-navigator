-- =====================================================
--  DRIVER PATH (ANALYTICS ENGINE)
-- =====================================================
CREATE TABLE IF NOT EXISTS driver_path (
    id SERIAL PRIMARY KEY,
    geom geometry(LineString, 4326),
    created_at TIMESTAMP DEFAULT NOW()
);

TRUNCATE TABLE driver_path;


INSERT INTO driver_path (geom)
VALUES (
    ST_SetSRID(
        ST_MakeLine(ARRAY[
            ST_MakePoint(72.94344,19.13179),
            ST_MakePoint(72.93871,19.12405),
            ST_MakePoint(72.93509,19.11540),
            ST_MakePoint(72.931266,19.106212),
            ST_MakePoint(72.929766,19.103262),
            ST_MakePoint(72.929676,19.102524),
            ST_MakePoint(72.928985,19.100681),
            ST_MakePoint(72.928415,19.099263),
            ST_MakePoint(72.927394,19.096993),
            ST_MakePoint(72.926764,19.095660),
			ST_MakePoint(72.925653,19.092767),
			ST_MakePoint(72.923582,19.087576),
			ST_MakePoint(72.921091,19.084186),
			ST_MakePoint(72.918975,19.081860),
			ST_MakePoint(72.918119,19.080754),
			ST_MakePoint(72.911786,19.074215),
			ST_MakePoint(72.907133,19.071010),
			ST_MakePoint(72.902061,19.067634),
			ST_MakePoint(72.899209,19.065761),
			ST_MakePoint(72.897708,19.064371),
			ST_MakePoint(72.894466,19.062243)
        ]),
    4326)
);


-- =====================================================
--  DRIVER ALERT SYSTEM (SPATIAL INTELLIGENCE)
-- =====================================================
CREATE OR REPLACE VIEW driver_alerts AS
SELECT
    d.id AS driver_id,
    z.id AS accident_id,
    z.severity_index,
    ROUND(
        ST_Distance(d.geom::geography, z.geom::geography)::NUMERIC,
        2
    ) AS distance_meters,
    CASE
        WHEN ST_Intersects(d.geom, z.buffer_geom)
            THEN 'INSIDE DANGER ZONE'
        WHEN ST_DWithin(d.geom::geography, z.geom::geography, 400)
            THEN 'APPROACHING DANGER ZONE'
        ELSE 'SAFE'
    END AS alert_status,
    CASE
        WHEN z.severity_index >= 20 THEN 'CRITICAL'
        WHEN z.severity_index >= 10 THEN 'HIGH'
        ELSE 'MODERATE'
    END AS alert_level
FROM driver_path d
JOIN accident_data1 z
ON ST_DWithin(d.geom::geography, z.geom::geography, 400)
WHERE z.risk_level = 'High';

-- =====================================================
--  DRIVER RISK SUMMARY (EXPOSURE METRICS)
-- =====================================================
CREATE OR REPLACE VIEW  driver_risk_summary AS
SELECT
    d.id AS driver_id,
    COUNT(z.id) AS high_risk_zones_nearby,
    ROUND(SUM(z.severity_index), 2) AS total_risk_exposure,
    ROUND(AVG(z.severity_index), 2) AS avg_zone_severity
FROM driver_path d
JOIN accident_data1 z
ON ST_DWithin(d.geom::geography, z.geom::geography, 400)
WHERE z.risk_level = 'High'
GROUP BY d.id;

-- =====================================================
-- FINAL CHECK
-- =====================================================
SELECT * FROM driver_alerts;



