
/*This is some example code to show basics of SAS coding that epis should really known*/

/*data merging*/
proc sort data=data1; by ID /*var2*/; run;
proc sort data=data2; by ID /*var2*/; run;

data merge1;
    merge data1 data2;
    by id /*var2*/;
run; *simple merge with wide dataset and one row per ID;

data merged2;
    merge data1(in=a) data2(in=b);
    by id /*var2*/;
    if a and b; *this is a conditional merge if the row exists in both wide datasets;
run;

/*data concatenation*/
data stacked1;
    set data1 data2;
run; *simple concatenation where you stack 2 datasets on top of each other;

proc append base=stacked2 data=data1; 
run;
proc append base=stacked2 data=data2; 
run; *another way to concatenate is to basically use proc append;



/*data transposition: wide to long and long to wide*/
/*transpose wide to long*/
proc transpose data=widedat out=long1 prefix=horm ;
   by ID;
var horm_1 horm_2 horm_3;
run;
proc transpose data=widedat out=long2 prefix=educate ;
   by ID;
var educate_1 educate_2 educate_3;
run;
proc transpose data=widedat out=long3 prefix=income ;
   by ID;
var income_1 income_2 income_3;
run;
data long_data;
   merge long1 (rename=(horm1=horm) drop=_name_) long2 (rename=(educate1=educate) drop=_name_)
         long3 (rename=(income1=income) drop=_name_); 
   by ID;
   year=input(substr(_name_, 7), 2.); *last _name_ is income_1, _2, _3, so we take the 7th character as value for year;
   drop _name_;
run;
proc sort data=long_final;
by year;
run;


/*transpose long to wide*/
proc transpose data=long_final out=wide1 prefix=horm;
   by ID;
   id year;
   var horm;
run;

proc transpose data=long2 out=wide2 prefix=educate;
   by ID;
   id year;
   var educate;
run;

proc transpose data=long2 out=wide3 prefix=income;
   by ID;
   id year;
   var income;
run;

data wide_final;
    merge  wide1(drop=_name_) wide2(drop=_name_) wide3(drop=_name_);
    by ID;
run;

proc print data=wide_final;
run;


/*assuming no major issues with missing data, wrongly entered data, implausible values like BMI = 400..., basic cleaning involves
dealing with missing values unless you want to impute, categorizing, or recoding variables */
data cleaned;
    set raw;
    /* if values don't make sense we can make them missing */
    if sex > 1 then sex = .; *assuming gender only takes value of 0 and 1;

    if bmi <= 18.5 then bmicat = 'Underwt';
    else if 18.5 < bmi < 25 then bmicat = 'Normal';
    else bmicat = 'overweight and above'; /*categorizing continuous var bmi*/

    if sex = 'M' then sexnum = 0; 
    else if sex = 'F' then sexnum = 1; *recode and create new variable that is numeric;
run;


/*basic date subtraction*/
data dates;
    set data1;
    format date1 date2 date9.;
    date1 = input('08JUN1992', date9.);
    date2 = input('08JUN2024', date9.);
    datesdiff = intck('year', date1, date2); *calculate difference in years between two dates you listed;
run;


/*importing and exporting data*/
/*these are both for csv files, which imo are most common outside of sas7bdat files*/
proc import datafile='yourpath/JerBear/needtoimport.csv'
    out=mydata
    dbms=csv
    replace;
    getnames=yes;
run;

proc export data=mydata outfile='yourpath/JerBear/targetexportfile.csv' dbms=csv replace;
    putnames=yes;
run;
