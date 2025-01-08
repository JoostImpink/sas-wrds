# Macros language

The following macro variables are used to read files:

```sas
/* adjust path to your folder */
%let mainFolder = C:\git\sas-wrds\;
%let subFolder4 = &mainFolder\4 - macros;
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


---

## Macro Variables <a name="macro_variables"></a>

In SAS, macro variables are placeholders for text that can be used throughout your code. They allow for flexibility and reusability by dynamically substituting values. You define macro variables using the `%let` statement and use them in your code by referencing them with an ampersand (`&`).

### Defining Macro Variables
You can define a macro variable using `%let`. The syntax is straightforward:

```sas
%let variable_name = value;
```

For example:
```sas
%let firstname = David;
%put The value of firstname is: &firstname;
```

In the above code:
- `%let` defines the macro variable `firstname` with the value `David`.
- `%put` displays the value of the macro variable in the SAS log. 

### Example: Using Macro Variables in Data Step
Macro variables are particularly useful for setting dynamic parameters in your code. For instance:
```sas
%let startYr = 2018;
%let endYr = 2020;

data b_comp (keep=gvkey fyear datadate sic2 sale);
    set a_comp;
    if &startYr <= fyear <= &endYr;
run;
```
Here, `&startYr` and `&endYr` are macro variables representing the range of years. The data step filters `a_comp` for rows where `fyear` falls within the specified range.

### Arithmetic with Macro Variables
You can perform simple arithmetic using the `%eval` function:
```sas
%let two = 1 + 1;
%put Just the macro variable two: &two;  /* Outputs: 1 + 1 */
%put Now with eval: %eval(&two);        /* Outputs: 2 */
```
Without `%eval`, SAS treats the value as text. Use `%eval` to evaluate the expression.

### Single Quotes vs. Double Quotes
Macro variables behave differently inside single and double quotes:
```sas
%put double quotes: "&firstname";
%put single quotes: '&firstname';
```
- Double quotes: Macro variables are resolved.
- Single quotes: Macro variables are not resolved and appear as-is.

### Using Macro Variables in SQL Queries
Macro variables can be integrated into SQL queries for dynamic filtering:
```sas
%let startYr = 2018;
%let endYr = 2020;

proc sql;
    create table b_comp as 
    select fyear, median(size) as size_median
    from a_comp
    where &startYr <= fyear <= &endYr
    group by fyear;
quit;
```
Here, `&startYr` and `&endYr` dynamically define the year range for the SQL query.

### Creating Macro Variables Dynamically
You can create macro variables dynamically from dataset values using the `into` clause in `PROC SQL`:
```sas
proc sql;
    select min(fyear), max(fyear) 
    into :minYr, :maxYr 
    from a_comp;
quit;

%put Start year: &minYr Ending year: &maxYr;
```
This example stores the minimum and maximum values of `fyear` into the macro variables `minYr` and `maxYr`.

### Combining Macro Variables with Text
To concatenate a macro variable with additional text, use a period (`.`) as a delimiter:
```sas
%let variable = roa;

/* Correct usage */
%put &variable._median is what I want;

/* calculate aggregates */
proc means data=a_comp noprint;
  OUTPUT OUT=work.meansout n= mean= median= stddev= /autoname;
  var roa size mtb;
run;

/* Retrieve the variable */
proc sql;
    create table test as 
    select &variable._median 
    from meansout;
quit;
```
Without the period, SAS cannot distinguish where the macro variable ends and the appended text begins.


---

## Macros <a name="macros"></a>

Macros in SAS are similar to functions in other programming languages. They help organize code that performs specific tasks so it can be easily tested and reused. Macros allow you to pass arguments, make your code dynamic, and improve efficiency.

### Basic Macro Definition and Execution

A macro is defined using `%macro` and `%mend`. Here’s a simple example:

```sas
%macro myMacro;
  data myData;
    x = 5;
  run;
%mend;

/* Execute the macro */
%myMacro;
```

In this example:
- `%macro` begins the macro definition.
- `%mend` marks the end of the macro.
- `%myMacro` executes the macro, generating the specified code.

### Passing Arguments to a Macro

Macros can accept arguments to make them more dynamic. For instance:

```sas
%macro mySecond(val); 
  data myData;
    x = &val;  
  run;
%mend;

/* Call the macro with an argument */
%mySecond(10);
```

This macro generates and runs the following code:
```sas
data myData;
  x = 10;  
run;
```

### Using Multiple Arguments

Macros can accept multiple arguments:

```sas
%macro myThird(dsout, val); 
  data &dsout;
    x = &val;  
  run;
%mend;

/* Example call */
%myThird(myData2, 5);
```

The generated code:
```sas
data myData2;
  x = 5;  
