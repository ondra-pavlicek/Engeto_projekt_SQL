**# Engeto_projekt_SQL**
I. Tvorba tabulek se zdrojovými daty
1) přepracované dotazy směrující k tvorbě tabulek. Nyní je tvořeno s vyžitím CTE, vždy jako jeden SQL dotaz, který si do CTE načítá data a následně tabulku vytvoří sjednocením výsledků dílčích dotazů. Původní řešení vyžadující od uživatele spuštění několika dílčích dotazů bylo blbé - děkuju za upozornění.
2) v rámci tvorby první tabulky ošetřena situace, kdy je chyba v jednom z pomocných číselníků kodujícím průměrnou mzdu. Dále jsou načtena data i pro neuvedenou kategorii průmyslu. 
4) tvorba druhé tabulky s ekonomickými ukazateli, omezení na region evropy a země evropy (tj. vč. agregovaných dat za regiony), některá data zdvojena, nutno nahrát jen unikátní hodnoty
   
II. Tvorba jednotlivých dotazů
1) **Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?**
 
Dotaz vyhodnotí roční průměr z průměrných mezd, vybere jen ty roky a odvětví, u kterých došlo k meziročnímu poklesu mzdy. Výstupem je tabulka s názvem odvětví, rokem, průměrnou mzdou za aktuální a za předchozí rok, mzdou za provní a za poslení rok sledovaného období, s rozdílem meziročním a rozdílem mezi mzdou z konce a počátku sledovaného období. Ve zdrojových datech byla skupina hodnot NULL, zahrnul jsem ji do souboru hodnocených dat a označil název odvetvi jako "Neuveden".

2) **Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?**
   
Nejprve určuju společná období - roky, ke kterým mám data jak o mzdách, tak o cenách komodit, používám CTE, ale Beaver editor potom označuje jako chybu v kódu, ačkoli dotaz vykoná. Alternativou by bylo uložit si je do tabulky, view nebo si pohrát s načtením do proměnných, ale vzhledem k tomu, že dotaz běží, nyní nerozpracovávám. V tomhle případě je jedna tabulka s kratším rozsahem datumu než ta druha, šlo by obejít vhodným pořadím v joinu. Připojuju k sobě data ze zdrojové tabulky. Výsledná tabulka obsahuje vypočtené množství komodity které šlo koupit v daný rok za průměrnou mzdu, název odvětví, průměrnou cenu komodity z tohoto roku, průměrnou mzdu odvetví průmyslu a rok.
  
3) **Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?**
   
Učím se na příkladu window fuknce, hodně mi pomohla předposlední přednáška, a info, že je třeba posloupnosti CTE dotazů. Výstupem je tabulka, s výpočty absolutní a relativních hodnot rozdílů cen, a to meziročních a za celé období, za které máme ke komoditě k dispozici data. Výsledkem je jednořádkový výstup vyfiltrovaný jako nejnižší průměrná meziroční změna. Stejná položka také má nejknižší nárůst ceny za celé období.    

4) **Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?**

Dotaz obsahuje velké množství CTE dotazů, princip je založen na výpočtu podílu meziroční průměrné změny ceny potravin a meziroční průměrné změny příjmů, a když je podílk těchto 2 zlomků >10%, je zařazen do tabulky rok, název kategorie, průměrná relativni meziroční změna cena změna potraviny a průměrná meziroční změna mzdy. 

5) **Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?**

V podstatě ohýbám předchozí query, dokonce si ponechávám kriterium hodnocení růstu mzdy. Pomocí CTE propojuju daata o cenách, o příjmech a o GDP (HDP). Počítám s GDP per capita. Principem je zhodnocení logické kombinace hodnot, funkce and a or. Výstup může být dvojí - agregovaná tabulka, která určuje četnost jednotlivých situací, a nebo tabulka, která pro každý rok dává informaci, do které kohorty patří. K dispozici jsou obě, jedna je zakomentovaná.


Dotazy jsem ladil a upravoval pomocí claude.ai a Copilotu. Hopndě mi to pomohlo, našlo a vysvětlilo mi to chybu, navedlo k opravě doatzů. super, AI asi začnu trénovat příště :-)  

K fromátování zdroj kodu jsem používal funkci DBeaveru a pak online nástroj, ale upřímě mi vyhovuje zápis do řádku než zalamování. Používání zkrácených názvů tabulek mě opakovaně vytrestalo, přesun dotazu na jiný list či odmazání jednipísmenkováho názvy, a stojí celé query. Fuj :-) 
Zdrojová data - nějaké drobnosti tam byly, už si moc nepamatuje. Někde zdvojená data o čr, přehozené jednotky v pomocném číselníku,absence kategorii průmyslu u průměrných mezd. A na další jsem asi nepřišel :-) 

