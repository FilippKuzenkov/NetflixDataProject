-- Data analysis: Solving 5 SQL questions

-- 1: For each director count the number of movies and tv shows created by them in separate columns
SELECT nd.director
,COUNT(DISTINCT CASE WHEN n.type = 'Movie' THEN n.show_id  END) AS no_of_movies
,COUNT(DISTINCT CASE WHEN n.type = 'TV Show' THEN n.show_id  END) AS no_of_tvshow   
FROM netflix_stage AS n
INNER JOIN netflix_directors AS nd 
ON n.show_id = nd.show_id
GROUP BY nd.director
HAVING COUNT(DISTINCT n.type) > 1
ORDER BY no_of_movies DESC, no_of_tvshow DESC

-- 2: Which country has the highest number of comedy movies
SELECT TOP 1 nc.country, COUNT(DISTINCT ng.show_id) AS no_of_comedy_movies
FROM netflix_genre AS ng
INNER JOIN netflix_country AS nc
ON ng.show_id = nc.show_id
INNER JOIN netflix_stage AS n
ON ng.show_id = n.show_id
WHERE ng.genre = 'Comedies'
AND n.type = 'Movie' 
GROUP BY nc.country
ORDER BY no_of_comedy_movies DESC


-- 3: For each year (as per date added to netflix), which director has released the most movies
WITH CTE AS (
	SELECT  nd.director, YEAR(date_added) AS date_year
	, COUNT(DISTINCT n.show_id) AS no_of_movies
	FROM netflix_stage AS n
	INNER JOIN netflix_directors AS nd
	ON n.show_id = nd.show_id
	WHERE type = 'Movie'
	GROUP BY nd.director, YEAR(date_added)
) 
, CTE_2 AS(
	SELECT *
	, ROW_NUMBER() OVER(PARTITION BY date_year 
	ORDER BY no_of_movies DESC, director) AS rn 
	FROM CTE
)
SELECT * 
FROM CTE_2
WHERE rn = 1

-- 4: What is the average duration of movies in each genre
SELECT ng.genre, AVG(CAST(REPLACE(duration,' min','') AS INT)) AS avg_duration_minutes
FROM netflix_stage AS n
INNER JOIN netflix_genre AS ng
ON n.show_id = ng.show_id
WHERE type = 'Movie'
GROUP BY ng.genre

-- 5: Find the list of directors who have created both horror and comedy movies
-- Display their names along with the number of movies
SELECT nd.director
, COUNT(DISTINCT CASE WHEN ng.genre = 'Comedies' THEN n.show_id END) AS no_of_comedie_movies
, COUNT(DISTINCT CASE WHEN ng.genre = 'Horror Movies' THEN n.show_id END) AS no_of_horror_movies
FROM netflix_stage AS n
INNER JOIN netflix_genre AS ng
ON n.show_id = ng.show_id
INNER JOIN netflix_directors AS nd
ON n.show_id = nd.show_id
WHERE type ='Movie' AND ng.genre IN ('Comedies','Horror Movies')
GROUP BY nd.director 
HAVING COUNT(DISTINCT ng.genre) = 2
ORDER BY no_of_comedie_movies DESC, no_of_horror_movies DESC
