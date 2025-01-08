# `%ARRAY`, `%DO_OVER`

The following macro variables are used to read files:

```sas
/* adjust path to your folder */
%let mainFolder = C:\git\sas-wrds\;
%let subFolder5 = &mainFolder\5 - array do_over;
```

## Example dataset <a name="example_dataset"></a>

Use the following code to create a sample dataset:

```sas
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

data a_comp (keep = gvkey fyear datadate sich roa mtb size sale at ni prcc_f csho sich sic2);
set comp.funda;
if 2018 <=fyear <= 2022;
if cmiss (of at sale ceq ni) eq 0;
if at > 0;
if ceq > 0;
roa = ni / at;
mtb = csho * prcc_f / ceq;
size = log(csho * prcc_f);
sic2 = floor(sich/100); /* 2-digit SICH */
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;

proc download data=a_comp out=a_comp; run;
endrsubmit;
```

## Native SAS Arrays  <a name="native"></a>

SAS arrays group variables under a single name, accessed via an index, enabling efficient data manipulation. They are useful for repetitive tasks like calculations, transformations, or comparisons. Arrays are only supported in the data step and do not create new variables in the dataset. To define an array, specify its name, size, and included variables. They simplify processing for variables with similar characteristics.

Defining an array involves specifying the array name, the number of elements, and the variables to include. See next example.

#### Data step - array example

Imagine you have a dataset containing test scores for five subjects (score1, score2, score3, score4, and score5) and you want to adjust each score by adding 10 points. Instead of writing separate statements for each variable, you can use an array:

```sas
data adjusted_scores;
    set original_scores;
    array scores[5] score1-score5;  /* Define an array containing the variables */
    do i = 1 to 5;                 /* Loop through each element in the array */
        scores[i] = scores[i] + 10; /* Add 10 to each score */
    end;
    drop i;                         /* Drop the temporary index variable */
run;

```

The following example replaces missing values for variables on the example dataset (roa, mtb and size) referenced through an array.

```sas
data b_clean;
set a_comp;
array myvars[3] roa mtb size ;
do i = 1 to 3;                 
        if missing(myvars[i]) then myvars[i] = 0;
end;
drop i;  
run;
```

## `%ARRAY` and `%DO_OVER` <a name="array_do_over"></a>

A limitation of SAS arrays is their restriction to data steps, making them unsuitable for tasks that require looping outside of a data step. For example, if you need to repeatedly call a macro and pass data from a data step, SAS arrays cannot directly facilitate this process.

To address this limitation, SAS consultant Ted Clay developed macros (`%array` and `%do_over`) that emulate the functionality of general arrays or lists. These macros enable you to define a set of values—either hardcoded or sourced from a dataset—and use them in loops within data steps or macro code, offering greater flexibility for complex programming tasks.

Documentation and examples: [%Array and %Do_over](./Clay%20macros/SAS%20arrays%20in%20macros.pdf)

#### %Array

The `%array` macro defines an array, either by hardcoding the values or specifying a dataset and variable. 

