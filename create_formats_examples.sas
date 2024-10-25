
/*
The following is a simple sample of creating formats for the artificial sweetened beverage and blood sugar RCT I helped with analysis
*/

libname myfile 'yourpath\bev_study';
*read in, removed id without any value in 3 time points;
proc import datafile="yourpath\bev_study\bg_data_2023.csv" 
  out=raw_data dbms=csv replace;
  getnames=yes;
  guessingrows=10000;
run;

proc format library=myfile.library;
*Redcap fmts;
	value $rcevent 
		screen_arm_1='Screened by assistant arm' run_arm_1='Run-in arm' 
		baseline_arm_1='Baseline' week3_arm_1='Week 3' 
		week6_arm_1='Week 6' week9_arm_1='Week 9' 
		week12_arm_1='Week 12' week15_arm_1='Week 15' 
		week18_arm_1='Week 18';
	
	value state
		1='TX' 
		2='CA';
	value gender
		1='Male' 2='Female' 3='Other';
	
	value bevsize
		1='small bottle' 2='normal bottle' 
		3='large bottle' 4='extralargebottle' 
		5='Other';
	value threemosugar 
		1='< 6.5%' 2='6.5-7.5%' 
		3='7.6-8.5%' 4='8.6-9.5%' 
		5='>9.5%';;
	value tobacco
		1='day' 2='sometimes' 
		3='Quiter' 4='Never';
	value language
		1='English' 2='Spanish' 
		3='French' 4='Chinese';
	value education
		1='up to high school' 2='Some high school' 
		3='High school graduate/GED' 4='some or 2 year college' 
		5='4 yr College degree' 6='Graduate degree/Professional degree/Licensed';
	value studycompletion
		0='Incomplete' 1='Unverified' 
		2='Complete';
	
	run;
