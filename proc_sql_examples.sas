/*following codes are some useful SQL commands I think epis would find useful to reference*/
/*there are of course more uses for proc SQL but these are most common ones I've used*/

proc sql;
    create table dat2 as
    select * /*if you like to choose specific variables list them here*/
    from dat1;
quit; *creates a new dataset dat2 from current dataset dat1;

proc sql;
    create table filtered_variables as
    select variable1, variable2, variable3
    from dat1;
quit; *select a few variables of interest;

proc sql;
    create table filtered_variables_condition as
    select variable1, variable2, variable3
    from dat1
    where age < 40;
quit; *conditional select where you choose variables 1, 2, and 3 but also limited it to age < 40;

proc sql;
    create table descriptive_tab as
    select variable3, 
           count(distinct ID) as uniq_ID,
           sum(variable3) as total_var3,
		   mean(variable3) as mean_var3
    from dat1
    group by age;
quit; *do summary statistics like count, sum, mean for variable 3 stratified by age;

/*Below is an example I used to confirm unique IDs in a final dataset I've cleaned*/
PROC SQL;
    SELECT COUNT(DISTINCT ID) AS Unique_ID_Count
    INTO :unique_id_count
    FROM cvddat;
QUIT;
%PUT Total Unique ID Count: &unique_id_count;