run;
```

#### Explicit Argument Names
You can define macros with named arguments, making it clearer and allowing arguments to be passed in any order:

```sas
%macro myFourth(dsout=, val=); 
  data &dsout;
    x = &val;  
  run;
%mend;

/* Specify arguments explicitly */
%myFourth(dsout=myData2, val=5);
/* Order does not matter */
%myFourth(val=5, dsout=myData2);
```

### Default Values for Arguments

You can assign default values to macro arguments. If the argument is not provided during execution, the default value will be used:

```sas
%macro myFifth(dsout=, val=7); 
  data &dsout;
    x = &val;  
  run;
%mend;

/* Call without passing val; val defaults to 7 */
%myFifth(dsout=myData2);
```

The generated code:
```sas
data myData2;
  x = 7;  
run;
```

### Accessing Macro Variables Defined Outside the Macro

Macros can access variables defined outside them, but this is not recommended as it reduces code modularity and clarity:

```sas
%let something = 1;

%macro mySixth(dsout=, val=7); 
  data &dsout;
    x = &val;  
    y = &something;  /* Access external macro variable */
  run;
%mend;

%mySixth(dsout=myData2, val=5);
```

The generated code:
```sas
data myData2;
  x = 5;
  y = 1;
run;
```

### Conditional Logic in Macros: `%if`, `%then`, `%else`

You can use conditional logic inside macros to generate code dynamically based on arguments:

```sas
%macro myMacro(happy=);
data happy;
  %if &happy = yes %then %do;
    %put Today is a happy day;  
    message = 'yay!';
  %end;
  %else %do;
    %put Not so happy;
    message = 'bleh..';
  %end;
run;
%mend;

/* Call the macro with a condition */
%myMacro(happy=yes);
```

Generated code:
```sas
data happy;
  %put Today is a happy day;  
  message = 'yay!';
run;
```

If the condition changes:
```sas
%myMacro(happy=no);
```

Generated code:
```sas
data happy;
  %put Not so happy;  
  message = 'bleh..';
run;
```

### Practical Use: Macros for Dynamic Code Generation

Macros can simplify repetitive tasks. For example, generating datasets for different conditions:
```sas
%macro createDataset(year);
  data sales_&year;
    set a_comp;
    if fyear = &year;
  run;
%mend;

/* Create datasets for 2020 and 2021 */
%createDataset(2020);
%createDataset(2021);
```

This will dynamically create datasets `sales_2020` and `sales_2021`.


---

## Macro Debugging <a name="macro_debugging"></a>

Macros work by performing text substitution to generate SAS code, which is then executed. However, debugging macros can be challenging due to the dynamic nature of their execution, especially when:
- Macros include conditional logic (`%if %then`).
- Macros are nested (one macro invokes another).

To troubleshoot issues, it’s helpful to examine the code generated by the macro. SAS provides options to write this generated code to disk for review.

### Writing Generated Code to Disk

You can capture the code generated by macros using the `filename` statement and the `options mprint mfile` statement. Here's how:

#### Steps to Enable Macro Debugging:
1. **Specify a file** to save the generated code using the `filename` statement.
2. **Enable debugging options**:
   - `mprint`: Displays the generated macro code in the log.
   - `mfile`: Redirects the generated code to the specified file.

#### Examples for Different Environments:

- **UF Apps (or similar shared environment):**
    ```sas
    filename mprint 'M:\tempSAScode.txt';
    options mprint mfile;
    ```

- **SAS Studio (cloud or server-based):**
    ```sas
    filename mprint '~/tempSAScode.txt';
    options mprint mfile;
    ```

- **PC (local environment):**
    ```sas
    filename mprint 'E:\temp\today\tempSAScode.txt';
    options mprint mfile;
    ```

### Example Use Case

Suppose you have the following macro:
```sas
%macro exampleMacro(year);
  data sales_&year;
    set a_comp;
    if fyear = &year;
  run;
%mend;

%exampleMacro(2020);
```

If the macro does not behave as expected, enable debugging as shown:
```sas
filename mprint 'E:\temp\today\macroCode.txt'; /* Define the output file */
options mprint mfile;

%exampleMacro(2020); /* Run the macro */
```

The generated SAS code is saved to the file `E:\temp\today\macroCode.txt` and can also be viewed in the log.

### Disabling Debugging

After debugging, you should turn off the `mfile` option to stop redirecting code to the file:
```sas
options nomfile;
```

This ensures that your subsequent SAS code runs without unnecessary file writes.




---

## `%include` to Read and Execute a File <a name="include"></a>

The `%include` statement is used to read and execute SAS code from an external file. This file can contain any SAS code, including macro definitions or data step code.

### Basic Usage

Assume you have a file, `hello.sas` in the folder 'macro files', containing the following code:
```sas
/* hello.sas */
%put hello how are you?; 

