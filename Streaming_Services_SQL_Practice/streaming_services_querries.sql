--
-- File generated with SQLiteStudio v3.3.3 on Thu Jun 23 14:18:16 2022
--
-- Text encoding used: UTF-8
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: netflix_shows
CREATE TABLE netflix_shows (show_id, type, title, director, "cast", country, date_added, release_year, rating, duration, listed_in, description);

-- Table: netflix_top10
CREATE TABLE netflix_top10 (week, category, weekly_rank, show_title, season_title, weekly_hours_viewed, cumulative_weeks_in_top_10);

-- Table: spotify_top200
CREATE TABLE spotify_top200 (Position, Track_Name, Artist, Streams, URL, Date, Region);

-- View: category total hours in top 10
CREATE VIEW "category total hours in top 10" AS SELECT category, 
    SUM(weekly_hours_viewed * cumulative_weeks_in_top_10) AS total_hours_top10
FROM netflix_top10
GROUP BY category
ORDER BY 2 DESC;

-- View: Content US vs.  Foreign 
CREATE VIEW "Content US vs.  Foreign " AS SELECT CASE 
         WHEN country = 'United States' 
             THEN 'US'
         WHEN country LIKE 'United States%' 
             THEN 'US Mixed'
         WHEN country NOT LIKE '%United States%' AND country NOT LIKE '%,%' 
             THEN 'Foreign'
         ELSE 'Foreign Mixed'
     END origin,
     count(*) AS num_movies
FROM netflix_shows
WHERE country != ''
GROUP BY 1
ORDER BY 2 DESC;

-- View: Movies by Release Year
CREATE VIEW "Movies by Release Year" AS SELECT release_year, COUNT(*) AS num_movies
FROM netflix_shows
WHERE type = 'Movie'
GROUP BY release_year;

-- View: Netflix Genres Distribution
CREATE VIEW "Netflix Genres Distribution" AS WITH a AS( /* temporary tables a, b, and c extract the 1-3 genres tagged in the listed_in column */
SELECT title,
    listed_in || ',' as listed_genres,
    SUBSTR(listed_in || ',', 1, INSTR(listed_in || ',', ',')) AS first_genre
FROM netflix_shows),

b AS(
SELECT title,
    REPLACE(listed_genres, first_genre, '') AS next_two_genres,
    SUBSTR(REPLACE(listed_genres, first_genre, ''), 1, INSTR(REPLACE(listed_genres, first_genre, ''), ',')) AS second_genre
FROM a),

c AS(
SELECT title,
    REPLACE(next_two_genres, second_genre, '') AS third_genre
FROM b),

/* this temporary table has a column for each of the up to 3 listed genres */
tv_genres AS(
SELECT a.title, 
    a.first_genre, 
    b.second_genre, 
    c.third_genre
FROM a
JOIN b ON a.title = b.title
JOIN c ON a.title = c.title),

/* the following three temporary tables calculate total tags for each of the three genre columns */
first_count AS(
SELECT first_genre, 
    count(*) AS count_1
FROM tv_genres
GROUP BY first_genre),

second_count AS(
SELECT second_genre, 
    count(*) AS count_2
FROM tv_genres
WHERE second_genre IS NOT ''
GROUP BY second_genre),

third_count AS(
SELECT third_genre, 
    count(*) AS count_3
FROM tv_genres
WHERE third_genre IS NOT ''
GROUP BY third_genre),

/* union of all genre tag counts */
comb_counts AS(
SELECT TRIM(first_genre) AS genre, count_1 AS count FROM first_count
UNION
SELECT TRIM(second_genre), count_2 FROM second_count
UNION
SELECT TRIM(third_genre), count_3 FROM third_count)

/* group by genre for the final tag counts */
SELECT RTRIM(genre,',') AS genre, 
    sum(count) AS genre_tag_sum
FROM comb_counts
GROUP BY 1
ORDER BY 1 ASC;

-- View: Netflix Top 10 Genre Distribution Percent Tagged Hours
CREATE VIEW "Netflix Top 10 Genre Distribution Percent Tagged Hours" AS WITH top10_genre_tags AS( /* Left join in order to aquire genre data for the movies/shows in the top10 table */
SELECT nt.show_title AS title, 
    sum(nt.weekly_hours_viewed) AS total_hours, 
    ns.listed_in AS listed_in
FROM netflix_top10 AS nt
    JOIN netflix_shows AS ns
        ON nt.show_title = ns.title
GROUP BY 1),
      
