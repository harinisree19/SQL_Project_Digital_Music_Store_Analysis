CREATE DATABASE MUSIC_DB;
USE MUSIC_DB;

/* SOLVING QUESTIONS OF THE COMPANY */

/* Q1: WHO IS THE SENIOR MOST EMPLOYEE BASED ON JOB TITLE? */

SELECT *FROM EMPLOYEE;

SELECT TITLE, LAST_NAME, FIRST_NAME 
FROM EMPLOYEE
ORDER BY LEVELS DESC
LIMIT 1;


/* Q2: WHICH COUNTRIES HAVE THE MOST INVOICES? */

SELECT *FROM INVOICE;

SELECT COUNT(*) AS INVOICE_COUNT, BILLING_COUNTRY 
FROM INVOICE
GROUP BY BILLING_COUNTRY
ORDER BY INVOICE_COUNT DESC;


/* Q3: WHAT ARE TOP 3 VALUES OF TOTAL INVOICE? */

SELECT *FROM INVOICE;

SELECT TOTAL 
FROM INVOICE
ORDER BY TOTAL DESC
LIMIT 3;


/* Q4: WHICH CITY HAS THE BEST CUSTOMERS? WE WOULD LIKE TO THROW A PROMOTIONAL MUSIC FESTIVAL IN THE CITY WE MADE THE MOST MONEY. 
WRITE A QUERY THAT RETURNS ONE CITY THAT HAS THE HIGHEST SUM OF INVOICE TOTALS. 
RETURN BOTH THE CITY NAME & SUM OF ALL INVOICE TOTALS */

SELECT *FROM INVOICE;

SELECT BILLING_CITY, SUM(TOTAL) AS INVOICE_TOTAL
FROM INVOICE
GROUP BY BILLING_CITY
ORDER BY INVOICE_TOTAL DESC
LIMIT 1;


/* Q5: WHO IS THE BEST CUSTOMER? THE CUSTOMER WHO HAS SPENT THE MOST MONEY WILL BE DECLARED THE BEST CUSTOMER. 
WRITE A QUERY THAT RETURNS THE PERSON WHO HAS SPENT THE MOST MONEY.*/

SELECT *FROM CUSTOMER;
SELECT *FROM INVOICE;

SET @@sql_mode = REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', '');

SELECT CUSTOMER.CUSTOMER_ID, CUSTOMER.FIRST_NAME, CUSTOMER.LAST_NAME, SUM(INVOICE.TOTAL) AS TOTAL_SPENDING
FROM CUSTOMER
INNER JOIN INVOICE ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
GROUP BY CUSTOMER.CUSTOMER_ID
ORDER BY TOTAL_SPENDING DESC
LIMIT 1;



/* Q6: WRITE QUERY TO RETURN THE EMAIL, FIRST NAME, LAST NAME, & GENRE OF ALL ROCK MUSIC LISTENERS. 
RETURN YOUR LIST ORDERED ALPHABETICALLY BY EMAIL STARTING WITH A. */

/*METHOD 1 */

SELECT DISTINCT EMAIL, FIRST_NAME, LAST_NAME
FROM CUSTOMER
JOIN INVOICE ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
JOIN INVOICE_LINE ON INVOICE.INVOICE_ID = INVOICE_LINE.INVOICE_ID
WHERE TRACK_ID IN(
	SELECT TRACK_ID FROM TRACK
	JOIN GENRE ON TRACK.GENRE_ID = GENRE.GENRE_ID
	WHERE GENRE.NAME LIKE 'ROCK'
)
ORDER BY EMAIL;


/* METHOD 2 */

SELECT DISTINCT EMAIL AS EMAIL, FIRST_NAME AS FIRSTNAME, LAST_NAME AS LASTNAME, GENRE.NAME AS NAME
FROM CUSTOMER
JOIN INVOICE ON INVOICE.CUSTOMER_ID = CUSTOMER.CUSTOMER_ID
JOIN INVOICE_LINE ON INVOICE_LINE.INVOICE_ID = INVOICE.INVOICE_ID
JOIN TRACK ON TRACK.TRACK_ID = INVOICE_LINE.TRACK_ID
JOIN GENRE ON GENRE.GENRE_ID = TRACK.GENRE_ID
WHERE GENRE.NAME LIKE 'ROCK'
ORDER BY EMAIL;


/* Q7: LET'S INVITE THE ARTISTS WHO HAVE WRITTEN THE MOST ROCK MUSIC IN OUR DATASET. 
WRITE A QUERY THAT RETURNS THE ARTIST NAME AND TOTAL TRACK COUNT OF THE TOP 10 ROCK BANDS. */

