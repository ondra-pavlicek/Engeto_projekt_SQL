/*
 * VYTVORENI TABULKY t_ondrej_pavlicek_project_sql_primary_final
 * VYTVORENI POMOCNYCH TABULEK KTERE SPOJIM DO PRVNI TABULUKY, POMOCNE TABULKY POTOM SMAZU
 * 
 * */
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