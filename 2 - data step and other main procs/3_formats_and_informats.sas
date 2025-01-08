data example_format;
    amount = 12345.678;
    format amount dollar12.2; /* Display amount as currency with 2 decimal places */
run;

proc print data=example_format;
run;


data example_informat;
    input date_str $10.;
    date = input(date_str, mmddyy10.); /* Convert string to date using an informat */
    format date date9.; /* Format the date for display */
datalines;
12/31/2023
01/01/2024
;
run;

proc print data=example_informat;
run;

data test;
x = 16;
y = .;
x2 = 150;
run;

/*	Format for deciles */
proc format;
value mySizeFormat
/* If 10 or higher */
0 - 5 = 'tiny'
5 - <10 = 'decent'
10 - <30 = 'big'
30 - 100 = 'huge'
. = 'missing'
/* Other values (catch-all) */
other = [best.];
run;

data test2;
set test;
/* apply format to variables x and y, note the period after the format name */
format x y x2 mySizeFormat.;
run;

data test3;
set test2;
z = x+1;
run;

data example_put;
    num_value = 12345.678;
    char_value = PUT(num_value, dollar12.2); /* Convert number to formatted character */
run;

proc print data=example_put;
run;

data example_put_date;
    date_value = '31DEC2023'd;  /* SAS date literal */
    char_date = PUT(date_value, date9.); /* Convert date to character format */
run;

proc print data=example_put_date;
run;

data example_input;
    char_num = '12345.67';
    num_value = INPUT(char_num, 8.); /* Convert character to numeric */
run;

proc print data=example_input;
run;


data example_input_date;
    char_date = '12/31/2023';
    date_value = INPUT(char_date, mmddyy10.); /* Convert character to SAS date */
    format date_value date9.; /* Apply date format for display */
run;

proc print data=example_input_date;
run;

data test;
set a_comp;
gvkey_num = 1 * gvkey;
run;
