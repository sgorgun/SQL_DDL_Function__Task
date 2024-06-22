--1. Create a view called "sales_revenue_by_category_qtr"
-- that shows the film category and total sales revenue for
-- the current quarter. The view should only display categories
-- with at least one sale in the current quarter. The current quarter
-- should be determined dynamically.
CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT
    c.name AS category,
    SUM(p.amount) AS total_sales
FROM
    category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
WHERE
    p.payment_date >= date_trunc('quarter', CURRENT_DATE)
GROUP BY
    c.name
HAVING
    SUM(p.amount) > 0;

--2. Create a query language function called "get_sales_revenue_by_category_qtr" that accepts one
-- parameter representing the current quarter and returns the same result as the "sales_revenue_by_category_qtr"
-- view.
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(current_quarter_start TIMESTAMPTZ)
RETURNS TABLE (category TEXT, total_sales NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.name AS category,
        SUM(p.amount) AS total_sales
    FROM
        category c
    JOIN film_category fc ON c.category_id = fc.category_id
    JOIN inventory i ON fc.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    WHERE
        p.payment_date >= current_quarter_start
    GROUP BY
        c.name
    HAVING
        SUM(p.amount) > 0;
END;
$$ LANGUAGE plpgsql;

-- Вызов функции
SELECT * FROM get_sales_revenue_by_category_qtr(date_trunc('quarter', CURRENT_DATE));


--3. Create a procedure language function called "new_movie" that takes a movie title as a parameter
-- and inserts a new movie with the given title in the film table. The function should generate a new
-- unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost
-- to 19.99, the release year to the current year, and "language" as Klingon. The function should also 
-- verify that the language exists in the "language" table. Then, ensure that no such function has been
-- created before; if so, replace it.
CREATE OR REPLACE PROCEDURE new_movie(movie_title TEXT)
AS $$
DECLARE
    new_film_id INT;
    klingon_language_id INT;
    existing_film_count INT;
BEGIN
    SELECT language_id INTO klingon_language_id
    FROM language
    WHERE name = 'Klingon';
-- Проверка на существование языка "Klingon"
    IF klingon_language_id IS NULL THEN
        RAISE EXCEPTION 'Language "Klingon" does not exist in the language table';
    END IF;

    SELECT COUNT(*) INTO existing_film_count
    FROM film
    WHERE title = movie_title;
-- Проверка на существование фильма с таким же названием
    IF existing_film_count > 0 THEN
        RAISE EXCEPTION 'A movie with the title "%" already exists', movie_title;
    END IF;

    SELECT nextval('film_film_id_seq') INTO new_film_id;

    INSERT INTO film (
        film_id,
        title,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        last_update
    ) VALUES (
        new_film_id,
        movie_title,
        EXTRACT(YEAR FROM CURRENT_DATE),
        klingon_language_id,
        3,
        4.99,
        19.99,
        CURRENT_TIMESTAMP
    );

    RAISE NOTICE 'New movie "%" has been added with film_id %', movie_title, new_film_id;
END;
$$ LANGUAGE plpgsql;

-- Вставка записи в таблицу language
INSERT INTO language (name)
VALUES ('Klingon');

-- Вызов процедуры
CALL new_movie('Star Wars: The Rise of Skywalker');