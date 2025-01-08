# Importing Excel files <a name="excelimport"></a>

### Paths to files

To make the code more flexible, since folder structures vary for each user, macro variables are used. Update 'mainFolder' (and 'subFolder1') if needed. 

```sas
/* adjust path to your folder */
%let mainFolder = C:\git\sas-wrds\;
%let subFolder1 = &mainFolder\1 - rsubmit import export;
```

## Excel import - Example 1 <a name="excelimportexample"></a>

The following code imports the Excelfile into 'myData' in the work library:

```sas
/* import starting at first row */
proc import 
  OUT       = work.myData DATAFILE= "&subFolder1\2 worldwide governance indicators\wgidataset.xlsx" 
  DBMS      = xlsx REPLACE;
  SHEET     = "VoiceandAccountability"; /* requires exact matching */
  GETNAMES  = YES; /* will read variable names from the first row (doesn't work here) */
run;
```
### Excel files cannot be imported when they are still open in Excel

If you are currently viewing the file in Excel you will get this error: 

```
ERROR: Error opening XLSX file -> C:\git\sas-wrds\1\2
worldwide governance indicators\\wgidataset.xlsx .  It is either not an Excel spreadsheet or it
is damaged.   Error code=80001019
Requested Input File Is Invalid
ERROR: Import unsuccessful.  See SAS Log for details.
*/
```
## Excel import - Example 2 - `DATAROW` <a name="datarow"></a>

Adding 'DATAROW' to specify the row to start reading data from, for our excelsheet that is row 16.  

```sas
proc import 
  OUT       = work.myData DATAFILE= "&subFolder1\2 worldwide governance indicators\wgidataset.xlsx" 
  DBMS      = xlsx REPLACE;
  SHEET     = "VoiceandAccountability"; /* requires exact matching */
  GETNAMES  = YES; /* will read variable names from the first row (doesn't work here) */
  DATAROW = 16; /* row with variable names (cannot specifiy two rows for variable names) */
run;
```

The import was succesful, but what are some issues that need to be addressed? 
- variable names were on rows 14+15, 'GETNAMES' requires row 1 to have variable names
- data has been imported as text (left aligned), not as numbers
- the data is in 'wide' format, we normally want 'long' format (easier for matching/future processing)

## 'Wide' vs 'long' format <a name="widelong"></a>

Some data sources (like the wgidataset) come in a 'wide' format. For further processing (including matching with other datasets) it is often easier to have the data in 'long' format. For example:

#### Wide format 
```
		country		1996 mean	1998 mean	2000 mean
		Andorra		1.56		1.53		1.54
```
#### Corresponding long format 
```
		country		year	voice
		Andorra		1996	1.56
		Andorra		1998	1.53
		Andorra		2000	1.54
```
For annual data in wide format, the variable names usually include a year, meaning a single observation contains data for multiple (or all) years. In long format, the year is treated as a separate variable, and each row represents data for only one year.

You can use `proc transpose` to convert a dataset from wide format to long format.

## Other Excel import options <a name="otheroptions"></a>

RANGE
-----
The `RANGE` option is used to specify which range SAS would import.

### `RANGE` Examples

`RANGE="Sheet1$B2:D10"` - tells SAS to import data from range B2:D10 from sheet1

`RANGE="Information"` - tells SAS to import data from excel defined name range. In the example shown above, it is Information.

XLS
---
`DBMS=XLS`: Import a Microsoft Excel 97-2003 file

`XLS`  suports `NAMEROW`, in our example it would be `NAMEROW=15` (for XLSX `GETNAMES=YES` will only read starting at row 1)





## Download from url <a name="download"></a>

To import an online Excel file, you can either manually download the file to your computer and then import it as a local file. Alternatively, the following code automatically downloads the Excel file and saves it to your disk:

```sas
filename src url "https://www.worldbank.org/content/dam/sites/govindicators/doc/wgidataset.xlsx" recfm=f lrecl=512;
filename dest "&subFolder1\2 worldwide governance indicators\dataset_downloaded.xlsx" recfm=f lrecl=512;

data _null_;
  infile src;
  file dest;
  input;
  put _infile_;
run;
```
---
# Importing text (.txt) and .csv files <a name="import_txt"></a>

Macro variable for the folder holding the examples:

```sas
%let topicFolder = &subFolder1\3 import txt files;
```

## Importing CSV and Delimited text files <a name="delimited"></a>

To import a CSV file, use `PROC IMPORT` with the `dbms=csv` option. The default delimiter is a comma, but you can specify a different delimiter using the `DELIMITER=` option. SAS automatically detects the structure of the dataset, including variable names and data types. However, dates are imported as strings, so additional processing is needed to convert them into SAS date formats for further analysis.

Here's an example of how to import a CSV file:

```sas
proc import datafile="C:\path\to\file.csv"
    out=mydata
    dbms=csv
    replace; /* Replaces the dataset if it already exists */
    getnames=yes; /* Extracts variable names from the first row */
run;
```

In this example, SAS reads the CSV file located at `C:\path\to\file.csv`, creates a dataset named `mydata`, and uses the first row of the file as variable names (`getnames=yes`). If the file doesn't have headers, you can set `getnames=no`, and SAS will assign default variable names.

Importing delimited text files into SAS is can also be done using the `INFILE` and `INPUT` statements. The `INFILE` statement specifies the location of the text file and includes options for handling delimiters (such as commas, tabs, or spaces). Common delimiters are comma (CSV), pipe (`|`) and tab, and SAS can handle these with options like `dlm=','` or `dlm='09'x` (for tab). In the `INPUT` statement, you specify the variable names to assign to each field in the file. SAS automatically reads fields based on the delimiter specified.

