/*very basic example of using SAS arrays to standardize a physical activity minutes*/

/*this is very useful where we want to keep the values between 0 and 1 because in certain cases, especially in high dimensional aspects,
this will make models (especially ML models) run very efficiently. Some individuals may have as high as 500 mins per week of exercise
while some individuals may only have 0. If we have multipl time points such as below, we should probably think about standardizing them
to make models run smoothly*/

data standardizing;
    set physactivity_mins;
    
    array physact{*} phys1-phys10; *define array physact which includes all physical activity variables over 10 time points;
    avgphys = mean(of physact{*});
    sdphys = std(of physact{*}); *get their mean and standard deviation;
    
    /* Standardize them using an array loop */
    do i = 1 to dim(physact); *this is 10;
        physact{i} = (physact{i} - avgphys) / sdphys;
    end;
run;
