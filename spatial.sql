/* DATA BASE CREATION  */
-- YOUR SQL CODE HERE TO BUILD CREATE SCHEMAS, TABLES, ETC
CREATE TABLE accidents (
    id VARCHAR(255),
    source VARCHAR(255),
    severity INTEGER CHECK (severity BETWEEN 1 AND 4),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    start_lat DOUBLE PRECISION,
    start_lng DOUBLE PRECISION,
    end_lat DOUBLE PRECISION,
    end_lng DOUBLE PRECISION,
    distance_mi DOUBLE PRECISION
);

--Add geom columns
ALTER TABLE accidents
ADD COLUMN start_geom GEOGRAPHY(POINT, 4326),
ADD COLUMN end_geom GEOGRAPHY(POINT, 4326);

Update geom columns based on lat and lng
UPDATE accidents
SET start_geom = ST_SetSRID(ST_MakePoint(start_lng, start_lat), 4326),
    end_geom = ST_SetSRID(ST_MakePoint(end_lng, end_lat), 4326);

-- create gist-index on start_geom, end_geom
--create index
CREATE INDEX idx_start_geom ON accidents USING GIST (start_geom);
CREATE INDEX idx_end_geom ON accidents USING GIST (end_geom);

-- Create B-Tree index on start_lat and start_lng
CREATE INDEX idx_accidents_btree ON accidents USING BTREE (start_lat, start_lng);	


-- Create an R-tree index on the start_lat and start_lng columns
CREATE INDEX idx_accidents_rtree ON accidents USING GIST (start_lat, start_lng);

/* 
Query Task 1:
find k nearest neighbours (data points) of a given trajectory for a given date
test case 1.x use sequential scan
test case 2.x use r-tree
test case 3.x use Gist
*/

/* Test Case 1.1: DESCRIBE YOUR CASE HERE */

/**
given trajectory((-122.4233, 37.7672), (-122.4244, 37.7688)), given date: 2016-02-08
*/

/* Test Case 1.1 with Sequential_Scan_1 */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1

SELECT id, start_time, start_lng, start_lat, ST_Distance(
  ST_SetSRID(ST_Point(start_lng, start_lat), 4326),
  ST_MakeLine(ST_SetSRID(ST_Point(-122.4233, 37.7672), 4326), ST_SetSRID(ST_Point(-122.4244, 37.7688), 4326))
) AS distance
FROM accidents
WHERE start_time::date = '2016-02-08' 
ORDER BY distance
LIMIT 3; 

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */

--   id  |     start_time      | start_lng  | start_lat |      distance
-- ------+---------------------+------------+-----------+--------------------
--  A-25 | 2016-02-08 12:16:44 | -84.259216 | 39.761379 |  38.21614917077723
--  A-20 | 2016-02-08 09:35:35 | -84.244461 | 39.790703 | 38.232424874429945
--  A-18 | 2016-02-08 09:24:37 | -84.239952 | 39.752174 |  38.23490795424751

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--  Limit  (cost=82760.03..82760.38 rows=3 width=40) (actual time=531.158..532.717 rows=3 loops=1)
--    Buffers: shared hit=11746 read=37508
--    ->  Gather Merge  (cost=82760.03..83246.10 rows=4166 width=40) (actual time=531.155..532.714 rows=3 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=11746 read=37508
--          ->  Sort  (cost=81760.00..81765.21 rows=2083 width=40) (actual time=507.166..507.167 rows=2 loops=3)
--                Sort Key: (st_distance(st_setsrid(st_point(start_lng, start_lat), 4326), '0102000020E6100000020000006519E258179B5EC0E0BE0E9C33E24240091B9E5E299B5EC01895D40968E24240'::geometry))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=11746 read=37508
--                Worker 0:  Sort Method: quicksort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..81733.08 rows=2083 width=40) (actual time=244.981..507.090 rows=12 loops=3)
--                      Filter: ((start_time)::date = '2016-02-08'::date)
--                      Rows Removed by Filter: 333321
--                      Buffers: shared hit=11672 read=37508
--  Planning Time: 0.408 ms
--  Execution Time: 532.926 ms
-- (18 rows)


/* Test Case 1.2: DESCRIBE YOUR CASE HERE */

/**
given trajectory((-82.4233, 37.7672), (-82.4244, 37.7688)), given date: 2016-02-08
*/

/* Test Case 1.2 with Sequential Scan_1 */

-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1
SELECT id, start_time, start_lng, start_lat, ST_Distance(
  ST_SetSRID(ST_Point(start_lng, start_lat), 4326),
  ST_MakeLine(ST_SetSRID(ST_Point(-82.4233, 37.7672), 4326), ST_SetSRID(ST_Point(-82.4244, 37.7688), 4326))
) AS distance
FROM accidents
WHERE start_time::date = '2016-02-08' 
ORDER BY distance
LIMIT 1; 

-- create index	
CREATE INDEX idx_start_geom ON accidents USING GIST (start_geom);
CREATE INDEX idx_end_geom ON accidents USING GIST (end_geom);



/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */

--   id  |     start_time      | start_lng  | start_lat |      distance
-- -----+---------------------+------------+-----------+--------------------
--  A-3 | 2016-02-08 06:49:27 | -84.032608 | 39.063148 | 2.0643811945394117

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--   Limit  (cost=82743.52..82743.64 rows=1 width=40) (actual time=599.633..601.028 rows=1 loops=1)
--    Buffers: shared hit=12034 read=37220
--    ->  Gather Merge  (cost=82743.52..83229.59 rows=4166 width=40) (actual time=599.630..601.025 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=12034 read=37220
--          ->  Sort  (cost=81743.50..81748.71 rows=2083 width=40) (actual time=540.185..540.185 rows=1 loops=3)
--                Sort Key: (st_distance(st_setsrid(st_point(start_lng, start_lat), 4326), '0102000020E6100000020000006519E258179B54C0E0BE0E9C33E24240091B9E5E299B54C01895D40968E24240'::geometry))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=12034 read=37220
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: quicksort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..81733.08 rows=2083 width=40) (actual time=271.667..540.093 rows=12 loops=3)
--                      Filter: ((start_time)::date = '2016-02-08'::date)
--                      Rows Removed by Filter: 333321
--                      Buffers: shared hit=11960 read=37220
--  Planning Time: 0.472 ms
--  Execution Time: 601.080 ms
-- (18 rows)

/* Test Case 1.3: DESCRIBE YOUR CASE HERE */

/**
given trajectory((-66.4233, 36.7672), (-66.4244, 36.7688)), given date: 2016-02-08
*/

/* Test Case 1.3 with Sequential Scan_1 */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1
SELECT id, start_time, start_lng, start_lat, ST_Distance(
  ST_SetSRID(ST_Point(start_lng, start_lat), 4326),
  ST_MakeLine(ST_SetSRID(ST_Point(-66.4233, 36.7672), 4326), ST_SetSRID(ST_Point(-66.4244, 36.7688), 4326))
) AS distance
FROM accidents
WHERE start_time::date = '2016-02-08' 
ORDER BY distance
LIMIT 1; 

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */
--   id  |     start_time      | start_lng  | start_lat |      distance
-- ------+---------------------+------------+-----------+--------------------
--  A-26 | 2016-02-08 12:41:08 | -82.641762 | 40.158024 | 16.567729764853716
 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */
--  Limit  (cost=82743.52..82743.64 rows=1 width=40) (actual time=184.075..185.922 rows=1 loops=1)
--    Buffers: shared hit=12418 read=36836
--    ->  Gather Merge  (cost=82743.52..83229.59 rows=4166 width=40) (actual time=184.073..185.920 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=12418 read=36836
--          ->  Sort  (cost=81743.50..81748.71 rows=2083 width=40) (actual time=165.097..165.098 rows=0 loops=3)
--                Sort Key: (st_distance(st_setsrid(st_point(start_lng, start_lat), 4326), '0102000020E6100000020000006519E258179B50C0E0BE0E9C33624240091B9E5E299B50C01895D40968624240'::geometry))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=12418 read=36836
--                Worker 0:  Sort Method: quicksort  Memory: 25kB
--                Worker 1:  Sort Method: quicksort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..81733.08 rows=2083 width=40) (actual time=104.317..165.015 rows=12 loops=3)
--                      Filter: ((start_time)::date = '2016-02-08'::date)
--                      Rows Removed by Filter: 333321
--                      Buffers: shared hit=12344 read=36836
--  Planning Time: 0.317 ms
--  Execution Time: 185.967 ms
-- (18 rows)


/* Test Case 2.1: DESCRIBE YOUR CASE HERE */

/**
given trajectory((-122.4233, 37.7672), (-122.4244, 37.7688)), given date: 2016-02-08
*/

/* Test Case 2.1 with R-tree Indexing via PostGIS_1 */
-- YOUR SQL CODE HERE WITH PostGIS_1
SELECT id, start_lng, start_lat, start_time, ST_Distance(
  ST_SetSRID(ST_Point(start_lng, start_lat), 4326),
  ST_MakeLine(ST_SetSRID(ST_Point(-122.4233, 37.7672), 4326), ST_SetSRID(ST_Point(-122.4244, 37.7688), 4326))
) AS distance
FROM accidents
WHERE start_time::date = '2016-02-08'
ORDER BY ST_SetSRID(ST_Point(start_lng, start_lat), 4326) <-> ST_MakeLine(ST_SetSRID(ST_Point(-122.4233, 37.7672), 4326), ST_SetSRID(ST_Point(-122.4244, 37.7688), 4326))
LIMIT 3;  -- Replace k with the number of neighbors you want


/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */
--   id  | start_lng  | start_lat |     start_time      |      distance
-- ------+------------+-----------+---------------------+--------------------
--  A-25 | -84.259216 | 39.761379 | 2016-02-08 12:16:44 |  38.21614917077723
--  A-20 | -84.244461 | 39.790703 | 2016-02-08 09:35:35 | 38.232424874429945
--  A-18 | -84.239952 | 39.752174 | 2016-02-08 09:24:37 |  38.23490795424751

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--  Limit  (cost=0.41..209.20 rows=3 width=48) (actual time=1195.247..1202.590 rows=3 loops=1)
--    Buffers: shared hit=570293 read=11283
--    ->  Index Scan using idx_accident_start_location on accidents  (cost=0.41..347984.41 rows=5000 width=48) (actual time=1195.245..1202.588 rows=3 loops=1)
--          Order By: (st_setsrid(st_point(start_lng, start_lat), 4326) <-> '0102000020E6100000020000006519E258179B5EC0E0BE0E9C33E24240091B9E5E299B5EC01895D40968E24240'::geometry)
--          Filter: ((start_time)::date = '2016-02-08'::date)
--          Rows Removed by Filter: 575341
--          Buffers: shared hit=570293 read=11283
--  Planning Time: 0.407 ms
--  Execution Time: 1202.697 ms
-- (9 rows)


/* Test Case 2.2: DESCRIBE YOUR CASE HERE */

/**
given trajectory((-82.4233, 37.7672), (-82.4244, 37.7688)), given date: 2016-02-08
*/

/* Test Case 2.2 with R-tree Indexing via PostGIS_2 */

-- YOUR SQL CODE HERE WITH r-tree_2
EXPLAIN (ANALYZE ON, BUFFERS ON)
SELECT id, start_lng, start_lat, start_time, ST_Distance(
  ST_SetSRID(ST_Point(start_lng, start_lat), 4326),
  ST_MakeLine(ST_SetSRID(ST_Point(-82.4233, 37.7672), 4326), ST_SetSRID(ST_Point(-82.4244, 37.7688), 4326))
) AS distance
FROM accidents
WHERE start_time::date = '2016-02-08'
ORDER BY ST_SetSRID(ST_Point(start_lng, start_lat), 4326) <-> ST_MakeLine(ST_SetSRID(ST_Point(-82.4233, 37.7672), 4326), ST_SetSRID(ST_Point(-82.4244, 37.7688), 4326))
LIMIT 1;  -- Replace k with the number of neighbors you want

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */

