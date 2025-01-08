# Working with dates

## Working with Dates in SAS <a name="dates"></a>

SAS has robust support for working with dates, including functions to handle date creation, manipulation, formatting, and calculations. SAS stores dates as **numeric values**, where the number represents the number of days since January 1, 1960 (with negative values for dates before this). Understanding how SAS handles dates helps you effectively manipulate them for analysis and reporting.

### How SAS Stores Dates

A SAS date is represented as the number of days from January 1, 1960. For example:
- **0** corresponds to **01JAN1960**.
- **1** corresponds to **02JAN1960**.
- **-1** corresponds to **31DEC1959**.

---

### Creating Dates in SAS

There are several ways to create and manipulate dates in SAS:

#### 1. Date Literals
You can create dates using date literals by placing a date in quotes followed by the letter `d`:

```sas
date1 = '31DEC2023'd;
date2 = '01JAN2024'd;
```

#### 2. Using `MDY()` Function
The `MDY()` function creates a SAS date from month, day, and year values:

```sas
date1 = mdy(12, 31, 2023); /* Creates 31DEC2023 */
```

---

## Formatting Dates <a name="formatdates"></a>

SAS has a wide variety of **date formats** to control how dates are displayed. Common formats include:

- **DATE9.**: Displays the date in `DDMMMYYYY` format (e.g., `31DEC2023`).
- **MMDDYY10.**: Displays the date as `MM/DD/YYYY` (e.g., `12/31/2023`).
- **WEEKDATE.**: Displays the day of the week with the full date (e.g., `Sunday, December 31, 2023`).

Example of applying a date format:

```sas
data example;
    date1 = '31DEC2023'd;
    format date1 date9.; /* Format date as DDMMMYYYY */
run;

proc print data=example;
run;
```

---

### Converting Character Strings to Dates

Use the `INPUT` function along with a date **informat** to convert a character string into a SAS date. Informats tell SAS how to interpret the raw data.

```sas
data example;
    char_date = '12/31/2023';
    date1 = input(char_date, mmddyy10.); /* Convert to SAS date */
    format date1 date9.; /* Format date for display */
run;

proc print data=example;
run;
```

Here, `mmddyy10.` tells SAS that the input string is in `MM/DD/YYYY` format and converts it to a SAS date.

---

## Date Calculations (INTCK, INTNX) <a name="intck_intnx"></a>

Since SAS dates are stored as the number of days since January 1, 1960, you can perform arithmetic operations on them easily.

#### 1. Adding or Subtracting Days

```sas
data example;
    start_date = '01JAN2024'd;
    new_date = start_date + 10; /* Adds 10 days */
    format start_date new_date date9.;
run;
```

In this example, `new_date` will be `11JAN2024`.

#### 2. Calculating the Difference Between Dates

You can subtract one SAS date from another to calculate the number of days between them:

```sas
data example;
    start_date = '01JAN2024'd;
    end_date = '15JAN2024'd;
    days_diff = end_date - start_date; /* Calculate the number of days between dates */
run;
```

The result will be `14` days.

#### 3. Using Interval Functions

SAS provides interval functions to calculate differences in months, years, weeks, etc., between dates.

- **`INTCK()`**: Counts the number of intervals (days, months, years) between two dates.
  
  Example: Count the number of months between two dates:
  ```sas
  months_diff = intck('month', '01JAN2024'd, '01JUL2024'd); /* Result: 6 months */
  ```

- **`INTNX()`**: Advances a date by a specified number of intervals (days, months, years).
  
  Example: Add 6 months to a date:
  ```sas
  new_date = intnx('month', '01JAN2024'd, 6); /* Adds 6 months */
  format new_date date9.;
  ```

---

### Example - Return window 3 months shifted

Older accounting papers often measure stock return for the fiscal year over a 12 month period that starts on the fourth month of the fiscal year. For example, if the fiscal year is January 1, 2020 - December 31, 2020, then the return window would by April 1, 2020 - March 31, 2021.

Assuming you have a dataset with gvkey, fyear and datadate, the following code uses `intnx` to calculate the beginning date ('boy') and ending date ('eoy') of the return window.

```sas
data b_comp;
set a_comp;
boy = intnx('month', datadate, -8, 'B');
eoy = intnx('month', datadate, +3, 'E');
format boy eoy date9.;
run;
```

## Extracting Date Components (YEAR, MONTH, DATE) <a name="year_month_date"></a>

You can extract specific components (like year, month, or day) from a SAS date using functions like:

- **`YEAR()`**: Extracts the year.
- **`MONTH()`**: Extracts the month.
- **`DAY()`**: Extracts the day.

```sas
data example;
    date1 = '31DEC2023'd;
    year = year(date1);
    month = month(date1);
    day = day(date1);
run;

proc print data=example;
run;
```

---

### Working with Time and DateTime Values

In addition to dates, SAS handles **time** and **datetime** values:
- **Time values**: Stored as the number of seconds since midnight.
- **Datetime values**: Stored as the number of seconds since midnight, January 1, 1960.

To create datetime values, use:

```sas
datetime_value = '31DEC2023:23:59:59'dt;
```

Formats for datetime include:
- **DATETIME18.**: Displays both date and time (e.g., `31DEC2023:23:59:59`).
  
