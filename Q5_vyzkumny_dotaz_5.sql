/*
	 * 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
	 * */
WITH food_price_avg_yearly
  AS (
SELECT
	AVG(price_value_avg) AS price_value_avg ,
	YEAR ,
	'Food' AS category_name
FROM
	t_ondrej_pavlicek_project_sql_primary_final
WHERE
	price_value_avg IS NOT NULL
GROUP BY
	YEAR
    ) ,
  food_price_avg_yearly_2
  AS (
SELECT
	* ,
	FIRST_VALUE(price_value_avg) OVER (
	ORDER BY YEAR DESC) AS last_price ,
	LAST_VALUE(price_value_avg) OVER (
	ORDER BY YEAR DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS first_price ,
	COALESCE(LAG(price_value_avg) OVER (ORDER BY YEAR DESC) , 0) AS NEXT ,
	COALESCE(LEAD(price_value_avg) OVER (ORDER BY YEAR DESC) , price_value_avg) AS previous
FROM
	food_price_avg_yearly
WHERE
	price_value_avg IS NOT NULL
    ) ,
  food_price_avg_yearly_3
  AS (
SELECT
	* ,
	price_value_avg - previous AS food_price_difference_abs_YTY ,
	(price_value_avg - previous) / NULLIF(previous , 0) AS food_price_difference_relative_YTY
FROM
	food_price_avg_yearly_2
ORDER BY
	YEAR DESC
    ) ,
  incomes_avg_yearly
  AS (
SELECT
	AVG(income_value_avg) AS income_value_avg ,
	YEAR ,
	'Industry' AS category_name
FROM
	t_ondrej_pavlicek_project_sql_primary_final
WHERE
	income_value_avg IS NOT NULL
GROUP BY
	YEAR
    ) ,
  incomes_avg_yearly_2
  AS (
SELECT
	* ,
	FIRST_VALUE(income_value_avg) OVER (
	ORDER BY YEAR DESC) AS last_price ,
	LAST_VALUE(income_value_avg) OVER (
	ORDER BY YEAR DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS first_price ,
	COALESCE(LAG(income_value_avg) OVER (ORDER BY YEAR DESC) , 0) AS NEXT ,
	COALESCE(LEAD(income_value_avg) OVER (ORDER BY YEAR DESC) , income_value_avg) AS previous
FROM
	incomes_avg_yearly
WHERE
	income_value_avg IS NOT NULL
    ) ,
  incomes_avg_yearly_3
  AS (
SELECT
	* ,
	income_value_avg - previous AS incomes_difference_abs_YTY ,
	(income_value_avg - previous) / NULLIF(previous , 0) AS incomes_difference_relative_YTY
FROM
	incomes_avg_yearly_2
ORDER BY
	YEAR DESC
    ) ,
  prehled_o_obsahu_tabulky
  AS (
SELECT
	DISTINCT country ,
	MIN(YEAR) AS min_year ,
	MAX(YEAR) AS max_year
FROM
	t_ondrej_pavlicek_project_sql_secondary_final
GROUP BY
	country
    ) ,
  gdp_data
  AS (
SELECT
	*
FROM
	t_ondrej_pavlicek_project_sql_secondary_final
    ) ,
  gdp_data_2
  AS (
SELECT
	* ,
	FIRST_VALUE(gdp_per_cap) OVER (PARTITION BY country
ORDER BY
	YEAR DESC) AS last_gdp ,
	LAST_VALUE(gdp_per_cap) OVER (PARTITION BY country
ORDER BY
	YEAR DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_gdp ,
	COALESCE(LAG(gdp_per_cap) OVER (PARTITION BY country ORDER BY YEAR DESC) , 0) AS NEXT ,
	COALESCE(LEAD(gdp_per_cap) OVER (PARTITION BY country ORDER BY YEAR DESC) , gdp_per_cap) AS previous
FROM
	gdp_data
    ) ,
  gdp_data_3
  AS (
SELECT
	* ,
	gdp_per_cap - previous AS gdp_difference_abs_YTY ,
	((gdp_per_cap - previous) / previous) AS gdp_differences_relative_yty
FROM
	gdp_data_2
ORDER BY
	country ASC ,
	YEAR DESC
    ) ,
  gdp_data_4
  AS (
SELECT
	YEAR ,
	Country ,
	gdp_differences_relative_yty
FROM
	gdp_data_3
WHERE
	country LIKE 'Czech%'
    ) ,
  food_price_incomes_gdp
  AS (
SELECT
	food_price_avg_yearly_3.year ,
	food_price_avg_yearly_3.category_name ,
	food_price_avg_yearly_3.food_price_difference_relative_yty AS food_price_difference_relative_yty ,
	incomes_avg_yearly_3.category_name AS kategorie_prijmu ,
	incomes_avg_yearly_3.incomes_difference_relative_yty AS incomes_difference_relative_yty ,
	gdp_data_4.gdp_differences_relative_yty AS gdp_differences_relative_yty ,
	CASE
		WHEN food_price_avg_yearly_3.food_price_difference_relative_yty > incomes_avg_yearly_3.incomes_difference_relative_yty * 1.1 THEN 'Higher tahn 10%'
		WHEN food_price_avg_yearly_3.food_price_difference_relative_yty > incomes_avg_yearly_3.incomes_difference_relative_yty THEN 'Between 100 and 110%'
		WHEN food_price_avg_yearly_3.food_price_difference_relative_yty = incomes_avg_yearly_3.incomes_difference_relative_yty THEN 'Eqal'
		ELSE 'Less than 100%'
	END AS rust_cen_potravin_vs_rust_mezd
FROM
	gdp_data_4
JOIN incomes_avg_yearly_3 ON
	gdp_data_4.year = incomes_avg_yearly_3.year
JOIN food_price_avg_yearly_3 ON
	food_price_avg_yearly_3.year = gdp_data_4.year
ORDER BY
	food_price_avg_yearly_3.year DESC
    ) ,
  GDPpCAP_estimation
  AS (
SELECT
	* ,
	COALESCE(LEAD(gdp_differences_relative_yty) OVER (ORDER BY YEAR DESC) , gdp_differences_relative_yty , 3) AS gdp_differences_relative_yyty ,
	CASE
		WHEN food_price_difference_relative_yty > 0
		AND incomes_difference_relative_yty > 0
		AND (gdp_differences_relative_yty > 0
			OR COALESCE(LEAD(gdp_differences_relative_yty) OVER (ORDER BY YEAR DESC) , gdp_differences_relative_yty) > 0) THEN 'Při nárůstu GDPpCAP zdražily potraviny a rostly mzdy'
		WHEN food_price_difference_relative_yty > 0
		AND incomes_difference_relative_yty < 0
		AND (gdp_differences_relative_yty > 0
			OR COALESCE(LEAD(gdp_differences_relative_yty) OVER (ORDER BY YEAR DESC) , gdp_differences_relative_yty) > 0) THEN 'Při nárůstu GDPpCAP zdražily potraviny a nerostly mzdy'
		WHEN food_price_difference_relative_yty < 0
		AND incomes_difference_relative_yty > 0
		AND (gdp_differences_relative_yty > 0
			OR COALESCE(LEAD(gdp_differences_relative_yty) OVER (ORDER BY YEAR DESC) , gdp_differences_relative_yty) > 0) THEN 'Při nárůstu GDPpCAP zlevnily potraviny a rostly mzdy'
		WHEN food_price_difference_relative_yty < 0
		AND incomes_difference_relative_yty < 0
		AND (gdp_differences_relative_yty > 0
			OR COALESCE(LEAD(gdp_differences_relative_yty) OVER (ORDER BY YEAR DESC) , gdp_differences_relative_yty) > 0) THEN 'Při nárůstu GDPpCAP zlevnily potraviny a nerostly mzdy'
		ELSE 'Nerostlo GDPpCAP'
	END AS gdp_final
FROM
	food_price_incomes_gdp
    )
/*-- Tahle alternativa zobrazi vyhodnoceni pro jednotlive roky    
SELECT
gdp_final,
YEAR
FROM
GDPpCAP_estimation; 
--Zobrazi vyhodnoceni pro jednotlivé roky
*/
--Tahle alternativa zobrazi kumulativne podle vyhodnoceni
SELECT
	gdp_final ,
	COUNT(*) AS pocet
FROM
	GDPpCAP_estimation
GROUP BY
	gdp_final
ORDER BY
	COUNT(*) DESC;		