--   id  |     start_time      | start_lng  | start_lat |      distance
-- -----+---------------------+------------+-----------+--------------------
--  A-3 | 2016-02-08 06:49:27 | -84.032608 | 39.063148 | 2.0643811945394117

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--   Limit  (cost=0.41..70.01 rows=1 width=48) (actual time=28.260..28.261 rows=1 loops=1)
--    Buffers: shared hit=1809 read=44
--    ->  Index Scan using idx_accident_start_location on accidents  (cost=0.41..347984.41 rows=5000 width=48) (actual time=28.259..28.259 rows=1 loops=1)
--          Order By: (st_setsrid(st_point(start_lng, start_lat), 4326) <-> '0102000020E6100000020000006519E258179B54C0E0BE0E9C33E24240091B9E5E299B54C01895D40968E24240'::geometry)
--          Filter: ((start_time)::date = '2016-02-08'::date)
--          Rows Removed by Filter: 1736
--          Buffers: shared hit=1809 read=44
--  Planning:
--    Buffers: shared hit=184
--  Planning Time: 17.453 ms
--  Execution Time: 28.429 ms
-- (11 rows)

/* Test Case 2.3: DESCRIBE YOUR CASE HERE */

/**
given trajectory((-66.4233, 36.7672), (-82.4244, 36.7688)), given date: 2016-02-08
*/

/* Test Case 2.3 with R-tree Indexing via PostGIS_3 */

-- YOUR SQL CODE HERE WITH R-tree_3
SELECT id, start_lng, start_lat, start_time, ST_Distance(
  ST_SetSRID(ST_Point(start_lng, start_lat), 4326),
  ST_MakeLine(ST_SetSRID(ST_Point(-66.4233, 36.7672), 4326), ST_SetSRID(ST_Point(-66.4244, 36.7688), 4326))
) AS distance
FROM accidents
WHERE start_time::date = '2016-02-08'
ORDER BY ST_SetSRID(ST_Point(start_lng, start_lat), 4326) <-> ST_MakeLine(ST_SetSRID(ST_Point(-66.4233, 36.7672), 4326), ST_SetSRID(ST_Point(-66.4244, 36.7688), 4326))
LIMIT 1;  -- Replace k with the number of neighbors you want

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */

--   id  | start_lng  | start_lat |     start_time      |      distance
-- ------+------------+-----------+---------------------+--------------------
--  A-26 | -82.641762 | 40.158024 | 2016-02-08 12:41:08 | 16.567729764853716

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */
--  Limit  (cost=0.41..70.01 rows=1 width=48) (actual time=629.141..629.141 rows=1 loops=1)
--    Buffers: shared hit=267336 read=4341
--    ->  Index Scan using idx_accident_start_location on accidents  (cost=0.41..347984.41 rows=5000 width=48) (actual time=629.140..629.140 rows=1 loops=1)
--          Order By: (st_setsrid(st_point(start_lng, start_lat), 4326) <-> '0102000020E6100000020000006519E258179B50C0E0BE0E9C33624240091B9E5E299B50C01895D40968624240'::geometry)
--          Filter: ((start_time)::date = '2016-02-08'::date)
--          Rows Removed by Filter: 269352
--          Buffers: shared hit=267336 read=4341
--  Planning:
--    Buffers: shared hit=181 read=3
--  Planning Time: 22.007 ms
--  Execution Time: 629.316 ms
-- (11 rows)


/* Test Case 3.1: DESCRIBE YOUR CASE HERE */

/**
given trajectory((-122.4233, 37.7672), (-122.4244, 37.7688)), given date: 2016-02-08
*/

/* Test Case 3.1 with Gist_1 */
-- YOUR SQL CODE HERE WITH Gist_1
SELECT id, start_time, ST_Distance(start_geom, ST_GeomFromText('LINESTRING(-122.4233 37.7672, -122.4244 37.7688)', 4326)) AS distance
FROM accidents
WHERE start_time::date = '2016-02-08'
ORDER BY distance
LIMIT 3;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */
--   id  |     start_time      |     distance
-- ------+---------------------+------------------
--  A-25 | 2016-02-08 12:16:44 | 3299249.56561846
--  A-20 | 2016-02-08 09:35:35 | 3300016.98838243
--  A-14 | 2016-02-08 08:37:07 | 3300262.90374533

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

----------------------------
--  Limit  (cost=82494.45..82494.80 rows=3 width=24) (actual time=135.189..137.101 rows=3 loops=1)
--    Buffers: shared hit=13453 read=35931
--    ->  Gather Merge  (cost=82494.45..82980.51 rows=4166 width=24) (actual time=135.188..137.098 rows=3 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=13453 read=35931
--          ->  Sort  (cost=81494.42..81499.63 rows=2083 width=24) (actual time=118.755..118.755 rows=1 loops=3)
--                Sort Key: (st_distance(start_geom, '0102000020E6100000020000006519E258179B5EC0E0BE0E9C33E24240091B9E5E299B5EC01895D40968E24240'::geography, true))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=13453 read=35931
--                Worker 0:  Sort Method: quicksort  Memory: 25kB
--                Worker 1:  Sort Method: quicksort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..81467.50 rows=2083 width=24) (actual time=75.716..118.689 rows=12 loops=3)
--                      Filter: ((start_time)::date = '2016-02-08'::date)
--                      Rows Removed by Filter: 333321
--                      Buffers: shared hit=13379 read=35931
--  Planning:
--    Buffers: shared hit=220
--  Planning Time: 19.071 ms
--  Execution Time: 137.217 ms
-- (20 rows)

/* Test Case 3.2: DESCRIBE YOUR CASE HERE */

/**
given trajectory((-82.4233, 37.7672), (-82.4244, 37.7688)), given date: 2016-02-08
*/

/* Test Case 3.2 with Gist_2 */
-- YOUR SQL CODE HERE WITH Gist_2
SELECT id, start_time, ST_Distance(start_geom, ST_GeomFromText('LINESTRING(-82.4233 37.7672, -82.4244 37.7688)', 4326)) AS distance
FROM accidents
WHERE start_time::date = '2016-02-08'
ORDER BY distance
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */
--  id  |     start_time      |    distance
-- -----+---------------------+-----------------
--  A-3 | 2016-02-08 06:49:27 | 200915.60922603

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */
--  Limit  (cost=82477.94..82478.06 rows=1 width=24) (actual time=138.766..140.571 rows=1 loops=1)
--    Buffers: shared hit=13756 read=36027
--    ->  Gather Merge  (cost=82477.94..82964.01 rows=4166 width=24) (actual time=138.765..140.569 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=13756 read=36027
--          ->  Sort  (cost=81477.91..81483.12 rows=2083 width=24) (actual time=126.008..126.009 rows=1 loops=3)
--                Sort Key: (st_distance(start_geom, '0102000020E6100000020000006519E258179B54C0E0BE0E9C33E24240091B9E5E299B54C01895D40968E24240'::geography, true))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=13756 read=36027
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: quicksort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..81467.50 rows=2083 width=24) (actual time=73.767..125.968 rows=12 loops=3)
--                      Filter: ((start_time)::date = '2016-02-08'::date)
--                      Rows Removed by Filter: 333321
--                      Buffers: shared hit=13682 read=36027
--  Planning:
--    Buffers: shared hit=208 read=12
--  Planning Time: 29.342 ms
--  Execution Time: 140.676 ms
-- (20 rows)

/* Test Case 3.3: DESCRIBE YOUR CASE HERE */

/**
given trajectory((-66.4233, 36.7672), (-66.4244, 36.7688)), given date: 2016-02-08
*/
/* Test Case 3.3 with Gist_3 */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1
SELECT id, start_time, ST_Distance(start_geom, ST_GeomFromText('LINESTRING(-66.4233 36.7672, -66.4244 36.7688)', 4326)) AS distance
FROM accidents
WHERE start_time::date = '2016-02-08'
ORDER BY distance
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */
--   id  |     start_time      |     distance
-- ------+---------------------+------------------
--  A-26 | 2016-02-08 12:41:08 | 1462194.88327015

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--  Limit  (cost=82477.94..82478.06 rows=1 width=24) (actual time=156.250..158.026 rows=1 loops=1)
--    Buffers: shared hit=13530 read=36123
--    ->  Gather Merge  (cost=82477.94..82964.01 rows=4166 width=24) (actual time=156.248..158.024 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=13530 read=36123
--          ->  Sort  (cost=81477.91..81483.12 rows=2083 width=24) (actual time=135.277..135.277 rows=1 loops=3)
--                Sort Key: (st_distance(start_geom, '0102000020E6100000020000006519E258179B50C0E0BE0E9C33624240091B9E5E299B50C01895D40968624240'::geography, true))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=13530 read=36123
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: quicksort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..81467.50 rows=2083 width=24) (actual time=76.418..135.200 rows=12 loops=3)
--                      Filter: ((start_time)::date = '2016-02-08'::date)
--                      Rows Removed by Filter: 333321
--                      Buffers: shared hit=13456 read=36123
--  Planning Time: 0.303 ms
--  Execution Time: 158.086 ms
-- (18 rows)

/* 
Query Task 2:
Find the nearest accident location to the given data point
test case 1.x use b tree index
test case 2.x use r tree index
test case 3.x use gist
*/

/* Test Case 1.1: DESCRIBE YOUR CASE HERE */

/**
given point (-122.4193 , 37.7751)
*/

/* Test Case 1.1 with B_TREE_INDEX */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1

SELECT id, start_lat, start_lng, end_lat, end_lng, distance_mi
FROM accidents
ORDER BY sqrt((start_lat - 37.7751)^2 + (start_lng - (-122.4193))^2)
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */
--    id    | start_lat |  start_lng  | end_lat | end_lng | distance_mi
-- ---------+-----------+-------------+---------+---------+-------------
--  A-39515 | 37.775158 | -122.419266 |         |         |        0.01

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */
--  Limit  (cost=62680.03..62680.15 rows=1 width=56) (actual time=498.613..499.987 rows=1 loops=1)
--    Buffers: shared hit=12181 read=37073
--    ->  Gather Merge  (cost=62680.03..159909.12 rows=833334 width=56) (actual time=498.611..499.985 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=12181 read=37073
--          ->  Sort  (cost=61680.01..62721.67 rows=416667 width=56) (actual time=489.708..489.709 rows=1 loops=3)
--                Sort Key: (sqrt((((start_lat - '37.7751'::double precision) ^ '2'::double precision) + ((start_lng - '-122.4193'::double precision) ^ '2'::double precision))))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=12181 read=37073
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..59596.67 rows=416667 width=56) (actual time=0.727..459.001 rows=333333 loops=3)
--                      Buffers: shared hit=12107 read=37073
--  Planning Time: 0.233 ms
--  Execution Time: 500.030 ms
-- (16 rows)

/* Test Case 1.2: DESCRIBE YOUR CASE HERE */

/**
given point (-88.4193 , 37.7751)
*/

/* Test Case 1.2 with B_TREE_INDEX */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1

SELECT id, start_lat, start_lng, end_lat, end_lng, distance_mi
FROM accidents
ORDER BY sqrt((start_lat - 37.7751)^2 + (start_lng - (-88.4193))^2)
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */
--    id    | start_lat | start_lng  | end_lat | end_lng | distance_mi
-- ----------+-----------+------------+---------+---------+-------------
--  A-958140 | 37.706718 | -88.571053 |         |         |           0

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
--  */
--  Limit  (cost=62680.03..62680.15 rows=1 width=56) (actual time=478.641..480.076 rows=1 loops=1)
--    Buffers: shared hit=12277 read=36977
--    ->  Gather Merge  (cost=62680.03..159909.12 rows=833334 width=56) (actual time=478.639..480.074 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=12277 read=36977
--          ->  Sort  (cost=61680.01..62721.67 rows=416667 width=56) (actual time=470.732..470.732 rows=1 loops=3)
--                Sort Key: (sqrt((((start_lat - '37.7751'::double precision) ^ '2'::double precision) + ((start_lng - '-88.4193'::double precision) ^ '2'::double precision))))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=12277 read=36977
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..59596.67 rows=416667 width=56) (actual time=0.275..438.986 rows=333333 loops=3)
--                      Buffers: shared hit=12203 read=36977
--  Planning:
--    Buffers: shared hit=183
--  Planning Time: 5.119 ms
--  Execution Time: 480.188 ms
-- (18 rows)
/* Test Case 1.3: DESCRIBE YOUR CASE HERE */

