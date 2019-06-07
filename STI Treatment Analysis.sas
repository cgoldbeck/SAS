/* This code generates univariate, bivariate, and multivariate analyses for time to STI treatment */

* Load data from directory;
libname d "C:\Users\cgoldbeck\Box Sync\ATN - CG\Data\Data and Scripts\Data Sets";

OPTIONS FMTSEARCH=(d.formatlib);

data lab (keep = ct enrollment_id lbtest contact_backend_id LBORRESQ enrollment_id visit LBDTSP study IARSNA19 IARSNG19 IARSNH19); set d.lab_deident_20190516;
	where lbtest in (31,32,33,34,35,35,36); * subset lab data to only gonorrhea and chlamydia results for urethral, anal, and throat;
run;

data base_gr; set d.baseline_gr_20190513;
	if enrollment_id = . then delete; * blank testing enrollment_id used for management;
run;
proc sort data = base_gr;
	by enrollment_id;
run;
data base_gr; set base_gr;
	by enrollment_id;
	if not(first.enrollment_id) then delete;
run;

%label(base_gr); * cleaning macro generated in supplementary file, creates new analytical variables;

proc sort data = lab;
	by enrollment_id;
run;
proc sort data = base_gr;
	by enrollment_id;
run;
data base_lab;
	merge base_gr (in = y) lab (in = x); **we do not wish to consider those with missing lab or assesments so we inner join;
	by enrollment_id;
	if x = 1 and y = 1;
run;

data base_lab; set base_lab;
	time_to_treatment = IARSNA19 - LBDTSP; * days to treatment from STI diagnosis;

	same_day_treat = 0;
	if LBDTSP >'15Mar2018'd and contact_backend_id = "LOS_ANGELES" then same_day_treat = 1; * same day treatment implemented at different times for each site;
	if LBDTSP >'9Oct2018'd and contact_backend_id = "NEW_ORLEANS" then same_day_treat = 1;

	if time_to_treatment < 0 then time_to_treatment = 0; * there is some lag between when treatment and diagnosis are each reported so any negative date should be same day;
	if IARSNA19 = . then time_to_treatment = .;

	treat_30 = .; * flag those getting treatment within 30 days;
	if time_to_treatment <= 30 then treat_30 = 1;
	if time_to_treatment > 30 then treat_30 = 0;
	if time_to_treatment = . then treat_30 = .;
	if LBORRESQ = 2 and treat_30 = . then treat_30 = 0; * missing treatment means not treated;

	format treat_30 y2n. same_day_treat y2n.;
run;
data lab_2; set base_lab;
	where LBORRESQ = 2; * subset data for only those STI positive;
	if LBDTSP + 30 > '16May2019'd and IARSNA19 = . then delete; * exclude those who have not had 30 days to seek treatment;
run;

* Each person can have multiple entries e.g. multiple testing sights and treatment applies to all sights but also have multiple test conudcted within a visit widnow 
* so we accumulate treatment outcomes based on ID, visit, date of testing so there are no duplicate entries;

* tabulate each person's 30 day treatment result for each positive set;
proc sort data = lab_r;
	by enrollment_id visit LBDTSP IARSNA19;
run;
proc freq data = lab_r;
	by enrollment_id visit LBDTSP IARSNA19;
	table treat_30 / noprint out = lab_3;
run;

* add demographics; 
proc sort data = lab_3;
	by enrollment_id;
run;
proc sort data = base_gr;
	by enrollment_id;
run;
data lab_3;
	merge base_gr (in = y) lab_3 (in = x);
	by enrollment_id;
	if x = 1 and y = 1;
run;
data lab_3; set lab_3;
	same_day_treat = 0;
	if LBDTSP >'15Mar2018'd and contact_backend_id = "LOS_ANGELES" then same_day_treat = 1;
	if LBDTSP >'9Oct2018'd and contact_backend_id = "NEW_ORLEANS" then same_day_treat = 1;

	format same_day_treat y2n.;
run;


* tabulate each person's time to treatment result for each positive set;
proc sort data = lab_2;
	by enrollment_id visit LBDTSP;
run;
proc freq data = lab_2;
	by enrollment_id visit LBDTSP;
	table time_to_treatment / noprint out = lab_4;
run;
proc sort data = lab_4;
	by enrollment_id;
run;
proc sort data = base_gr;
	by enrollment_id;
run;
* add demographics; 
data lab_4;
	merge base_gr (in = y) lab_4 (in = x);
	by enrollment_id;
	if x = 1 and y = 1;
run;
data lab_4; set lab_4;
	same_day_treat = 0;
	if LBDTSP >'15Mar2018'd and contact_backend_id = "LOS_ANGELES" then same_day_treat = 1;
	if LBDTSP >'9Oct2018'd and contact_backend_id = "NEW_ORLEANS" then same_day_treat = 1;

	format same_day_treat y2n.;
