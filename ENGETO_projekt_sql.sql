/*
 * kontrola sekvanci pomoci copilota, claude.ai
 * fromatování kodu pomoci https://www.dpriver.com/pp/sqlformat.htm
 * 
 * */

/*
 * VYTVORENI TABULKY t_ondrej_pavlicek_project_sql_primary_final
 * VYTVORENI POMOCNYCH TABULEK KTERE SPOJIM DO PRVNI TABULUKY, POMOCNE TABULKY POTOM SMAZU
 * 
 * */

-- POMOCNA TABULKA S PRIJMY
CREATE TABLEIF NOT EXISTS t_ondrej_pavlicek_project_sql_primary_final_payroll AS
(
          SELECT
                    --připravim si prázdné sloupce pro sjednoceni s druhou tabulkou
                    NULL::numeric                 AS price_value_avg,
                    NULL::integer                 AS category_code,
                    NULL::varchar(50)             AS category_name,
                    NULL::float(8)                AS price_value,
                    NULL::varchar(2)              AS price_unit,
                    round(avg(value)::numeric, 2) AS income_value_avg,
                    --cp.value_type_code,
                    cpvt.NAME AS value_type_name,
                    --cp.unit_code,
                    /*
* jednodušší cesta jak by šlo opravit napojení unit_code aby výsledkem byla Kč:
* 1) 'kč' AS mena,
* 2) v joinu upravit podmínku na cp.unit_code <> cpu.code , což mi projde jen proto, že jsou jen dvě hodnoty cpu.code
* 3) update v databázi/výstupu v příslušném sloupci
* 4) volím využití jednoduché matematiky a přičtení 80203, abych dostal hodnotu klíče odpovídajícího Kč :-)
* */
                    cpu.NAME,
                    --cp.calculation_code,
                    cpc.NAME AS calculation_name,
                    cp.industry_branch_code,
                    --vyřazením toho sloupce ale přijdu o 22 hodnot, u kterých nebyl vyplněn atribut a měly hodnotu "NULL". Může to být chyba v datech, ale taky příležitost jak ztratit část dat
                    cpib.NAME       AS industry_name,
                    cp.payroll_year AS year
          FROM      czechia_payroll cp
          JOIN      czechia_payroll_unit cpu
          ON        cp.unit_code + 80203 = cpu.code
          JOIN      czechia_payroll_value_type cpvt
          ON        cp.value_type_code = cpvt.code
          LEFT JOIN czechia_payroll_industry_branch cpib
          ON        cp.industry_branch_code = cpib.code
          JOIN      czechia_payroll_calculation cpc
          ON        cp.calculation_code = cpc.code
          WHERE     cp.value IS NOT NULL
          AND       cp.value_type_code = '5958'
          AND       cp.calculation_code = 100
          GROUP BY  cp.payroll_year,
                    --cp.value_type_code,
                    cpu.NAME,
                    cpvt.NAME,
                    --cp.unit_code,
                    --cp.calculation_code,
                    cpc.NAME,
                    cp.industry_branch_code,
                    cpib.NAME
          ORDER BY  cp.industry_branch_code ASC,
                    cp.payroll_year DESC
);
--POMOCNA TABULKA S CENAMICREATE TABLEIF NOT EXISTS t_ondrej_pavlicek_project_sql_primary_final_payroll_prices AS
(
         SELECT   round(avg(cp.value)::numeric, 2) AS price_value_avg,
                  cp.category_code,
                  cpc.NAME AS category_name,
                  cpc.price_value,
                  cpc.price_unit,
                  NULL::numeric                   AS income_value_avg,
                  NULL::varchar(50)               AS value_type_name,
                  NULL::varchar(50)               AS NAME,
                  NULL::varchar(50)               AS calculation_name,
                  NULL::bpchar(1)                 AS industry_branch_code,
                  NULL::varchar(255)              AS industry_name,
                  date_part('year', cp.date_from) AS year
         FROM     czechia_price cp
         JOIN     czechia_price_category cpc
         ON       cp.category_code = cpc.code
         WHERE    cp.region_code IS NOT NULL
         GROUP BY category_code,
                  date_part('year', date_from),
                  cpc.NAME,
                  cpc.price_value,
                  cpc.price_unit
) ;

--KONTROLNÍ SELEKTY K ZOBRAZENI POMOCNYCH TABULEK
SELECT *
FROM   t_ondrej_pavlicek_project_sql_primary_final_payroll;

