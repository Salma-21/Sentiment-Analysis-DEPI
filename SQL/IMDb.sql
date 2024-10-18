-- Extract all data from title_basics table
SELECT * FROM title_basics;

-- Extract all data from reviews table
SELECT * FROM reviews;

-- Count the number of reviews for each movie
SELECT movie_title, COUNT(*) AS review_count
FROM reviews
GROUP BY movie_title;

-- List the top 3 movies with the most reviews
SELECT movie_title, COUNT(*) AS review_count
FROM reviews
GROUP BY movie_title
ORDER BY review_count DESC
LIMIT 3;

-- Extract all movies released after the year 2000
SELECT * FROM title_basics
WHERE startYear > 2000 AND titleType = 'movie';

-- Extract all ratings
SELECT * FROM title_ratings;

-- Extract all crew details for a specific movie by tconst
SELECT * FROM title_crew
WHERE tconst = 'tt1234567';

-- Count the number of movies for each genre
SELECT unnest(string_to_array(genres, ',')) AS genre, COUNT(*)
FROM title_basics
WHERE titleType = 'movie'
GROUP BY genre;

-- Calculate the average rating of all movies
SELECT AVG(averageRating)
FROM title_ratings;

-- Select the top 5 highest-rated movies
SELECT tb.originalTitle, tr.averageRating, tr.numVotes
FROM title_ratings tr
JOIN title_basics tb ON tr.tconst = tb.tconst
WHERE tb.titleType = 'movie'
ORDER BY tr.averageRating DESC
LIMIT 5;

-- Find the director with the most movies
SELECT p.primaryName, COUNT(*)
FROM title_crew tc
JOIN name_basics p ON tc.directors = p.nconst
GROUP BY p.primaryName
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Find the total number of votes for each genre
SELECT unnest(string_to_array(genres, ',')) AS genre, SUM(numVotes) AS totalVotes
FROM title_basics tb
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE tb.titleType = 'movie'
GROUP BY genre;

-- Select movies with their genres and number of votes
SELECT tb.primaryTitle, tb.genres, tr.numVotes
FROM title_basics tb
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE tb.titleType = 'movie';

-- Find the average rating and total number of votes for movies released each year
SELECT tb.startYear, AVG(tr.averageRating) AS avgRating, SUM(tr.numVotes) AS totalVotes
FROM title_basics tb
JOIN title_ratings tr ON tb.tconst = tr.tconst
WHERE tb.titleType = 'movie'
GROUP BY tb.startYear
ORDER BY tb.startYear;

-- Find the top-rated movie in each genre
WITH GenreRatings AS (
  SELECT tb.mainTitle, unnest(string_to_array(tb.genres, ',')) AS genre, tr.averageRating
  FROM title_basics tb
  JOIN title_ratings tr ON tb.tconst = tr.tconst
  WHERE tb.titleType = 'movie'
)
SELECT genre, mainTitle, averageRating
FROM (
  SELECT genre, mainTitle, averageRating, 
         ROW_NUMBER() OVER (PARTITION BY genre ORDER BY averageRating DESC) AS rank
  FROM GenreRatings
) AS ranked
WHERE rank = 1;

-- Find the actors with the most appearances
SELECT nb.primaryName, COUNT(*) AS numAppearances
FROM title_principals tp
JOIN name_basics nb ON tp.nconst = nb.nconst
WHERE tp.category = 'actor' OR tp.category = 'actress'
GROUP BY nb.primaryName
ORDER BY numAppearances DESC
LIMIT 5;

-- Calculate the average birth year of all people in the database
SELECT AVG(birthYear)
FROM name_basics
WHERE birthYear IS NOT NULL;

--------------------------------------------------------------------
-- Update runtimeMinutes for a specific movie by tconst
UPDATE title_basics
SET runtimeMinutes = 150
WHERE tconst = 'tt1234567';

-- Select updated runtimeMinutes for a specific movie by tconst
SELECT tconst, mainTitle, runtimeMinutes
FROM title_basics
WHERE tconst = 'tt1234567';
--------------------------------------------------------------------
-- Create a view for basic movie details
CREATE VIEW movie_details AS
SELECT tconst, primaryTitle, startYear, genres, runtimeMinutes
FROM title_basics
WHERE titleType = 'movie';

-- Select all columns from movie_details view
SELECT * FROM movie_details;

-- Create a view for top-rated movies
CREATE VIEW top_rated_movies AS
SELECT tb.primaryTitle, tb.genres, tr.averageRating
FROM title_ratings tr
JOIN title_basics tb ON tr.tconst = tb.tconst
WHERE tb.titleType = 'movie'
ORDER BY tr.averageRating DESC
LIMIT 5;

-- Select all columns from top_rated_movies view
SELECT * FROM top_rated_movies;

-- Create a view for director movie counts
CREATE VIEW director_movie_counts AS
SELECT nb.primaryName AS director, COUNT(*) AS movie_count
FROM title_crew tc
JOIN name_basics nb ON tc.directors = nb.nconst
GROUP BY nb.primaryName
ORDER BY movie_count DESC;

-- Select all columns from director_movie_counts view
SELECT * FROM director_movie_counts;
------------------------------------------------------------------------
-- Drop the existing function get_movies_by_year
DROP FUNCTION IF EXISTS get_movies_by_year(integer);

-- Create a function to get movies by release year
CREATE OR REPLACE FUNCTION get_movies_by_year(release_year INT)
RETURNS TABLE(tconst VARCHAR, mainTitle VARCHAR, genres VARCHAR, runtimeMinutes INT) AS $$
BEGIN
    RETURN QUERY
    SELECT tb.tconst, tb.mainTitle::VARCHAR, tb.genres::VARCHAR, tb.runtimeMinutes
    FROM title_basics tb
    WHERE tb.titleType = 'movie' AND tb.startYear = release_year;
END;
$$ LANGUAGE plpgsql;

-- Select all columns from get_movies_by_year function for the year 2020
SELECT * FROM get_movies_by_year(2020);
-------------------------------------------------------------------

-- Rename the column primaryTitle to mainTitle
ALTER TABLE title_basics RENAME COLUMN primaryTitle TO mainTitle;

-- Select data to verify the column has been renamed
SELECT tconst, mainTitle, startYear, genres, runtimeMinutes FROM title_basics;

-- Add a new column director_name
ALTER TABLE title_basics ADD COLUMN director_name VARCHAR(255);

-- Select data to verify the new column has been added
SELECT tconst, mainTitle, director_name FROM title_basics;

-- Alter the column averageRating to drop NOT NULL constraint
ALTER TABLE title_ratings ALTER COLUMN averageRating DROP NOT NULL;

-- Select data to verify the column constraint has been altered
SELECT tconst, averageRating FROM title_ratings;

-- Add a new column for review_date
ALTER TABLE reviews ADD COLUMN review_date DATE;

-- Select all data from reviews table
SELECT * FROM reviews;

-- Change the data type of movie_title to TEXT
ALTER TABLE reviews ALTER COLUMN movie_title TYPE TEXT;

-- Select column names and data types from reviews table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'reviews';

-- Add a new column nationality
ALTER TABLE name_basics ADD COLUMN nationality VARCHAR(255);

-- Select nconst, primaryName, nationality from name_basics
SELECT nconst, primaryName, nationality FROM name_basics;


