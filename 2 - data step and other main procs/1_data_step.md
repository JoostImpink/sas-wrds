# Data step

## DATA Step Overview <a name="datastep_overview"></a>

The **DATA step** allows you to create, manipulate, and analyze data sets. A DATA step typically consists of reading input data, performing calculations, transforming the data, and then writing the output to a new SAS data set.

The SAS DATA step processes the data row by row, making it versatile for handling large data sets. It also provides control through conditional logic (`IF-THEN` statements) and loops (`DO` loops), giving you the power to customize how each row is handled.

The basic structure of a DATA step is as follows:

```sas
DATA output_data;
    SET input_data;
    /* Data manipulation and calculations */
RUN;
```

#### Key Components:

 The **DATA statement** defines the name of the output data set, with SAS creating a temporary data set if no name is provided. The **SET statement** allows you to read in an existing SAS data set, with the option to merge or concatenate multiple data sets. Within the DATA step, you can perform **data manipulation** tasks such as creating new variables, modifying existing ones, filtering rows, or applying calculations. Finally, the **RUN statement** signals SAS to execute the instructions in the DATA step.



### Data step example 

The following example gets records from Compustat Funda. The data step uses 'comp.funda' as the input dataset (`set comp.funda`), the code contains filtering (`if` statements), and constructs new variables.

The `keep` statement specifies which variables to retain after the DATA step is executed.

The `cmiss` function counts the number of missing values for the variables listed after the `of` keyword. Having the count equal zero (`eq 0`) implies that only records that have no missing values for the listed variables are kept.

The `missing` function operates on a single variable. If the variable is missing for a given observation, it returns 1; if it is non-missing, it returns 0. In the example below, `miss_sich` will be set to 1 if the `sich` (standard industry code) is missing.

```sas
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

   data a_comp (keep = gvkey fyear datadate sich roa mtb size sale at ni prcc_f csho miss_sich);
   set comp.funda;

   /* require fyear to be within 2010-2013 */
   if 2010 <=fyear <= 2013;
   /* require assets, sales, equity and net income to be non-missing */
   if cmiss (of at sale ceq ni) eq 0;
   /* prevent double records */
   if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;

   /* construct some variables */
   roa = ni / at;
   mtb = csho * prcc_f / ceq;
   size = log(csho * prcc_f);
   miss_sich = missing(sich);
   run;

   proc download data=a_comp out=a_comp;run;
endrsubmit;
```

### Combining Datasets with `set`

While it’s common to use a single dataset as input, SAS allows you to combine multiple datasets using `set`. When the datasets have the same structure (with matching variable names and types), they are simply stacked together.

For example, if you have annual datasets (such as `data2010`, `data2011`, …, `data2020`) and want to combine them into one dataset:

```sas
data myData;
    set data2010-data2020;
run;
```

This code will stack the datasets from `data2010` through `data2020` into a single dataset named `myData`.

---

## `keep`, `drop`, `where`, and `rename` <a name="keepdrop"></a>

In the previous example, the `keep` statement is used to retain specific variables. This is particularly useful when dealing with a dataset that contains many variables but you only want to keep a select few. Conversely, if you want to retain most variables while dropping a few, the `drop` statement can be used. Additionally, you can rename variables for clarity or consistency.

These keywords can be applied to both the input and output datasets.

### Example:

Let's read records where sales exceeds 100 and rename gvkey to company_id.

```sas
data b_large (keep = gvkey sale rename=(gvkey = company_id));
set a_comp (where=(sale>100));
run;
```

In this example:
- The `WHERE` statement filters observations to include only those with `sale` values greater than 100. Since the `where` is included on the `set`, the data step will only work with records that meet this condition
- The `KEEP` statement retains only the `gvkey` and `sale` variables (renaming is done afterwards).
- The `DROP` statement removes any specified unwanted variables from the output dataset.
- The `RENAME` statement changes the name of the `gvkey` variable to `company_id`.

> Note, `keep`, `drop`, `where` and `rename` can also be included in the data step code block, as follows:

```sas
data b_large;
set a_comp ;
where sale > 100; 
keep gvkey sale company_id;    
/* drop unwanted_var; * not used here */
rename gvkey = company_id; 
run;
```
> Note: it seems that the `keep` keyword cannot be used on the input dataset on WRDS. The following doesn't work:

```sas
rsubmit;
   data test;
   set comp.funda (keep = gvkey fyear);
endrsubmit;
```
On a remote dataset in the work folder however it does work:

