--- Start of data cleaning---

----check column names and data types----
/*
SELECT column_name, data_type 
FROM `cycle-case-study-443823.2020_trips.INFORMATION_SCHEMA.COLUMNS`
*/

---- check for NULL values----
/*
SELECT 
  COUNTIF(ride_id IS NULL) AS ride_id_null_count,
  COUNTIF(started_at IS NULL) AS started_at_null_count,
  COUNTIF(ended_at IS NULL) AS ended_at_null_count, 
  COUNTIF(start_station_name IS NULL) AS start_station_name_null_count,
  COUNTIF(start_station_id IS NULL) AS start_station_id_null_count,
  COUNTIF(end_station_name IS NULL) AS  end_station_name_null_count, -- 1 NULL value returned 
  COUNTIF(end_station_id IS NULL) AS end_station_id_null_count,-- 1 NULL value returned 
  COUNTIF(rideable_type IS NULL) AS rideable_type_null_count,
  COUNTIF(member_casual IS NULL) AS member_casual_null_count,
FROM `cycle-case-study-443823.2020_trips.trips`;
*/


----further check for valid end_station_id or coordinates that could infer the row end_station_name
/*
SELECT *
FROM `cycle-case-study-443823.2020_trips.trips`
WHERE end_station_name IS NULL;
---- end_station_id and end_station_name both return NULL
*/

------removed row with end_station_name and end_station_id with NULL values created new table----
/*
REATE OR REPLACE TABLE `cycle-case-study-443823.2020_trips.cleaned_trips` AS
SELECT *
FROM `cycle-case-study-443823.2020_trips.trips`
WHERE end_station_name IS NOT NULL AND end_station_id IS NOT NULL;
*/

---- missing value original row count----
/*
SELECT COUNT(*) AS original_row_count  -- orginal row count 42687
  FROM `cycle-case-study-443823.2020_trips.trips` 
*/

---- cleaned new row count ----
/*
 SELECT COUNT(*) AS cleaned_row_count
FROM `cycle-case-study-443823.2020_trips.cleaned_trips` -- new row count 426886
*/

---- checking for duplicates----
/*
SELECT 
    ride_id, 
    start_station_id, 
    end_station_id, 
    started_at, 
    ended_at, 
    COUNT(*) AS duplicate_count
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
GROUP BY 
    ride_id, 
    start_station_id, 
    end_station_id, 
    started_at, 
    ended_at
HAVING COUNT(*) > 1;
*/
---- no data to display ----

----check columns for outliers. Using started_at, ended_at dataypes to calclate rider duration in time ----

/*SELECT 
  TIMESTAMP_DIFF(ended_at,started_at, SECOND) AS ride_duration_seconds
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
limit 10
*/

----inspect the Calculated Column: Check for any unusually high or low values (e.g., negative durations or extremely large numbers) un an aggregated summary to get descriptive statistics: minimum, maximum, average----
/*
SELECT 
  MIN(ride_duration_seconds) AS min_duration, --- returned -552. further investigation needed into data 
  MAX(ride_duration_seconds) AS max_duration_seconds,
  AVG(ride_duration_seconds) AS avg_duration
FROM (
  SELECT 
    timestamp_diff(ended_at, started_at, SECOND) AS ride_duration_seconds
  FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
  );
*/

---inspection of records for issue identifcation on negative durations----  
/*
SELECT *
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
WHERE TIMESTAMP_DIFF(ended_at, started_at, SECOND) < 0 -- start_station_id and end_station_id 675 returns all     100 rows with negative duration. Possible problematic rows.This suggests that the negative durations might be related to entries where the start and end stations are incorrectly recorded as the same station, which could lead to unexpected results, such as an "end time" being before the "start time."
LIMIT 100;
*/

----pattern confirmation for station 675. verify if the negative durations are only occurring for this specific station----
/*
SELECT *
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
WHERE  TIMESTAMP_DIFF(ended_at, started_at, SECOND) < 0
AND (start_station_id = 675 OR end_station_id = 675)
LIMIT 100;
*/

----create a new table by replacing the exsitng one  with removed rows that have negative duration -----
/*
CREATE OR REPLACE TABLE `cycle-case-study-443823.2020_trips.cleaned_trips` AS 
SELECT *
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
WHERE TIMESTAMP_DIFF(ended_at, started_at, SECOND) >= 0;
*/

----verify rows with negative duration----
/*
SELECT COUNT(*) AS negative_duration_count
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
WHERE TIMESTAMP_DIFF(ended_at, started_at, SECOND) < 0;---returns 0
*/

----verify minumun duration is not negative timestamp ----
/*
SELECT  min(timestamp_diff(ended_at, started_at, SECOND)) AS min_duration
FROM `cycle-case-study-443823.2020_trips.cleaned_trips` -- returns 0
*/