data test2;
x = 5;
run;
```

To execute this file in your SAS program:
```sas
%include "&subFolder4\macro files\hello.sas";
```

This command reads the code from `hello.sas` and runs it as if it were written directly in your program.

### Including a File with Macro Definitions

Consider a file, `hello_macro.sas` in the folder 'macro files', with a macro definition:
```sas
/* hello_macro.sas */
%macro hellothere(drink);
  %put Isn't it time for &drink.? ;
%mend;
```

To include and define this macro:
```sas
%include "&subFolder4\macro files\hello_macro.sas";
```

You can now invoke the macro in your program:
```sas
%hellothere(beer);
```

### Including Multiple Files from a Folder

To include all `.sas` files in a folder, you can use a wildcard:
```sas
filename mymacros "E:\temp\project";
%include mymacros('*.sas');
```

### Example: Adding Fama-French 48 Industry Classification

Instead of reading from disk, you can include SAS code directly from a URL:
```sas
/* Read and define macro */
filename m1 url 'https://raw.githubusercontent.com/JoostImpink/fama-french-industry/master/SAS/Siccodes48.sas';
%include m1;

/* Invoke the macro */
%ff48(dsin=a_comp, dsout=b_comp_ff48);
```

---

## The `runquit` Macro <a name="runquit"></a>

The `runquit` macro halts SAS execution if an error occurs. It replaces the `run;` or `quit;` statement in your code.

### Macro Definition
```sas
%macro runquit;
; run; quit;
%if &syserr. ne 0 %then %do;
  %abort cancel;
%end;
%mend runquit;
```

### Usage Example

Without the `runquit` macro, SAS continues execution after an error:
```sas
proc go_gators!; quit; /* This will throw an error but won't stop execution */
/* Executes despite the earlier error */
data myData2;
x = 1;
run; 
```

With `runquit`, SAS halts on error:
```sas
proc go_gators!; %runquit;
/* No longer executes this data step */
data myData2;
x = 1;
run; 
```

In general, replace all `run;` or `quit;` statements with `%runquit;` to use this macro:
```sas
data myData2;
set myData;
year = year(date);
%runquit;
```

---

## `syslput` for Remote Macro Variables <a name="syslput"></a>

`syslput` allows you to pass macro variables from a local session to a remote session. This is particularly useful when working with environments like WRDS (Wharton Research Data Services).

### Defining a Remote Connection
```sas
rsubmit;endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;
options comamid = TCP remote=WRDS;
signon username=_prompt_;
```

### Passing Variables with `%syslput`
Define a macro variable in the local session:
```sas
%let myVar = HelloWorld;
%syslput myVar=&myVar; /* Send myVar to the remote session */
```

Use the variable in the remote session:
```sas
rsubmit;
  %put Remote session: &myVar;
endrsubmit;
```

This ensures that macro variables created locally are accessible remotely.

---

## Loops <a name="loops"></a>

SAS provides several mechanisms for implementing loops. Loops can be within a **DATA step**, see file '2_loops_conditional_logic' or using **macro code**, which we will discuss here.

### **Macro Loops (Macros)**
Loops in SAS macros are used to generate repetitive code dynamically. Macro loops are often used to run the same code across multiple datasets, variables, or values.

#### a. **%DO Loop (Macro)**
The `%DO` loop in macro code works similarly to the iterative `DO` loop in a DATA step. It is typically used inside a macro definition to execute repetitive code across different values.

```sas
%MACRO example;
    %DO i = 1 %TO 5;
        %PUT The value of i is &i;
    %END;
%MEND;

%example;
```
- `%DO i = 1 %TO 5;` runs the block of code from `i = 1` to `i = 5`.
- The `%PUT` statement writes messages to the log.

#### b. **%DO UNTIL Loop (Macro)**

Executes the macro code until a specified condition becomes **true**.

```sas
%MACRO loop_until;
    %LET x = 0;
    %DO %UNTIL (&x >= 50);
        %LET x = %EVAL(&x + 5);
        %PUT The value of x is &x;
    %END;
%MEND;

%loop_until;
```
- This macro runs until `x` reaches 50 or greater.
- `%EVAL` is used to evaluate arithmetic expressions within macros.

#### c. **%DO WHILE Loop (Macro)**
Executes the macro code **while** a specified condition remains **true**.

```sas
%MACRO loop_while;
    %LET x = 1;
    %DO %WHILE (&x < 20);
        %LET x = %EVAL(&x * 2);
        %PUT The value of x is &x;
    %END;
%MEND;

%loop_while;
```
- This macro continues running as long as `x` is less than 20.