SELECT ARTIST.ARTIST_ID, ARTIST.NAME, COUNT(ARTIST.ARTIST_ID) AS NUMBER_OF_SONGS
FROM TRACK
JOIN ALBUM ON ALBUM.ALBUM_ID = TRACK.ALBUM_ID
JOIN ARTIST ON ARTIST.ARTIST_ID = ALBUM.ARTIST_ID
JOIN GENRE ON GENRE.GENRE_ID = TRACK.GENRE_ID
WHERE GENRE.NAME LIKE 'ROCK'
GROUP BY ARTIST.ARTIST_ID
ORDER BY NUMBER_OF_SONGS DESC
LIMIT 10;


/* Q8: RETURN ALL THE TRACK NAMES THAT HAVE A SONG LENGTH LONGER THAN THE AVERAGE SONG LENGTH. 
RETURN THE NAME AND MILLISECONDS FOR EACH TRACK. ORDER BY THE SONG LENGTH WITH THE LONGEST SONGS LISTED FIRST. */

SELECT NAME, MILLISECONDS
FROM TRACK
WHERE MILLISECONDS > (
	SELECT AVG(MILLISECONDS) AS AVG_TRACK_LENGTH
	FROM TRACK )
ORDER BY MILLISECONDS DESC;



/* Q9: FIND HOW MUCH AMOUNT SPENT BY EACH CUSTOMER ON ARTISTS? WRITE A QUERY TO RETURN CUSTOMER NAME, ARTIST NAME AND TOTAL SPENT */

/* STEPS TO SOLVE: FIRST, FIND WHICH ARTIST HAS EARNED THE MOST ACCORDING TO THE INVOICELINES. NOW USE THIS ARTIST TO FIND 
WHICH CUSTOMER SPENT THE MOST ON THIS ARTIST. FOR THIS QUERY, YOU WILL NEED TO USE THE INVOICE, INVOICELINE, TRACK, CUSTOMER, 
ALBUM, AND ARTIST TABLES. NOTE, THIS ONE IS TRICKY BECAUSE THE TOTAL SPENT IN THE INVOICE TABLE MIGHT NOT BE ON A SINGLE PRODUCT, 
SO YOU NEED TO USE THE INVOICELINE TABLE TO FIND OUT HOW MANY OF EACH PRODUCT WAS PURCHASED, AND THEN MULTIPLY THIS BY THE PRICE
FOR EACH ARTIST. */