/**
given point (-66.4193 , 37.7751)
*/

/* Test Case 1.3 with B_TREE_INDEX */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1

SELECT id, start_lat, start_lng, end_lat, end_lng, distance_mi
FROM accidents
ORDER BY sqrt((start_lat - 37.7751)^2 + (start_lng - (-66.4193))^2)
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
 */
--     id    | start_lat | start_lng  | end_lat | end_lng | distance_mi
-- ----------+-----------+------------+---------+---------+-------------
--  A-869828 | 41.689919 | -69.957573 |         |         |           0

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--  Limit  (cost=62680.03..62680.15 rows=1 width=56) (actual time=446.896..459.485 rows=1 loops=1)
--    Buffers: shared hit=12373 read=36881
--    ->  Gather Merge  (cost=62680.03..159909.12 rows=833334 width=56) (actual time=446.895..459.484 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=12373 read=36881
--          ->  Sort  (cost=61680.01..62721.67 rows=416667 width=56) (actual time=442.039..442.040 rows=1 loops=3)
--                Sort Key: (sqrt((((start_lat - '37.7751'::double precision) ^ '2'::double precision) + ((start_lng - '-66.4193'::double precision) ^ '2'::double precision))))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=12373 read=36881
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..59596.67 rows=416667 width=56) (actual time=0.214..409.457 rows=333333 loops=3)
--                      Buffers: shared hit=12299 read=36881
--  Planning:
--    Buffers: shared hit=183
--  Planning Time: 1.946 ms
--  Execution Time: 459.533 ms
-- (18 rows)

/* Test Case 2.1: DESCRIBE YOUR CASE HERE */

/**
given point (-122.4193 , 37.7751)
*/

/* Test Case 2.1 with R_TREE_INDEX */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1
-- Find the nearest accident location to the given data point using R-tree index
SELECT id, start_lat, start_lng, end_lat, end_lng, distance_mi
FROM accidents
ORDER BY ST_Distance(ST_MakePoint(start_lng, start_lat), ST_MakePoint(-122.4193, 37.7751))
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */
--    id    | start_lat |  start_lng  | end_lat | end_lng | distance_mi
-- ---------+-----------+-------------+---------+---------+-------------
--  A-39515 | 37.775158 | -122.419266 |         |         |        0.01

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--                                                                   QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------------------------------------------
--  Limit  (cost=5316850.90..5316851.02 rows=1 width=56) (actual time=288.624..290.098 rows=1 loops=1)
--    Buffers: shared hit=13863 read=35391
--    ->  Gather Merge  (cost=5316850.90..5414079.99 rows=833334 width=56) (actual time=288.621..290.094 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=13863 read=35391
--          ->  Sort  (cost=5315850.88..5316892.54 rows=416667 width=56) (actual time=260.682..260.682 rows=1 loops=3)
--                Sort Key: (st_distance(st_makepoint(start_lng, start_lat), '01010000009FCDAACFD59A5EC097900F7A36E34240'::geometry))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=13863 read=35391
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..5313767.54 rows=416667 width=56) (actual time=0.205..228.973 rows=333333 loops=3)
--                      Buffers: shared hit=13789 read=35391
--  Planning Time: 0.481 ms
--  Execution Time: 290.202 ms
-- (16 rows)

/* Test Case 2.2: DESCRIBE YOUR CASE HERE */

/**
given point (-82.4193 , 37.7751)
*/

/* Test Case 2.2 with R_TREE_INDEX */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1

-- Find the nearest accident location to the given data point using R-tree index
SELECT id, start_lat, start_lng, end_lat, end_lng, distance_mi
FROM accidents
ORDER BY ST_Distance(ST_MakePoint(start_lng, start_lat), ST_MakePoint(-82.4193, 37.7751))
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
    id    | start_lat | start_lng  | end_lat | end_lng | distance_mi
----------+-----------+------------+---------+---------+-------------
 A-877497 | 37.523228 | -82.571571 |         |         |           0 
 
 */

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */
--                                                                 QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------------------------------------------
--  Limit  (cost=5316850.90..5316851.02 rows=1 width=56) (actual time=268.688..270.054 rows=1 loops=1)
--    Buffers: shared hit=14151 read=35103
--    ->  Gather Merge  (cost=5316850.90..5414079.99 rows=833334 width=56) (actual time=268.686..270.052 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=14151 read=35103
--          ->  Sort  (cost=5315850.88..5316892.54 rows=416667 width=56) (actual time=247.440..247.440 rows=1 loops=3)
--                Sort Key: (st_distance(st_makepoint(start_lng, start_lat), '01010000009FCDAACFD59A54C097900F7A36E34240'::geometry))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=14151 read=35103
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..5313767.54 rows=416667 width=56) (actual time=0.396..215.699 rows=333333 loops=3)
--                      Buffers: shared hit=14077 read=35103
--  Planning Time: 0.557 ms
--  Execution Time: 270.157 ms
-- (16 rows)

/* Test Case 2.3: DESCRIBE YOUR CASE HERE */

/**
given point (-66.4193 , 36.7751)
*/

/* Test Case 2.3 with R_TREE_INDEX */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1

-- Find the nearest accident location to the given data point using R-tree index

SELECT id, start_lat, start_lng, end_lat, end_lng, distance_mi
FROM accidents
ORDER BY ST_Distance(ST_MakePoint(start_lng, start_lat), ST_MakePoint(-66.4193, 36.7751))
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE
    id    | start_lat | start_lng  | end_lat | end_lng | distance_mi
----------+-----------+------------+---------+---------+-------------
 A-869828 | 41.689919 | -69.957573 |         |         |           0
(1 row)
 
 */

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */
--                                                                     QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------------------------------------------
--  Limit  (cost=5316850.90..5316851.02 rows=1 width=56) (actual time=272.119..273.674 rows=1 loops=1)
--    Buffers: shared hit=14343 read=34911
--    ->  Gather Merge  (cost=5316850.90..5414079.99 rows=833334 width=56) (actual time=272.117..273.672 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=14343 read=34911
--          ->  Sort  (cost=5315850.88..5316892.54 rows=416667 width=56) (actual time=251.787..251.788 rows=1 loops=3)
--                Sort Key: (st_distance(st_makepoint(start_lng, start_lat), '01010000009FCDAACFD59A50C097900F7A36634240'::geometry))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=14343 read=34911
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..5313767.54 rows=416667 width=56) (actual time=0.187..219.865 rows=333333 loops=3)
--                      Buffers: shared hit=14269 read=34911
--  Planning Time: 0.262 ms
--  Execution Time: 273.719 ms
-- (16 rows)


/* Test Case 3.1: DESCRIBE YOUR CASE HERE */

/**
given point (-122.4193 , 37.7751)
*/

/* Test Case 3.1 with gist_1 */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_1
-- Find the nearest accident location to the given data point using gist index
EXPLAIN (ANALYZE ON, BUFFERS ON)
SELECT id, start_lat, start_lng, end_lat, end_lng, distance_mi
FROM accidents
ORDER BY ST_Distance(start_geom, ST_SetSRID(ST_MakePoint(-122.4193, 37.7751), 4326))
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */
--   id    | start_lat |  start_lng  | end_lat | end_lng | distance_mi
-- ---------+-----------+-------------+---------+---------+-------------
--  A-39515 | 37.775158 | -122.419266 |         |         |        0.01
-- (1 row)

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */
--                                                                    QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------------------------------------------
--  Limit  (cost=5264767.53..5264767.64 rows=1 width=56) (actual time=537.023..538.658 rows=1 loops=1)
--    Buffers: shared hit=15333 read=34719
--    ->  Gather Merge  (cost=5264767.53..5361996.61 rows=833334 width=56) (actual time=537.021..538.656 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=15333 read=34719
--          ->  Sort  (cost=5263767.50..5264809.17 rows=416667 width=56) (actual time=506.493..506.494 rows=1 loops=3)
--                Sort Key: (st_distance(start_geom, '0101000020E61000009FCDAACFD59A5EC097900F7A36E34240'::geography, true))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=15333 read=34719
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..5261684.17 rows=416667 width=56) (actual time=3.183..475.175 rows=333333 loops=3)
--                      Buffers: shared hit=15259 read=34719
--  Planning Time: 0.390 ms
--  Execution Time: 538.810 ms
-- (16 rows)

/* Test Case 3.2: DESCRIBE YOUR CASE HERE */

/**
given point (-82.4193 , 37.7751)
*/

/* Test Case 3.2 with gist_2 */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_2
-- Find the nearest accident location to the given data point using gist index
SELECT id, start_lat, start_lng, end_lat, end_lng, distance_mi
FROM accidents
ORDER BY ST_Distance(start_geom, ST_SetSRID(ST_MakePoint(-82.4193, 37.7751), 4326))
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */
--     id    | start_lat | start_lng  | end_lat | end_lng | distance_mi
-- ----------+-----------+------------+---------+---------+-------------
--  A-877497 | 37.523228 | -82.571571 |         |         |           0

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */
--                                                                      QUERY PLAN
-- --------------------------------------------------------------------------------------------------------------------------------------------------
--  Limit  (cost=5264767.53..5264767.64 rows=1 width=56) (actual time=541.914..543.538 rows=1 loops=1)
--    Buffers: shared hit=15525 read=34527
--    ->  Gather Merge  (cost=5264767.53..5361996.61 rows=833334 width=56) (actual time=541.912..543.536 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=15525 read=34527
--          ->  Sort  (cost=5263767.50..5264809.17 rows=416667 width=56) (actual time=522.808..522.809 rows=1 loops=3)
--                Sort Key: (st_distance(start_geom, '0101000020E61000009FCDAACFD59A54C097900F7A36E34240'::geography, true))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=15525 read=34527
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..5261684.17 rows=416667 width=56) (actual time=12.458..492.354 rows=333333 loops=3)
--                      Buffers: shared hit=15451 read=34527
--  Planning Time: 0.378 ms
--  Execution Time: 543.645 ms
-- (16 rows)


/* Test Case 3.3: DESCRIBE YOUR CASE HERE */

/**
given point (-66.4193 , 36.7751)
*/

/* Test Case 3.3 with gist_3 */
-- YOUR SQL CODE HERE WITH YOUR_INDEX_METHOD_3
-- Find the nearest accident location to the given data point using gist index

SELECT id, start_lat, start_lng, end_lat, end_lng, distance_mi
FROM accidents
ORDER BY ST_Distance(start_geom, ST_SetSRID(ST_MakePoint(-66.4193, 36.7751), 4326))
LIMIT 1;

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */

--    id    | start_lat | start_lng  | end_lat | end_lng | distance_mi
-- ----------+-----------+------------+---------+---------+-------------
--  A-869828 | 41.689919 | -69.957573 |         |         |           0
 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--                                                                     QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------------------------------------------
--  Limit  (cost=5264767.53..5264767.64 rows=1 width=56) (actual time=573.581..575.283 rows=1 loops=1)
--    Buffers: shared hit=15717 read=34335
--    ->  Gather Merge  (cost=5264767.53..5361996.61 rows=833334 width=56) (actual time=573.579..575.280 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=15717 read=34335
--          ->  Sort  (cost=5263767.50..5264809.17 rows=416667 width=56) (actual time=527.890..527.891 rows=1 loops=3)
--                Sort Key: (st_distance(start_geom, '0101000020E61000009FCDAACFD59A50C097900F7A36634240'::geography, true))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=15717 read=34335
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..5261684.17 rows=416667 width=56) (actual time=2.933..497.203 rows=333333 loops=3)
--                      Buffers: shared hit=15643 read=34335
--  Planning Time: 0.570 ms
--  Execution Time: 575.971 ms
-- (16 rows)

