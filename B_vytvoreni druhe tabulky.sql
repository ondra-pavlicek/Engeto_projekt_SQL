/*
 * VYTVOŘENÍ TABULKY t_ondrej_pavlicek_project_SQL_secondary_final
 * */

CREATE TABLE IF NOT EXISTS t_ondrej_pavlicek_project_sql_secondary_final AS
  (SELECT DISTINCT country,
                   year,
                   gdp,
                   population,
                   gini,
                   gdp / population AS "gdp_per_cap"
   FROM   economies
   WHERE  ( country IN (SELECT DISTINCT country
                        FROM   countries
                        WHERE  continent LIKE ( '%Europe%' ))
             OR country LIKE '%Euro%' )
          AND gdp IS NOT NULL
   ORDER  BY country,
             year DESC);