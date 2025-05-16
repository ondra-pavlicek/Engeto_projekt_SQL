**# Engeto_projekt_SQL**
I. Tvorba tabulek se zdrojovými daty
1) tvorba pomocnych tabulek t_ondrej_pavlicek_project_sql_primary_final_payroll, t_ondrej_pavlicek_project_sql_primary_final_payroll_prices, do kjerých jsou nahrána data z jednotlivých zdrojových abulek a příslušných pomocných tabulek - číselníků.
2) spojení dílčích tabulek pomocí UNION do t_ondrej_pavlicek_project_sql_primary_final
3) odstranění pomocných tabulek t_ondrej_pavlicek_project_SQL_primary_final_payroll_prices, t_ondrej_pavlicek_project_SQL_primary_final_payroll
4) tvorba druhé tabulky s eknomickými ukazateli, omezení na region evropy a země evropy (tj. vč. agregovaných dat za regiony), některá data zdvojena, nutno nahrát jen unikátní hodnoty
   
II. Tvorba jednotlivých dotazů
1) **Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?**
Dotaz vyhodnotí roční průměr z průměrných mezd, vybere jen ty roky a odvětví, u kterých došlo k meziročnímu poklesu mzdy. Výstupem je tabulka s názvem odvětví, rokem, průměrnou mzdou za aktuální a za předchozí rok, mzdou za provní a za poslení rok sledovaného období, s rozdílem meziročním a rozdílem mezi mzdou z konce a počátku sledovaného období. Ve zdrojových datech byla skupina hodnot NULL, zahrnul jsem ji do souboru hodnocených dat a označil název odvetvi jako "Neuveden".
2) **Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?**
  Nejprve určuju společná období - roky, ke kterým mám data jak o mzdách, tak o cenách komodit, používám CTE, ale Beaver editor potom označuje jako chybu v kódu, ačkoli dotaz vykoná. Alternativou by bylo uložit si je do tabulky, view nebo si pohrát s načtením do proměnných, ale vzhledem k tomu, že dotaz běží, nyní nerozpracovávám. V tomhle případě je jedna tabulka s kratším rozsahem datumu než ta druha, šlo by obejít vhodným pořadím v joinu. Připojuju k sobě data ze zdrojové tabulky. Výsledná tabulka obsahuje vypočtené množství komodity které šlo koupit v daný rok za průměrnou mzdu, název odvětví, průměrnou cenu komodity z tohoto roku, průměrnou mzdu odvetví průmyslu a rok.
3) **Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?**
Učím se na příkladu window fuknce, hodně mi pomohla předposlední přednáška, a info, že je třeba posloupnosti CTE dotazů. Výstupem je tabulka, s výpočty absolutní a relativních hodnot rozdílů cen, a to meziročních a za celé období, za které máme ke komoditě k dispozici data. Výsledkem je jednořádkový výstup vyfiltrovaný jako nejnižší průměrná meziroční změna. Stejná položka také má nejknižší nárůst ceny za celé období.    