---- calculate the distance between two latitude and longitude points. Calculate the distance in kilometers and add it as a new column using the Haversine formula.This formula determines the great-circle distance between two points on a sphere, which is ideal for measuring geographic distances.

/*CREATE OR REPLACE TABLE `cycle-case-study-443823.2020_trips.cleaned_trips` AS
SELECT *,
 6371 * ACOS(
    LEAST(1, GREATEST(-1, 
      COS(start_lat * 3.141592653589793 / 180) * COS(end_lat * 3.141592653589793 / 180) *
      COS((end_lng - start_lng) * 3.141592653589793 / 180) +
      SIN(start_lat * 3.141592653589793 / 180) * SIN(end_lat * 3.141592653589793 / 180)
    ))
  ) AS trip_distance_km
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`;
*/

----run query----
/*
SELECT trip_distance_km
from `cycle-case-study-443823.2020_trips.cleaned_trips` --- all rows returned with values of 0.0
LIMIT 10
*/

---Check for possible identical latitide and longitude vlaues--
/*
SELECT 
  COUNTIF(start_lat = end_lat AND start_lng = end_lng) AS identical_cordinate_count,
  COUNT(*) AS total_rows
FROM `cycle-case-study-443823.2020_trips.cleaned_trips` limit 10;

*/

--remove rows with indentical lat/lng--
/*
CREATE OR REPLACE TABLE `cycle-case-study-443823.2020_trips.cleaned_trips` AS 
SELECT *
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
WHERE NOT  (start_lat = end_lat AND start_lng = end_lng);
*/

---- verify change of removed rows----
/*
SELECT COUNT(*) AS total_rows
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
*/

-----check for extreme or unrealistic values.Identify rows with unusually large or small distances that may indicate errors in the data.------
/*
SELECT MIN(trip_distance_km) AS min_distance,--- 0.0349
       MAX(trip_distance_km) AS max_distance,--- 23.096
       AVG(trip_distance_km) AS avg_distance --- 1.9425

FROM `cycle-case-study-443823.2020_trips.cleaned_trips`;
*/

----query to find missing values in key columns---
/*
SELECT
  COUNTIF(start_station_id IS NULL) AS missing_start_station,
  COUNTIF(end_station_id IS NULL) AS missing_end_station,
  COUNTIF(start_lat IS NULL) AS missing_start_lat,
  COUNTIF(start_lng IS NULL) AS missing_start_lng,
  COUNTIF(end_lat IS NULL) AS missing_end_lat,
  COUNTIF(end_lng IS NULL) AS missing_end_ling
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`; --- row returned with 0 in all columns
*/

----check for redundant columns or unused columns. list all column names
/*
SELECT *
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
LIMIT 1;
*/

----check unique values---

/*
SELECT COUNT(DISTINCT ) AS unique_values, COUNT(*) AS total_values --- rideable_type as 1 unique value
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
*/

----list columns and descriptions----
/*
SELECT COLUMN_NAME,DATA_TYPE
FROM `cycle-case-study-443823.2020_trips.INFORMATION_SCHEMA.COLUMNS`
WHERE TABLE_NAME = 'cleaned_trips';
*/

--new query to create/replace table with relevant rows---
/*
CREATE OR REPLACE TABLE `cycle-case-study-443823.2020_trips.focused_trips` AS 
SELECT  
  started_at,
  ended_at,
  trip_distance_km,
  start_lat,
  start_lng,
  end_lat,
  end_lng,
  member_casual
FROM `cycle-case-study-443823.2020_trips.cleaned_trips`
*/

---verify there are no negative duration times-----
/*
SELECT COUNT(*) AS negative_duration_count
FROM `cycle-case-study-443823.2020_trips.focused_trips`
WHERE TIMESTAMP_DIFF(ended_at, started_at, SECOND) < 0;  ----returns 0
*/

---verifying there are no anomolie values-----
/*
SELECT 
  MIN(trip_distance_km) AS min_distance,
  MAX(trip_distance_km) AS max_distance,
  AVG(trip_distance_km) AS avg_distance
FROM `cycle-case-study-443823.2020_trips.focused_trips` 
*/


--- verifying there are no missing values---
/*
SELECT
  COUNTIF(started_at IS NULL) AS missing_started_at, 
  COUNTIF(ended_at IS NULL) AS missing_ended_at,
  COUNTIF(trip_distance_km IS NULL) AS missing_trip_distance_km,
  COUNTIF(member_casual IS NULL) AS missing_member_casual
FROM `cycle-case-study-443823.2020_trips.focused_trips`;
*/
---- data cleaning completed----------