SELECT *
FROM   t_ondrej_pavlicek_project_sql_primary_final_payroll_prices; 

/*
 * SJEDNOCENI POMOCNYCH TABULEK PODLE ROKU
*/
DROP TABLE IF EXISTS t_ondrej_pavlicek_project_sql_primary_final;

CREATE TABLE IF NOT EXISTS t_ondrej_pavlicek_project_sql_primary_final AS
  (SELECT *
   FROM   t_ondrej_pavlicek_project_sql_primary_final_payroll
   UNION
   SELECT *
   FROM   t_ondrej_pavlicek_project_sql_primary_final_payroll_prices);

SELECT *
FROM   t_ondrej_pavlicek_project_sql_primary_final; 

/*
 * SMAZANI POMOCNYCH TABULEK
 * */
DROP TABLE IF EXISTS t_ondrej_pavlicek_project_SQL_primary_final_payroll_prices;
DROP TABLE IF EXISTS t_ondrej_pavlicek_project_SQL_primary_final_payroll;

/*
 * VYTVOŘENÍ TABULKY t_ondrej_pavlicek_project_SQL_secondary_final
 * */

CREATE TABLE IF NOT EXISTS t_ondrej_pavlicek_project_sql_secondary_final AS
  (SELECT DISTINCT country,
                   year,
                   gdp,
                   population,
                   gdp / population AS "gdp_per_cap"
   FROM   economies
   WHERE  ( country IN (SELECT DISTINCT country
                        FROM   countries
                        WHERE  continent LIKE ( '%Europe%' ))
             OR country LIKE '%Euro%' )
          AND gdp IS NOT NULL
   ORDER  BY country,
             year DESC);

--KONTROLNI SELEKT K ZOBRAZENÍ VYTVOŘENÉ TABULKY
SELECT *
FROM   t_ondrej_pavlicek_project_sql_secondary_final;
/*
 * KONEC TVORBY POMOCNYCH TABULEK------------------------------------------------------------
 * */


/*
 * SELEKTY NA JEDNOTLIVÉ VÝZKUMNÉ OTÁZKY
 * */


/*
 * 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?----------------
 * */
--DOTAZ VYHODNOTÍM MEZIROČNÍ ZMĚNU, IDENTIFIKUJE ODVĚTVÍ A ROK, VE KTERÉM DOŠLO K MEZIROČNÍMU POKLESU, DOTAZ NEHODNOTÍ TREND ZA CELÉ SLEDOVANÉ OBDOBÍ
WITH incomes_by_industry_name
     AS (SELECT Coalesce (industry_branch_code, 'Neuveden')              AS	industry_branch_code,
                
                Coalesce (industry_name, 'Neuveden')                     AS industry_name,
                year,
                Avg(income_value_avg)                                    AS avg_income,
                Coalesce(Lead(Avg(income_value_avg))
                           over (
                             PARTITION BY industry_branch_code
                             ORDER BY year DESC), Avg(income_value_avg)) AS prev_year_income,
                First_value(Avg(income_value_avg))
                  over (
                    PARTITION BY industry_branch_code
                    ORDER BY year DESC)                                  AS last_income,
                Last_value(Avg(income_value_avg))
                  over (
                    PARTITION BY industry_branch_code
                    ORDER BY year DESC ROWS BETWEEN unbounded preceding AND
                  unbounded
                  following)
                                                                         AS first_income
         FROM   t_ondrej_pavlicek_project_sql_primary_final
         GROUP  BY industry_branch_code,
                   industry_name,
                   year)
SELECT industry_name,
       year,
       -- umyslne zobrazuju navic sloupce pro snažší kontrolu výstupu
       avg_income,
       prev_year_income,
       ( avg_income - prev_year_income ) AS income_change,
       first_income,
       last_income,
       last_income - first_income        AS income_change_period
FROM   incomes_by_industry_name
WHERE  ( avg_income - prev_year_income ) < 0
--pokud bych chtěl hodnotit meziroční změnu, resp jen meziroční poklesy
--WHERE (last_income-first_income)<0 -- pokud BY mi stačilo hodnotit jen za celé sledované období, ale TO BY bylo vhodné i snížit počet řádků v odpovědi, vzhledem k tomu, že ve všech obdobích za celé období nakonec nzdy vzrostly, nedává ani smysl
ORDER  BY industry_name,
          year DESC; 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
 * 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 * */
