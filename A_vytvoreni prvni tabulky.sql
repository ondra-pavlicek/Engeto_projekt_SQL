/*
 * VYTVORENI TABULKY t_ondrej_pavlicek_project_sql_primary_final
 * VYTVORENI POMOCNYCH TABULEK KTERE SPOJIM DO PRVNI TABULUKY, POMOCNE TABULKY POTOM SMAZU
 * 
 * */

-- vytvorim 2 pomocne tabulky, které následně spojím do jedine, oproti puvodnimu reseni je prepracovano tak, aby bylo pomocí CTE, takže si data načtu dvěma pomocnými dotazy. využiju CREATE TABLE AS,  aby vše proběhlo v jediném dotazu, 

/*
* Cesty jak by šlo opravit napojení unit_code aby výsledkem byla Kč - obejití přehozených kodů v číselníku:
* 1) 'kč' AS mena,
* 2) v joinu upravit podmínku na cp.unit_code <> cpu.code , což mi projde jen proto, že jsou jen dvě hodnoty cpu.code
* 3) update v databázi/výstupu v příslušném sloupci
* 4) volím využití jednoduché matematiky a přičtení 80203, abych dostal hodnotu klíče odpovídajícího Kč :-) 
* ponechám si i sloupec cp.industry_branch_code, abych nepřišel o údaj příslušný k nezařazeným 22 hodnotám.
* */
--vyřazením sloupce cp.industry_branch_code BYCH PŘIŠEL o 22 hodnot, u kterých nebyl vyplněn atribut a měly hodnotu "NULL". Může to být chyba v datech, ale taky příležitost jak ztratit část dat. ZACHOVÁM HO A NÁSLEDNĚ OŠETŘÍM HODNOTU NULL JAKO NEUVEDENO
 
 

-- VŠE DO JEDINÉHO DOTAZU:
CREATE TABLE t_ondrej_pavlicek_project_sql_primary_final AS
WITH TABLE_1 AS (
    SELECT
        NULL::numeric AS price_value_avg,
        NULL::integer AS category_code,
        NULL::varchar(50) AS category_name,
        NULL::DOUBLE PRECISION AS price_value,
        NULL::varchar(2) AS price_unit,
        round(avg(value)::numeric, 2) AS income_value_avg,
        cpvt.NAME AS value_type_name,
        cpu.NAME,
        cpc.NAME AS calculation_name,
        cp.industry_branch_code,
        cpib.NAME AS industry_name,
        cp.payroll_year AS year
    FROM czechia_payroll cp
    JOIN czechia_payroll_unit cpu ON cp.unit_code = cpu.code - 80203
    JOIN czechia_payroll_value_type cpvt ON cp.value_type_code = cpvt.code
    LEFT JOIN czechia_payroll_industry_branch cpib ON cp.industry_branch_code = cpib.code
    JOIN czechia_payroll_calculation cpc ON cp.calculation_code = cpc.code
    WHERE cp.value IS NOT NULL
    AND cp.value_type_code = '5958'
    AND cp.calculation_code = 100
    GROUP BY cp.payroll_year, cpu.NAME, cpvt.NAME, cpc.NAME, cp.industry_branch_code, cpib.NAME
),
TABLE_2 AS (
    SELECT 
        round(avg(cp.value)::numeric, 2) AS price_value_avg,
        cp.category_code,
        cpc.NAME AS category_name,
        cpc.price_value,
        cpc.price_unit,
        NULL::numeric AS income_value_avg,
        NULL::varchar(50) AS value_type_name,
        NULL::varchar(50) AS NAME,
        NULL::varchar(50) AS calculation_name,
        NULL::bpchar(1) AS industry_branch_code,
        NULL::varchar(255) AS industry_name,
        date_part('year', cp.date_from)::integer AS year
    FROM czechia_price cp
    JOIN czechia_price_category cpc ON cp.category_code = cpc.code
    WHERE cp.region_code IS NOT NULL
    GROUP BY category_code, date_part('year', cp.date_from), cpc.NAME, cpc.price_value, cpc.price_unit
)
SELECT * FROM TABLE_1
UNION ALL
SELECT * FROM TABLE_2;

--DROP TABLE t_ondrej_pavlicek_project_sql_primary_final;
--SELECT * FROM  t_ondrej_pavlicek_project_sql_primary_final;
