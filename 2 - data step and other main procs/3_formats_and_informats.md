# Formats and informats, PUT and INPUT

## Formats and Informats in SAS  <a name="formats"></a>

In SAS, **formats** and **informats** are used to control how data is displayed and how raw data is read into a dataset, respectively.

- **Formats**: These define how SAS values are presented or displayed in reports, outputs, or when printing data. Formats do not change the underlying value of the data but rather affect its appearance.
  
- **Informats**: These are used to instruct SAS on how to read and interpret raw data when importing or reading from an external source (like a text file). Informats help SAS understand the structure of input data.

### Formats Example:

Let’s say you have a numeric variable, but you want it to be displayed as currency. You can apply a **format** to change how it looks.

```sas
data example_format;
    amount = 12345.678;
    format amount dollar12.2; /* Display amount as currency with 2 decimal places */
run;

proc print data=example_format;
run;
```

In this example, `dollar12.2` is a format that tells SAS to display `amount` as currency with two decimal places. The `12` refers to the total field width (including the dollar sign, commas, and decimal places).

**Output:**
```
$12,345.68
```

Other common formats include:
- **comma**: Adds commas to large numbers (`comma10.` turns `1000000` into `1,000,000`).
- **date**: Displays dates in different formats (`date9.` formats a date as `01JAN2024`).
  
### Informats Example:

When reading raw data, you may need to use an **informat** to help SAS understand how to interpret the input. For instance, when reading a date as a string, you can apply a date informat so that SAS knows it's a date.

```sas
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
```

In this example, `mmddyy10.` is an informat that tells SAS how to interpret the string `12/31/2023` as a date. The `input()` function reads the raw string and converts it into a SAS date value, which is then formatted as `01JAN2024` for display.

> There are many formats available. See for example the documentation on formats for dates: https://documentation.sas.com/doc/en/vdmmlcdc/8.1/ds2pg/p0bz5detpfj01qn1kz2in7xymkdl.htm

## Defining your own formats - example <a name="formatExample"></a>

### Example data 

```sas
data test;
x = 16;
y = .;
x2 = 150;
run;
```

#### Defining the format `mySizeFormat`

```
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
```

```sas
data test2;
set test;
/* apply format to variables x and y, note the period after the format name */
format x y x2 mySizeFormat.;
run;
```

Even though the variable appears to be text, it is still a number.
```
data test3;
set test2;
z = x+1;
run;
```

## `PUT` and `INPUT` Functions in SAS <a name="putinput"></a>

The `PUT` and `INPUT` functions in SAS are essential tools for converting data between different data types, such as converting character variables to numeric and vice-versa, or for handling date formats. Here's an introduction and examples of how to use these functions for various conversions.

### The `PUT` Function

The `PUT` function is used to **convert a numeric variable or date into a character string**. It allows you to apply a format to a numeric value, turning it into a formatted text representation.

#### Syntax:
```sas
character_variable = PUT(numeric_variable, format.);
```

#### Example 1: Convert a Number to a Character String

```sas
data example_put;
    num_value = 12345.678;
    char_value = PUT(num_value, dollar12.2); /* Convert number to formatted character */
run;

proc print data=example_put;
run;
```

In this example:
- `PUT(num_value, dollar12.2)` converts the numeric value `12345.678` to the string `$12,345.68`, stored in `char_value`.

#### Example 2: Convert a Date to a Character String

```sas
data example_put_date;
    date_value = '31DEC2023'd;  /* SAS date literal */
    char_date = PUT(date_value, date9.); /* Convert date to character format */
run;

proc print data=example_put_date;
run;
```

In this case:
- `PUT(date_value, date9.)` converts the SAS date `31DEC2023` to the character string `"31DEC2023"`.

---

### The `INPUT` Function

The `INPUT` function is used to **convert a character string to a numeric or date value**. It allows SAS to read a character value using a specified informat, converting it into a number or a date that SAS can process.

#### Syntax:
```sas
numeric_variable = INPUT(character_variable, informat.);
```

#### Example 1: Convert a Character String to a Numeric Value

```sas
data example_input;
    char_num = '12345.67';
    num_value = INPUT(char_num, 8.); /* Convert character to numeric */
run;

proc print data=example_input;
run;
```

In this example:
- `INPUT(char_num, 8.)` converts the character string `'12345.67'` into the numeric value `12345.67`.

#### Example 2: Convert a Character String to a Date

```sas
data example_input_date;
    char_date = '12/31/2023';
    date_value = INPUT(char_date, mmddyy10.); /* Convert character to SAS date */
    format date_value date9.; /* Apply date format for display */
run;

proc print data=example_input_date;
run;
```

In this case:
- `INPUT(char_date, mmddyy10.)` converts the character string `'12/31/2023'` into the SAS date `31DEC2023`.
- The `date9.` format is applied to display the date in a readable format.

---

## Convert text to number using multiplication <a name="convert"></a>

It is also possible to 'force' text into numerical format. You can do this by multiplying the text by 1.

### Example

In Compustat, gvkey is a string holding a number. We can create a new variable by multiplying it by 1. 

```sas
data test;
set a_comp;
gvkey_num = 1 * gvkey;
run;
```