WITH year_range
     AS (SELECT Min(year) AS min_year,
                Max(year) AS max_year
         FROM   t_ondrej_pavlicek_project_sql_primary_final
         WHERE  NAME IS NULL
         UNION ALL
         SELECT Min(year) AS min_year,
                Max(year) AS max_year
         FROM   t_ondrej_pavlicek_project_sql_primary_final
         WHERE  NAME IS NOT NULL),
     cte2
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
                         SELECT Min("max_year")
                         FROM   year_range)
                AND category_name IN ( 'Chléb konzumní kmínový',
                                       'Mléko polotučné pasterované' ))
SELECT Round(t.income_value_avg / c.price_value_avg, 2) AS ratio,
       CASE
         WHEN c.price_value_avg = 16.12 THEN 'kg Chleba 2006'
         WHEN c.price_value_avg = 24.24 THEN 'kg Chleba 2018'
         WHEN c.price_value_avg = 14.44 THEN 'l Mléka 2006'
         WHEN c.price_value_avg = 19.82 THEN 'l Mléka 2018'
         ELSE 'Neznámá hodnota'
       END                                              AS produkt_info,
       COALESCE(t.industry_name, 'Neuvedeno')           AS industry_name,
       c.price_value_avg,
       t.income_value_avg,
       t.year
--, t.category_name
FROM   t_ondrej_pavlicek_project_sql_primary_final t
       JOIN cte2 c
         ON t.year = c.year
WHERE  t.year IN (SELECT Max(year_range.min_year)
                  --Dberaver na tomto řádku indikuje, že hodnoty nezná, možná mám víc štěstí než rozumu, ale AI mi říká, že TO mám správně. Mám štěstí. Jsem unavený abych to si ty hodnoty uložit  DO tabulky, proměnné nebo VIEW, ale věřím, že tím bych TO obešel
                  FROM   year_range
                  UNION
                  SELECT Min(year_range.max_year)
                  FROM   year_range)
       AND t.category_name IS NULL;
-- tyhle zkraceny nazvy tabulek mi byl čert dlužnej, jak překopírovávám mezi verzemi, ztratím zkratku a pak neumím snadno najít, která tabulka TO byla. proto je teď nepoužívám.
	
-----------------------------------------------------------------------------------------------------------------------------------------------------------------	
/*
 * 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 * */	
	
	-- VYHODNOTIM PRUMERNOU MEZIROCNI ZMENU CENY U JEDNOTLIVYCH KATEGORII
WITH price_review AS
(
         SELECT   
                  price_value_avg,
                  category_name,
                  price_value,
                  price_unit,
                  year,
                  First_value(price_value_avg) OVER (partition BY category_name ORDER BY year DESC)                                                      AS last_price ,
                  last_value(price_value_avg) OVER (partition BY category_name ORDER BY year DESC rows BETWEEN CURRENT row AND      UNBOUNDED following) AS first_price ,
                  COALESCE(lag(price_value_avg) OVER (partition BY category_name ORDER BY category_name, year DESC), 0)                                  AS next ,
                  COALESCE(lead(price_value_avg) OVER (partition BY category_name ORDER BY category_name, year DESC), price_value_avg)                   AS previous
         FROM     t_ondrej_pavlicek_project_sql_primary_final
         WHERE    price_value_avg IS NOT NULL
         ORDER BY category_name ASC ,
                  year DESC ) , summary_price_review AS
(
       SELECT                 *,
              price_value_avg - previous              AS difference_abs,
              (price_value_avg - previous)/ previous  AS difference_relative,
              last_price - first_price                AS difference_abs_period,
              (last_price - first_price)/ first_price AS difference_relative_period
       FROM   price_review )
SELECT   category_name ,
         round(avg(difference_relative)       * 100, 2) AS difference_relative_avg ,
         round(avg(difference_relative_period)* 100, 2) AS difference_abs_period_avg
FROM     summary_price_review
GROUP BY category_name
ORDER BY difference_relative_avg ASC limit 1; --TATO MĚLA NEJNIZŽÍ PRŮMĚRNOU HODNOTU MEZIROCNICH ZDRAZENI
-- difference_abs_period_avg ASC LIMIT 1;--TATO KATEGORIE ZDRAŽILA NEJMÉNĚ ZA CELÉ OBDOBÍ HODNOCENÉ 2006 - 2018

