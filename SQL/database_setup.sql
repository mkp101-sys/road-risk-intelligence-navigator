
-- =====================================================
--  ENABLE POSTGIS
-- =====================================================
CREATE EXTENSION IF NOT EXISTS postgis;

-- =====================================================
--  BASE TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS accident_data1 (
    id INTEGER PRIMARY KEY,
    city TEXT,
    area TEXT,
    location TEXT,
    Accident_2021 INTEGER,
    Accident_2022 INTEGER,
    Accident_2023 INTEGER,
    Total_Accident INTEGER,
    Total_fatality integer,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
);

-- =====================================================
--  REMOVE INVALID COORDINATES
-- =====================================================
DELETE FROM accident_data1
WHERE latitude IS NULL
   OR longitude IS NULL
   OR latitude = 0
   OR longitude = 0;

-- =====================================================
--  GEOMETRY COLUMN
-- =====================================================
ALTER TABLE accident_data1
ADD COLUMN IF NOT EXISTS geom geometry(Point, 4326);

UPDATE accident_data1
SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326);
