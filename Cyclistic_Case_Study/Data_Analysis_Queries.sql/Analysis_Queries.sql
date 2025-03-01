--Analyze pattern casual riders and annual mamber-----

--calculate average and maximum trip duration---
/*
SELECT 
  member_casual,
  COUNT(*) AS total_trips,
  AVG(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)) AS avg_duration_minutes,
  MAX(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)) AS max_duration_minutes
 FROM `cycle-case-study-443823.2020_trips.focused_trips`
 GROUP BY member_casual; 
*/

-- analyze trip duration distribution---
/*
SELECT 
  member_casual,
  CASE
    WHEN TIMESTAMP_DIFF(ended_at, started_at, MINUTE) <= 5 THEN '0-5 minutes' 
    WHEN TIMESTAMP_DIFF(ended_at, started_at, MINUTE) <= 15 THEN '5-15 minutes'
    WHEN TIMESTAMP_DIFF(ended_at, started_at, MINUTE) <= 30 THEN '15-30 minutes'
    WHEN TIMESTAMP_DIFF(ended_at, started_at, MINUTE) <= 60 THEN '30-60 minutes'
    ELSE '60+ minutes'
  END AS duration_range,
  COUNT(*) AS trip_count
FROM `cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY member_casual,duration_range
ORDER BY member_casual, duration_range;
--Casual largest trip count: 15-30 minutes (12,697 trips).Second largest: 5-15 minutes (11,709 trips)--
-- Members largest trip count: 5-15 minutes (184,344 trips).Second largest: 0-5 minutes (112,223 trips)--
*/

-- deeper duration analysis, time-based patterns such as time of day and day of week.To discover when riders are most active.

-- Analyze trip duration by time of day. This query categorizes trips into time ranges (morning, afternoon, evening, etc.) based on the started_at column---

/*
SELECT
  member_casual,
  CASE
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 5 and 11 THEN 'Morning (5am - 11am)'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 12 and 16 THEN 'Afternoon (12pm - 4pm)'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 17 and 20 THEN 'Evening (5pm - 8pm)'
    ELSE 'Night (9pm - 4am)'
  END AS time_of_day,
  COUNT(*) AS trip_count,
  AVG(TIMESTAMP_DIFF(ended_at,started_at,MINUTE)) AS avg_duration_minutes
FROM `cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY member_casual, time_of_day
ORDER BY member_casual, time_of_day;
*/

--- This query shows trends by weekdays and weekends---
/*
SELECT
  member_casual,
  CASE
    WHEN EXTRACT(DAYOFWEEK FROM started_at) IN (2,3,4,5,6) THEN  'Weekday'
    ELSE 'Weekend'
  END AS day_type,
  COUNT(*) AS trip_count,
  AVG(TIMESTAMP_DIFF(ended_at,started_at,MINUTE)) AS avg_duration_minutes
  FROM `cycle-case-study-443823.2020_trips.focused_trips`
  GROUP BY member_casual,day_type
  ORDER BY member_casual, day_type;
*/

---trends on distance---
/*
SELECT 
  member_casual,
  CASE 
    WHEN EXTRACT(DAYOFWEEK FROM started_at) IN (1, 7) THEN 'Weekend'
    ELSE 'Weekday'
  END AS day_type,
  COUNT(*) AS trip_count,
  AVG(trip_distance_km) AS avg_trip_distance_km
  FROM `cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY member_casual,day_type
ORDER BY member_casual, day_type;
*/

--- query for trends in distance for time of the day---
/*
SELECT
  member_casual,
  CASE
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 5 AND 11  THEN 'Morning (5am - 11am)'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 12 AND 16 THEN 'Afternoon (12pm - 4pm)'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 17 AND 20 THEN 'Evening (5pm - 8pm)'
    ELSE 'Night (9pm - 4am)'
  END AS time_of_day,
    COUNT(*) AS trip_count,
    AVG(trip_distance_km) AS avg_trip_distance_km
FROM `cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY
  member_casual,
  time_of_day
ORDER BY
  member_casual,
  time_of_day
*/

--Correlation Between Duration and Distance--
/*
SELECT
  member_casual,
  TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS trip_duration_minutes,
  trip_distance_km
FROM `cycle-case-study-443823.2020_trips.focused_trips` 
*/

---identify outlieers in trip duration in the data set. Review trips with extremely high or low durations. Trips lasting longer than 24 hours (1,440 MINUTES) are likly outliers ----
/*
SELECT  
  member_casual,
 TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS trip_duration_minutes,
  trip_distance_km,

FROM `cycle-case-study-443823.2020_trips.focused_trips`
WHERE
 TIMESTAMP_DIFF(ended_at, started_at, MINUTE) > 1440 --- duration over 1 day
ORDER BY
 TIMESTAMP_DIFF(ended_at, started_at, MINUTE) DESC;
*/

