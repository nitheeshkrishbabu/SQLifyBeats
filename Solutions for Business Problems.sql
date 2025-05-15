-- Advanced SQL Project - Spotify

-- create table

DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);

SELECT COUNT(*) from spotify;

SELECT COUNT(DISTINCT artist) from spotify;

SELECT COUNT(DISTINCT album) from spotify;

SELECT DISTINCT album_type from spotify;

SELECT MAX(duration_min) from spotify;

SELECT MIN(duration_min) from spotify;

DELETE FROM spotify
WHERE duration_min = 0;

SELECT * FROM spotify
WHERE duration_min = 0;

SELECT DISTINCT channel FROM spotify;

SELECT DISTINCT most_played_on FROM spotify;

-- --------------------------------------------
-- Data Analysis - Easy Level
-- --------------------------------------------

-- Q.1 Retrieve the names of all tracks that have more than 1 billion streams.

SELECT * FROM spotify
WHERE stream > 1e9;

-- Q.2 List all albums along with their respective artists.

SELECT 
	DISTINCT album,
	artist
FROM spotify
ORDER BY 1;

-- Q.3 Get the total number of comments for tracks where licensed = TRUE.

SELECT 
	SUM(comments) AS total_no_of_comments
FROM spotify
WHERE licensed = 'true';

-- Q.4 Find all tracks that belong to the album type single.

SELECT track
FROM spotify
WHERE album_type IN ('single');

-- Q.5 Count the total number of tracks by each artist.

SELECT 
	artist,
	COUNT(*) AS total_no_of_tracks
FROM spotify
GROUP BY artist
ORDER BY 2 DESC;

-- --------------------------------------------
-- Data Analysis - Medium Level
-- --------------------------------------------

-- Q.6 Calculate the average danceability of tracks in each album.

SELECT 
	DISTINCT album,
	AVG(danceability) AS average_danceability
FROM spotify
GROUP BY 1
ORDER BY 2 DESC;

-- Q.7 Find the top 5 tracks with the highest energy values.

SELECT 
	track,
	MAX(energy) AS highest_energy_values
FROM spotify
GROUP BY track
ORDER BY 2 DESC
LIMIT 5;

-- Q.8 List all tracks along with their views and likes where official_video = TRUE.

SELECT 
	track,
	SUM(views) AS total_views,
	SUM(likes) AS total_likes
FROM spotify
WHERE official_video = 'true'
GROUP BY track
ORDER BY 2 DESC;

-- Q.9 For each album, calculate the total views of all associated tracks.

SELECT 
	album,
	track,
	SUM(views) AS total_views
FROM spotify
GROUP BY 1,2
ORDER BY 3 DESC;

-- Q.10 Retrieve the track names that have been streamed on Spotify more than YouTube.

SELECT * FROM spotify;

WITH streams
AS
(
	SELECT 
		track,
		COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END),0) AS streamed_on_youtube,
		COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END),0) AS streamed_on_Spotify
	FROM spotify
	GROUP BY 1

)
SELECT *
FROM streams
WHERE 
	streamed_on_Spotify > streamed_on_youtube
	AND 
	streamed_on_youtube <> 0;

-- --------------------------------------------
-- Data Analysis - Advanced Level
-- --------------------------------------------


-- Q.11 Find the top 3 most-viewed tracks for each artist using window functions.

WITH artist_data 
AS
(
	SELECT 
		artist, 
		track,
		SUM(views) AS most_viewed
	FROM 
		spotify
	GROUP BY 1,2
	ORDER BY 1,3 DESC
),
artist_ranking
AS
(
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY artist ORDER BY artist, most_viewed DESC) AS rn
	FROM artist_data
)
SELECT 
	artist,
	track
FROM 
	artist_ranking
WHERE rn <=3;


-- Q.12 Write a query to find tracks where the liveness score is above the average.

select * from spotify; 

SELECT
	artist,
	track,
	liveness
FROM spotify
WHERE liveness >(SELECT 	
					AVG(liveness) AS liveness_average 
				FROM spotify); 

-- Q.13 Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.

select * from spotify; 

WITH highest_lowest_energy
AS
(
	SELECT 
		album,
		MAX(energy) AS highest_energy,
		MIN(energy) AS lowest_energy
	FROM spotify
	GROUP BY 1
)

SELECT 
	album,
	highest_energy - lowest_energy AS energy_difference
FROM highest_lowest_energy
ORDER BY 2 DESC;

-- Q.14 Find tracks where the energy-to-liveness ratio is greater than 1.2.

SELECT 
	track,
	energy,
	liveness,
	ROUND((energy / liveness)::numeric, 2) AS ratio
FROM 
	spotify
WHERE 
	liveness > 0 AND energy/liveness > 1.2
ORDER BY ratio desc; 

-- Q.15 Calculate the cumulative sum of likes for tracks ordered by the number of views, using window functions

SELECT 
	track,
	views,
	likes,
	SUM(likes) OVER(ORDER BY views asc) AS cumulative_likes
FROM spotify
WHERE views <>0 And likes <>0;

-- Q.16 Calculate Stream-to-Like Ratio

WITH stream_like_ratio AS (
    SELECT track, artist, stream, likes,
           CASE WHEN likes = 0 THEN 0 ELSE stream::float / likes END AS stream_like_ratio
    FROM spotify
)
SELECT * 
FROM stream_like_ratio
ORDER BY stream_like_ratio DESC
LIMIT 10;

-- Q.17 Calculate Average Metrics by Album Type and Compare Each Song to Its Group

WITH album_metrics AS (
    SELECT 
        album_type,
        AVG(energy) AS avg_energy,
        AVG(valence) AS avg_valence
    FROM spotify
    GROUP BY album_type
)
SELECT 
    s.track,
    s.album_type,
    s.energy,
    a.avg_energy,
    s.energy - a.avg_energy AS energy_diff,
    s.valence - a.avg_valence AS valence_diff
FROM spotify s
JOIN album_metrics a ON s.album_type = a.album_type;

-- Q.18 Find the Tracks with Highest Engagement (Likes + Comments) - Top 10

WITH engagement AS (
    SELECT 
        track,
        artist,
        likes,
        comments,
        (likes + comments) AS total_engagement,
        RANK() OVER (ORDER BY (likes + comments) DESC) AS engagement_rank
    FROM spotify
)
SELECT * 
FROM engagement
WHERE engagement_rank <= 10;

-- Q.19 Find Songs with Highest-to-Lowest Likes-to-Comments Ratio

WITH ratios AS (
    SELECT 
        track,
        artist,
        likes,
        comments,
        CASE 
            WHEN comments = 0 THEN NULL 
            ELSE ROUND((likes::numeric / comments), 2)
        END AS like_comment_ratio
    FROM spotify
)
SELECT *
FROM ratios
ORDER BY like_comment_ratio DESC
LIMIT 10;

-- Q.20 Find Longest Song per Album with Dense Rank

WITH song_ranks AS (
    SELECT 
        album,
        track,
        duration_min,
        DENSE_RANK() OVER (PARTITION BY album ORDER BY duration_min DESC) AS rank_in_album
    FROM spotify
)
SELECT *
FROM song_ranks
WHERE rank_in_album = 1;




-- Query Optimization

EXPLAIN ANALYZE -- exe time: 7.830 ms plan time: 0.138 ms
SELECT 
	artist,
	track,
	views
FROM spotify
WHERE artist = 'Gorillaz'
	AND
	most_played_on = 'Youtube'
ORDER BY stream DESC LIMIT 25;

CREATE INDEX idx_artist ON spotify(artist);

select * from spotify