See [%array code](./Clay%20macros/ARRAY.sas). I have also uploaded it in a github gist at [https://gist.githubusercontent.com/JoostImpink/c22197c93ecd27bbf7ef/raw/2e2a54825c9dbfdfd66cfc94b9abe05e9d1f1a8e/array.sas](https://gist.githubusercontent.com/JoostImpink/c22197c93ecd27bbf7ef/raw/2e2a54825c9dbfdfd66cfc94b9abe05e9d1f1a8e/array.sas)

#### %Do_over

The `%do_over` macro specifies which code or macro to loop through. 

See [%do_over code](./Clay%20macros/DO_OVER.SAS). I have also uploaded it in a github gist at [https://gist.githubusercontent.com/JoostImpink/c22197c93ecd27bbf7ef/raw/2e2a54825c9dbfdfd66cfc94b9abe05e9d1f1a8e/do_over.sas
](https://gist.githubusercontent.com/JoostImpink/c22197c93ecd27bbf7ef/raw/2e2a54825c9dbfdfd66cfc94b9abe05e9d1f1a8e/do_over.sas)

The `array` and `do_over` macros use `numlist`.

### Importing `%array`, `%do_over` and `%numlist`

The following snippet will include the macros from github:

```sas
filename m1 url 'https://gist.githubusercontent.com/JoostImpink/c22197c93ecd27bbf7ef/raw/2e2a54825c9dbfdfd66cfc94b9abe05e9d1f1a8e/array.sas'; 
%include m1;

filename m2 url 'https://gist.githubusercontent.com/JoostImpink/c22197c93ecd27bbf7ef/raw/2e2a54825c9dbfdfd66cfc94b9abe05e9d1f1a8e/do_over.sas'; 
%include m2;

filename m3 url 'https://gist.githubusercontent.com/JoostImpink/c22197c93ecd27bbf7ef/raw/2e2a54825c9dbfdfd66cfc94b9abe05e9d1f1a8e/numlist.sas'; 
%include m3;

```
Turn on macro debugging:

```sas
filename mprint 'E:\temp\today\tempSAScode.txt'; options mprint mfile;
```

---

## Example: Replace Missing Values with Zero <a name="example_missing"></a>

Instead of using data step's native array, specify the variables to replace as an array.


### Using `%do_over`
```sas
/* Define variables */
%let varlist = roa mtb size;

data b_clean;
    set a_comp;
    %do_over(values=&varlist, phrase=if missing(?) then ? = 0;);
run;
```

### Equivalent Manual Code

```sas
data b_clean;
    set a_comp;
    if missing(roa) then roa = 0;
    if missing(mtb) then mtb = 0;
    if missing(size) then size = 0;
run;
```

---

## Creating Year-Indicator Variables

### Using Basic Data Step Code
```sas
data b_indicators;
    set a_comp;
    d2018 = (fyear eq 2018);
    d2019 = (fyear eq 2019);
    d2020 = (fyear eq 2020);
    d2021 = (fyear eq 2021);
    d2022 = (fyear eq 2022);
run;
```

### Using `%do_over`
```sas
data b_indicators;
    set a_comp;
    %do_over(values=2018-2022, phrase=d? = (fyear eq ?););
run;
```

### Dynamic Range Example
```sas
/* Determine first and last years */
proc sql;
    select min(fyear), max(fyear) into :minYr, :maxYr 
    from a_comp;
quit;

data b_indicators;
    set a_comp;
    %do_over(values=&minYr - &maxYr, phrase=d? = (fyear eq ?););
run;
```

---

## Calling a Macro for Each Value <a name="do_over_macro"></a>

### Using `%do_over` with a Macro
```sas
%macro myMacro(var);
    %put Macro called with &var;
%mend;

/* Call macro for each value */
%do_over(values=hi hello goodbye, macro=myMacro);
```

This generates:
```sas
%myMacro(hi);
%myMacro(hello);
%myMacro(goodbye);
```

### Passing Values as Arguments
```sas
%macro myMacro2(var=);
    %put Macro called with &var;
%mend;

/* Use phrase to include arguments */
%do_over(values=hi hello goodbye, phrase=%myMacro2(var=?););
```

### Adding a Counter
```sas
%macro myMacro2(var, num);
    %put Macro called with &var;
    %put Counter is &num;
    data test&num;
        x = "&var";
        y = "&num";
    run;
%mend;

/* Invoke macro with text and counter */
%do_over(values=hi hello goodbye, phrase=%myMacro2(?, ?_i_););
```

## `DO_OVER` 'DELIM' option<a name="do_over_delim"></a>

The default delimter for the values being passed to do_over is a comma. It is possible to define a different delimter with 'DELIM', for example:

```sas
%do_over(values=hi|hello|goodbye, DELIM=|, phrase=%myMacro2(?, ?_i_););
```


## Using two arrays with `DO_OVER` 

Instead of using a single array, it is possible to pass two arrays (of equal length). These can be used in a phrase or macro call. 

### Example macro call with two arrays

```sas
%ARRAY(first,VALUES=hi hello goodbye);
%ARRAY(second,VALUES=15 20 3);
%DO_OVER(first second, macro=myMacro2);
```
This will generate:

```sas
%myMacro2(hi, 15);
%myMacro2(hello, 20);
%myMacro2(goodbye, 3);
```
This is useful when two arguments are needed (other than the second argument being a counter).

---

## Using `%array` to Access Dataset Variables <a name="array"></a>

### Example: Creating Indicators for Dynamic Year Ranges
```sas
/* Create a dataset of unique years */
proc sql;
    create table myYears as 
    select distinct fyear 
    from a_comp;
quit;

/* Define array using dataset values */
%array(years, data=myYears, var=fyear);

/* Display array elements */
%put yearsN: &yearsN;
%put years1: &years1;
%put years2: &years2;

/* Use array in a data step */
data b_indicators;
    set a_comp;
    %do_over(years, phrase=d? = (fyear eq ?););
run;
```

---

This tutorial provides a quick overview of `%do_over` and `%array` usage in SAS. These macros simplify repetitive tasks, enhance readability, and reduce the risk of errors in your code.

## Example: processing files in some folder <a name="example_folder"></a>


The following code creates a dataset with filenames (with paths) for a given folder. (Code copied from "Obtaining A List of Files In A Directory Using SAS - ResearchGate")

```sas
 %let folder = "&subFolder5\example_files_to_import";

 /* the following datastep constructs a dataset with the filename and full path */
data yfiles (keep = filename path);
 length fref $8 filename $80 path $300;
 rc = filename(fref, &folder);
 if rc = 0 then  do;
  did = dopen(fref);
  rc = filename(fref);
  end;
 else do;
  length msg $200.;
  msg = sysmsg();
  put msg=;
  did = .;
 end;
 if did <= 0  then  putlog 'ERR' 'OR: Unable to open directory.';
 dnum = dnum(did);
 do i = 1 to dnum;
   filename = dread(did, i);
   path = &folder || "\" || filename;
  /* If this entry is a file, then output. */
  fid = mopen(did, filename);
  if fid > 0 then output;
 end;
 rc = dclose(did);
 run;

 /* print it */
proc print data=yfiles;
run;
```

The following code creates an array with the filenames:

```sas
/* path holds the file name paths, assign to an array */
%ARRAY(files, DATA=yfiles, VAR=path) ;

%put number of files: &filesN;

%put %do_over(files, phrase =file: ? ?_I_);
```

The following macro will import each file:

```sas
/* this macro will import the file with path f to a dataset myData, that gets appended to allInputData */
%macro doImport(f);

    /* import file f */
    filename MYFILE "&f";
    data myData; /* should add index */
    infile MYFILE dsd delimiter='09'x /* tab delimited */ firstobs=2 LRECL=32767 missover;
    input score gvkey fyear mymeasure  auditfee  filinglength  delay fog numberWords  mkvalt  size  roa numest institutHold;
    run;

    %if %sysfunc(exist(allInputData)) %then %do;
      /* allInputData exists, append the newly imported data */
      proc append base=allInputData data=myData; run;
    %end;
    %else %do;
      /* it is the first dataset -> set allInputData to equal newly imported dataset */
      data allInputData; set myData;run;
    %end;
%mend;
```

For debugging purposes (when running the code more than once), make sure to delete the dataset that is created:

```sas
proc datasets; delete allInputData;quit;
```

The following `%do_over` will invoke the macro for each of the files:

```sas
%do_over(files, macro=doImport);
```