/* temporary tables a, b, and c extract the 1-3 genres listed in the listed_in column */   
a AS(
SELECT title,
    listed_in || ',' as listed_genres,
    SUBSTR(listed_in || ',', 1, INSTR(listed_in || ',', ',')) AS first_genre,
    total_hours
FROM top10_genre_tags),

b AS(
SELECT title,
    REPLACE(listed_genres, first_genre, '') AS next_two_genres,
    SUBSTR(REPLACE(listed_genres, first_genre, ''), 1, INSTR(REPLACE(listed_genres, first_genre, ''), ',')) AS second_genre
FROM a),

c AS(
SELECT title,
    REPLACE(next_two_genres, second_genre, '') AS third_genre
FROM b),

/* this temporary table has a column for each of the up to 3 listed genres */
tv_genres AS(
SELECT a.title, 
    a.total_hours, 
    a.first_genre, 
    b.second_genre, 
    c.third_genre
FROM a
JOIN b ON a.title = b.title
JOIN c ON a.title = c.title),

/* the following three temporary tables calculate total hours for each of the three genre columns */
first_count AS(
SELECT first_genre, 
    SUM(total_hours) AS genre_hours
FROM tv_genres
GROUP BY first_genre),

second_count AS(
SELECT second_genre, 
    SUM(total_hours) AS genre_hours
FROM tv_genres
WHERE second_genre IS NOT ''
GROUP BY second_genre),

third_count AS(
SELECT third_genre, 
    SUM(total_hours) AS genre_hours
FROM tv_genres
WHERE third_genre IS NOT ''
GROUP BY third_genre),

/* union of all genre hour totals */
comb_counts AS(
SELECT TRIM(first_genre) AS genre, genre_hours FROM first_count
UNION
SELECT TRIM(second_genre), genre_hours FROM second_count
UNION
SELECT TRIM(third_genre), genre_hours FROM third_count),

/* group by genre for the final hour sums */
genre_hours AS(
SELECT RTRIM(genre,',') AS genre, 
    genre_hours, 
    SUM(genre_hours) OVER() AS tot_top10_hours
FROM comb_counts
GROUP BY 1
ORDER BY 1 ASC)

/* normalization of hour sums */
SELECT genre, 
    CAST(genre_hours AS FLOAT) / CAST(tot_top10_hours AS FLOAT) AS genre_perc
FROM genre_hours;

-- View: Netflix Top10 Genres Distribution
CREATE VIEW "Netflix Top10 Genres Distribution" AS WITH top10_genre_tags AS( /* Left join in order to aquire genre data for the movies/shows in the top10 table */
SELECT DISTINCT(nt.show_title) AS title, 
    ns.listed_in AS listed_in
FROM netflix_top10 AS nt
    JOIN netflix_shows AS ns
        ON nt.show_title = ns.title),

/* temporary tables a, b, and c extract the 1-3 genres listed in the listed_in column */ 
a AS(
SELECT title,
    listed_in || ',' as listed_genres,
    SUBSTR(listed_in || ',', 1, INSTR(listed_in || ',', ',')) AS first_genre
FROM top10_genre_tags),

b AS(
SELECT title,
    REPLACE(listed_genres, first_genre, '') AS next_two_genres,
    SUBSTR(REPLACE(listed_genres, first_genre, ''), 1, INSTR(REPLACE(listed_genres, first_genre, ''), ',')) AS second_genre
FROM a),

c AS(
SELECT title,
    REPLACE(next_two_genres, second_genre, '') AS third_genre
FROM b),

/* this temporary table has a column for each of the up to 3 listed genres */
tv_genres AS(
SELECT a.title,
    a.first_genre,
    b.second_genre,
    c.third_genre
FROM a
JOIN b ON a.title = b.title
JOIN c ON a.title = c.title),

/* the following three temporary tables calculate total tags for each of the three genre columns */
first_count AS(
SELECT first_genre,
    count(*) AS count_1
FROM tv_genres
GROUP BY first_genre),

second_count AS(
SELECT second_genre,
    count(*) AS count_2
FROM tv_genres
WHERE second_genre IS NOT ''
GROUP BY second_genre),

third_count AS(
SELECT third_genre,
    count(*) AS count_3
FROM tv_genres
WHERE third_genre IS NOT ''
GROUP BY third_genre),