/* 
Query Task 3:
find all data points in a given rectangular area and within a certain time window
testcase 1.x use sequential scan
testcase 2.x use gist indexing
testcase 3.x use BRIN indexing
*/

/* Test Case 1.1 with sequential scan_1 */

SELECT *
FROM accidents
WHERE ST_Within(ST_Transform(ST_SetSRID(ST_MakePoint(start_lng, start_lat), 4326), 4326), 
                ST_Transform(ST_SetSRID(ST_MakeEnvelope(-81, 49.5, -82.2, 39.8), 4326), 4326)) 
  AND start_time::date BETWEEN '2016-02-09' AND '2016-02-10';


/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */

--   id  | source  | severity |     start_time      |      end_time       | start_lat | start_lng  | end_lat | end_lng | distance_mi |                     start_geom                     | end_geom | centroid_lat | centroid_lng
-- ------+---------+----------+---------------------+---------------------+-----------+------------+---------+---------+-------------+----------------------------------------------------+----------+--------------+--------------
--  A-68 | Source2 |        3 | 2016-02-09 08:20:30 | 2016-02-09 08:50:30 | 41.407391 | -81.646767 |         |         |        0.01 | 0101000020E610000073486AA1646954C0A5D7666325B44440 |          |              |
--  A-69 | Source2 |        3 | 2016-02-09 08:35:53 | 2016-02-09 09:05:53 | 41.424404 | -81.578674 |         |         |        0.01 | 0101000020E6100000EA42ACFE086554C05325CADE52B64440 |          |              |
--  A-85 | Source2 |        3 | 2016-02-10 17:10:00 | 2016-02-10 23:59:00 | 41.040714 | -81.613144 |         |         |        0.01 | 0101000020E610000046EF54C03D6754C0A33EC91D36854440 |          |              |
--  A-86 | Source2 |        3 | 2016-02-10 18:09:00 | 2016-02-10 23:59:00 | 41.083679 | -81.579002 |         |         |        1.28 | 0101000020E61000006494675E0E6554C0552E54FEB58A4440 |          |              |
-- (4 rows)

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--                                                                     QUERY PLAN
-- --------------------------------------------------------------------------------------------------------------------------------------------------
--  Limit  (cost=5264767.53..5264767.64 rows=1 width=56) (actual time=541.914..543.538 rows=1 loops=1)
--    Buffers: shared hit=15525 read=34527
--    ->  Gather Merge  (cost=5264767.53..5361996.61 rows=833334 width=56) (actual time=541.912..543.536 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=15525 read=34527
--          ->  Sort  (cost=5263767.50..5264809.17 rows=416667 width=56) (actual time=522.808..522.809 rows=1 loops=3)
--                Sort Key: (st_distance(start_geom, '0101000020E61000009FCDAACFD59A54C097900F7A36E34240'::geography, true))
--                Sort Method: top-N heapsort  Memory: 25kB
--                Buffers: shared hit=15525 read=34527
--                Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
--                Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
--                ->  Parallel Seq Scan on accidents  (cost=0.00..5261684.17 rows=416667 width=56) (actual time=12.458..492.354 rows=333333 loops=3)
--                      Buffers: shared hit=15451 read=34527
--  Planning Time: 0.378 ms
--                                                                                                                                                                                                      QUERY PLAN
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Gather  (cost=1000.00..10528305.10 rows=1 width=156) (actual time=1.984..629.259 rows=4 loops=1)
--    Workers Planned: 2
--    Workers Launched: 2
--    Buffers: shared hit=133 read=49047
--    ->  Parallel Seq Scan on accidents  (cost=0.00..10527305.00 rows=1 width=156) (actual time=377.197..585.795 rows=1 loops=3)
--          Filter: (((start_time)::date >= '2016-02-09'::date) AND ((start_time)::date <= '2016-02-10'::date) AND st_within(st_transform(st_setsrid(st_makepoint(start_lng, start_lat), 4326), 4326), '0103000020E6100000010000000500000000000000004054C00000000000C0484000000000004054C06666666666E64340CDCCCCCCCC8C54C06666666666E64340CDCCCCCCCC8C54C00000000000C0484000000000004054C00000000000C04840'::geometry))
--          Rows Removed by Filter: 333332
--          Buffers: shared hit=133 read=49047
--  Planning Time: 1.226 ms
--  Execution Time: 629.390 ms
-- (10 rows)

-- (END)


/* Test Case 1.2 with sequential scan_2 */


SELECT *
FROM accidents
WHERE ST_Within(ST_Transform(ST_SetSRID(ST_MakePoint(start_lng, start_lat), 4326), 4326), 
                ST_Transform(ST_SetSRID(ST_MakeEnvelope(-81, 49.5, -82.2, 39.8), 4326), 4326)) 
  AND start_time::date BETWEEN '2016-03-01' AND '2016-03-05';


/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */


--   id   | source  | severity |     start_time      |      end_time       | start_lat | start_lng  | end_lat | end_lng | distance_mi |                     start_geom                     | end_geom | centroid_lat | centroid_lng
-- -------+---------+----------+---------------------+---------------------+-----------+------------+---------+---------+-------------+----------------------------------------------------+----------+--------------+--------------
--  A-449 | Source2 |        2 | 2016-03-02 17:52:45 | 2016-03-02 18:22:45 | 41.316475 | -81.649101 |         |         |        0.01 | 0101000020E610000042B3EBDE8A6954C03480B74082A84440 |          |              |
--  A-482 | Source2 |        3 | 2016-03-04 06:39:05 | 2016-03-04 07:09:05 | 41.113785 | -81.611633 |         |         |        0.01 | 0101000020E6100000E109BDFE246754C03FE3C281908E4440 |          |              |
-- (2 rows)

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--                                                                     QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------------------------------------------
--  Limit  (cost=5264767.53..5264767.64 rows=1 width=56) (actual time=573.581..575.283 rows=1 loops=1)
--    Buffers: shared hit=15717 read=34335
--    ->  Gather Merge  (cost=5264767.53..5361996.61 rows=833334 width=56) (actual time=573.579..575.280 rows=1 loops=1)
--          Workers Planned: 2
--          Workers Launched: 2
--          Buffers: shared hit=15717 read=34335
--                                                                                                                                                                                                      QUERY PLAN
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Gather  (cost=1000.00..10528305.10 rows=1 width=156) (actual time=2.368..526.163 rows=2 loops=1)
--    Workers Planned: 2
--    Workers Launched: 2
--    Buffers: shared hit=422 read=48758
--    ->  Parallel Seq Scan on accidents  (cost=0.00..10527305.00 rows=1 width=156) (actual time=326.469..500.646 rows=1 loops=3)
--          Filter: (((start_time)::date >= '2016-03-01'::date) AND ((start_time)::date <= '2016-03-05'::date) AND st_within(st_transform(st_setsrid(st_makepoint(start_lng, start_lat), 4326), 4326), '0103000020E6100000010000000500000000000000004054C00000000000C0484000000000004054C06666666666E64340CDCCCCCCCC8C54C06666666666E64340CDCCCCCCCC8C54C00000000000C0484000000000004054C00000000000C04840'::geometry))
--          Rows Removed by Filter: 333333
--          Buffers: shared hit=422 read=48758
--  Planning Time: 0.372 ms
--  Execution Time: 526.212 ms
-- (10 rows)


/* Test Case 1.3 with sequential scan_3 */


SELECT *
FROM accidents
WHERE ST_Within(ST_Transform(ST_SetSRID(ST_MakePoint(start_lng, start_lat), 4326), 4326), 
                ST_Transform(ST_SetSRID(ST_MakeEnvelope(-85, 49.5, -81, 39.8), 4326), 4326)) 
  AND start_time::date BETWEEN '2016-03-01' AND '2016-03-05';


/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */

--   id   | source  | severity |     start_time      |      end_time       | start_lat | start_lng  | end_lat | end_lng | distance_mi |                     start_geom                     | end_geom | centroid_lat | centroid_lng
-- -------+---------+----------+---------------------+---------------------+-----------+------------+---------+---------+-------------+----------------------------------------------------+----------+--------------+--------------
--  A-426 | Source2 |        2 | 2016-03-01 05:05:42 | 2016-03-01 05:35:42 | 39.945835 | -83.061295 |         |         |           0 | 0101000020E6100000221ADD41ECC354C0C2340C1F11F94340 |          |              |
--  A-429 | Source2 |        2 | 2016-03-01 07:31:53 | 2016-03-01 08:01:53 | 39.927441 | -83.056198 |         |         |        0.01 | 0101000020E610000070067FBF98C354C01AFCFD62B6F64340 |          |              |
--  A-430 | Source2 |        2 | 2016-03-01 07:46:03 | 2016-03-01 08:16:03 | 39.946892 | -82.915489 |         |         |        0.01 | 0101000020E610000041B62C5F97BA54C0096CCEC133F94340 |          |              |
--  A-431 | Source2 |        3 | 2016-03-01 08:16:30 | 2016-03-01 08:46:30 | 40.002552 | -83.118355 |         |         |        0.01 | 0101000020E61000005B94D92093C754C00B45BA9F53004440 |          |              |
--  A-436 | Source2 |        3 | 2016-03-01 11:56:36 | 2016-03-01 12:26:36 | 40.151196 | -84.220032 |         |         |        7.07 | 0101000020E6100000B4041901150E55C09CA4F9635A134440 |          |              |
--  A-437 | Source2 |        2 | 2016-03-01 12:36:27 | 2016-03-01 13:51:27 | 40.033405 | -82.910225 |         |         |        0.01 | 0101000020E61000001AC05B2041BA54C0EE42739D46044440 |          |              |
--  A-439 | Source2 |        2 | 2016-03-01 16:41:08 | 2016-03-01 17:11:08 | 40.080338 | -82.880074 |         |         |        0.01 | 0101000020E6100000D503E62153B854C02250FD83480A4440 |          |              |
--  A-440 | Source2 |        2 | 2016-03-01 17:23:06 | 2016-03-01 18:23:06 | 40.200333 | -83.027435 |         |         |           0 | 0101000020E610000002F1BA7EC1C154C0A0A70183A4194440 |          |              |
--  A-441 | Source2 |        3 | 2016-03-01 17:31:22 | 2016-03-01 18:01:22 |  40.02504 | -82.904129 |         |         |        0.01 | 0101000020E61000005F97E13FDDB954C0C18BBE8234034440 |          |              |
--  A-442 | Source2 |        3 | 2016-03-01 17:39:00 | 2016-03-01 21:00:00 | 40.013062 |  -82.90213 |         |         |        0.01 | 0101000020E610000064AF777FBCB954C00169FF03AC014440 |          |              |
--  A-443 | Source2 |        3 | 2016-03-01 18:07:29 | 2016-03-01 18:37:29 | 40.065559 | -82.906418 |         |         |        0.01 | 0101000020E61000005EA0A4C002BA54C0AF7AC03C64084440 |          |              |
--  A-445 | Source2 |        2 | 2016-03-01 18:52:22 | 2016-03-01 19:22:22 | 39.902195 | -83.084763 |         |         |           0 | 0101000020E61000004B3ACAC16CC554C0AFCE31207BF34340 |          |              |
--  A-446 | Source2 |        3 | 2016-03-02 16:36:08 | 2016-03-02 17:06:08 | 41.370506 | -83.616997 |         |         |        0.01 | 0101000020E6100000BA2EFCE07CE754C0637C98BD6CAF4440 |          |              |
--  A-447 | Source2 |        2 | 2016-03-02 17:12:54 | 2016-03-02 17:42:54 | 39.945427 | -82.846558 |         |         |        0.01 | 0101000020E6100000B30A9B012EB654C0B1E07EC003F94340 |          |              |
--  A-448 | Source2 |        3 | 2016-03-02 17:32:51 | 2016-03-02 18:02:51 | 39.945751 | -82.846252 |         |         |        0.01 | 0101000020E61000002D0B26FE28B654C06494675E0EF94340 |          |              |
--  A-449 | Source2 |        2 | 2016-03-02 17:52:45 | 2016-03-02 18:22:45 | 41.316475 | -81.649101 |         |         |        0.01 | 0101000020E610000042B3EBDE8A6954C03480B74082A84440 |          |              |
--  A-453 | Source2 |        2 | 2016-03-03 04:51:44 | 2016-03-03 05:21:44 | 40.005947 | -82.858887 |         |         |           0 | 0101000020E610000069FD2D01F8B654C031410DDFC2004440 |          |              |
--  A-455 | Source2 |        3 | 2016-03-03 06:51:45 | 2016-03-03 07:21:45 | 40.030914 | -82.994598 |         |         |        0.01 | 0101000020E6100000B0AA5E7EA7BF54C0897E6DFDF4034440 |          |              |
--  A-458 | Source2 |        3 | 2016-03-03 07:44:53 | 2016-03-03 08:14:53 | 39.976398 | -83.119225 |         |         |        0.01 | 0101000020E610000066F7E461A1C754C09EF0129CFAFC4340 |          |              |
--  A-459 | Source2 |        3 | 2016-03-03 07:45:33 | 2016-03-03 08:15:33 | 39.948391 | -82.943558 |         |         |        0.01 | 0101000020E610000044F8174163BC54C00E6954E064F94340 |          |              |
--  A-463 | Source2 |        3 | 2016-03-03 09:42:54 | 2016-03-03 10:12:54 | 39.939571 | -83.009911 |         |         |        0.01 | 0101000020E6100000B937BF61A2C054C090A2CEDC43F84340 |          |              |
--  A-465 | Source2 |        2 | 2016-03-03 11:28:29 | 2016-03-03 11:58:29 | 39.815628 | -84.093338 |         |         |           0 | 0101000020E6100000575EF23FF90555C0D7D9907F66E84340 |          |              |
--  A-471 | Source2 |        2 | 2016-03-03 15:07:36 | 2016-03-03 15:37:36 | 39.919437 | -82.775238 |         |         |           0 | 0101000020E61000007427D87F9DB154C0BEDD921CB0F54340 |          |              |
--  A-472 | Source2 |        2 | 2016-03-03 16:11:40 | 2016-03-03 16:41:40 | 39.972076 | -83.098183 |         |         |        0.01 | 0101000020E61000007C8159A148C654C0FE9C82FC6CFC4340 |          |              |
--  A-476 | Source2 |        3 | 2016-03-03 18:30:12 | 2016-03-03 19:00:12 | 39.934155 | -82.852524 |         |         |        0.01 | 0101000020E610000087C3D2C08FB654C08B321B6492F74340 |          |              |
--  A-478 | Source2 |        3 | 2016-03-03 20:04:00 | 2016-03-03 21:00:00 | 40.045822 | -83.033424 |         |         |        0.01 | 0101000020E6100000B2B96A9E23C254C0FAB7CB7EDD054440 |          |              |
--  A-479 | Source2 |        3 | 2016-03-03 20:21:07 | 2016-03-03 20:51:07 | 40.051949 | -83.032806 |         |         |        0.01 | 0101000020E61000003447567E19C254C0AB07CC43A6064440 |          |              |
--  A-480 | Source2 |        2 | 2016-03-04 06:10:42 | 2016-03-04 06:40:42 | 39.943745 | -83.073151 |         |         |        0.01 | 0101000020E6100000DC2A8881AEC454C0BB61DBA2CCF84340 |          |              |
--  A-481 | Source2 |        3 | 2016-03-04 06:11:18 | 2016-03-04 06:41:18 |  39.89217 | -83.039169 |         |         |        0.01 | 0101000020E61000001781B1BE81C254C0753C66A032F24340 |          |              |
--  A-482 | Source2 |        3 | 2016-03-04 06:39:05 | 2016-03-04 07:09:05 | 41.113785 | -81.611633 |         |         |        0.01 | 0101000020E6100000E109BDFE246754C03FE3C281908E4440 |          |              |
--  A-483 | Source2 |        3 | 2016-03-04 06:43:09 | 2016-03-04 07:13:09 | 39.948158 | -83.036201 |         |         |        0.01 | 0101000020E610000048C5FF1D51C254C06BB8C83D5DF94340 |          |              |
--  A-484 | Source2 |        3 | 2016-03-04 06:44:45 | 2016-03-04 07:14:45 | 39.819839 | -84.189087 |         |         |        0.01 | 0101000020E610000052465C001A0C55C0207EFE7BF0E84340 |          |              |
--  A-489 | Source2 |        3 | 2016-03-04 07:37:31 | 2016-03-04 08:07:31 | 41.351006 | -83.622826 |         |         |        0.01 | 0101000020E61000004E469561DCE754C09259BDC3EDAC4440 |          |              |
--  A-491 | Source2 |        2 | 2016-03-04 07:59:13 | 2016-03-04 08:29:13 | 39.943653 | -83.060631 |         |         |           0 | 0101000020E6100000EC87D860E1C354C0DAE21A9FC9F84340 |          |              |
--  A-492 | Source2 |        2 | 2016-03-04 08:01:42 | 2016-03-04 08:31:42 | 39.985336 | -82.789841 |         |         |        0.01 | 0101000020E61000008E0244C18CB254C025C9737D1FFE4340 |          |              |
--  A-493 | Source2 |        3 | 2016-03-04 08:06:17 | 2016-03-04 08:36:17 | 40.077419 | -82.907898 |         |         |        0.01 | 0101000020E6100000A58636001BBA54C0658BA4DDE8094440 |          |              |
--  A-495 | Source2 |        2 | 2016-03-04 08:24:47 | 2016-03-04 08:54:47 | 40.083298 | -84.117058 |         |         |        0.01 | 0101000020E61000000D6FD6E07D0755C03EE94482A90A4440 |          |              |
--  A-496 | Source2 |        2 | 2016-03-04 08:33:12 | 2016-03-04 09:03:12 | 40.089439 | -83.036194 |         |         |        0.01 | 0101000020E6100000EE93A30051C254C054FEB5BC720B4440 |          |              |
--  A-501 | Source2 |        2 | 2016-03-04 14:55:28 | 2016-03-04 15:25:28 |  39.95232 | -83.037613 |         |         |           0 | 0101000020E6100000E2395B4068C254C0D2A92B9FE5F94340 |          |              |
--  A-502 | Source2 |        2 | 2016-03-04 16:46:11 | 2016-03-04 17:16:11 |  40.01757 | -82.928978 |         |         |        0.01 | 0101000020E6100000062D246074BB54C003B2D7BB3F024440 |          |              |
--  A-503 | Source2 |        2 | 2016-03-04 17:31:00 | 2016-03-04 21:00:00 | 39.956528 | -83.018555 |         |         |        0.01 | 0101000020E6100000598B4F0130C154C0A9DA6E826FFA4340 |          |              |
--  A-504 | Source2 |        2 | 2016-03-04 17:28:40 | 2016-03-04 17:58:40 | 39.939571 | -83.009911 |         |         |        0.01 | 0101000020E6100000B937BF61A2C054C090A2CEDC43F84340 |          |              |
--  A-506 | Source2 |        3 | 2016-03-05 07:07:25 | 2016-03-05 07:37:25 | 41.137856 | -83.658844 |         |         |        0.01 | 0101000020E61000009D4A06802AEA54C058C7F143A5914440 |          |              |

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */


-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Gather  (cost=1000.00..10528305.10 rows=1 width=156) (actual time=1.541..620.552 rows=43 loops=1)
--    Workers Planned: 2
--    Workers Launched: 2
--    Buffers: shared hit=614 read=48566
--    ->  Parallel Seq Scan on accidents  (cost=0.00..10527305.00 rows=1 width=156) (actual time=380.099..585.598 rows=14 loops=3)
--          Filter: (((start_time)::date >= '2016-03-01'::date) AND ((start_time)::date <= '2016-03-05'::date) AND st_within(st_transform(st_setsrid(st_makepoint(start_lng, start_lat), 4326), 4326), '0103000020E6100000010000000500000000000000004055C00000000000C0484000000000004055C06666666666E6434000000000004054C06666666666E6434000000000004054C00000000000C0484000000000004055C00000000000C04840'::geometry))
--          Rows Removed by Filter: 333319
--          Buffers: shared hit=614 read=48566
--  Planning Time: 0.355 ms
--  Execution Time: 620.614 ms
-- (10 rows)


/* Test Case 2.1 with gist_1 */
CREATE INDEX ON accidents USING GIST (start_geom);

SELECT *
FROM accidents
WHERE ST_Intersects(start_geom, 
                    ST_Transform(ST_SetSRID(ST_MakeEnvelope(-81, 49.5, -82.2, 39.8), 4326), 4326)::geography) 
  AND start_time::date BETWEEN '2016-02-09' AND '2016-02-10';



/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */
--   id  | source  | severity |     start_time      |      end_time       | start_lat | start_lng  | end_lat | end_lng | distance_mi |                     start_geom                     | end_geom | centroid_lat | centroid_lng
-- ------+---------+----------+---------------------+---------------------+-----------+------------+---------+---------+-------------+----------------------------------------------------+----------+--------------+--------------
--  A-68 | Source2 |        3 | 2016-02-09 08:20:30 | 2016-02-09 08:50:30 | 41.407391 | -81.646767 |         |         |        0.01 | 0101000020E610000073486AA1646954C0A5D7666325B44440 |          |              |
--  A-69 | Source2 |        3 | 2016-02-09 08:35:53 | 2016-02-09 09:05:53 | 41.424404 | -81.578674 |         |         |        0.01 | 0101000020E6100000EA42ACFE086554C05325CADE52B64440 |          |              |
--  A-85 | Source2 |        3 | 2016-02-10 17:10:00 | 2016-02-10 23:59:00 | 41.040714 | -81.613144 |         |         |        0.01 | 0101000020E610000046EF54C03D6754C0A33EC91D36854440 |          |              |
--  A-86 | Source2 |        3 | 2016-02-10 18:09:00 | 2016-02-10 23:59:00 | 41.083679 | -81.579002 |         |         |        1.28 | 0101000020E61000006494675E0E6554C0552E54FEB58A4440 |          |              |


 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */
                                                                                                                                                                      QUERY PLAN
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Gather  (cost=1851.17..134460.67 rows=74 width=156) (actual time=62.183..159.840 rows=4 loops=1)
--    Workers Planned: 2
--    Workers Launched: 2
--    Buffers: shared hit=1 read=5978 written=4374
--    ->  Parallel Bitmap Heap Scan on accidents  (cost=851.17..133453.27 rows=31 width=156) (actual time=90.449..122.560 rows=1 loops=3)
--          Filter: (((start_time)::date >= '2016-02-09'::date) AND ((start_time)::date <= '2016-02-10'::date) AND st_intersects(start_geom, '0103000020E6100000010000000500000000000000004054C00000000000C0484000000000004054C06666666666E64340CDCCCCCCCC8C54C06666666666E64340CDCCCCCCCC8C54C00000000000C0484000000000004054C00000000000C04840'::geography))
--          Rows Removed by Filter: 6652
--          Heap Blocks: exact=1887
--          Buffers: shared hit=1 read=5978 written=4374
--          ->  Bitmap Index Scan on accidents_start_geom_idx4  (cost=0.00..851.15 rows=18515 width=0) (actual time=61.446..61.446 rows=19959 loops=1)
--                Index Cond: (start_geom && '0103000020E6100000010000000500000000000000004054C00000000000C0484000000000004054C06666666666E64340CDCCCCCCCC8C54C06666666666E64340CDCCCCCCCC8C54C00000000000C0484000000000004054C00000000000C04840'::geography)
--                Buffers: shared read=402 written=124
--  Planning:
--    Buffers: shared hit=13 read=4 dirtied=2
--  Planning Time: 4.973 ms
--  Execution Time: 159.885 ms
-- (16 rows)


/* Test Case 2.2 with gist_2 */

SELECT *
FROM accidents
WHERE ST_Intersects(start_geom, 
                    ST_Transform(ST_SetSRID(ST_MakeEnvelope(-81, 49.5, -82.2, 39.8), 4326), 4326)::geography) 
  AND start_time::date BETWEEN '2016-03-01' AND '2016-03-05';



/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */
--   id   | source  | severity |     start_time      |      end_time       | start_lat | start_lng  | end_lat | end_lng | distance_mi |                     start_geom                     | end_geom | centroid_lat | centroid_lng
-- -------+---------+----------+---------------------+---------------------+-----------+------------+---------+---------+-------------+----------------------------------------------------+----------+--------------+--------------
--  A-449 | Source2 |        2 | 2016-03-02 17:52:45 | 2016-03-02 18:22:45 | 41.316475 | -81.649101 |         |         |        0.01 | 0101000020E610000042B3EBDE8A6954C03480B74082A84440 |          |              |
--  A-482 | Source2 |        3 | 2016-03-04 06:39:05 | 2016-03-04 07:09:05 | 41.113785 | -81.611633 |         |         |        0.01 | 0101000020E6100000E109BDFE246754C03FE3C281908E4440 |          |              |
 
 
 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--                                                                                                                                                                           QUERY PLAN
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Gather  (cost=1851.17..134460.67 rows=74 width=156) (actual time=5.352..153.236 rows=2 loops=1)
--    Workers Planned: 2
--    Workers Launched: 2
--    Buffers: shared hit=332 read=5752 written=5362
--    ->  Parallel Bitmap Heap Scan on accidents  (cost=851.17..133453.27 rows=31 width=156) (actual time=73.725..122.564 rows=1 loops=3)
--          Filter: (((start_time)::date >= '2016-03-01'::date) AND ((start_time)::date <= '2016-03-05'::date) AND st_intersects(start_geom, '0103000020E6100000010000000500000000000000004054C00000000000C0484000000000004054C06666666666E64340CDCCCCCCCC8C54C06666666666E64340CDCCCCCCCC8C54C00000000000C0484000000000004054C00000000000C04840'::geography))
--          Rows Removed by Filter: 6652
--          Heap Blocks: exact=2212
--          Buffers: shared hit=332 read=5752 written=5362
--          ->  Bitmap Index Scan on accidents_start_geom_idx9  (cost=0.00..851.15 rows=18515 width=0) (actual time=4.663..4.663 rows=19959 loops=1)
--                Index Cond: (start_geom && '0103000020E6100000010000000500000000000000004054C00000000000C0484000000000004054C06666666666E64340CDCCCCCCCC8C54C06666666666E64340CDCCCCCCCC8C54C00000000000C0484000000000004054C00000000000C04840'::geography)
--                Buffers: shared hit=331 read=176
--  Planning:
--    Buffers: shared hit=14 read=3
--  Planning Time: 9.699 ms
--  Execution Time: 153.290 ms
-- (16 rows)

/* Test Case 2.3 with gist_3 */

SELECT *
FROM accidents
WHERE ST_Intersects(start_geom, 
                    ST_Transform(ST_SetSRID(ST_MakeEnvelope(-85, 49.5, -81, 39.8), 4326), 4326)::geography) 
  AND start_time::date BETWEEN '2016-03-01' AND '2016-03-05';


/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */

--    id   | source  | severity |     start_time      |      end_time       | start_lat | start_lng  | end_lat | end_lng | distance_mi |                     start_geom                     | end_geom | centroid_lat | centroid_lng
-- -------+---------+----------+---------------------+---------------------+-----------+------------+---------+---------+-------------+----------------------------------------------------+----------+--------------+--------------
--  A-426 | Source2 |        2 | 2016-03-01 05:05:42 | 2016-03-01 05:35:42 | 39.945835 | -83.061295 |         |         |           0 | 0101000020E6100000221ADD41ECC354C0C2340C1F11F94340 |          |              |
--  A-429 | Source2 |        2 | 2016-03-01 07:31:53 | 2016-03-01 08:01:53 | 39.927441 | -83.056198 |         |         |        0.01 | 0101000020E610000070067FBF98C354C01AFCFD62B6F64340 |          |              |
--  A-430 | Source2 |        2 | 2016-03-01 07:46:03 | 2016-03-01 08:16:03 | 39.946892 | -82.915489 |         |         |        0.01 | 0101000020E610000041B62C5F97BA54C0096CCEC133F94340 |          |              |
--  A-431 | Source2 |        3 | 2016-03-01 08:16:30 | 2016-03-01 08:46:30 | 40.002552 | -83.118355 |         |         |        0.01 | 0101000020E61000005B94D92093C754C00B45BA9F53004440 |          |              |
--  A-436 | Source2 |        3 | 2016-03-01 11:56:36 | 2016-03-01 12:26:36 | 40.151196 | -84.220032 |         |         |        7.07 | 0101000020E6100000B4041901150E55C09CA4F9635A134440 |          |              |
--  A-437 | Source2 |        2 | 2016-03-01 12:36:27 | 2016-03-01 13:51:27 | 40.033405 | -82.910225 |         |         |        0.01 | 0101000020E61000001AC05B2041BA54C0EE42739D46044440 |          |              |
--  A-439 | Source2 |        2 | 2016-03-01 16:41:08 | 2016-03-01 17:11:08 | 40.080338 | -82.880074 |         |         |        0.01 | 0101000020E6100000D503E62153B854C02250FD83480A4440 |          |              |
--  A-440 | Source2 |        2 | 2016-03-01 17:23:06 | 2016-03-01 18:23:06 | 40.200333 | -83.027435 |         |         |           0 | 0101000020E610000002F1BA7EC1C154C0A0A70183A4194440 |          |              |
--  A-441 | Source2 |        3 | 2016-03-01 17:31:22 | 2016-03-01 18:01:22 |  40.02504 | -82.904129 |         |         |        0.01 | 0101000020E61000005F97E13FDDB954C0C18BBE8234034440 |          |              |
--  A-442 | Source2 |        3 | 2016-03-01 17:39:00 | 2016-03-01 21:00:00 | 40.013062 |  -82.90213 |         |         |        0.01 | 0101000020E610000064AF777FBCB954C00169FF03AC014440 |          |              |
--  A-443 | Source2 |        3 | 2016-03-01 18:07:29 | 2016-03-01 18:37:29 | 40.065559 | -82.906418 |         |         |        0.01 | 0101000020E61000005EA0A4C002BA54C0AF7AC03C64084440 |          |              |
--  A-445 | Source2 |        2 | 2016-03-01 18:52:22 | 2016-03-01 19:22:22 | 39.902195 | -83.084763 |         |         |           0 | 0101000020E61000004B3ACAC16CC554C0AFCE31207BF34340 |          |              |
--  A-446 | Source2 |        3 | 2016-03-02 16:36:08 | 2016-03-02 17:06:08 | 41.370506 | -83.616997 |         |         |        0.01 | 0101000020E6100000BA2EFCE07CE754C0637C98BD6CAF4440 |          |              |
--  A-447 | Source2 |        2 | 2016-03-02 17:12:54 | 2016-03-02 17:42:54 | 39.945427 | -82.846558 |         |         |        0.01 | 0101000020E6100000B30A9B012EB654C0B1E07EC003F94340 |          |              |
--  A-448 | Source2 |        3 | 2016-03-02 17:32:51 | 2016-03-02 18:02:51 | 39.945751 | -82.846252 |         |         |        0.01 | 0101000020E61000002D0B26FE28B654C06494675E0EF94340 |          |              |
--  A-449 | Source2 |        2 | 2016-03-02 17:52:45 | 2016-03-02 18:22:45 | 41.316475 | -81.649101 |         |         |        0.01 | 0101000020E610000042B3EBDE8A6954C03480B74082A84440 |          |              |
--  A-453 | Source2 |        2 | 2016-03-03 04:51:44 | 2016-03-03 05:21:44 | 40.005947 | -82.858887 |         |         |           0 | 0101000020E610000069FD2D01F8B654C031410DDFC2004440 |          |              |
--  A-455 | Source2 |        3 | 2016-03-03 06:51:45 | 2016-03-03 07:21:45 | 40.030914 | -82.994598 |         |         |        0.01 | 0101000020E6100000B0AA5E7EA7BF54C0897E6DFDF4034440 |          |              |
--  A-458 | Source2 |        3 | 2016-03-03 07:44:53 | 2016-03-03 08:14:53 | 39.976398 | -83.119225 |         |         |        0.01 | 0101000020E610000066F7E461A1C754C09EF0129CFAFC4340 |          |              |
--  A-459 | Source2 |        3 | 2016-03-03 07:45:33 | 2016-03-03 08:15:33 | 39.948391 | -82.943558 |         |         |        0.01 | 0101000020E610000044F8174163BC54C00E6954E064F94340 |          |              |
--  A-463 | Source2 |        3 | 2016-03-03 09:42:54 | 2016-03-03 10:12:54 | 39.939571 | -83.009911 |         |         |        0.01 | 0101000020E6100000B937BF61A2C054C090A2CEDC43F84340 |          |              |
--  A-465 | Source2 |        2 | 2016-03-03 11:28:29 | 2016-03-03 11:58:29 | 39.815628 | -84.093338 |         |         |           0 | 0101000020E6100000575EF23FF90555C0D7D9907F66E84340 |          |              |
--  A-471 | Source2 |        2 | 2016-03-03 15:07:36 | 2016-03-03 15:37:36 | 39.919437 | -82.775238 |         |         |           0 | 0101000020E61000007427D87F9DB154C0BEDD921CB0F54340 |          |              |
--  A-472 | Source2 |        2 | 2016-03-03 16:11:40 | 2016-03-03 16:41:40 | 39.972076 | -83.098183 |         |         |        0.01 | 0101000020E61000007C8159A148C654C0FE9C82FC6CFC4340 |          |              |
--  A-476 | Source2 |        3 | 2016-03-03 18:30:12 | 2016-03-03 19:00:12 | 39.934155 | -82.852524 |         |         |        0.01 | 0101000020E610000087C3D2C08FB654C08B321B6492F74340 |          |              |
--  A-478 | Source2 |        3 | 2016-03-03 20:04:00 | 2016-03-03 21:00:00 | 40.045822 | -83.033424 |         |         |        0.01 | 0101000020E6100000B2B96A9E23C254C0FAB7CB7EDD054440 |          |              |
--  A-479 | Source2 |        3 | 2016-03-03 20:21:07 | 2016-03-03 20:51:07 | 40.051949 | -83.032806 |         |         |        0.01 | 0101000020E61000003447567E19C254C0AB07CC43A6064440 |          |              |
--  A-480 | Source2 |        2 | 2016-03-04 06:10:42 | 2016-03-04 06:40:42 | 39.943745 | -83.073151 |         |         |        0.01 | 0101000020E6100000DC2A8881AEC454C0BB61DBA2CCF84340 |          |              |
--  A-481 | Source2 |        3 | 2016-03-04 06:11:18 | 2016-03-04 06:41:18 |  39.89217 | -83.039169 |         |         |        0.01 | 0101000020E61000001781B1BE81C254C0753C66A032F24340 |          |              |
--  A-482 | Source2 |        3 | 2016-03-04 06:39:05 | 2016-03-04 07:09:05 | 41.113785 | -81.611633 |         |         |        0.01 | 0101000020E6100000E109BDFE246754C03FE3C281908E4440 |          |              |
--  A-483 | Source2 |        3 | 2016-03-04 06:43:09 | 2016-03-04 07:13:09 | 39.948158 | -83.036201 |         |         |        0.01 | 0101000020E610000048C5FF1D51C254C06BB8C83D5DF94340 |          |              |
--  A-484 | Source2 |        3 | 2016-03-04 06:44:45 | 2016-03-04 07:14:45 | 39.819839 | -84.189087 |         |         |        0.01 | 0101000020E610000052465C001A0C55C0207EFE7BF0E84340 |          |              |
--  A-489 | Source2 |        3 | 2016-03-04 07:37:31 | 2016-03-04 08:07:31 | 41.351006 | -83.622826 |         |         |        0.01 | 0101000020E61000004E469561DCE754C09259BDC3EDAC4440 |          |              |
--  A-491 | Source2 |        2 | 2016-03-04 07:59:13 | 2016-03-04 08:29:13 | 39.943653 | -83.060631 |         |         |           0 | 0101000020E6100000EC87D860E1C354C0DAE21A9FC9F84340 |          |              |
--  A-492 | Source2 |        2 | 2016-03-04 08:01:42 | 2016-03-04 08:31:42 | 39.985336 | -82.789841 |         |         |        0.01 | 0101000020E61000008E0244C18CB254C025C9737D1FFE4340 |          |              |
--  A-493 | Source2 |        3 | 2016-03-04 08:06:17 | 2016-03-04 08:36:17 | 40.077419 | -82.907898 |         |         |        0.01 | 0101000020E6100000A58636001BBA54C0658BA4DDE8094440 |          |              |
--  A-495 | Source2 |        2 | 2016-03-04 08:24:47 | 2016-03-04 08:54:47 | 40.083298 | -84.117058 |         |         |        0.01 | 0101000020E61000000D6FD6E07D0755C03EE94482A90A4440 |          |              |
--  A-496 | Source2 |        2 | 2016-03-04 08:33:12 | 2016-03-04 09:03:12 | 40.089439 | -83.036194 |         |         |        0.01 | 0101000020E6100000EE93A30051C254C054FEB5BC720B4440 |          |              |
--  A-501 | Source2 |        2 | 2016-03-04 14:55:28 | 2016-03-04 15:25:28 |  39.95232 | -83.037613 |         |         |           0 | 0101000020E6100000E2395B4068C254C0D2A92B9FE5F94340 |          |              |
--  A-502 | Source2 |        2 | 2016-03-04 16:46:11 | 2016-03-04 17:16:11 |  40.01757 | -82.928978 |         |         |        0.01 | 0101000020E6100000062D246074BB54C003B2D7BB3F024440 |          |              |
--  A-503 | Source2 |        2 | 2016-03-04 17:31:00 | 2016-03-04 21:00:00 | 39.956528 | -83.018555 |         |         |        0.01 | 0101000020E6100000598B4F0130C154C0A9DA6E826FFA4340 |          |              |
--  A-504 | Source2 |        2 | 2016-03-04 17:28:40 | 2016-03-04 17:58:40 | 39.939571 | -83.009911 |         |         |        0.01 | 0101000020E6100000B937BF61A2C054C090A2CEDC43F84340 |          |              |
--  A-506 | Source2 |        3 | 2016-03-05 07:07:25 | 2016-03-05 07:37:25 | 41.137856 | -83.658844 |         |         |        0.01 | 0101000020E61000009D4A06802AEA54C058C7F143A5914440 |          |              |
-- (43 rows)

 /* QUERY PLAN:
COPT PASTE THE RETURNED QUERY PLAN HERE
 */

--                                                                                                                                                                           QUERY PLAN
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Gather  (cost=3214.18..305606.95 rows=248 width=156) (actual time=138.183..261.219 rows=43 loops=1)
--    Workers Planned: 2
--    Workers Launched: 2
--    Buffers: shared hit=325 read=7708 written=4887
--    ->  Parallel Bitmap Heap Scan on accidents  (cost=2214.18..304582.15 rows=103 width=156) (actual time=169.410..242.829 rows=14 loops=3)
--          Filter: (((start_time)::date >= '2016-03-01'::date) AND ((start_time)::date <= '2016-03-05'::date) AND st_intersects(start_geom, '0103000020E6100000010000000500000000000000004055C00000000000C0484000000000004055C06666666666E6434000000000004054C06666666666E6434000000000004054C00000000000C0484000000000004055C00000000000C04840'::geography))
--          Rows Removed by Filter: 15104
--          Heap Blocks: exact=2503
--          Buffers: shared hit=325 read=7708 written=4887
--          ->  Bitmap Index Scan on accidents_start_geom_idx9  (cost=0.00..2214.11 rows=48244 width=0) (actual time=137.215..137.217 rows=45356 loops=1)
--                Index Cond: (start_geom && '0103000020E6100000010000000500000000000000004055C00000000000C0484000000000004055C06666666666E6434000000000004054C06666666666E6434000000000004054C00000000000C0484000000000004055C00000000000C04840'::geography)
--                Buffers: shared read=798 written=383
--  Planning:
--    Buffers: shared hit=17
--  Planning Time: 3.699 ms
--  Execution Time: 261.255 ms
-- (16 rows)

/* Test Case 3.1 with BRIN_1 */

CREATE INDEX ON accidents USING BRIN (start_geom);

SELECT *
FROM accidents
WHERE ST_Intersects(start_geom, 
                    ST_Transform(ST_SetSRID(ST_MakeEnvelope(-81, 49.5, -82.2, 39.8), 4326), 4326)::geography) 
  AND start_time::date BETWEEN '2016-02-09' AND '2016-02-10';



/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */
--   id  | source  | severity |     start_time      |      end_time       | start_lat | start_lng  | end_lat | end_lng | distance_mi |                     start_geom                     | end_geom | centroid_lat | centroid_lng
-- ------+---------+----------+---------------------+---------------------+-----------+------------+---------+---------+-------------+----------------------------------------------------+----------+--------------+--------------
--  A-68 | Source2 |        3 | 2016-02-09 08:20:30 | 2016-02-09 08:50:30 | 41.407391 | -81.646767 |         |         |        0.01 | 0101000020E610000073486AA1646954C0A5D7666325B44440 |          |              |
--  A-69 | Source2 |        3 | 2016-02-09 08:35:53 | 2016-02-09 09:05:53 | 41.424404 | -81.578674 |         |         |        0.01 | 0101000020E6100000EA42ACFE086554C05325CADE52B64440 |          |              |
--  A-85 | Source2 |        3 | 2016-02-10 17:10:00 | 2016-02-10 23:59:00 | 41.040714 | -81.613144 |         |         |        0.01 | 0101000020E610000046EF54C03D6754C0A33EC91D36854440 |          |              |
--  A-86 | Source2 |        3 | 2016-02-10 18:09:00 | 2016-02-10 23:59:00 | 41.083679 | -81.579002 |         |         |        1.28 | 0101000020E61000006494675E0E6554C0552E54FEB58A4440 |          |              |
-- (4 rows)

/**Query plan**/
                                                                                                                                                                      QUERY PLAN
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Index Scan using accidents_start_geom_idx9 on accidents  (cost=0.29..294986.95 rows=74 width=156) (actual time=7.659..15.197 rows=4 loops=1)
--    Index Cond: (start_geom && '0103000020E6100000010000000500000000000000004054C00000000000C0484000000000004054C06666666666E64340CDCCCCCCCC8C54C06666666666E64340CDCCCCCCCC8C54C00000000000C0484000000000004054C00000000000C04840'::geography)
--    Filter: (((start_time)::date >= '2016-02-09'::date) AND ((start_time)::date <= '2016-02-10'::date) AND st_intersects(start_geom, '0103000020E6100000010000000500000000000000004054C00000000000C0484000000000004054C06666666666E64340CDCCCCCCCC8C54C06666666666E64340CDCCCCCCCC8C54C00000000000C0484000000000004054C00000000000C04840'::geography))
--    Rows Removed by Filter: 19955
--    Buffers: shared hit=18852 read=13
--  Planning:
--    Buffers: shared hit=434 read=26
--  Planning Time: 9.541 ms
--  Execution Time: 15.770 ms
-- (9 rows)


/* Test Case 3.2 with BRIN_2 */


CREATE INDEX ON accidents USING BRIN (start_geom);

SELECT *
FROM accidents
WHERE ST_Intersects(start_geom, 
                    ST_Transform(ST_SetSRID(ST_MakeEnvelope(-81, 49.5, -82.2, 39.8), 4326), 4326)::geography) 
  AND start_time::date BETWEEN '2016-03-01' AND '2016-03-05';

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */
--   id   | source  | severity |     start_time      |      end_time       | start_lat | start_lng  | end_lat | end_lng | distance_mi |                     start_geom                     | end_geom | centroid_lat | centroid_lng
-- -------+---------+----------+---------------------+---------------------+-----------+------------+---------+---------+-------------+----------------------------------------------------+----------+--------------+--------------
--  A-449 | Source2 |        2 | 2016-03-02 17:52:45 | 2016-03-02 18:22:45 | 41.316475 | -81.649101 |         |         |        0.01 | 0101000020E610000042B3EBDE8A6954C03480B74082A84440 |          |              |
--  A-482 | Source2 |        3 | 2016-03-04 06:39:05 | 2016-03-04 07:09:05 | 41.113785 | -81.611633 |         |         |        0.01 | 0101000020E6100000E109BDFE246754C03FE3C281908E4440 |          |              |
-- (2 rows)

/**Query plan**/
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Index Scan using accidents_start_geom_idx9 on accidents  (cost=0.29..294986.95 rows=74 width=156) (actual time=2.288..9.352 rows=2 loops=1)
--    Index Cond: (start_geom && '0103000020E6100000010000000500000000000000004054C00000000000C0484000000000004054C06666666666E64340CDCCCCCCCC8C54C06666666666E64340CDCCCCCCCC8C54C00000000000C0484000000000004054C00000000000C04840'::geography)
--    Filter: (((start_time)::date >= '2016-03-01'::date) AND ((start_time)::date <= '2016-03-05'::date) AND st_intersects(start_geom, '0103000020E6100000010000000500000000000000004054C00000000000C0484000000000004054C06666666666E64340CDCCCCCCCC8C54C06666666666E64340CDCCCCCCCC8C54C00000000000C0484000000000004054C00000000000C04840'::geography))
--    Rows Removed by Filter: 19957
--    Buffers: shared hit=18758
--  Planning:
--    Buffers: shared hit=22
--  Planning Time: 3.971 ms
--  Execution Time: 9.373 ms
-- (9 rows)

/* Test Case 3.2 with BRIN_2 */

CREATE INDEX ON accidents USING BRIN (start_geom);

EXPLAIN (ANALYZE ON, BUFFERS ON)

SELECT *
FROM accidents
WHERE ST_Intersects(start_geom, 
                    ST_Transform(ST_SetSRID(ST_MakeEnvelope(-85, 49.5, -81, 39.8), 4326), 4326)::geography) 
  AND start_time::date BETWEEN '2016-03-01' AND '2016-03-05';

/* Outputs:
COPT PASTE THE RETURNED OUTPUTS HERE */
--   id   | source  | severity |     start_time      |      end_time       | start_lat | start_lng  | end_lat | end_lng | distance_mi |                     start_geom                     | end_geom | centroid_lat | centroid_lng
-- -------+---------+----------+---------------------+---------------------+-----------+------------+---------+---------+-------------+----------------------------------------------------+----------+--------------+--------------
--  A-426 | Source2 |        2 | 2016-03-01 05:05:42 | 2016-03-01 05:35:42 | 39.945835 | -83.061295 |         |         |           0 | 0101000020E6100000221ADD41ECC354C0C2340C1F11F94340 |          |              |
--  A-429 | Source2 |        2 | 2016-03-01 07:31:53 | 2016-03-01 08:01:53 | 39.927441 | -83.056198 |         |         |        0.01 | 0101000020E610000070067FBF98C354C01AFCFD62B6F64340 |          |              |
--  A-481 | Source2 |        3 | 2016-03-04 06:11:18 | 2016-03-04 06:41:18 |  39.89217 | -83.039169 |         |         |        0.01 | 0101000020E61000001781B1BE81C254C0753C66A032F24340 |          |              |
--  A-483 | Source2 |        3 | 2016-03-04 06:43:09 | 2016-03-04 07:13:09 | 39.948158 | -83.036201 |         |         |        0.01 | 0101000020E610000048C5FF1D51C254C06BB8C83D5DF94340 |          |              |
--  A-491 | Source2 |        2 | 2016-03-04 07:59:13 | 2016-03-04 08:29:13 | 39.943653 | -83.060631 |         |         |           0 | 0101000020E6100000EC87D860E1C354C0DAE21A9FC9F84340 |          |              |
--  A-501 | Source2 |        2 | 2016-03-04 14:55:28 | 2016-03-04 15:25:28 |  39.95232 | -83.037613 |         |         |           0 | 0101000020E6100000E2395B4068C254C0D2A92B9FE5F94340 |          |              |
--  A-449 | Source2 |        2 | 2016-03-02 17:52:45 | 2016-03-02 18:22:45 | 41.316475 | -81.649101 |         |         |        0.01 | 0101000020E610000042B3EBDE8A6954C03480B74082A84440 |          |              |
--  A-446 | Source2 |        3 | 2016-03-02 16:36:08 | 2016-03-02 17:06:08 | 41.370506 | -83.616997 |         |         |        0.01 | 0101000020E6100000BA2EFCE07CE754C0637C98BD6CAF4440 |          |              |
--  A-489 | Source2 |        3 | 2016-03-04 07:37:31 | 2016-03-04 08:07:31 | 41.351006 | -83.622826 |         |         |        0.01 | 0101000020E61000004E469561DCE754C09259BDC3EDAC4440 |          |              |
--  A-506 | Source2 |        3 | 2016-03-05 07:07:25 | 2016-03-05 07:37:25 | 41.137856 | -83.658844 |         |         |        0.01 | 0101000020E61000009D4A06802AEA54C058C7F143A5914440 |          |              |
--  A-482 | Source2 |        3 | 2016-03-04 06:39:05 | 2016-03-04 07:09:05 | 41.113785 | -81.611633 |         |         |        0.01 | 0101000020E6100000E109BDFE246754C03FE3C281908E4440 |          |              |
--  A-436 | Source2 |        3 | 2016-03-01 11:56:36 | 2016-03-01 12:26:36 | 40.151196 | -84.220032 |         |         |        7.07 | 0101000020E6100000B4041901150E55C09CA4F9635A134440 |          |              |
--  A-458 | Source2 |        3 | 2016-03-03 07:44:53 | 2016-03-03 08:14:53 | 39.976398 | -83.119225 |         |         |        0.01 | 0101000020E610000066F7E461A1C754C09EF0129CFAFC4340 |          |              |
--  A-472 | Source2 |        2 | 2016-03-03 16:11:40 | 2016-03-03 16:41:40 | 39.972076 | -83.098183 |         |         |        0.01 | 0101000020E61000007C8159A148C654C0FE9C82FC6CFC4340 |          |              |
--  A-492 | Source2 |        2 | 2016-03-04 08:01:42 | 2016-03-04 08:31:42 | 39.985336 | -82.789841 |         |         |        0.01 | 0101000020E61000008E0244C18CB254C025C9737D1FFE4340 |          |              |
--  A-442 | Source2 |        3 | 2016-03-01 17:39:00 | 2016-03-01 21:00:00 | 40.013062 |  -82.90213 |         |         |        0.01 | 0101000020E610000064AF777FBCB954C00169FF03AC014440 |          |              |
--  A-453 | Source2 |        2 | 2016-03-03 04:51:44 | 2016-03-03 05:21:44 | 40.005947 | -82.858887 |         |         |           0 | 0101000020E610000069FD2D01F8B654C031410DDFC2004440 |          |              |
--  A-502 | Source2 |        2 | 2016-03-04 16:46:11 | 2016-03-04 17:16:11 |  40.01757 | -82.928978 |         |         |        0.01 | 0101000020E6100000062D246074BB54C003B2D7BB3F024440 |          |              |
--  A-437 | Source2 |        2 | 2016-03-01 12:36:27 | 2016-03-01 13:51:27 | 40.033405 | -82.910225 |         |         |        0.01 | 0101000020E61000001AC05B2041BA54C0EE42739D46044440 |          |              |
--  A-441 | Source2 |        3 | 2016-03-01 17:31:22 | 2016-03-01 18:01:22 |  40.02504 | -82.904129 |         |         |        0.01 | 0101000020E61000005F97E13FDDB954C0C18BBE8234034440 |          |              |
--  A-439 | Source2 |        2 | 2016-03-01 16:41:08 | 2016-03-01 17:11:08 | 40.080338 | -82.880074 |         |         |        0.01 | 0101000020E6100000D503E62153B854C02250FD83480A4440 |          |              |
--  A-493 | Source2 |        3 | 2016-03-04 08:06:17 | 2016-03-04 08:36:17 | 40.077419 | -82.907898 |         |         |        0.01 | 0101000020E6100000A58636001BBA54C0658BA4DDE8094440 |          |              |
--  A-440 | Source2 |        2 | 2016-03-01 17:23:06 | 2016-03-01 18:23:06 | 40.200333 | -83.027435 |         |         |           0 | 0101000020E610000002F1BA7EC1C154C0A0A70183A4194440 |          |              |
--  A-496 | Source2 |        2 | 2016-03-04 08:33:12 | 2016-03-04 09:03:12 | 40.089439 | -83.036194 |         |         |        0.01 | 0101000020E6100000EE93A30051C254C054FEB5BC720B4440 |          |              |
--  A-443 | Source2 |        3 | 2016-03-01 18:07:29 | 2016-03-01 18:37:29 | 40.065559 | -82.906418 |         |         |        0.01 | 0101000020E61000005EA0A4C002BA54C0AF7AC03C64084440 |          |              |
--  A-455 | Source2 |        3 | 2016-03-03 06:51:45 | 2016-03-03 07:21:45 | 40.030914 | -82.994598 |         |         |        0.01 | 0101000020E6100000B0AA5E7EA7BF54C0897E6DFDF4034440 |          |              |
--  A-463 | Source2 |        3 | 2016-03-03 09:42:54 | 2016-03-03 10:12:54 | 39.939571 | -83.009911 |         |         |        0.01 | 0101000020E6100000B937BF61A2C054C090A2CEDC43F84340 |          |              |
--  A-504 | Source2 |        2 | 2016-03-04 17:28:40 | 2016-03-04 17:58:40 | 39.939571 | -83.009911 |         |         |        0.01 | 0101000020E6100000B937BF61A2C054C090A2CEDC43F84340 |          |              |
--  A-480 | Source2 |        2 | 2016-03-04 06:10:42 | 2016-03-04 06:40:42 | 39.943745 | -83.073151 |         |         |        0.01 | 0101000020E6100000DC2A8881AEC454C0BB61DBA2CCF84340 |          |              |
--  A-465 | Source2 |        2 | 2016-03-03 11:28:29 | 2016-03-03 11:58:29 | 39.815628 | -84.093338 |         |         |           0 | 0101000020E6100000575EF23FF90555C0D7D9907F66E84340 |          |              |
--  A-459 | Source2 |        3 | 2016-03-03 07:45:33 | 2016-03-03 08:15:33 | 39.948391 | -82.943558 |         |         |        0.01 | 0101000020E610000044F8174163BC54C00E6954E064F94340 |          |              |
--  A-430 | Source2 |        2 | 2016-03-01 07:46:03 | 2016-03-01 08:16:03 | 39.946892 | -82.915489 |         |         |        0.01 | 0101000020E610000041B62C5F97BA54C0096CCEC133F94340 |          |              |
--  A-445 | Source2 |        2 | 2016-03-01 18:52:22 | 2016-03-01 19:22:22 | 39.902195 | -83.084763 |         |         |           0 | 0101000020E61000004B3ACAC16CC554C0AFCE31207BF34340 |          |              |
--  A-471 | Source2 |        2 | 2016-03-03 15:07:36 | 2016-03-03 15:37:36 | 39.919437 | -82.775238 |         |         |           0 | 0101000020E61000007427D87F9DB154C0BEDD921CB0F54340 |          |              |
--  A-476 | Source2 |        3 | 2016-03-03 18:30:12 | 2016-03-03 19:00:12 | 39.934155 | -82.852524 |         |         |        0.01 | 0101000020E610000087C3D2C08FB654C08B321B6492F74340 |          |              |
--  A-478 | Source2 |        3 | 2016-03-03 20:04:00 | 2016-03-03 21:00:00 | 40.045822 | -83.033424 |         |         |        0.01 | 0101000020E6100000B2B96A9E23C254C0FAB7CB7EDD054440 |          |              |
--  A-479 | Source2 |        3 | 2016-03-03 20:21:07 | 2016-03-03 20:51:07 | 40.051949 | -83.032806 |         |         |        0.01 | 0101000020E61000003447567E19C254C0AB07CC43A6064440 |          |              |
--  A-484 | Source2 |        3 | 2016-03-04 06:44:45 | 2016-03-04 07:14:45 | 39.819839 | -84.189087 |         |         |        0.01 | 0101000020E610000052465C001A0C55C0207EFE7BF0E84340 |          |              |
--  A-431 | Source2 |        3 | 2016-03-01 08:16:30 | 2016-03-01 08:46:30 | 40.002552 | -83.118355 |         |         |        0.01 | 0101000020E61000005B94D92093C754C00B45BA9F53004440 |          |              |
--  A-503 | Source2 |        2 | 2016-03-04 17:31:00 | 2016-03-04 21:00:00 | 39.956528 | -83.018555 |         |         |        0.01 | 0101000020E6100000598B4F0130C154C0A9DA6E826FFA4340 |          |              |
--  A-447 | Source2 |        2 | 2016-03-02 17:12:54 | 2016-03-02 17:42:54 | 39.945427 | -82.846558 |         |         |        0.01 | 0101000020E6100000B30A9B012EB654C0B1E07EC003F94340 |          |              |
--  A-448 | Source2 |        3 | 2016-03-02 17:32:51 | 2016-03-02 18:02:51 | 39.945751 | -82.846252 |         |         |        0.01 | 0101000020E61000002D0B26FE28B654C06494675E0EF94340 |          |              |
--  A-495 | Source2 |        2 | 2016-03-04 08:24:47 | 2016-03-04 08:54:47 | 40.083298 | -84.117058 |         |         |        0.01 | 0101000020E61000000D6FD6E07D0755C03EE94482A90A4440 |          |              |
-- (43 rows)

/**Query plan**/


-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Index Scan using accidents_start_geom_idx9 on accidents  (cost=0.29..735705.00 rows=248 width=156) (actual time=0.899..25.026 rows=43 loops=1)
--    Index Cond: (start_geom && '0103000020E6100000010000000500000000000000004055C00000000000C0484000000000004055C06666666666E6434000000000004054C06666666666E6434000000000004054C00000000000C0484000000000004055C00000000000C04840'::geography)
--    Filter: (((start_time)::date >= '2016-03-01'::date) AND ((start_time)::date <= '2016-03-05'::date) AND st_intersects(start_geom, '0103000020E6100000010000000500000000000000004055C00000000000C0484000000000004055C06666666666E6434000000000004054C06666666666E6434000000000004054C00000000000C0484000000000004055C00000000000C04840'::geography))
--    Rows Removed by Filter: 45313
--    Buffers: shared hit=41230
--  Planning:
--    Buffers: shared hit=24
--  Planning Time: 7.293 ms
--  Execution Time: 25.060 ms
-- (9 rows)