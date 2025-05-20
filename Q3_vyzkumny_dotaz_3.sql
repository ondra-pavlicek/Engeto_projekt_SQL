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
                  year DESC ) ,
summary_price_review AS
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
ORDER BY difference_relative_avg ASC limit 1; --TATO MĚLA NEJNIŽŠÍ PRŮMĚRNOU HODNOTU RELATIVNICH MEZIROCNICH ZDRAZENI