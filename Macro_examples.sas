/*
This is a code block demonstrating my use of SAS macros to:
1. From a master dataset of RCT participants, break each participant into their own separate SAS dataset titled by their RCT user ID
2. Create new composite dietary variables based on existing answers to diet-based intervention questionnaires
3. Utilize the HEI 2015 diet quality index macro (from Automated-Self-Assessment 24-hour recall by NCI) to calculate their
   2015 HEI diet quality score, which measures their overall diet quality from a completed 24-hour recall.
4. Append their calculated score to their individual datasets.
5. Then append all individuals together into one master file, with their calculated diet quality scores, for final analysis (after
   converting them from wide to long form since this RCT has 3 separate periods).
*/



libname ASA "YourPath/ASA24_Jerbear";
option mprint mlogic macrogen symbolgen source source2;
%include "YourPath/ASA24_Jerbear/hei2015_score_macro.sas";

proc import file= "YourPath/ASA24_Jerbear/ASA24hrrecall.csv"
    out=work.ASA24_answers
    dbms=csv;
run;

/*Now let's iteratively break this file down into 15 separate datasets corresponding to each participant*/
%macro create_datasets;
    /* Get unique values of Participant IDs */
    proc sql noprint;
        select distinct ParticipantID into :participant_ids separated by ' '
        from work.ASA24_answers;
    quit;
    /* Loop through each Participant and create a new dataset */
    %let num_participants = %sysfunc(countw(&participant_ids));
    %do i = 1 %to &num_participants;
        %let participant_id = %scan(&participant_ids, &i);
        data ASA_24_&participant_id;
            set work.ASA24_answers;
            where ParticipantID = &participant_id;
        run;
    %end;
%mend;
%create_datasets;

/*Create new columns that the hei macro needs to calculate score for each dataset*/
%macro apply_code_to_datasets;
    %do participant_id = 1 %to 15;
        /* Specify the input and output dataset names */
        %let input_dataset = ASA_24_&participant_id;
        %let output_dataset = ASA_24_&participant_id;

        /* Apply the code to the dataset */
        data &output_dataset;
            set work.&input_dataset;
            FWHOLEFRT = F_CITMLB + F_OTHER;
            MONOPOLY = MFAT + PFAT;
            VTOTALLEG = V_TOTAL + V_LEGUMES;
            VDRKGRLEG = V_DRKGR + V_LEGUMES;
            PFALLPROTLEG = PF_MPS_TOTAL + PF_EGGS + PF_NUTSDS + PF_SOY + PF_LEGUMES;
            PFSEAPLANTLEG = PF_SEAFD_HI + PF_SEAFD_LOW + PF_NUTSDS + PF_SOY + PF_LEGUMES;
        run;
    %end;
%mend;
%apply_code_to_datasets;
 
/*Iteratively run the HEI 2015 macro for each dataset*/
%macro apply_macro_to_datasets;
    %do participant_id = 1 %to 15; *out of 15 participants;
        /* Specify the input and output dataset names */
        %let input_dataset = work.ASA_24_&participant_id;
        %let output_dataset = ASA_24_&participant_id._HEIscore;

        /* Call the HEI2015 macro with the specified input and output datasets */
        %HEI2015(indat=&input_dataset,
                  kcal=KCAL,
                  vtotalleg=VTOTALLEG,
                  vdrkgrleg=VDRKGRLEG,
                  f_total=F_TOTAL,
                  fwholefrt=FWHOLEFRT,
                  g_whole=G_WHOLE,
                  d_total=D_TOTAL,
                  pfallprotleg=PFALLPROTLEG,
                  pfseaplantleg=PFSEAPLANTLEG,
                  monopoly=MONOPOLY,
                  satfat=SFAT,
                  sodium=SODI,
                  g_refined=G_REFINED,
                  add_sugars=ADD_SUGARS,
                  outdat=&output_dataset);
    %end;
%mend;
%apply_macro_to_datasets;

/*Now let's append the datasets together so we have all original columns and newly calculated HEI score related
  columns together*/
/* Create an empty dataset to store the appended data */
data ASA_24_HEI_calculated;
    set work.ASA_24_1_HEIscore; 
	if ParticipantID=1;/* Use the first HEI dataset as a template */
run;

/* Append the remaining HEI datasets to the ASA_24_HEI_calculated dataset */
%macro append_HEI_datasets;
    %do participant_id = 2 %to 15;
        /* Specify the dataset to append */
        %let dataset_name = ASA_24_&participant_id._HEIscore;

        /* Append the dataset to ASA_24_HEI_calculated */
        proc append base=ASA_24_HEI_calculated data=&dataset_name force;
        run;
    %end;
%mend;
%append_HEI_datasets;
/*Let's export the total dataset with all HEI values calculated first, and make this the master file*/
proc export data=ASA_24_HEI_calculated
    outfile="YourPath/ASA24_Jerbear/ASA_24_HEI_masterfile.csv"
    dbms=csv
    replace;
run;

/*Create a dataset which keeps the HEI scores per recall per participant*/
Data ASA_24_HEI_recall;
set work.ASA_24_HEI_calculated;
keep User ParticipantID RecallNum RecallPer ReportDate HEI2015_TOTAL_SCORE;
run;
proc export data=ASA_24_HEI_recall
    outfile="YourPath/ASA24_Jerbear/ASA_24_HEI_recall.csv"
    dbms=csv
    replace;
run;

/*Now let's create a dataset which we average the HEI scores per study period*/
proc means data=ASA_24_HEI_recall noprint;
    var HEI2015_TOTAL_SCORE;
    class RecallPer;
    by ParticipantID;
    output out=ASA_24_HEI_Period mean=Average_HEI2015_TOTAL_SCORE;
run;
Data ASA_24_HEI_Period;
set work.ASA_24_HEI_Period;
if _TYPE_=0 then delete;
run;
Data ASA_24_HEI_Period;
set work.ASA_24_HEI_Period;
drop _TYPE_ _FREQ_;
run;
proc export data=ASA_24_HEI_Period
    outfile="YourPath/ASA24_Jerbear/ASA_24_HEI_Period.csv"
    dbms=csv
    replace;
run;