---------------------------------------------------------------------------------------------------------------------------------------------------------------
	
/*
 * 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 * */	
	
	--Ze zadání mi nebylo zřejmé, zda hodnotit změnu cen po jednotlivých kategiriích potravin, a kategoriích průmyslu - dávalo by mi smysl mít takto detailní vhledl, protože by to bylo výhodnější pro doplňující otázky. (aspoň ze svojí praxe kontingenčních tabulek vím, že je často velmi užitečné mít šanci rozkliknout si detail a potom se vrátit o level výš. ale v sql bych to nedal, připravil bych si to do csv, a přes power query načetl do excelu a kontringenčky. Dalo by to 27x19x12 hodnot,fuj)
	--SELECT count(DISTINCT category_name), count (DISTINCT industry_name), 2018-2006, 27*12*19 FROM t_ondrej_pavlicek_project_sql_primary_final
	-- už jsem získal seběvědomí v CTE, po info, že views jsou pomalejší než vytvoření pomocných tabulek, al ety zase ne vždy budu moc vytvářet a s ohledem na to, že reálně nebudu pracovat s miliardama řádkůjdu přes CTE. hodně mi pomohlo si uvědomit, že na dílčí dotazy mohu v rámci dotazu odkazovaz, dostal jsem se s tím do analogie s názvy kroků v power query... 
	
	WITH food_price_avg_yearly
     AS (SELECT Avg(price_value_avg) AS price_value_avg,
                year,
                'Food'               AS category_name
         FROM   t_ondrej_pavlicek_project_sql_primary_final
         WHERE  price_value_avg IS NOT NULL
         GROUP  BY year),
     food_price_avg_yearly_2
     AS (SELECT *,
                First_value(price_value_avg)
                  over (
                    ORDER BY year DESC)
                   AS last_price,
                Last_value(price_value_avg)
                  over (
                    ORDER BY year DESC ROWS BETWEEN CURRENT ROW AND unbounded
                  following)
                   AS
                first_price,
                Coalesce(Lag(price_value_avg)
                           over (
                             ORDER BY year DESC), 0)
                   AS NEXT,
                Coalesce(Lead(price_value_avg)
                           over (
                             ORDER BY year DESC), price_value_avg)
                   AS previous
         FROM   food_price_avg_yearly
         WHERE  price_value_avg IS NOT NULL),
     food_price_avg_yearly_3
     AS (SELECT *,
                price_value_avg - previous                           AS
                   difference_abs_YTY,
                ( price_value_avg - previous ) / Nullif(previous, 0) AS
                   difference_relative_YTY
         FROM   food_price_avg_yearly_2
         ORDER  BY year DESC),
     incomes_avg_yearly
     AS (SELECT Avg(income_value_avg) AS income_value_avg,
                year,
                'Industry'            AS category_name
         FROM   t_ondrej_pavlicek_project_sql_primary_final
         WHERE  income_value_avg IS NOT NULL
         GROUP  BY year),
     incomes_avg_yearly_2
     AS (SELECT *,
                First_value(income_value_avg)
                  over (
                    ORDER BY year DESC)
                   AS last_price,
                Last_value(income_value_avg)
                  over (
                    ORDER BY year DESC ROWS BETWEEN CURRENT ROW AND unbounded
                  following)
                   AS
                first_price,
                Coalesce(Lag(income_value_avg)
                           over (
                             ORDER BY year DESC), 0)
                   AS NEXT,
                Coalesce(Lead(income_value_avg)
                           over (
                             ORDER BY year DESC), income_value_avg)
                   AS previous
         FROM   incomes_avg_yearly
         WHERE  income_value_avg IS NOT NULL),
     incomes_avg_yearly_3
     AS (SELECT *,
                income_value_avg - previous                           AS
                   difference_abs_YTY,
                ( income_value_avg - previous ) / Nullif(previous, 0) AS
                   difference_relative_YTY
         FROM   incomes_avg_yearly_2
         ORDER  BY year DESC)
SELECT food_price_avg_yearly_3.year,
       food_price_avg_yearly_3.category_name,
       Round(food_price_avg_yearly_3.difference_relative_yty * 100, 2) AS
       food_difference_relative_YTY,
       incomes_avg_yearly_3.category_name                              AS
       category_name,
       Round(incomes_avg_yearly_3.difference_relative_yty * 100, 2)    AS
       incomes_difference_relative_YTY,
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
       END                                                             AS
       price_increase_measure
