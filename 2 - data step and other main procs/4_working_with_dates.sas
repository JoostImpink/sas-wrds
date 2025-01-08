  
data test;
date1 = '31DEC2023'd;
date2 = '01JAN2024'd;
date3 = mdy(12, 31, 2023); /* Creates 31DEC2023 */

format date1-date3 date9.;
run;

data example;
    char_date = '12/31/2023';
    date1 = input(char_date, mmddyy10.); /* Convert to SAS date */
    format date1 date9.; /* Format date for display */
run;

proc print data=example;
run;

data example;
    start_date = '01JAN2024'd;
    new_date = start_date + 10; /* Adds 10 days */
    format start_date new_date date9.;
run;

data example;
    start_date = '01JAN2024'd;
    end_date = '15JAN2024'd;
    days_diff = end_date - start_date; /* Calculate the number of days between dates */
run;


data test;

months_diff = intck('week', '01JAN2024'd, '11JUL2024'd); /* Result: 6 months */
new_date = intnx('month', '01JAN2024'd, 6, 'E'); /* Adds 6 months */
format new_date date9.;
run;



data b_comp;
set a_comp;
boy = intnx('month', datadate, -8, 'B');
eoy = intnx('month', datadate, +3, 'E');
format boy eoy date9.;
run;

/* year ends 20110531 , started 20100601 -> return window sep 1, 2010 - aug 31, 2011 */

data b_comp (keep = gvkey fyear datadate boy eoy);
set a_comp;
boy = intnx('month', datadate, -8, 'B');
eoy = intnx('month', datadate, +3, 'E');
format boy eoy date9.;
run;

data example;
    date1 = '31DEC2023'd;
    year = year(date1);
    month = month(date1);
    day = day(date1);
run;

proc print data=example;
run;