-- further analysis to investigate high trip durations---
/*
SELECT
  member_casual,
  COUNT(*) AS trip_count,
  AVG(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)) AS avg_durataion_minutes
FROM `cycle-case-study-443823.2020_trips.focused_trips`
WHERE 
  TIMESTAMP_DIFF(ended_at, started_at, MINUTE) > 1440 
GROUP BY 
  member_casual;--- casual rider far exceeded the time duration indicating outliers caused by other factors--
*/

---removed outliers from data set for more accurate data----
/*
CREATE OR REPLACE TABLE `cycle-case-study-443823.2020_trips.focused_trips` AS 
SELECT *
FROM `cycle-case-study-443823.2020_trips.focused_trips`
WHERE 
  TIMESTAMP_DIFF(ended_at,started_at,MINUTE) <= 1440;
*/

--verified the new dataset to ensure the filtered dataset has fewer rows---
/*
SELECT
  COUNT(*) AS total_rows
FROM `cycle-case-study-443823.2020_trips.focused_trips`;
*/

---confirm the removed rows by counting the number of rows with durations exceeding 1440 minutes---
/*
SELECT COUNT(*) AS outlier_count ---returned 0
FROM `cycle-case-study-443823.2020_trips.focused_trips`
WHERE TIMESTAMP_DIFF(ended_at, started_at, MINUTE) > 1440;
*/

---  correlation analysis to calculate the correation coefficient between trip duration and trip distance--
/*
SELECT
  member_casual,
  CORR(TIMESTAMP_DIFF(ended_at, started_at, MINUTE), trip_distance_km) AS corelation_coefficient
FROM`cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY
  member_casual;

*/

---create new table with trip_duration_minutes column---
/*
CREATE OR REPLACE TABLE `cycle-case-study-443823.2020_trips.focused_trips` AS 
SELECT
  *,
  TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS trip_duration_minutes
  FROM `cycle-case-study-443823.2020_trips.focused_trips`;
*/

-- Average Trip Duration by User Type---
/*
SELECT 
  member_casual,
  AVG(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)) AS avg_trip_duration_minutes
FROM 
  `cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY 
  member_casual;
*/
/*
--This query will show how ride frequencies change depending on the day of the week.--
SELECT 
  member_casual,
  EXTRACT(DAYOFWEEK FROM started_at) AS day_of_week,
  COUNT(*) AS total_rides
FROM 
  `cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY 
  member_casual, day_of_week
ORDER BY 
  total_rides DESC;
-- Casual riders primarily use bikes on weekends for leisure, while weekday usage is significantly lower.-
--Members ride most often on weekdays (Tuesday, Wednesday, Thursday)--.
*/

---Peak ride hours: This query will extract the hour of the day when rides are most frequent, helping identify peak usage times--
/*
SELECT
  member_casual,
  EXTRACT( HOUR FROM started_at)AS ride_hour,
  COUNT(*) AS total_rides
FROM `cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY 
  member_casual, ride_hour
ORDER BY 
  ride_hour ASC;
  */

  ---Query to Separate Weekdays vs. Weekends--
/*
  SELECT
  member_casual,
  EXTRACT(DAYOFWEEK FROM started_at) AS day_of_week,
  EXTRACT(HOUR FROM started_at) AS ride_hour,
  COUNT(*) AS total_rides
  FROM `cycle-case-study-443823.2020_trips.focused_trips`
  GROUP BY 
    member_casual,day_of_week, ride_hour
  ORDER BY 
  day_of_week, ride_hour; 
*/

-- query to compare weekend vs weekend peak ride hours---
/*
SELECT
  member_casual,
  CASE
    WHEN EXTRACT(DAYOFWEEK FROM started_at) IN (2,3,4,5,6) THEN 'weekday'
  ELSE 'Weekend'
  END AS day_category,
  EXTRACT(HOUR FROM started_at) AS ride_hour,
  COUNT(*) AS total_rides
FROM `cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY 
  member_casual,day_category,ride_hour
ORDER BY 
  total_rides desc;
*/

---query finding the Top 3 Peak Ride Hours for Each User Type--
/*
WITH Ranked_hours AS (
  SELECT
    member_casual,
    EXTRACT(HOUR FROM started_at) AS ride_hour,
    COUNT(*) AS total_rides,
    RANK() OVER (PARTITION BY member_casual ORDER BY COUNT(*) DESC) AS rank
FROM`cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY 
  member_casual,ride_hour
)
SELECT * 
FROM Ranked_hours
WHERE rank <= 3
ORDER BY member_casual, total_rides DESC;
*/

---
/*
SELECT 
  member_casual, 
  EXTRACT(HOUR FROM started_at) AS ride_hour,
  COUNT(*) AS total_rides
FROM `cycle-case-study-443823.2020_trips.focused_trips`
GROUP BY member_casual, ride_hour
ORDER BY ride_hour;
/*





