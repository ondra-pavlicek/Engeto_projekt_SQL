/*
 * 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 * */
--DOTAZ VYTVOŘÍ TABULKU, VYPOČÍTÁVAJÍCÍ POMĚR PRŮMĚRNÉ MZDY A PRŮMĚRNÉ JEDNOTKOVÉ CENY VYBRANÉHO PRODUKTU PRO KAŽDOU KATEGORII PRŮMYSLU V HORNÍM A DOLNÍ MEZI INTERVALU LET

WITH year_range
     AS (SELECT Min(year) 								AS min_year,
                Max(year) 								AS max_year
         FROM   t_ondrej_pavlicek_project_sql_primary_final
         WHERE  NAME IS NULL
         UNION
         SELECT Min(year)								AS min_year,
                Max(year) 								AS max_year
         FROM   t_ondrej_pavlicek_project_sql_primary_final
         WHERE  NAME IS NOT NULL),
     food_price_value_avg_years
     AS (SELECT price_value_avg,
                category_code,
                category_name,
                price_value,
                price_unit,
                year
         FROM   t_ondrej_pavlicek_project_sql_primary_final
         WHERE  year IN (SELECT Max(min_year)
                         FROM   year_range
                         UNION
                         SELECT Min(max_year)
                         FROM   year_range)
                AND category_name IN ( 'Chléb konzumní kmínový',
                                       'Mléko polotučné pasterované' ))
SELECT Round(t.income_value_avg / c.price_value_avg, 2) AS ratio,
       c.price_unit
       || ' '
       || c.category_name
       || ' '
       || c.year                                        AS product_info,
       COALESCE(t.industry_name, 'Neuvedeno')           AS industry_name,
       c.price_value_avg,
       t.income_value_avg,
       t.year
FROM   t_ondrej_pavlicek_project_sql_primary_final t
       JOIN food_price_value_avg_years c
         ON t.year = c.year
WHERE  t.year IN (SELECT Max(min_year)
                  FROM   year_range
                  UNION
                  SELECT Min(max_year)
                  FROM   year_range)
       AND t.category_name IS NULL
ORDER  BY industry_name DESC,
          product_info DESC,
          year DESC; 