FROM   food_price_avg_yearly_3
       join incomes_avg_yearly_3
         ON food_price_avg_yearly_3.year = incomes_avg_yearly_3.year
WHERE  food_price_avg_yearly_3.difference_relative_yty >
       incomes_avg_yearly_3.difference_relative_yty * 1.1
ORDER  BY food_price_avg_yearly_3.year DESC; 
	
-------------------------------------------------------------------------------------------------------------------------------------------------	
	
	
	/*
	 * 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
	 * */
		
WITH food_price_avg_yearly AS (
SELECT
	AVG(price_value_avg) AS price_value_avg,
	YEAR,
	'Food' AS category_name
FROM
	t_ondrej_pavlicek_project_sql_primary_final
WHERE
	price_value_avg IS NOT NULL
GROUP BY
	YEAR
),
food_price_avg_yearly_2 AS (
SELECT
	*,
	FIRST_VALUE(price_value_avg) OVER (
	ORDER BY YEAR DESC) AS last_price,
	LAST_VALUE(price_value_avg) OVER (
	ORDER BY YEAR DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS first_price,
	COALESCE(LAG(price_value_avg) OVER (ORDER BY YEAR DESC), 0) AS NEXT,
	COALESCE(LEAD(price_value_avg) OVER (ORDER BY YEAR DESC), price_value_avg) AS previous
FROM
	food_price_avg_yearly
WHERE
	price_value_avg IS NOT NULL
),
food_price_avg_yearly_3 AS (
SELECT
	*,
	price_value_avg - previous AS food_price_difference_abs_YTY,
	(price_value_avg - previous) / NULLIF(previous, 0) AS food_price_difference_relative_YTY
FROM
	food_price_avg_yearly_2
ORDER BY
	YEAR DESC
),
incomes_avg_yearly AS (
SELECT
	AVG(income_value_avg) AS income_value_avg,
	YEAR,
	'Industry' AS category_name
FROM
	t_ondrej_pavlicek_project_sql_primary_final
WHERE
	income_value_avg IS NOT NULL
GROUP BY
	YEAR
),
incomes_avg_yearly_2 AS (
SELECT
	*,
	FIRST_VALUE(income_value_avg) OVER (
	ORDER BY YEAR DESC) AS last_price,
	LAST_VALUE(income_value_avg) OVER (
	ORDER BY YEAR DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS first_price,
	COALESCE(LAG(income_value_avg) OVER (ORDER BY YEAR DESC), 0) AS NEXT,
	COALESCE(LEAD(income_value_avg) OVER (ORDER BY YEAR DESC), income_value_avg) AS previous
FROM
	incomes_avg_yearly
WHERE
	income_value_avg IS NOT NULL
),
incomes_avg_yearly_3 AS (
SELECT
	*,
	income_value_avg - previous AS incomes_difference_abs_YTY,
	(income_value_avg - previous) / NULLIF(previous, 0) AS incomes_difference_relative_YTY
FROM
	incomes_avg_yearly_2
ORDER BY
	YEAR DESC
),
prehled_o_obsahu_tabulky AS (
SELECT
	DISTINCT 
        country,
	MIN(YEAR) AS min_year,
	MAX(YEAR) AS max_year
FROM
	t_ondrej_pavlicek_project_sql_secondary_final
GROUP BY
	country
),
gdp_data AS (
SELECT
	*
FROM
	t_ondrej_pavlicek_project_sql_secondary_final
),
gdp_data_2 AS (
SELECT
	*,
	FIRST_VALUE(gdp_per_cap) OVER (PARTITION BY country
ORDER BY
	YEAR DESC) AS last_gdp,
	LAST_VALUE(gdp_per_cap) OVER (PARTITION BY country
ORDER BY
	YEAR DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_gdp,
	COALESCE(LAG(gdp_per_cap) OVER (PARTITION BY country ORDER BY YEAR DESC), 0) AS NEXT,
	COALESCE(LEAD(gdp_per_cap) OVER (PARTITION BY country ORDER BY YEAR DESC), gdp_per_cap) AS previous
FROM
	gdp_data
),
gdp_data_3 AS (
SELECT
	*,
	gdp_per_cap - previous AS gdp_difference_abs_YTY,
	((gdp_per_cap - previous) / previous) AS gdp_differences_relative_yty
FROM
	gdp_data_2
ORDER BY
	country ASC,
	YEAR DESC
),
gdp_data_4 AS (
SELECT
	YEAR,
	Country,
	gdp_differences_relative_yty
FROM
	gdp_data_3
WHERE
	country LIKE 'Czech%'
),
food_price_incomes_gdp AS (
SELECT
	food_price_avg_yearly_3.YEAR,
	food_price_avg_yearly_3.category_name,
	food_price_avg_yearly_3.food_price_difference_relative_yty AS food_price_difference_relative_yty,
	incomes_avg_yearly_3.category_name AS kategorie_prijmu,
	incomes_avg_yearly_3.incomes_difference_relative_yty AS incomes_difference_relative_yty,
	gdp_data_4.gdp_differences_relative_yty AS gdp_differences_relative_yty,
	CASE
		WHEN food_price_avg_yearly_3.food_price_difference_relative_yty > incomes_avg_yearly_3.incomes_difference_relative_yty * 1.1 THEN 'Higher tahn 10%'
		WHEN food_price_avg_yearly_3.food_price_difference_relative_yty > incomes_avg_yearly_3.incomes_difference_relative_yty THEN 'Between 100 and 110%'
		WHEN food_price_avg_yearly_3.food_price_difference_relative_yty = incomes_avg_yearly_3.incomes_difference_relative_yty THEN 'Eqal'
		ELSE 'Less than 100%'
	END AS rust_cen_potravin_vs_rust_mezd
FROM
	gdp_data_4
JOIN 
        incomes_avg_yearly_3 ON
	gdp_data_4.YEAR = incomes_avg_yearly_3.YEAR
JOIN
        food_price_avg_yearly_3 ON
	food_price_avg_yearly_3.YEAR = gdp_data_4.YEAR
ORDER BY
	food_price_avg_yearly_3.YEAR DESC
)
,
GDPpCAP_estimation AS (
SELECT
	*,
	COALESCE(LEAD(gdp_differences_relative_yty) OVER (ORDER BY YEAR DESC), gdp_differences_relative_yty, 3) AS gdp_differences_relative_yyty,
	CASE
		WHEN food_price_difference_relative_yty > 0
		AND incomes_difference_relative_yty > 0
		AND (gdp_differences_relative_yty > 0
			OR COALESCE(LEAD(gdp_differences_relative_yty) OVER (ORDER BY YEAR DESC), gdp_differences_relative_yty) > 0) 
            THEN 'Při nárůstu GDPpCAP zdražily potraviny a rostly mzdy'
		WHEN food_price_difference_relative_yty > 0
		AND incomes_difference_relative_yty < 0
		AND (gdp_differences_relative_yty > 0
			OR COALESCE(LEAD(gdp_differences_relative_yty) OVER (ORDER BY YEAR DESC), gdp_differences_relative_yty) > 0) 
            THEN 'Při nárůstu GDPpCAP zdražily potraviny a nerostly mzdy'
		WHEN food_price_difference_relative_yty < 0
		AND incomes_difference_relative_yty > 0
		AND (gdp_differences_relative_yty > 0
			OR COALESCE(LEAD(gdp_differences_relative_yty) OVER (ORDER BY YEAR DESC), gdp_differences_relative_yty) > 0) 
            THEN 'Při nárůstu GDPpCAP zlevnily potraviny a rostly mzdy'
		WHEN food_price_difference_relative_yty < 0
		AND incomes_difference_relative_yty < 0
		AND (gdp_differences_relative_yty > 0
			OR COALESCE(LEAD(gdp_differences_relative_yty) OVER (ORDER BY YEAR DESC), gdp_differences_relative_yty) > 0) 
            THEN 'Při nárůstu GDPpCAP zlevnily potraviny a nerostly mzdy'
		ELSE 'Nerostlo GDPpCAP'
	END AS gdp_final
FROM
	food_price_incomes_gdp)      
-- Tahle alternativa zobrazi vyhodnoceni pro jednotlive roky    
/*	SELECT
	gdp_final,
	YEAR
FROM
	GDPpCAP_estimation; */
--Zobrazi vyhodnoceni pro jednotlivé roky
--Tahle alternativa zobrazi kumulativne podle vyhodnoceni
    SELECT 
    gdp_final, 
    COUNT(*) AS pocet
FROM 
    GDPpCAP_estimation 
GROUP BY 
    gdp_final
ORDER BY
    COUNT(*) DESC;