SELECT *  --checking if japanese symbols are shown properly
FROM netflix_raw
WHERE show_id = 's5023' 
/*
Data cleaning part:
1 remove duplicates
2 create a new table for listed_in, director, country, cast to introduce normalization
3 convert data types
4 populate missing values
5 deal with NULLs by setting them as not_available
*/

-- 1: dealing with duplicates
SELECT show_id, COUNT(*)
FROM netflix_raw
GROUP BY show_id
HAVING COUNT(*)>1; -- Result: no duplicates for show_id found, show_id will be primary key

SELECT *
FROM netflix_raw
WHERE CONCAT(UPPER(title),type) IN (
	SELECT CONCAT(UPPER(title),type)
	FROM netflix_raw
	GROUP BY UPPER(title),type
	HAVING COUNT(*) > 1
)
ORDER BY title -- Result: there are duplicates due to titles being written differently

WITH CTE AS(
	SELECT *
	,ROW_NUMBER() OVER(PARTITION BY title, type ORDER BY show_id) as rn
	FROM netflix_raw
)
SELECT *
FROM CTE
WHERE rn=1 -- duplicates are now handled


-- 2: normalizing the table 
SELECT show_id, TRIM(value) AS director
INTO netflix_directors
FROM netflix_raw
CROSS APPLY STRING_SPLIT(director,',')

SELECT show_id, TRIM(value) AS country
INTO netflix_country
FROM netflix_raw
CROSS APPLY STRING_SPLIT(country,',')

SELECT show_id, TRIM(value) AS cast
INTO netflix_cast
FROM netflix_raw
CROSS APPLY STRING_SPLIT(cast,',')

SELECT show_id, TRIM(value) AS genre
INTO netflix_genre
FROM netflix_raw
CROSS APPLY STRING_SPLIT(listed_in,',')

-- 3: Data type conversions
WITH CTE AS(
	SELECT *
	,ROW_NUMBER() OVER(PARTITION BY title, type ORDER BY show_id) as rn
	FROM netflix_raw
)
SELECT show_id, type, title, CAST(date_added AS date) AS date_added
,release_year, rating, duration, description 
FROM CTE
WHERE rn=1
-- 4: Populating missing values in columns:
-- country 
INSERT INTO netflix_country
SELECT show_id, m.country
FROM netflix_raw AS nr
INNER JOIN (
SELECT director, country
FROM netflix_country AS nc
INNER JOIN netflix_directors AS nd 
ON nc.show_id = nd.show_id
GROUP BY director, country
) AS m ON nr.director = m.director
WHERE nr.country IS NULL;
-- approximation on similar data (all combinations of director + country) & that the movie is released in all countries the direcotr worked in
-- not optimal bc we may not have some info about directors, but still works


-- duration
SELECT * 
FROM netflix_raw
WHERE duration IS NULL --that way I found that for some reason duration data got inserted into rating column

WITH CTE AS( -- this way I fillin most data, of course, if rating and duration is null, nothing will happen
	SELECT *
	,ROW_NUMBER() OVER(PARTITION BY title, type ORDER BY show_id) as rn
	FROM netflix_raw
)
SELECT show_id, type, title, CAST(date_added AS date) AS date_added
,release_year, rating, CASE WHEN duration IS NULL THEN rating ELSE duration END AS duration, description 
INTO netflix_stage --final table, for other columns use JOIN
FROM CTE

-- 5: Dealing with nulls: setting them as not_available, except for date,as we dont have a null value for date
UPDATE netflix_stage
SET 
    type = COALESCE(type, 'not_available'),
    title = COALESCE(title, 'not_available'),
    release_year = COALESCE(release_year, 0), -- Using 0 for unknown release years
    rating = COALESCE(rating, 'N/A'),
    duration = COALESCE(duration, 'not_available'),
    description = COALESCE(description, 'not_available');

-- Updating the normalized tables as well
UPDATE netflix_directors
SET director = COALESCE(director, 'not_available');

UPDATE netflix_country
SET country = COALESCE(country, 'not_available');

UPDATE netflix_cast
SET cast = COALESCE(cast, 'not_available');

UPDATE netflix_genre
SET genre = COALESCE(genre, 'not_available');

-- Verifying the changes
SELECT * 
FROM netflix_stage 
WHERE type = 'not_available' OR title = 'not_available' OR release_year = 0 OR rating = 'not_available' OR duration = 'not_available' OR description = 'not_available';

SELECT *
FROM netflix_directors 
WHERE director = 'not_available';

SELECT * 
FROM netflix_country
WHERE country = 'not_available';

SELECT *
FROM netflix_cast
WHERE cast = 'not_available';

SELECT * 
FROM netflix_genre 
WHERE genre = 'not_available';