/* union of all genre tag counts */
comb_counts AS(
SELECT TRIM(first_genre) AS genre, count_1 AS count FROM first_count
UNION
SELECT TRIM(second_genre), count_2 FROM second_count
UNION
SELECT TRIM(third_genre), count_3 FROM third_count)

/* group by genre for the final tag counts */
SELECT RTRIM(genre,',') AS genre,
    sum(count) AS genre_tag_sum
FROM comb_counts
GROUP BY 1
ORDER BY 1 ASC;

-- View: Number of Shows Added per Day
CREATE VIEW "Number of Shows Added per Day" AS WITH a AS( /* here I begin fromating the provided datestring by replacing written months with an appropriate string */
SELECT show_id, 
    CASE
        WHEN date_added LIKE '%January %' 
            THEN REPLACE(TRIM(date_added),'January ','01-')
        WHEN date_added LIKE '%February %' 
            THEN REPLACE(TRIM(date_added),'February ','02-')
        WHEN date_added LIKE '%March %' 
            THEN REPLACE(TRIM(date_added),'March ','03-')
        WHEN date_added LIKE '%April %' 
            THEN REPLACE(TRIM(date_added),'April ','04-')
        WHEN date_added LIKE '%May %' 
            THEN REPLACE(TRIM(date_added),'May ','05-')
        WHEN date_added LIKE '%June %' 
            THEN REPLACE(TRIM(date_added),'June ','06-')
        WHEN date_added LIKE '%July %' 
            THEN REPLACE(TRIM(date_added),'July ','07-')
        WHEN date_added LIKE '%August %' 
            THEN REPLACE(TRIM(date_added),'August ','08-')
        WHEN date_added LIKE '%September %' 
            THEN REPLACE(TRIM(date_added),'September ','09-')
        WHEN date_added LIKE '%October %' 
            THEN REPLACE(TRIM(date_added),'October ','10-')
        WHEN date_added LIKE '%November %' 
            THEN REPLACE(TRIM(date_added),'November ','11-')
        WHEN date_added LIKE '%December %' 
            THEN REPLACE(TRIM(date_added),'December ','12-')
    END date
FROM netflix_shows
WHERE date_added != ''),

/* temporary tables b and c involve reordering the values and making sure all datestrings are the same length */
b AS(
SELECT show_id, 
    TRIM(REPLACE(SUBSTR(date, 7, 10) || '-' || SUBSTR(date, 1, 5), ',', '')) AS datestring
FROM a),

c AS(
SELECT show_id, 
    CASE
        WHEN LENGTH(datestring) = 9 THEN SUBSTR(datestring, 1, 8) || '0' || SUBSTR(datestring, 9, 9)
        ELSE datestring
    END datestring2
FROM b)

/* now that the datestring is in the correct format it can be converted into a datetime datatype for appropriate ordering */
SELECT count(show_id) AS quantity_added,
    DATE(datestring2) AS date
FROM c
GROUP BY 2
ORDER BY 2;

-- View: TV Shows by Release Year
CREATE VIEW "TV Shows by Release Year" AS SELECT release_year, 
    count(*) AS num_shows
FROM netflix_shows
WHERE type == 'TV Show'
GROUP BY release_year;

-- View: Type Weeks in Top 10
CREATE VIEW "Type Weeks in Top 10" AS SELECT ns.type, 
    sum(nt.cumulative_weeks_in_top_10) AS weeks_in_top10
FROM netflix_top10 AS nt
JOIN netflix_shows AS ns
    ON nt.show_title == ns.title
GROUP BY ns.type
ORDER BY 2 DESC;

-- View: US-CA Similarity Metric
CREATE VIEW "US-CA Similarity Metric" AS WITH us_topsongs AS( /* first two temporary tables get day counts for top songs in each region */
SELECT Track_Name, 
    Artist, 
    COUNT(*) AS days_in_top200
FROM spotify_top200
WHERE Region = 'us' 
GROUP BY Track_Name, Artist),

ca_topsongs AS(
SELECT Track_Name, 
    Artist, 
    COUNT(*) AS days_in_top200
FROM spotify_top200
WHERE Region = 'ca' 
GROUP BY Track_Name, Artist),

/* this table calculates the squared error of the days in top 200 for the shared songs among the two countries */
us_ca_shared AS(
SELECT us.Track_Name, 
    us.Artist, 
    us.days_in_top200, 
    ca.days_in_top200, 
    (us.days_in_top200-ca.days_in_top200)*(us.days_in_top200-ca.days_in_top200) AS squared_error
FROM us_topsongs AS us
INNER JOIN ca_topsongs AS ca
    ON us.Track_Name = ca.Track_name AND us.Artist = ca.Artist
WHERE us.Track_Name != '' AND us.Artist != '')