```sas
rsubmit;
data test;
set a_comp (keep = gvkey fyear);
run;
endrsubmit;
```

So this may be related to file permissions (meaning having both read and write permissions). 

---

## `_null_` <a name="null"></a>

It is possible to have `_null_` as the output dataset, in which case no dataset is created. For example to set the number of observations to a macro variable

```sas
data _NULL_;
	if 0 then set work.a_comp nobs=n;
   /* set macro variable nrows to n (nobs) */
	call symputx('nrows',n);
	stop;
run;
/* display a message with the number of observations */
%put The number of observations is &nrows;
```

---


## `_N_` <a name="N"></a>

In the SAS DATA step, `_N_` is an automatic variable that counts the number of times the DATA step has iterated, representing the current observation or row being processed. It starts counting at 1.

```sas
data myTable2;
set myTable;
/* create counter */
counter = _N_;
/* keep the first 100 obs */
if _N_ <= 100;
run;
```

---

## Filtering: `IF` versus `WHERE` and indices <a name="filtering"></a>

In SAS, both the `IF` and `WHERE` statements are used to filter data, but they operate differently and have distinct use cases.

### `IF` Statement:
- The `IF` statement filters data **after it is read into the program data vector (PDV)**. This means all observations are read into memory first, and the `IF` statement decides which ones to keep or discard based on the condition.
- You can use **multiple `IF` statements** within the same DATA step to apply several conditions.
  
### `WHERE` Statement:
- The `WHERE` statement filters data **before it is read into the PDV**. This can make it more efficient than `IF` for large data sets, as it reduces the number of observations read into memory.
- You can only use **one `WHERE` statement** in a DATA step, but you can apply multiple conditions within that statement using logical operators.
- The `WHERE` statement can also take advantage of **indices**, if available, to speed up data retrieval.


### What are Indices?
Indices are used to speed up the search and retrieval of data in a data set. They function like a table of contents, allowing SAS to locate observations quickly, especially when filtering with the `WHERE` statement. By using an index, SAS can directly access the relevant rows instead of scanning the entire data set.



### How to View Indices
To see which indices are available on a SAS table, use the **`PROC CONTENTS`** statement:

```sas
rsubmit;
PROC CONTENTS DATA=comp.funda;
RUN;
endrsubmit;
```

This will display metadata about the data set, including any indices that have been created. The following indices are set on comp.funda:

```                                                                                      
                    Alphabetic List of Indexes and Attributes                                     
                                                                                                  
                                         # of                                                     
                                       Unique                                                     
                #    Index             Values    Variables                                        
                                                                                                  
                1    cusip              44392                                                     
                2    fyear                 76                                                     
                3    gvkey_datadate    579623    gvkey datadate                                   
                4    tic                44388 
```

> A joint index (like gvkey_datadate) is faster than a single index (like cusip or tic) when it comes to sorting and matching when the date is used together with gvkey. 


### Example

Run the following code and compare the running times in the log:

```sas
rsubmit;

/* where will benefit from indices */
data test;
set comp.funda;
where gvkey eq "001004";
run;

/* if will read the full dataset */
data test;
set comp.funda;
if gvkey eq "001004";
run;

endrsubmit;
```

---


## Creating an Indicator Variable Using Expressions  <a name="indicator"></a>

An **indicator variable** (also known as a dummy variable) is often used in data analysis to flag certain conditions or categories in a dataset. In SAS, you can create indicator variables using expressions that evaluate to **true (1)** or **false (0)**.

### How It Works:
Expressions in SAS are logical conditions that return either `1` (true) or `0` (false). When creating an indicator variable, you write a condition (or set of conditions) that SAS evaluates for each observation. If the condition is true for a given observation, the indicator variable will be set to `1`; otherwise, it will be set to `0`.

### Example:
Suppose you want to create an indicator variable, `large`, that flags whether the sales exceeds 116.084.

```sas
DATA a_comp2;
    SET a_comp;
    /* Creating an indicator for high sales */
    large = (sale > 116.084);
RUN;
```

### Explanation:
- **Expression**: `(sale > 116.084)` is a logical condition. It evaluates to `1` if the `sale` is greater than 116.084, and `0` otherwise.
- the parenthesis around the expression are not strictly needed, but it makes the code more readable.

This approach allows for easy filtering, grouping, or analysis of specific categories or conditions within the data.

---

## `Retain` <a name="retain"></a>