WITH BEST_SELLING_ARTIST AS (
	SELECT ARTIST.ARTIST_ID AS ARTIST_ID, ARTIST.NAME AS ARTIST_NAME, SUM(INVOICE_LINE.UNIT_PRICE*INVOICE_LINE.QUANTITY) AS TOTAL_SALES
	FROM INVOICE_LINE
	JOIN TRACK ON TRACK.TRACK_ID = INVOICE_LINE.TRACK_ID
	JOIN ALBUM ON ALBUM.ALBUM_ID = TRACK.ALBUM_ID
	JOIN ARTIST ON ARTIST.ARTIST_ID = ALBUM.ARTIST_ID
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT C.CUSTOMER_ID, C.FIRST_NAME, C.LAST_NAME, BSA.ARTIST_NAME, SUM(IL.UNIT_PRICE*IL.QUANTITY) AS AMOUNT_SPENT
FROM INVOICE I
JOIN CUSTOMER C ON C.CUSTOMER_ID = I.CUSTOMER_ID
JOIN INVOICE_LINE IL ON IL.INVOICE_ID = I.INVOICE_ID
JOIN TRACK T ON T.TRACK_ID = IL.TRACK_ID
JOIN ALBUM ALB ON ALB.ALBUM_ID = T.ALBUM_ID
JOIN BEST_SELLING_ARTIST BSA ON BSA.ARTIST_ID = ALB.ARTIST_ID
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


/* Q10: WE WANT TO FIND OUT THE MOST POPULAR MUSIC GENRE FOR EACH COUNTRY. WE DETERMINE THE MOST POPULAR GENRE AS THE GENRE 
WITH THE HIGHEST AMOUNT OF PURCHASES. WRITE A QUERY THAT RETURNS EACH COUNTRY ALONG WITH THE TOP GENRE. FOR COUNTRIES WHERE 
THE MAXIMUM NUMBER OF PURCHASES IS SHARED RETURN ALL GENRES. */

/* STEPS TO SOLVE:  THERE ARE TWO PARTS IN QUESTION- FIRST MOST POPULAR MUSIC GENRE AND SECOND NEED DATA AT COUNTRY LEVEL. */

/* METHOD 1: USING CTE */

WITH POPULAR_GENRE AS 
(
    SELECT COUNT(INVOICE_LINE.QUANTITY) AS PURCHASES, CUSTOMER.COUNTRY, GENRE.NAME, GENRE.GENRE_ID, 
	ROW_NUMBER() OVER(PARTITION BY CUSTOMER.COUNTRY ORDER BY COUNT(INVOICE_LINE.QUANTITY) DESC) AS ROWNO 
    FROM INVOICE_LINE 
	JOIN INVOICE ON INVOICE.INVOICE_ID = INVOICE_LINE.INVOICE_ID
	JOIN CUSTOMER ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
	JOIN TRACK ON TRACK.TRACK_ID = INVOICE_LINE.TRACK_ID
	JOIN GENRE ON GENRE.GENRE_ID = TRACK.GENRE_ID
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM POPULAR_GENRE WHERE ROWNO <= 1;


/* METHOD 2: : USING RECURSIVE */

WITH RECURSIVE
	SALES_PER_COUNTRY AS(
		SELECT COUNT(*) AS PURCHASES_PER_GENRE, CUSTOMER.COUNTRY, GENRE.NAME, GENRE.GENRE_ID
		FROM INVOICE_LINE
		JOIN INVOICE ON INVOICE.INVOICE_ID = INVOICE_LINE.INVOICE_ID
		JOIN CUSTOMER ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
		JOIN TRACK ON TRACK.TRACK_ID = INVOICE_LINE.TRACK_ID
		JOIN GENRE ON GENRE.GENRE_ID = TRACK.GENRE_ID
		GROUP BY 2,3,4
		ORDER BY 2
	),
	MAX_GENRE_PER_COUNTRY AS (SELECT MAX(PURCHASES_PER_GENRE) AS MAX_GENRE_NUMBER, COUNTRY
		FROM SALES_PER_COUNTRY
		GROUP BY 2
		ORDER BY 2)

SELECT SALES_PER_COUNTRY.* 
FROM SALES_PER_COUNTRY
JOIN MAX_GENRE_PER_COUNTRY ON SALES_PER_COUNTRY.COUNTRY = MAX_GENRE_PER_COUNTRY.COUNTRY
WHERE SALES_PER_COUNTRY.PURCHASES_PER_GENRE = MAX_GENRE_PER_COUNTRY.MAX_GENRE_NUMBER;


/* Q11: WRITE A QUERY THAT DETERMINES THE CUSTOMER THAT HAS SPENT THE MOST ON MUSIC FOR EACH COUNTRY. 
WRITE A QUERY THAT RETURNS THE COUNTRY ALONG WITH THE TOP CUSTOMER AND HOW MUCH THEY SPENT. 
FOR COUNTRIES WHERE THE TOP AMOUNT SPENT IS SHARED, PROVIDE ALL CUSTOMERS WHO SPENT THIS AMOUNT. */

/* STEPS TO SOLVE:  SIMILAR TO THE ABOVE QUESTION. THERE ARE TWO PARTS IN QUESTION- 
FIRST FIND THE MOST SPENT ON MUSIC FOR EACH COUNTRY AND SECOND FILTER THE DATA FOR RESPECTIVE CUSTOMERS. */

/* METHOD 1: USING CTE */

WITH CUSTOMTER_WITH_COUNTRY AS (
		SELECT CUSTOMER.CUSTOMER_ID,FIRST_NAME,LAST_NAME,BILLING_COUNTRY,SUM(TOTAL) AS TOTAL_SPENDING,
	    ROW_NUMBER() OVER(PARTITION BY BILLING_COUNTRY ORDER BY SUM(TOTAL) DESC) AS ROWNO 
		FROM INVOICE
		JOIN CUSTOMER ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM CUSTOMTER_WITH_COUNTRY WHERE ROWNO <= 1;


/* METHOD 2: USING RECURSIVE */

WITH RECURSIVE 
	CUSTOMTER_WITH_COUNTRY AS (
		SELECT CUSTOMER.CUSTOMER_ID,FIRST_NAME,LAST_NAME,BILLING_COUNTRY,SUM(TOTAL) AS TOTAL_SPENDING
		FROM INVOICE
		JOIN CUSTOMER ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	COUNTRY_MAX_SPENDING AS(
		SELECT BILLING_COUNTRY,MAX(TOTAL_SPENDING) AS MAX_SPENDING
		FROM CUSTOMTER_WITH_COUNTRY
		GROUP BY BILLING_COUNTRY)

SELECT CC.BILLING_COUNTRY, CC.TOTAL_SPENDING, CC.FIRST_NAME, CC.LAST_NAME, CC.CUSTOMER_ID
FROM CUSTOMTER_WITH_COUNTRY CC
JOIN COUNTRY_MAX_SPENDING MS
ON CC.BILLING_COUNTRY = MS.BILLING_COUNTRY
WHERE CC.TOTAL_SPENDING = MS.MAX_SPENDING
ORDER BY 1;



