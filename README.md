**# Engeto_projekt_SQL**
I. Tvorba tabulek se zdrojovými daty
1) tvorba pomocnych tabulek t_ondrej_pavlicek_project_sql_primary_final_payroll, t_ondrej_pavlicek_project_sql_primary_final_payroll_prices, do kjerých jsou nahrána data z jednotlivých zdrojových abulek a příslušných pomocných tabulek - číselníků.
2) spojení dílčích tabulek pomocí UNION do t_ondrej_pavlicek_project_sql_primary_final
3) odstranění pomocných tabulek t_ondrej_pavlicek_project_SQL_primary_final_payroll_prices, t_ondrej_pavlicek_project_SQL_primary_final_payroll
4) tvorba druhé tabulky s eknomickými ukazateli, omezení na region evropy a země evropy (tj. vč. agregovaných dat za regiony), některá data zdvojena, nutno nahrát jen unikátní hodnoty
   
II. Tvorba jednotlivých dotazů
1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
Dotaz vyhodnotí roční průměr z průměrných mezd, vybere jen ty roky a odvětví, u kterých došlo k meziročnímu poklesu mzdy. Výstupem je tabulka s názvem odvětví, rokem, průměrnou mzdou za aktuální a za předchozí rok, mzdou za provní a za poslení rok sledovaného období, s rozdílem meziročním a rozdílem mezi mzdou z konce a počátku sledovaného období. Ve zdrojových datech byla skupina hodnot NULL, zahrnul jsem ji do souboru hodnocených dat a označil název odvetvi jako "Neuveden".