In a SAS DATA step, the **`retain`** statement preserves the value of a variable across iterations of the DATA step, rather than reinitializing it to missing for each new observation. This is useful when you need to carry forward values or accumulate data between observations.

### Example

Let's create an indicator variable by firm to flag if annual sales has increased over time. Let's use `retain` to remember sale of the previous year.

```sas
data a_comp2 (keep = gvkey fyear sale sale_prev increase);
set a_comp;
retain sale_prev;
/* create indicator */
increase = (sale > sale_prev);
/* update sale_prev to be used in the next record */
sale_prev = sale;
run;
```

> When retaining a variable (here 'sale_prev'), it is important that this variable does not exist on the input dataset. If that is the case, it will be overwritten by the input data and nothing is retained.

When we inspect the data (`proc print data=a_comp2 (obs=12);run;`) we see an increase for the first observation and the tenth observation that should have really been missing instead.

```
Obs gvkey fyear sale      sale_prev increase 
1   001004 2010 1775.7820  1775.78  1  < should be .
2   001004 2011 2074.4980  2074.50  1 
3   001004 2012 2167.1000  2167.10  1 
4   001004 2013 2035.0000  2035.00  0 
5   001013 2010 1156.6000  1156.60  0 
6   001019 2010 72.4330    72.43    0 
7   001019 2011 71.5200    71.52    0 
8   001019 2012 73.8700    73.87    1 
9   001019 2013 75.8150    75.82    1 
10  001045 2010 22170.0000 22170.00 1 < should be .
11  001045 2011 24022.0000 24022.00 1 
12  001045 2012 24855.0000 24855.00 1  
```
For observation 1, increase is set to 1 because sale_prev isn't set yet. And, the missing value in SAS is represented (visually) as a period, but when used for expressions, it is a large negative number. Since sales is a positive number it will be larger than a large negative number. 

Increase for the observation in row 10 should be missing as well, as 2010 is the first year of data for gvkey '0001014'. It should not have used sales of row 9 to determine if there was an increase. 

The solution is to use `retain` combined with `by`, to process the rows by firm.

## `retain` using `by` <a name="retainby"></a>

When used with a BY statement, the retain statement allows you to retain and accumulate values within groups of observations. The BY statement defines groups based on one or more variables, and the first. and last. indicators are used to reset or finalize values at the beginning or end of each group.

It requires the dataset to be already sorted by the `by` variable.

### Example

```sas
/* sort by gvkey */
proc sort data=a_comp; by gvkey;run;

/* add increase indicator */
data a_comp2 (keep = gvkey fyear sale sale_prev increase);
set a_comp;
/* add by statement */
by gvkey;
/* variable to retain */
retain sale_prev;
/* just like before */
increase = (sale > sale_prev); 
/* guard against initial record for each firm
set increase to missing */
if first.gvkey then increase = .;
/* set retained variable for next observation */
sale_prev = sale; 
run;
```

---


## `output` keyword  <a name="output"></a>

In the SAS DATA step, the **`output`** statement explicitly writes the current observation to the output dataset. Normally, SAS automatically outputs an observation at the end of each iteration of the DATA step, but using the `output` statement allows you to:
- Control **when** an observation is written.
- Write the same observation multiple times.
- Direct output to **specific datasets** in a multi-dataset step.

If no `output` statement is used, SAS will automatically output the observation at the end of the DATA step by default.

```sas
data test;
x = 1; y='a'; output; output; output;
x = 2; y='b'; output; output; output;
run;
proc print;run;
```

This will print the following:
```
Obs x  y 
1   1  a 
2   1  a 
3   1  a 
4   2  b 
5   2  b 
6   2  b 
```

### Using `retain` and `by` with the `output` Statement

When using `retain` to process data by group, you may sometimes want to capture only the last observation of each group. To achieve this, you can use the `.last` indicator to check if it is the last row in the group, and if so, apply the `output` statement to write that observation to the output dataset.

For example, the following will calculate the average sales for each firm:

```sas
data a_comp3 (keep = gvkey avgSale numObs sumSale);
set a_comp;
by gvkey;
retain sumSale numObs;
/* initializing */
if first.gvkey then do;
   sumSale = 0;
   numObs = 0;
end;
/* processing data */
sumSale = sumSale + sale;
numObs = numObs + 1;
/* last record */
if last.gvkey then do;
   avgSale = sumSale / numObs;
   output;
end;
run;
```

The `if`, `then do` - `end` block is conditional code that runs if the if statement evaluates to true.

