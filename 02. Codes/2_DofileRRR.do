clear all 
set more off 
set maxvar 8000 

cd "C:\Users\frans\Dropbox\Projet d'économétrie"

global sourcedata "C:\Users\frans\Dropbox\Projet d'économétrie\02. Data\Raw data"
global savedata "C:\Users\frans\Dropbox\Projet d'économétrie\02. Data\Cleaned data" 
global dofile "C:\Users\frans\Dropbox\Projet d'économétrie\02. Codes"
global Table   "C:\Users\frans\Dropbox\Projet d'économétrie\03. Results\Tables"


cap capture log close
log using "$savedata\logresults.log", replace 




                                     
*************************************************************************************************************************************************************
										                            *Base de données et Fusion*
*************************************************************************************************************************************************************

**Base investissement (IMF investment stock Dataset) **

clear all
import excel using "$sourcedata\IMFInvestmentandCapitalStockDataset.xlsx", clear first sheet("Dataset") cellra("A1:Q11641")

drop kgov_rppp
drop kpriv_rppp
drop ippp_rppp
drop kppp_rppp
drop kgov_n
drop kpriv_n
drop kppp_n
drop GDP_n
drop igov_n
drop ifscode

bys country: gen invest = (ipriv_rppp/GDP_rppp)*100
label var invest  "Investissement privé (formation brute de capital fixe), en % du PIB"

bysort country: gen gov_invest=(igov_rppp/GDP_rppp)*100
label var gov_invest "Investissement public (formation brute de capital fixe), en % du PIB"

drop ipriv_rppp
drop GDP_rppp
keep country isocode  year invest gov_invest
drop if year <1990
ren isocode iso 
save "$savedata\invest", replace 



/* Base données traitée avec toutes nos variables sauf l'investissement privé et la centralité */


import excel using "$savedata\Database.xlsx", clear first 
drop if year >2019
sort iso year
bysort country: egen mean_gov_stab = mean(gov_stab)

drop if mean_gov_stab ==. // On supprime tous les pays  qui n'ont aucune donnée sur la stabilité politique du gouvernement sur toute la période. 
br 

/*Fusion avec l'investissement */

merge 1:1 iso year using "$savedata\invest"
 
keep if _merge ==3
drop _merge


/*Fusion avec la base de données de centralité */
 
merge m:1 iso using "$savedata\centrality_data" 

drop if _merge !=3

drop _merge


***identifient
egen id =group(iso)





*************************************************************************************************************************************************************
						                                        *Construction de variables*
*************************************************************************************************************************************************************

**Remittances: Pour calculer la probabilité de recevoir les transferts, nous avons besoin des montants des remittances en dollars constants, ce qui justifie ce calcul. 

g remit_cons= (remitofgdp*gdp)/100



**Probabilité de recvoir les transferts**

bys year : egen remit_year = sum(remit_cons)

bys iso: gen prob_remit = (remit_cons/remit_year)*100

**Construction de l'instrument**

