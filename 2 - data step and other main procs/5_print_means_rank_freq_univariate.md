# Proc print, means, rank, standard, freq, univariate

## **`PROC PRINT`** <a name="print"></a>

**Purpose**:  
`PROC PRINT` is used to display the contents of a SAS dataset. It prints the values of variables in the dataset, making it a useful tool for examining data in its raw form before performing any analyses.

#### Syntax:
```sas
proc print data=dataset_name;
run;
```

#### Key Options:
- **`VAR`**: Specifies which variables to include in the output.
- **`WHERE`**: Filters the data to display only rows meeting specific criteria.
- **`OBS=`**: Limits the number of rows printed.
- **`NOOBS`**: Suppresses the row number column (Observation column).
- **`LABEL`**: Prints labels instead of variable names.

#### Example:
```sas
proc print data=sashelp.class(obs=5 noobs);
    var name age height weight;
    where age > 12;
run;
```
This prints the first 5 observations from the `sashelp.class` dataset where the age is greater than 12, without showing row numbers.

---

## **`PROC MEANS`** <a name="means"></a>

**Purpose**:  
`PROC MEANS` calculates descriptive statistics such as the mean, median, standard deviation, minimum, and maximum for numeric variables in a dataset. It’s commonly used for summarizing continuous data.

#### Syntax:
```sas
proc means data=dataset_name <statistic-options>;
run;
```

#### Common supported statistics:

- Keyword	Description
- N Counting
- SUM Sum
- MIN	Minimum
- MEAN	Mean
- MEDIAN	Median
- MAX	Maximum
- STD	Standard deviation
- QRANGE	Interquartile range
- VAR	Variance
- SKEW	Skew

In addition, there are several percentiles: P1, P5, P10, P25, P50 (=Median), P75, P90, P95 and P99.

Example:

```SAS
/* summary statistics for full sample */
proc means data=a_comp n mean  median stddev;
  OUTPUT OUT=work.meansout n= mean= median= stddev= /autoname;
  var roa size mtb;
run;
```

The above example computes the count, mean, median and standard deviation for var1, var2, and var3, and will print these, as well as generate a dataset (`output out=`).


#### Default Statistics:
By default, `PROC MEANS` provides:
- N (number of observations)
- Mean
- Standard Deviation (Std Dev)
- Minimum (Min)
- Maximum (Max)

#### Key Options:
- **`VAR`**: Specifies which numeric variables to calculate statistics for.
- **`CLASS`**: Produces statistics for each level of a categorical variable.
- **`BY`**: Provides statistics separately for each level of the BY variable.
- **`MAXDEC=`**: Limits the number of decimal places for results.
- **`OUTPUT`**: Creates a new dataset with the summary statistics.


### Suppressing output to screen


By default, proc means will print the statistics to the screen. To supress this, add the 'noprint' keyword (`proc means data=work.myData noprint`). 

### Autoname

The autoname keyword will automatically create variable names for the different statistics, by concatenating the variable names with the statistic (in the example, var1_N, var1_Mean, var1_Median, var1_Stddev, similarly for var2). The output dataset will also hold a frequency count (_FREQ_). The difference between _N and _FREQ_ is that missings are included in _FREQ_, but not counted towards _N_.


### By

Proc means supports 'by', which means that statistics can be computed by group (for example, by firm, industry, year, etc). Example:

```SAS
proc sort data=a_comp; by fyear; run;
/* as above, but repeated by a group (requires sorting on that variable) */
proc means data=a_comp n mean median stddev;
  OUTPUT OUT=work.meansout n= mean= median= stddev= /autoname;
  var roa size mtb;
  by fyear;
run;
```

When 'by' is used, the output dataset will have one row for each group. A column is added that holds the variable used to group by (in the example 'groupvar').


---

## **`PROC RANK`**  <a name="rank"></a>

**Purpose**:  
`PROC RANK` ranks numeric variables in a dataset. It is often used to categorize data into quantiles (e.g., quartiles, deciles) or to assign ranks to continuous variables.

#### Syntax:
```sas
proc rank data=dataset_name out=output_dataset <options>;
    var variable_name;
    ranks rank_variable_name;
run;
```

#### Key Options:
- **`GROUPS=`**: Specifies the number of quantile groups to create (e.g., quartiles, deciles).
- **`TIES=`**: Specifies how to handle ties (default is to give tied values the average rank).
- **`DESCENDING`**: Assigns higher ranks to higher values.

#### Example:
```sas
proc rank data=a_comp out=ranked_data groups=10;
    var size;
    ranks size_d;
run;
```
This ranks the `size` variable into 10 groups (deciles), creating a new variable `size_d` in the output dataset.


`Proc rank` also supports the `by` statement, so you can create buckets within partitions (say, deciles by year or by industry).

---




## `PROC STANDARD` in SAS  <a name="standard"></a>

**`PROC STANDARD`** is used in SAS to standardize numeric variables by transforming their values into a common scale, typically to have a specified mean and standard deviation. The most common use of this procedure is to standardize data to have a mean of 0 and a standard deviation of 1, which is useful in statistical analyses, such as regression or clustering, where variables on different scales can lead to biased results.