If the first row of the file contains variable names, the `firstobs=2` option can be used in the `INFILE` statement to skip that header. Additionally, `DSD` can be used to handle files where fields are enclosed in quotes and commas are treated as field separators, and `MISSOVER` can be used to ensure missing values are handled properly. 

### DSD

In the infile statement, the dsd option stands for "Delimiter-Sensitive Data." It changes how SAS reads delimited data by treating consecutive delimiters (commas, in this case) as missing values and allowing strings enclosed in quotes to contain embedded delimiters (such as commas within a team name). This makes it useful for reading CSV-like data. */

```sas
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
```
> In the log you will see many warnings (invalid data for WeeklySales and TotalSales); this is because of N/A values, which are not in line with the numerical formats (cooma8. and comma10.).

## `PUT` and `INPUT` <a name="put_input"></a>

`PUT` and `INPUT` are functions to transform text to numbers and reverse
here we use input to convert date like '14 Jul 2014' (which is text) to a SAS date (numeric).

The following example shows the use of `INPUT`:

```sas
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
```

## Fixed width text files <a name="fixed"></a>

Importing fixed-width text files into SAS requires understanding the structure of the data, where each field has a specific position and length. To achieve this, the `INFILE` and `INPUT` statements are used. The `INFILE` statement specifies the file's location, and the `INPUT` statement defines how to read the variables by specifying the starting positions and lengths of each field.

When importing a fixed-width file, you generally use the `@` symbol to control where SAS begins reading for each variable. For example, input @1 Var1 $10. @11 Var2 8.; tells SAS to read Var1 as a 10-character string starting at position 1, and Var2 as an 8-digit numeric field starting at position 11. If the positions of the fields are known and consistent, this method allows precise control over the data import.

### Example

The first few lines of 'bushee.txt':

```
  110 1  5000 1999 IIA QIX QIX LVA LVA VAL G&I
  110 1  5000 2000 IIA QIX QIX LVA LVA G&I G&I
  110 1  5000 2001 IIA QIX QIX LVA LVA VAL G&I
```

The following code reads the file, note the `input` line here the variable names, a $ flag for textual variables, and the positions are specified:

```sas
filename MYFILE "&topicFolder\bushee.txt";

data bushee;
infile MYFILE;
input mngr 1-5 version 7 perkey 9-13 year 15-18 type $ 20-22 transient $ 24-26 perm $28-30 investm $ 32-34 perminv $ 36-38 growth $ 40-42 permgr $ 44-46;
run;

proc print data=bushee (obs=10);
run;
```

## A more challenging import - An example 

Challenging import: the information is spread over multiple lines. 
Here we read each line into one variable (line) and use substring to extract the data input is used to conver the text into numbers.

The first few rows are as follows:

```
Alabama
2012.................. 1.16 0.24 0.60 2.00 9
2011.................. 1.14 0.24 0.59 1.97 9
2010.................. 1.16 0.23 0.58 1.97 9
```
The following code will read each line into a variable (line), test if holds a State name or not, and if not, uses substring (substr) to extract the values.

The `retain` keyword will remember the State name. The `output` keyword triggers a row in the output dataset. See more on `retain` and `output` in week 2, topic 'data step'.

```sas
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
```
> See `alcohol_to_csv.py` for python code to read the alcohol data.

##	Datalines <a name="datalines"></a>

In SAS, you can import data using the DATA step and the `DATALINES` statement. The DATA step defines the dataset and variables, while `DATALINES` allows you to input raw data directly within the code. Each line of data represents a new observation, and values are assigned to variables defined in the `INPUT` statement. This method is ideal for small, manually entered datasets, so you will see this in documentation/online examples.

Example from https://go.documentation.sas.com/doc/en/pgmmvacdc/9.4/lrcon/n1w749t788cgi2n1txpuccsuqtro.htm

```sas
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
```
---
# Exporting datasets <a name="exporting"></a>

In SAS, `PROC EXPORT` is used to export datasets to different file formats, including Excel worksheets, CSV files, and Stata files. This procedure is versatile, allowing you to specify both the format and location of the output file.

SAS can also export to other text formats, such as fixed-width, which is useful when the file is too large for Excel. In research, heavy data processing is typically done in SAS, with the final dataset exported to Stata for further analysis or to Excel for creating tables and summaries.

If you want to export data to Python, it can directly read SAS datasets. However, Python cannot save data in SAS format.

### Example dataset

Run the following code to create a sample dataset:

```sas
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
```


## Export to Excel <a name="export_excel"></a>

To export a dataset to an Excel worksheet, you can use the following code:

```sas
proc export data=a_comp
    outfile="E:\temp\today\a_comp.xlsx"
    dbms=xlsx replace;
    sheet="Sheet1";
run;
```
The `replace` option allows you to overwrite an existing file. However, if the file is open in Excel, it cannot be overwritten.

> You can export multiple datasets to the same Excel file, with each dataset placed in a separate worksheet. In the same Excel file, you can add additional worksheets for further data processing, such as creating formatted tables. If these worksheets use cell references, updating tables and figures becomes easier and more dynamic.

## Export to CSV <a name="export_csv"></a>

For exporting to a CSV file, the `dbms=csv` option is used:

```sas
proc export data=a_comp
    outfile="E:\temp\today\a_comp.csv"
    dbms=csv replace;
run;
```

## Export to Stata <a name="export_stata"></a>

To export the dataset to a Stata file (`.dta`), the `dbms=dta` option is specified:

```sas
proc export data=a_comp
    outfile="E:\temp\today\a_comp.dta"
    dbms=dta replace;
run;
```