/* here we calculate teh sum of square errors, the percentage of shared songs, and the similarity metric which is a function of the two preceeding columns */
SELECT SUM(squared_error) AS SSE, 
    CAST(count(*) AS FLOAT) / ((SELECT COUNT(*) FROM us_topsongs) + (SELECT COUNT(*) FROM ca_topsongs)) AS perc_shared_songs,
    SUM(squared_error) * (1 - CAST(count(*) AS FLOAT) / ((SELECT COUNT(*) FROM us_topsongs) + (SELECT COUNT(*) FROM ca_topsongs))) AS similarity_metric
FROM us_ca_shared;

-- View: US-JP Similarity Metric
CREATE VIEW "US-JP Similarity Metric" AS WITH us_topsongs AS( /* first two temporary tables get day counts for top songs in each region */
SELECT Track_Name, 
    Artist, 
    COUNT(*) AS days_in_top200
FROM spotify_top200
WHERE Region = 'us' 
GROUP BY Track_Name, Artist),

jp_topsongs AS(
SELECT Track_Name, 
    Artist, 
    COUNT(*) AS days_in_top200
FROM spotify_top200
WHERE Region = 'jp' 
GROUP BY Track_Name, Artist),

/* this table calculates the squared error of the days in top 200 for the shared songs among the two countries */
us_jp_shared AS(
SELECT us.Track_Name, 
    us.Artist, 
    us.days_in_top200, 
    jp.days_in_top200, 
    (us.days_in_top200-jp.days_in_top200)*(us.days_in_top200-jp.days_in_top200) AS squared_error
FROM us_topsongs as us
INNER JOIN jp_topsongs as jp
    ON us.Track_Name = jp.Track_name AND us.Artist = jp.Artist
WHERE us.Track_Name != '' AND us.Artist != '')

/* here we calculate teh sum of square errors, the percentage of shared songs, and the similarity metric which is a function of the two preceeding columns */
SELECT SUM(squared_error) AS SSE, 
    CAST(count(*) AS FLOAT) / ((SELECT COUNT(*) FROM us_topsongs) + (SELECT COUNT(*) FROM jp_topsongs)) AS perc_shared_songs,
    SUM(squared_error) * (1 - CAST(count(*) AS FLOAT) / ((SELECT COUNT(*) FROM us_topsongs) + (SELECT COUNT(*) FROM jp_topsongs))) AS similarity_metric
FROM us_jp_shared;

-- View: US-MX Similarity Metric
CREATE VIEW "US-MX Similarity Metric" AS WITH us_topsongs AS( /* first two temporary tables get day counts for top songs in each region */
SELECT Track_Name, 
    Artist, 
    COUNT(*) AS days_in_top200
FROM spotify_top200
WHERE Region = 'us' 
GROUP BY Track_Name, Artist),

mx_topsongs AS(
SELECT Track_Name, 
    Artist, 
    COUNT(*) AS days_in_top200
FROM spotify_top200
WHERE Region = 'mx' 
GROUP BY Track_Name, Artist),

/* this table calculates the squared error of the days in top 200 for the shared songs among the two countries */
us_mx_shared AS(
SELECT us.Track_Name, 
    us.Artist, 
    us.days_in_top200, 
    mx.days_in_top200, 
    (us.days_in_top200-mx.days_in_top200)*(us.days_in_top200-mx.days_in_top200) AS squared_error
FROM us_topsongs as us
INNER JOIN mx_topsongs as mx
    ON us.Track_Name = mx.Track_name AND us.Artist = mx.Artist
WHERE us.Track_Name != '' AND us.Artist != '')

/* here we calculate teh sum of square errors, the percentage of shared songs, and the similarity metric which is a function of the two preceeding columns */
SELECT SUM(squared_error) AS SSE, 
    CAST(count(*) AS FLOAT) / ((SELECT COUNT(*) FROM us_topsongs) + (SELECT COUNT(*) FROM mx_topsongs)) AS perc_shared_songs,
    SUM(squared_error) * (1 - CAST(count(*) AS FLOAT) / ((SELECT COUNT(*) FROM us_topsongs) + (SELECT COUNT(*) FROM mx_topsongs))) AS similarity_metric
FROM us_mx_shared;

COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