run;

* tabulate each person's No. of partner treatment packs taken for each positive set;
proc sort data = lab_2;
	by enrollment_id visit LBDTSP;
run;
proc freq data = lab_2;
	by enrollment_id visit LBDTSP;
	table IARSNH19 / noprint out = lab_5;
run;
proc sort data = lab_5;
	by enrollment_id;
run;
proc sort data = base_gr;
	by enrollment_id;
run;
* add demographics; 
data lab_5;
	merge base_gr (in = y) lab_5 (in = x);
	by enrollment_id;
	if x = 1 and y = 1;
run;
data lab_5; set lab_5;
	same_day_treat = 0;
	if LBDTSP >'15Mar2018'd and contact_backend_id = "LOS_ANGELES" then same_day_treat = 1;
	if LBDTSP >'9Oct2018'd and contact_backend_id = "NEW_ORLEANS" then same_day_treat = 1;

	format same_day_treat y2n.;
run;


* Now we find cross sectional counts, percents, and means for before and after same day treatment implementation by site (contact_backend_id) and 
* overall for each outcome created above;

* treatment within 30 days;
proc freq data = lab_3;
	table treat_30  * same_day_treat / nopercent norow;
	table contact_backend_id * treat_30  * same_day_treat / nopercent norow;
run;

* time to treatment;
proc means data = lab_4 mean std median;
	class same_day_treat;
	var time_to_treatment;
run;
proc means data = lab_4 mean std median;
	class same_day_treat contact_backend_id;
	var time_to_treatment;
run;

* partner treatment packs taken;
proc means data = lab_5 mean n nmiss sum;
	class same_day_treat ;
	var IARSNH19;
run;
proc means data = lab_5 mean n nmiss sum ;
	class same_day_treat contact_backend_id;
	var IARSNH19;
run;


* We create two sets of regression models, controlling for demographic vars, predicting treatment within 30 days (binary) and time to treatment (continuous). One model of each
* generates the overall same day treatment effect and the other examines by site. Due to the repeated test on each person, we give each person a random intercept;

* Treatment within 30 days;
proc glimmix data = lab_r3 noclprint method=laplace;
	class enrollment_id treat_30 (ref = "No")  raceCat3 (ref = "African American") genderCat2 (ref = "Straight Men") 
	Education (ref = "Below high school") Employment (ref = "Employed") Insurance (ref = "Private") same_day_treat (ref = "No") 
	contact_backend_id (ref = "LOS_ANGELES");
	model treat_30 = same_day_treat contact_backend_id Age raceCat3 genderCat2 Education Employment Insurance / 
	solution dist = binafry link = logit oddsratio;
	random intercept / subject = enrollment_id;
run;
proc glimmix data = lab_r3 noclprint method=laplace;
	class enrollment_id treat_30 (ref = "No")  raceCat3 (ref = "African American") genderCat2 (ref = "Straight Men") 
	Education (ref = "Below high school") Employment (ref = "Employed") Insurance (ref = "Private") same_day_treat (ref = "No")
	contact_backend_id (ref = "LOS_ANGELES");
	model treat_30 = same_day_treat|contact_backend_id Age raceCat3 genderCat2 Education Employment Insurance / 
	solution dist = binary link = logit oddsratio;
	random intercept / subject = enrollment_id;
	lsmeans same_day_treat*contact_backend_id / slicediff=contact_backend_id oddsratio ilink cl; * effect by site;
run;

* Time to treatment;
proc glimmix data = lab_r4  ;
	class enrollment_id raceCat3 (ref = "African American") genderCat2 (ref = "Straight Men") 
	Education (ref = "Below high school") Employment (ref = "Employed") Insurance (ref = "Private") same_day_treat (ref = "No") 
	contact_backend_id (ref = "LOS_ANGELES");
	model time_to_treatment = same_day_treat Age raceCat3 genderCat2 Education Employment Insurance contact_backend_id/ 
	solution dist = n link = identity cl;
	random intercept / subject = enrollment_id;
run;
proc glimmix data = lab_r4  ;
	class enrollment_id raceCat3 (ref = "African American") genderCat2 (ref = "Straight Men") 
	Education (ref = "Below high school") Employment (ref = "Employed") Insurance (ref = "Private") same_day_treat (ref = "No")
	contact_backend_id (ref = "LOS_ANGELES");
	model time_to_treatment = same_day_treat|contact_backend_id Age raceCat3 genderCat2 Education Employment Insurance / 
	solution dist = n link = identity;
	random intercept / subject = enrollment_id;
	lsmeans same_day_treat*contact_backend_id / slicediff=contact_backend_id ilink cl; * effect by site;
run;