* Notre instrument est une interaction ente une variable exogène (Mesure de centralité) et une variable endogène (probabilité pour un pays de recevoir les remittances à l'années t)

g IV2= prob_remit*vectorlang // la probabilité de recvoir les tranferts multipliée par la mesure de centralité(calculé à partir de la proximité linguistique entre les pays)

br 

**Effets fixes individuels et temporel**

tab year, gen(yr)

tab id , gen (dummy)

save "$savedata\FinalDatabase", replace 





*************************************************************************************************************************************************************
										                          *Analyse Statistique*
*************************************************************************************************************************************************************


**Résumé statistique**

sum invest remitofgdp p_gap inf ka_open tcr fdi gdpgrowthannual credit_priv 


**Matrice de corrélation Avec toutes les variables** 

pwcorr invest remitofgdp p_gap inf ka_open tcr fdi gdpgrowthannual credit_priv , star(0.1)

**Matrice de corrélation avec les composantes de l'instrument**

pwcorr remitofgdp vectorlang prob_remit 






*************************************************************************************************************************************************************
										                       *Analyse Econométrique*
*************************************************************************************************************************************************************

**Déclaration du panel

xtset id year 

**On prend la variable credit_priv en log pour lisser sa distribution (elle est asymétrique à gauche). 



**Global**
global control inf trade fdi credit_priv gov_stab gdpgrowthannual gov_invest ka_open
										  

**column 1 OLS **
xtreg invest remitofgdp $control i.year, fe robust 

estadd local nobs="1466"
estadd local fe="Oui"
estadd local ft="Oui" 
estadd local R2= " 0.33"

eststo OLS

********************************************************************************
                  ***Methodes des variables instrumentales***
********************************************************************************
 
*column 2 IV sans Effets fixes temporels 

*Anderson Rubin Confidence Interval : On récupère les intervales de confiance de Anderson Rubin qui pemret de juger également de la force des instruments

ivreg2 invest (remitofgdp= IV2) $control dummy*, robust first
rivtest, ci level(90) /*-.019, .435*/

qui ivreg2 invest (remitofgdp= IV2),  first robust

xtivreg2 invest (remitofgdp= IV2)  $control  if e(sample), fe robust first savefirst savefprefix(fsc1)

estadd local nobs=" 1466"
estadd local fe="Oui"
estadd local ft="Non"
estadd local fstat="56.968" 
estadd local pval="0.000"	
estadd local ar="[-.019, .435]"
estadd local R2 = " 0.26"

eststo result1 

/*On récupère juste le coefficient et sa p-value pour insérer dans la table des résultats.*/
xtreg remitofgdp IV2 $control if e(sample), fe robust 
estadd local nobs="1466"
estadd local fe="Oui"
estadd local ft="Non"
estadd local R2= "0.08"
eststo rc1


*column 3 IV avec Effets fixes temporels & remitofgdp <= 19.3297

*Anderson Rubin Confidence Interval : On récupère les intervales de confiance de Anderson Rubin qui pemret de juger également de la force des instruments

ivreg2 invest (remitofgdp= IV2) $control yr* dummy*, robust first 
rivtest, ci level(90) /*.057, .563*/

qui ivreg2 invest (remitofgdp= IV2) ,  first robust

xtivreg2 invest (remitofgdp= IV2)  $control yr* if e(sample), fe robust first savefirst savefprefix(fsc1) 

estadd local nobs="1466"
estadd local fe="Oui"
estadd local ft="Oui"
estadd local fstat="87.077" 
estadd local pval="0.000"	
estadd local ar="[.057, .563]"
estadd local R2= "0.27"

eststo result2 

/*On récupère juste le coefficient et sa p-value pour insérer dans la table des résultats.*/
xtreg remitofgdp IV2 $control yr* if e(sample), fe robust
estadd local nobs="1466"
estadd local fe="Oui"
estadd local ft="Oui"
estadd local R2= "0.17"
eststo rc2    
 
 
********************************************************************************
						        *Robustesse* 
********************************************************************************
										  
**column 4: IV avec Effets fixes temporels et sans les valeurs extrêmes ** 


/* On teste la sensibilité de nos résultats en excluant les valeurs extrêmes (5% des valeurs faibles et 5% des valeurs élevées, suivant la distribution de notre variable d'intérêt) */

hist remitofgdp
sum remitofgdp, d // Le 5ème percentile est égal à .0431768 et le 95ème percentile à 16.7475

*Anderson Rubin Confidence Interval : On récupère les intervales de confiance de Anderson Rubin qui pemret de juger également de la force des instruments

ivreg2 invest (remitofgdp= IV2) $control yr* dummy* if remitofgdp >= .0431768 & remitofgdp <  16.7475, robust first 
rivtest, ci level(90) /*.047, .570*/

qui ivreg2 invest (remitofgdp= IV2) ,  first robust

xtivreg2 invest (remitofgdp= IV2)  $control yr* if e(sample) & remitofgdp >= .0431768 & remitofgdp <  16.7475, fe robust first savefirst savefprefix(fsc1) 

estadd local nobs="1355"
estadd local fe="Oui"
estadd local ft="Oui"
estadd local fstat="101.758" 
estadd local pval="0.000"	
estadd local ar="[.047, .570]"
estadd local R2= "0.32"

eststo rob1

/*On récupère juste le coefficient et sa p-value pour insérer dans la table des résultats.*/
xtreg remitofgdp IV2 $control yr* if e(sample) & remitofgdp >=  .0431768 & remitofgdp < 16.7475, fe robust
estadd local nobs="1357"
estadd local fe="Oui"
estadd local ft="Oui"
estadd local R2= "0.25"
eststo robc1


**column 5 : Robustesse avec remplacement de la variable stabilité du gouvernement (gov_stab) par le contrôle de corruption (corup). 

global control2 inf trade fdi credit_priv corup gdpgrowthannual gov_invest ka_open

*Anderson Rubin Confidence Interval : On récupère les intervales de confiance de Anderson Rubin qui pemret de juger également de la force des instruments

ivreg2 invest (remitofgdp= IV2) $control2 yr* dummy*, robust first 
rivtest, ci level(90) /*.083, .608*/

qui ivreg2 invest (remitofgdp= IV2) ,  first robust

xtivreg2 invest (remitofgdp= IV2)  $control2 yr* if e(sample), fe robust first savefirst savefprefix(fsc1) 

estadd local nobs="1466"
estadd local fe="Oui"
estadd local ft="Oui"
estadd local fstat="84.010" 
estadd local pval="0.000"	
estadd local ar="[.083, .608]"
estadd local R2= "0.27"

eststo rob2 

/*On récupère juste le coefficient et sa p-value pour insérer dans la table des résultats.*/
xtreg remitofgdp IV2 $control2 yr* if e(sample), fe robust
estadd local nobs="1466"
estadd local fe="Oui"
estadd local ft="Oui"
estadd local R2= "0.17"
eststo robc2    





********************************************************************************
                                  *Hétérogénéité*
********************************************************************************

***Hétérogénéité -- Niveau de qualité institutionnelle***

// On définit une muette govslevel qui représente la qualité insitutionnelle. Cette muette est égale à 1 si la variable de stabilité du gouvernement (gov_stab) est supérieure à sa valeur moyenne et 0 sinon. 

sum gov_stab, d
gen govslevel = 1 if gov_stab > 7.6619 
replace govslevel = 0 if govslevel ==. 


/* Pour les pays ayant une bonne qualité institutionnelle (if govslevel==1) */
							
*Anderson Rubin Confidence Interval : On récupère les intervales de confiance de Anderson Rubin qui pemret de juger également de la force des instruments. 

ivreg2 invest (remitofgdp= IV2) $control yr* dummy* if govslevel ==1, robust first
rivtest, ci level(90) /*.146, .815*/

qui ivreg2 invest (remitofgdp= IV2),  first robust

xtivreg2 invest (remitofgdp= IV2)  $control yr*  if e(sample) & govslevel ==1, fe robust first savefirst savefprefix(fsc1) 

estadd local nobs="740"
estadd local fe="Oui"
estadd local ft="Oui"
estadd local fstat="32.918" 
estadd local pval="0.000"	
estadd local ar="[.146, .815]"
estadd local R2= "0.36"

eststo het1 

*On récupère juste le coefficient et sa p-value pour insérer dans la table des résultats. 
xtreg remitofgdp IV2 $control yr* if e(sample) & govslevel ==1, fe robust
estadd local nobs="743"
estadd local fe="Oui"
estadd local ft="Oui"
estadd local R2= "0.17"

eststo hc1


/* Pour les pays ayant une mauvaise qualité institutionnelle (if govslevel==0) */
							
*Anderson Rubin Confidence Interval : On récupère les intervales de confiance de Anderson Rubin qui pemret de juger également de la force des instruments. 

ivreg2 invest (remitofgdp= IV2) $control yr* dummy* if govslevel ==0, robust first
rivtest, ci level(90) /*.053, .796*/

qui ivreg2 invest (remitofgdp= IV2),  first robust

xtivreg2 invest (remitofgdp= IV2)  $control yr*  if e(sample) & govslevel ==0, fe robust first savefirst savefprefix(fsc1) 

estadd local nobs="721"
estadd local fe="Oui"
estadd local ft="Oui"
estadd local fstat="50.433" 
estadd local pval="0.000"	
estadd local ar="[.053, .796]"
estadd local R2= "0.30"

eststo het2 

*On récupère juste le coefficient et sa p-value pour insérer dans la table des résultats. 
xtreg remitofgdp IV2 $control yr* if e(sample) & govslevel ==0, fe robust
estadd local nobs="723"
estadd local fe="Oui"
estadd local ft="Oui"
estadd local R2= "0.33"

eststo hc2





********************************************************************************
           ***Table - Equation de 2nd étape  - Corps du document***
********************************************************************************

*Panel A : Résultats 2nd étape*	
 
		esttab OLS result1 result2 rob1 rob2 het1 het2  using ///
		"$Table\Table1.tex", fragment booktabs se(3) b(3) star starlevels(* 0.10 ** 0.05 *** 0.01)  replace  ///
				drop( _cons yr*) order(remitofgdp trade fdi inf gov_invest ka_open credit_priv gov_stab corup gdpgrowthannual ) varlabel( remitofgdp "Transferts de migrants (%PIB)" trade "Ouverture commerciale" fdi "IDE" inf "Inflation" gov_invest "Investissement public (%PIB)" ka_open "Ouverture financière" credit_priv "Crédit privé (%PIB)" gov_stab "Stabilité du gouvernement" corup "Contrôle de Corruption" gdpgrowthannual "Taux de croissance (PIB/tête)"  ) ///
				mlabel(none) style(tex)  nolines nogaps nonumbers  ///
				stats(nobs fe ft fstat pval ar r2, fmt(0 0 0 0 3 3 3 3) ///
				label("\hline N.Obs" "Effets fixes individuels" "Effets fixes temporels" "K-P F-stat." "K-P LM-stat. p-val." "Anderson-Rubin 95\% CI" "R2")) postfoot(\hline)
				
			
*Panel B : Résultats 1ère étape - On reporte uniquement le coefficient de l'instrument et sa significativité*

        esttab rc1 rc2 robc1 robc2 hc1 hc2 ///
			using "$Table\Table2.tex", replace fragment booktabs se(3) b(3) star starlevels(* 0.10 ** 0.05 *** 0.01) keep(IV2) ///
			varlabel(IV2 "IV" ) mlabel(none) style(tex) nonumbers nolines nogaps stats() noabbr noobs 
	

	
	
	
********************************************************************************
                 ***Table - Equation de 1ère étape - Annexe***
********************************************************************************
	
	esttab rc1 rc2 robc1 robc2 hc1 hc2  using ///
		"$Table\Table3.tex", fragment booktabs se(3) b(3) star starlevels(* 0.10 ** 0.05 *** 0.01)  replace  ///
				drop( _cons yr*) order( IV2 trade fdi inf gov_invest ka_open gov_stab corup gdpgrowthannual ) varlabel(IV2 "IV (Instrument)" trade "Ouverture commerciale" fdi "IDE" inf "Inflation" gov_invest "Investissement public (%PIB)" ka_open "Ouverture financière" credit_priv "Crédit privé (%PIB)" gov_stab "Stabilité du gouvernement" corup "Contrôle de Corruption" gdpgrowthannual "Taux de croissance (PIB/tête)"  ) ///
				mlabel(none) style(tex)  nolines nogaps nonumbers  ///
				stats(nobs fe ft r2, fmt(0 0 0 3 ) ///
				label("\hline N.Obs" "Effets fixes individuels" "Effets fixes temporels" "R2")) 
postfoot( \hline)




********************************************************************************
                         ***Canaux de transmission***
********************************************************************************
							
							
/* On teste les canaux par des corrélations pures et simples : D'abord, on effectue une corrélation entre le canal (credit_priv) et la variable d'intérêt (remitofgdp) et ensuite on effectue une corrélation entre la variable expliquée (invest) et le canal (credit_priv) */


*Canal et variable d'intérêt 
pwcorr credit_priv remitofgdp invest, star(0.01) 

				
***Nombre de pays particpant à l'étude. 				
bys iso : g ID = _n ==1 
count if ID  // 79 Pays en développement participent à notre étude. 

		
log close		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
  