/*
 * 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 * */
--DOTAZEM VYHODNOTÍM MEZIROČNÍ ZMĚNU PRO JEDNOTLIVA ODVETVI, IDENTIFIKUJE ODVĚTVÍ A ROK, VE KTERÉM DOŠLO K MEZIROČNÍMU POKLESU A TO VYPISU
--DOTAZ NEHODNOTÍ TREND JAKO ROZDIL V PRIJMECH MEZI PRVNI A POSLEDNI HODNOTOU CELEHO SLEDOVANEHO OBDOBI. TO BYCH UPRAVIL "WHERE (last_income-first_income) < 0 " TESTEM JSEM ZJISTIL, ZE ZA CELE SLEDOVANE OBDOBI VZROSTLY MZDY VSUDE
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
ORDER  BY industry_name,
          year DESC; 