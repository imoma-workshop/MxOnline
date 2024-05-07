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

Add geom columns
ALTER TABLE accidents
ADD COLUMN start_geom GEOGRAPHY(POINT, 4326),
ADD COLUMN end_geom GEOGRAPHY(POINT, 4326);

Update geom columns based on lat and lng
UPDATE accidents
SET start_geom = ST_SetSRID(ST_MakePoint(start_lng, start_lat), 4326),
    end_geom = ST_SetSRID(ST_MakePoint(end_lng, end_lat), 4326);

-- create gist-index on start_geom, end_geom
create index
CREATE INDEX idx_start_geom ON accidents USING GIST (start_geom);
CREATE INDEX idx_end_geom ON accidents USING GIST (end_geom);

-- Create B-Tree index on start_lat and start_lng
CREATE INDEX idx_accidents_btree ON accidents USING BTREE (start_lat, start_lng);	

/* 
Query Task 1:
find k nearest neighbours (data points) of a given trajectory for a given date
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
find the trajectory that is shortest and fastest from given data point to another.
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

/* Test Case 2.1 with B_TREE_INDEX */
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

/* 
Query Task 3:
DESCRIBE YOUR QUERY TASK HERE 

follow the same formats as query task 1 

*/