The procedure allows for both **standardization** and **replacement of missing values** with a user-specified value. 

---

### Key Uses of `PROC STANDARD`:
1. **Standardizing Variables**: Convert variables to have a specific mean and standard deviation.
2. **Handling Missing Data**: Replace missing values with the mean or another specified value.
3. **Normalization**: Rescale variables so that they are on the same scale, typically used to normalize data before applying statistical models.

---

### Syntax:
```sas
proc standard data=input_data out=output_data mean=desired_mean std=desired_std replace;
   var variable_list;
run;
```

### Key Options:
- **`data`**: Specifies the input dataset.
- **`out`**: Specifies the output dataset where the standardized variables are saved.
- **`mean=`**: The desired mean for standardization (default is 0).
- **`std=`**: The desired standard deviation for standardization (default is 1).
- **`replace`**: Replaces missing values with the specified mean (or the mean of the data if no mean is specified).
- **`var`**: The list of numeric variables to standardize.

---

### Example: Standardizing Variables to a Mean of 0 and Standard Deviation of 1
In this example, we standardize the `income` and `expenses` variables to have a mean of 0 and a standard deviation of 1.

```sas
proc standard data=a_comp out=b_comp mean=0 std=1;
   var roa size mtb;
run;
```


### Additional Notes:

- **Handling missing values**: By default, `PROC STANDARD` does not change missing values unless the `replace` option is used. When `replace` is specified, missing values are replaced with the overall mean of the variable (or a user-specified value).
  
- **Compatibility with other procedures**: After standardizing your data with `PROC STANDARD`, it is common to feed the resulting dataset into other procedures like `PROC REG` (for regression), `PROC CLUSTER` (for clustering), or `PROC GLM` (for general linear models).

---


## **`PROC FREQ`**  <a name="freq"></a>

**Purpose**:  
`PROC FREQ` computes frequency counts for categorical variables. It produces frequency tables, which show the distribution of a variable’s values and can also compute percentages, cumulative frequencies, and chi-square tests for associations between variables.

#### Syntax:
```sas
proc freq data=dataset_name;
    tables variable1 * variable2 / options;
run;
```

#### Key Options:
- **`TABLES`**: Specifies the variables for which frequency counts are generated.
    - Can also create cross-tabulations (e.g., `var1*var2`).
- **`NOPRINT`**: Suppresses the display of the frequency table.
- **`CHISQ`**: Requests a chi-square test of association.
- **`NOROW` / `NOCOL` / `NOCUM`**: Suppresses the row, column, and cumulative percentages, respectively.

#### Example:
```sas
proc freq data=sashelp.class;
    tables age / nocum nopercent;
run;
```
This produces a frequency table of the `age` variable without cumulative frequencies or percentages.

#### Example of a Two-Way Table:
```sas
proc freq data=sashelp.class;
    tables sex * age / chisq;
run;
```
This produces a cross-tabulation of `sex` by `age`, and it performs a chi-square test for independence between the two variables.

---

## **`PROC UNIVARIATE`**  <a name="univariate"></a>

**Purpose**:  
`PROC UNIVARIATE` provides detailed descriptive statistics for a single variable, including summary statistics, percentiles, extreme values, normality tests, and visualizations like histograms and box plots. It’s more comprehensive than `PROC MEANS`.

#### Syntax:
```sas
proc univariate data=a_comp;
    var size;
run;
```

#### Key Options:
- **`VAR`**: Specifies the variable(s) to analyze.
- **`PLOT`**: Requests visualizations such as histograms or box plots (in older versions of SAS).
- **`CDF`**: Computes the cumulative distribution function.
- **`NORMAL`**: Performs tests for normality (e.g., Shapiro-Wilk, Kolmogorov-Smirnov tests).

#### Example:
```sas
proc univariate data=sashelp.class;
    var height;
    histogram height / normal;
    inset mean std / format=5.2;
run;
```
This produces descriptive statistics for `height`, a histogram with a normal curve, and inserts the mean and standard deviation into the plot.

#### Output from `PROC UNIVARIATE` Includes:
- Basic statistics: mean, median, mode, standard deviation.
- Percentiles (e.g., 5th, 25th, 50th, 75th, 95th).
- Extreme values: the lowest and highest values in the dataset.
- Tests for normality.

---

### Comparison of Procedures:

| **Procedure**     | **Purpose**                                      | **Key Use Cases**                                      |
|-------------------|--------------------------------------------------|--------------------------------------------------------|
| `PROC PRINT`      | Prints raw data                                  | View raw dataset, examine specific variables            |
| `PROC MEANS`      | Calculates summary statistics for numeric data   | Get averages, min/max, standard deviations, etc.        |
| `PROC RANK`       | Assigns ranks to numeric variables               | Create quantiles or rank values                         |
| `PROC FREQ`       | Generates frequency counts for categorical data  | Count values, create cross-tabulations, chi-square tests|
| `PROC UNIVARIATE` | Provides detailed descriptive statistics         | Analyze distribution, assess normality, visualize data  |

