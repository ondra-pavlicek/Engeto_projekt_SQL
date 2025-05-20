/*
 * 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 * */	
	WITH food_price_avg_yearly
     AS (
SELECT
	Avg(price_value_avg) AS price_value_avg,
	YEAR,
	'Food' AS category_name
FROM
	t_ondrej_pavlicek_project_sql_primary_final
WHERE
	price_value_avg IS NOT NULL
GROUP BY
	YEAR),
     food_price_avg_yearly_2
     AS (
SELECT
	*,
	FIRST_VALUE(price_value_avg)
                  OVER (
ORDER BY
	YEAR DESC)
                   AS last_price,
	LAST_VALUE(price_value_avg)
                  OVER (
ORDER BY
	YEAR DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED
                  FOLLOWING)
                   AS
                first_price,
	COALESCE(LAG(price_value_avg)
                           OVER (
                             ORDER BY YEAR DESC), 0)
                   AS NEXT,
	COALESCE(LEAD(price_value_avg)
                           OVER (
                             ORDER BY YEAR DESC), price_value_avg)
                   AS previous
FROM
	food_price_avg_yearly
WHERE
	price_value_avg IS NOT NULL),
     food_price_avg_yearly_3
     AS (
SELECT
	*,
	price_value_avg - previous AS
                   difference_abs_YTY,
	( price_value_avg - previous ) / NULLIF(previous, 0) AS
                   difference_relative_YTY
FROM
	food_price_avg_yearly_2
ORDER BY
	YEAR DESC),
     incomes_avg_yearly
     AS (
SELECT
	Avg(income_value_avg) AS income_value_avg,
	YEAR,
	'Industry' AS category_name
FROM
	t_ondrej_pavlicek_project_sql_primary_final
WHERE
	income_value_avg IS NOT NULL
GROUP BY
	YEAR),
     incomes_avg_yearly_2
     AS (
SELECT
	*,
	FIRST_VALUE(income_value_avg)
                  OVER (
ORDER BY
	YEAR DESC)
                   AS last_price,
	LAST_VALUE(income_value_avg)
                  OVER (
ORDER BY
	YEAR DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED
                  FOLLOWING)
                   AS
                first_price,
	COALESCE(LAG(income_value_avg)
                           OVER (
                             ORDER BY YEAR DESC), 0)
                   AS NEXT,
	COALESCE(LEAD(income_value_avg)
                           OVER (
                             ORDER BY YEAR DESC), income_value_avg)
                   AS previous
FROM
	incomes_avg_yearly
WHERE
	income_value_avg IS NOT NULL),
     incomes_avg_yearly_3
     AS (
SELECT
	*,
	income_value_avg - previous AS
                   difference_abs_YTY,
	( income_value_avg - previous ) / NULLIF(previous, 0) AS
                   difference_relative_YTY
FROM
	incomes_avg_yearly_2
ORDER BY
	YEAR DESC)
SELECT
	food_price_avg_yearly_3.year,
	food_price_avg_yearly_3.category_name,
	Round(food_price_avg_yearly_3.difference_relative_yty * 100, 2) AS
       food_difference_relative_YTY,
	incomes_avg_yearly_3.category_name AS
       category_name,
	Round(incomes_avg_yearly_3.difference_relative_yty * 100, 2) AS
       incomes_difference_relative_YTY,
    Round(food_price_avg_yearly_3.difference_relative_yty / incomes_avg_yearly_3.difference_relative_yty * 100, 2)   AS Food_Incomes_Ratio,
	CASE
		WHEN food_price_avg_yearly_3.difference_relative_yty >
              incomes_avg_yearly_3.difference_relative_yty * 1.1 THEN
         'Price/Incomes > 10% '
		WHEN food_price_avg_yearly_3.difference_relative_yty >
              incomes_avg_yearly_3.difference_relative_yty THEN
         'Price/Incomes (0;10%)'
		WHEN food_price_avg_yearly_3.difference_relative_yty =
              incomes_avg_yearly_3.difference_relative_yty THEN
         'Price/Incomes = 1'
		ELSE 'Neprevysuje'
	END AS
       price_increase_measure
FROM
	food_price_avg_yearly_3
JOIN incomes_avg_yearly_3
         ON
	food_price_avg_yearly_3.year = incomes_avg_yearly_3.year
WHERE
	food_price_avg_yearly_3.difference_relative_yty >
       incomes_avg_yearly_3.difference_relative_yty * 1.1
ORDER BY
	food_price_avg_yearly_3.year DESC;
	