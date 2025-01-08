
/* adjust path to your folder */
%let mainFolder = C:\git\sas-wrds\;
%let subFolder1 = &mainFolder\1 - rsubmit import export;

/* import starting at first row */
proc import 
  OUT       = work.myData DATAFILE= "&subFolder1\2 worldwide governance indicators\wgidataset.xlsx" 
  DBMS      = xlsx REPLACE;
  SHEET     = "VoiceandAccountability"; /* requires exact matching */
  GETNAMES  = YES; /* will read variable names from the first row (doesn't work here) */
run;

/* add 'DATAROW' - specifies the row to start reading data from, for our excelsheet: 16 */
proc import 
  OUT       = work.myData DATAFILE= "&subFolder1\2 worldwide governance indicators\wgidataset.xlsx" 
  DBMS      = xlsx REPLACE;
  SHEET     = "VoiceandAccountability"; /* requires exact matching */
  GETNAMES  = YES; /* will read variable names from the first row (doesn't work here) */
  DATAROW = 16; /* row with variable names (cannot specifiy two rows for variable names) */
run;

/* The following code downloads an Excel file and saves it to disk */

filename src url "https://www.worldbank.org/content/dam/sites/govindicators/doc/wgidataset.xlsx" recfm=f lrecl=512;
filename dest "&subFolder1\2 worldwide governance indicators\dataset_downloaded.xlsx" recfm=f lrecl=512;

data _null_;
  infile src;
  file dest;
  input;
  put _infile_;
run;

/* importing txt files */

/* adjust path to your folder */
%let topicFolder = &subFolder1\3 import txt files;

/* Delimited text files */

data games;
    infile "&topicFolder\game_sales_data_vg-chartz-usa.txt" dlm='09'x dsd firstobs=1;
    input
        Date : $15.
        Country : $3.
        Rank : 8.
        Game : $50.
        Platform : $10.
        Publisher : $30.
        Genre : $20.
        WeeklySales : comma8.
        TotalSales : comma10.
        Weeks : 8.;
run;

/*	put and input are functions to transform text to numbers and reverse
	here we use input to convert date like '14 Jul 2014' (which is text) to a SAS date (numeric) */

data games2;
set games;

/* Remove only the suffix (th, st, nd, rd) after the day number */
clean_date = prxchange('s/(st|nd|rd|th)//i', 1, Date);

/* Trim any leading/trailing spaces and convert to a SAS date with the input function*/
sas_date = input(trim(clean_date), date9.);

/* Format the SAS date for display */
format sas_date date9.;
run;

proc print data=games2 (obs=10);
run;


/* Fixed width text files */

filename MYFILE "&topicFolder\bushee.txt";

data bushee;
infile MYFILE;
input mngr 1-5 version 7 perkey 9-13 year 15-18 type $ 20-22 transient $ 24-26 perm $28-30 investm $ 32-34 perminv $ 36-38 growth $ 40-42 permgr $ 44-46;
run;

proc print data=bushee (obs=10);
run;

/* Challenging import: the information is spread over multiple lines
	Here we read each line into one variable (line) and use substring to extract the data
	input is used to conver the text into numbers
*/

data state_data (drop = line);
    infile "&topicFolder\alcohol_by_state.txt" truncover;
	/* this remembers State as it processes each of the rows, without 'retain' it would be missing */
    retain State; 

    /* Read each line from the file */
    input line $100.;

    /* Check if the line is a state name (no numbers in the line) */
    if anydigit(line) = 0 then do;
        State = line; /* Store the state name */
    end;
    else do;
        /* Extract data based on fixed positions using substr */
        Year  = input(substr(line, 1, 4), 4.);  /* Year is in columns 1-4 */
        Rate1 = input(substr(line, 24, 4), 8.); /* Rate1 is in columns 24-28 */
        Rate2 = input(substr(line, 29, 4), 8.); /* Rate2 is in columns 29-33 */
        Rate3 = input(substr(line, 34, 4), 8.); /* Rate3 is in columns 34-38 */
        Rate4 = input(substr(line, 39, 4), 8.); /* Rate4 is in columns 39-43 */
        Rate5 = input(substr(line, 44, 2), 8.); /* Rate5 is in columns 44-45 */
        
        /* Output the observation */
        output;
    end;
run;

proc print data=state_data (obs=10);
run;

/*	Datalines */

data scores;

infile datalines dsd;
/* the ~ (tilde) in input means to read and retain single quotation marks, double quotation marks, and 
delimiters within character values.  */
input Name : $9. Score1-Score3 Team ~ $25. Div $;

datalines;
Smith,12,22,46,"Green Hornets, Atlanta",AAA 
Mitchel,23,19,25,"High Volts, Portland",AAA 
Jones,09,17,54,"Vulcans, Las Vegas",AA 
;
proc print data=scores; run;


/* Exporting datasets */

/* sample dataset */
rsubmit; endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

  data a_comp (keep = gvkey fyear datadate cik conm sich sale at ni ceq prcc_f csho xrd curcd);
  set comp.funda;

  /* years 2010 and later*/
  if fyear >= 2010;

  /* prevent double records (specific to Compustat Funda only, other datasets do't need this) */
  if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
  run;
  
  /* download the dataset that was created */
  proc download data=a_comp out=a_comp;run;

endrsubmit;

/* Export to Excel */

proc export data=a_comp
    outfile="E:\temp\today\a_comp.xlsx"
    dbms=xlsx replace;
    sheet="Sheet1";
run;

/* Export to CSV */

proc export data=a_comp
    outfile="E:\temp\today\a_comp.csv"
    dbms=csv replace;
run;

/* Export to Stata */

proc export data=a_comp
    outfile="E:\temp\today\a_comp.dta"
    dbms=dta replace;
run;

