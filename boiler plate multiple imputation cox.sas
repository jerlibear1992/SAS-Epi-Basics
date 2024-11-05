libname mylib "\your_library_path\";

data unimputed_data;
set mylib.mydata;
run;

/* Step 1: Use PROC MI to impute 20 separate datasets. Variables in here should only be vars with missing information.*/
proc mi data=unimputed_data nimpute=20 out=imputed_data;
class cat_var1 cat_var2 cat_var3 binary_var1 binary_var2; /*Put your categorical variables (binary or 3 or more levels) here*/
														  /*MI methods: Continuous = reg; Binary = logistic; Categorical = discrim*/
fcs nbiter=10 /*10 iterations for burn in*/
logistic(binary_var1 binary_var2)
discrim(cat_var1 cat_var2 cat_var3)
reg(continuous_var1 continuous_var2 continuous_var3);
var binary_var1 binary_var2 cat_var1 cat_var2 cat_var3 continuous_var1 continuous_var2 continuous_var3;
run;

/* Step 2: Run cox regression for each of the 20 imputed datasets. Notice 'nonmissingvariables_' are not in step 1 because you're not imputing
																								 non-missing variables*/
proc phreg data=imputed data;
    class cat_var1 cat_var2 cat_var3 binary_var1 binary_var2 nonmissingvariables_categorical/ ref=FIRST;
	by _imputation_;
	model time_var*indicator_var(0) = binary_var1 binary_var2 cat_var1 cat_var2 cat_var3 continuous_var1 continuous_var2 continuous_var3 
									  nonmissingvariables_continuous nonmissingvariables_categorical/ RL ;
	output out=regression_output  / order=data;
	ods output ParameterEstimates=paramest;
run;


/* Step 3: Pool the parameter estimates from each of the 20 separate analysis parameters into the final estimates. These are your final
																													estimates to table. */
PROC MIANALYZE parms(classvar=FULL)=paramest;
class cat_var1 cat_var2 cat_var3 binary_var1 binary_var2 nonmissingvariables_categorical;
MODELEFFECTS binary_var1 binary_var2 cat_var1 cat_var2 cat_var3 continuous_var1 continuous_var2 continuous_var3 
			 nonmissingvariables_continuous nonmissingvariables_categorical;
ods output ParameterEstimates=comb_parms;
RUN;