The 'flow' of the datastep is to first initialize the retained variables. `first.gvkey` will be true for the first record for each firm. Then do the processing (here, adding sales and counting the number of obs). Finally, we test if we came to the last record. If so, we calculate the average and create the record. The `keep` statement will keep the variables we are interested in (gvkey and the aggregate variables).

### 'wide' to 'long' with `output`


Consider the following dataset:

```SAS
data somedata;
  input @01 id        1.
        @03 year2010  4.
		@08 year2011  4.
        @13 year2012  4.
		@18 year2013  4.
	;
datalines;
1 1870 1242 2022 1325
2 9822 3186 1505 8212
3      1221 4321 9120
4 4701 2323 3784
run;
```

The data looks as follows:
```
Obs id year2010 year2011 year2012 year2013 
1   1  1870     1242     2022     1325 
2   2  9822     3186     1505     8212 
3   3  .        1221     4321     9120 
4   4  4701     2323     3784     . 

```
The above data is in 'wide' format (that is, a record has data for multiple years for each firm). To conver this to 'long' format (each record has data for one firm-year):

```SAS
data long (keep = id year value);
set somedata;
value = year2010; year = 2010; output;
value = year2011; year = 2011; output;
value = year2012; year = 2012; output;
value = year2013; year = 2013; output;
run;
```
The 'output' triggers the output of a new record. Each time, a year201x variable is set into 'value' and year is set to the correct value. The relevant columns for the output dataset are 'id', 'year' and 'value'.

The dataset in long format:

```
Obs id value year 
1   1  1870  2010 
2   1  1242  2011 
3   1  2022  2012 
4   1  1325  2013 
5   2  9822  2010 
6   2  3186  2011 
7   2  1505  2012 
8   2  8212  2013 
9   3  .     2010 
10  3  1221  2011 
11  3  4321  2012 
12  3  9120  2013 
13  4  4701  2010 
14  4  2323  2011 
15  4  3784  2012 
16  4  .     2013 
```

---

## Merging Datasets with `merge` <a name="merge"></a>

In the SAS Data Step, the `merge` statement combines multiple datasets by aligning them based on one or more common key variables. Unlike the `set` statement, which stacks datasets vertically, `merge` is used to join datasets side-by-side, effectively adding columns rather than rows. Each dataset must have the same key variable(s), and these variables should be sorted or indexed to ensure correct alignment during the merge process. 

For example:

```sas
data combinedData;
    merge dataset1 dataset2;
    by keyVariable;
run;
```

Here, `dataset1` and `dataset2` are merged by the variable `keyVariable`, so the resulting dataset `combinedData` will have all columns from both input datasets, matched by the specified key. If a key value exists in one dataset but not the other, the unmatched data fields will be set to missing. This approach is especially useful for adding different types of information about the same entities (e.g., adding financial and sales data for a company based on an identifier like `companyID`).

### Merge example

```sas

rsubmit;

	/* rename fyear to fyearq for merge later on */
   data myTable (keep = gvkey fyearq datadate sich roa mtb size sale at ni prcc_f csho);
   set comp.funda;

   /* require fyear to be within 2010-2013 */
   if 2010 <=fyear <= 2013;
   /* require assets, sales, equity and net income to be non-missing */
   if cmiss (of at sale ceq ni) eq 0;
   /* prevent double records */
   if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;

   /* construct some variables */
   roa = ni / at;
   mtb = csho * prcc_f / ceq;
   size = log(csho * prcc_f);
   miss_sich = missing(sich);
   /* for merge with fundq (uses fyearq) */
   fyearq = fyear;
   run;

   /* fundq is not properly sorted  */
   proc sort data=comp.fundq (where=(2010 <= fyearq <= 2013) keep=gvkey fyearq atq ceqq niq) out=myq ; by gvkey fyearq; run;

   /* merge it with comp.fundq */
   data myTable2;
   merge myTable myq;
   by gvkey fyearq;
   run;

   proc download data=myTable2 out=myTable2;run;

endrsubmit;
```

In this example, `myTable` is merged with `comp.fundq` using `merge`, requiring both datasets to be sorted by the same key variables. Since `myTable` uses `fyear` while `comp.fundq` uses `fyearq`, rename `fyear` to `fyearq` on 'myTable' to match. Then, sort `comp.fundq` on `gvkey` and `fyearq` into a new table `myq` with key variables, as direct changes to `comp.fundq` are not possible.


---