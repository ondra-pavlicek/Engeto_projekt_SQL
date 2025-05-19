/*
 * 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 * */
--Dberaver idikuje chybu ve druhém poddotazu cte2 na řádcích odkazujících na hodnoty min_year, max_year indikuje ve slupci s čísly řádků s tím, že hodnoty slopce a tabulky nezná, možná mám víc štěstí než rozumu, ale AI mi říká, že TO mám správně. Třeba nefunguje správně nápověda v dbeaveru :-) Mám štěstí. Asi bych obešel pomocným dotazem tvořícím tabulky, proměnné nebo VIEW
WITH year_range AS (
    SELECT MIN(year) AS min_year, MAX(year) AS max_year
    FROM t_ondrej_pavlicek_project_sql_primary_final
    WHERE name IS NULL
    UNION
    SELECT MIN(year) AS min_year, MAX(year) AS max_year
    FROM t_ondrej_pavlicek_project_sql_primary_final
    WHERE name IS NOT NULL
),
cte2 AS (
    SELECT price_value_avg, category_code, category_name, price_value, price_unit, year
    FROM t_ondrej_pavlicek_project_sql_primary_final
    WHERE year IN (
        SELECT MAX(min_year) FROM year_range
        UNION
        SELECT MIN(max_year) FROM year_range
    )
    AND category_name IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované')
)
SELECT 
    ROUND(t.income_value_avg / c.price_value_avg, 2) AS ratio,
    CASE 
        WHEN c.price_value_avg = 16.12 THEN 'kg chleba 2006'
        WHEN c.price_value_avg = 24.24 THEN 'kg chleba 2018'
        WHEN c.price_value_avg = 14.44 THEN 'l mléka 2006'
        WHEN c.price_value_avg = 19.82 THEN 'l mléka 2018'
        ELSE 'Neznámá hodnota'
    END AS produkt_info,
    COALESCE(t.industry_name, 'Neuvedeno') AS industry_name,
    c.price_value_avg,
    t.income_value_avg,
    t.year
FROM t_ondrej_pavlicek_project_sql_primary_final t
JOIN cte2 c ON t.year = c.year
WHERE t.year IN (
    SELECT MAX(min_year) FROM year_range
    UNION
    SELECT MIN(max_year) FROM year_range
)
AND t.category_name IS NULL;