# `PROC SQL` 

## Overview SQL  <a name="overview"></a>

SAS supports Structured Query Language (SQL), a powerful tool for querying and managing datasets.

### Key Sections in `PROC SQL`
A typical `PROC SQL` statement has the following main sections:

- **`select`**: Specifies columns or calculations to include in the output dataset.
- **`from`**: Specifies the input dataset(s).
- **`where`**: Filters rows in the input dataset or defines conditions for joining multiple datasets.
- **`having`**: Filters based on output values, such as newly calculated fields.
- **`group by`**: Defines grouping variables for aggregation.
- **`order by`**: Defines the variable(s) to sort by.

---

### Example: Selecting and Filtering Data

```sas
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
proc sql;
  create table a_comp as 
  select gvkey, fyear, datadate, sale, at, floor(sich/100) as sic2
  from comp.funda
  where indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C';
quit;
proc download data=a_comp out=a_comp;run;
endrsubmit;
```
This code creates `a_comp`, selecting specified columns from `comp.funda` and applying conditions using `where`. The 'floor' function rounds the 4-digit SIC divided by 100 down to a 2-digit SIC.


### Executing Multiple SQL Statements in a `PROC SQL` Block

In SAS, you can execute multiple SQL statements within a single `PROC SQL` block. This allows you to create or manipulate multiple tables in a single execution.

```sas
proc sql;
    create table b_test1 as 
        select gvkey, fyear, sale 
        from a_comp;
    
    create table b_test2 as 
        select gvkey, fyear, at 
        from a_comp;
quit;
```

Each `create table` statement operates independently, allowing you to define multiple output tables in one streamlined `PROC SQL` block. This approach is efficient for creating and saving multiple data views in a single procedure.

---

## Using `GROUP BY` <a name="group_by"></a>

Grouping is useful for aggregating data. For example, the following query adds a variable with the highest sales a company had:

```sas
proc sql;
  create table work.dsOut as 
    select gvkey, fyear, sale, max(sale) as highest, count(*) as numObs 
    from a_comp
    group by gvkey; /* proc sql doesn't require sorting */
quit;
```

`Count` is an aggregation function: it counts the number of rows; the '*' means that 'all rows' are counted.

Aggregation functions like `min`, `max`, `median`, `mean`, `std` (standard deviation) are also available.

---

### Example: Inner Join
```sas
rsubmit;
proc sql;
  create table work.b_comp as 
  select a.*, b.fic, b.sic, b.ipodate
  from work.a_comp a, comp.company b
  where a.gvkey = b.gvkey;
quit;
endrsubmit;
```

In this example, all columns from `work.a_comp` are selected (`a.*`), while `b.fic`, `b.sic`, and `b.ipodate` are chosen from `comp.company`. The `where` clause matches records based on `gvkey`. This is an inner join, so only matching `gvkey` values appear in the output.

---



## Self Join  <a name="self"></a>

Self-joins match a table with itself (meaning the 'left' and 'right' side of the join are the same table). This is, useful for calculations like sales growth or retrieving recent years' data.

```sas
proc sql;
  create table b_growth as 
  select a.*, a.sale / b.sale - 1 as sales_growth, b.fyear as prev_fyear
  from a_comp a, a_comp b
  where a.gvkey = b.gvkey
  and a.fyear - 1 = b.fyear; 
quit;
```
This code calculates `sales_growth` by comparing sales between consecutive years.

---

## Left Join <a name="left"></a>

A left join keeps unmatched rows from the left dataset. For example:

```sas
proc sql;
  create table b_growth as 
  select a.*, a.sale / b.sale - 1 as sales_growth, b.fyear as prev_fyear
  from a_comp a left join a_comp b
  on  a.gvkey = b.gvkey
  and a.fyear - 1 = b.fyear; 
quit;
```
This is similar to the previous query, but now records on the 'left' that have no match on the 'right' (meaning, the first year of data) are still included in the output dataset with missing values for 'sales_growth' and 'prev_year'.

---
## Using `HAVING` to Filter Grouped Data <a name="having"></a>

The `HAVING` clause in `PROC SQL` filters the output dataset after grouping is performed, unlike the `WHERE` clause, which filters the input data before aggregation. `HAVING` is typically combined with `GROUP BY` to enable more refined filtering based on grouped or calculated values, making it useful when filtering on aggregate conditions.

#### Example:
This example demonstrates using `HAVING` to filter observations with specific aggregate values. The code groups data by `sic2` and `fyear`, and retrieves the company with the highest sales, given that there are at leat 5 firms in the industry-year.

```sas
proc sql;
    create table myTable4 as 
        select *, 
            median(sale) as sale_median label="Industry median sales" format=comma20.,
            max(sale) as sale_max, 
            min(sale) as sale_min
        from a_comp 
        group by sic2, fyear
        having 
            sale = max(sale)          /* selects observations with the highest sale in each industry-year */
            and count(*) > 5;         /* only includes industries with more than 5 observations */
quit;
```

#### Explanation:
- **`GROUP BY sic2, fyear`**: Aggregates data by industry (`sic2`) and fiscal year (`fyear`).
- **`HAVING sale = max(sale)`**: Filters the output to include only rows with the maximum sale value for each industry-year grouping.
- **`HAVING count(*) > 5`**: Retains only groups where there are more than five observations, useful for analyses that require a minimum sample size in each group. 

> It is possible that multiple firms have the same highest value for 'sale'. 

The `HAVING` clause, when combined with `GROUP BY`, enables more precise filtering based on calculated or aggregate conditions within groups.

---

## Subqueries <a name="subqueries"></a>
`PROC SQL` can nest queries as datasets. For example:

```sas
proc sql;	
  create table myData2 as
    select fyear, count(*) as numFirms, median(mtb) as median_mtb
    from (
      select fyear, (csho * prcc_f / ceq) as mtb 
      from comp.funda
      where SICH = 7370 and fyear > 2000 
      and indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C'
    )
    group by fyear;
quit;
```
This example calculates the median market-to-book ratio (`mtb`) for firms in industry `7370` after 2000, grouping by `fyear`.

---

## Using `IN` and `NOT IN` for Filtering Data <a name="IN"></a>

In SAS `PROC SQL`, the `IN` and `NOT IN` keywords are valuable for filtering data based on specified values or lists. These keywords streamline querying by allowing inclusion or exclusion of specific data points without requiring complex `WHERE` clauses. With `IN`, observations are selected when they match any of the values in a list, while `NOT IN` filters out any observations that match values in the list.

#### Example Using `IN`:
The `IN` keyword selects rows where `fyear` matches specified years (2020 or 2022):

```sas
proc sql;
    create table test3 as 
    select gvkey, fyear, sale
    from a_comp
    where fyear IN (2020, 2022);
quit;
```

#### Using `IN` with a Subquery:
Values in `IN` and `NOT IN` do not need to be explicitly specified and can be dynamically sourced from a query. In the example below, `NOT IN` excludes records from the maximum year in the dataset:

```sas
proc sql;
    create table test3 as 
    select gvkey, fyear, sale
    from a_comp
    where fyear NOT IN ( select max(fyear) from a_comp );
quit;
```

#### Explanation:
- `IN (2020, 2022)`: Filters the dataset to only include records where `fyear` is either 2020 or 2022.
- `NOT IN (select max(fyear)...)`: Dynamically excludes rows for the highest `fyear`, using a subquery to determine the maximum year.


---

## Using `DISTINCT` to Remove Duplicates <a name="distinct"></a>

The `DISTINCT` keyword in `PROC SQL` is useful when generating an output dataset with unique rows, as it eliminates duplicates from the result. This is often applied in queries where each unique combination of specific variable values is needed, instead of all observations.

#### Example:
In the example below, `DISTINCT` is used to return only unique combinations of `sich` and `fyear` from `a_comp`. The `OUTOBS=50` option limits the result to the first 50 unique records:

```sas
proc sql outobs=50;
    create table test3 as
    select distinct sich, fyear
    from a_comp;
quit;
```

#### Explanation:
- **`DISTINCT sich, fyear`**: Keeps only one instance of each `sich`-`fyear` combination in the output.
- **`OUTOBS=50`**: Limits the result to the first 50 unique rows, providing a way to preview or work with a subset of the data.

---

## `LIMIT`, `outobs=` <a name="limit"></a>

`PROC SQL` in SAS does not support the `LIMIT` keyword. Instead, use `outobs=` to limit the number of observations in the output dataset.

```sas
/* distinct (no duplicates) */
proc sql outobs=50; ;
    create table test3 as
    select distinct sich, fyear
    from a_comp;
quit;
```

## Creating Binary (Dummy) Variables in SAS with Expressions <a name="dummy"></a>

In SAS, expressions can be used to create binary (dummy) variables. These variables are useful in statistical modeling, categorization, or setting flags for observations that meet a certain criterion. By evaluating an expression within a `PROC SQL` or `DATA` step, SAS can assign a binary outcome to the new variable, reflecting whether the condition is met.

Here’s a basic example of how expressions can be used to create a dummy variable that categorizes firms based on sales:

```sas
proc sql;
    create table test2 as 
    select a.*, (sale > median(sale)) as large
    from a_comp a
    where missing(sic2) eq 0
    group by sic2, fyear; 
quit;
```

#### Explanation:
- `(sale > median(sale)) as large`: Creates the binary variable `large`, setting it to 1 if `sale` exceeds the median of `sale` (computed within each `sic2` and `fyear` group) and 0 otherwise. The parentheses are not strictly necessary, but help with readability
- `missing(sic2) eq 0`: Filters out records where `sic2` is missing, ensuring only complete data is included.
- `group by sic2, fyear`: Groups records by `sic2` and `fyear` for median calculation. So we compare a firm-year's sales with the median industry mean for that year as opposed to a sample-wide median if we had not used a group by.



## Applying Labels and Formats to Variables <a name="labels"></a>

Labels and formats in SAS help clarify variable meanings and improve data readability. A `LABEL` assigns a descriptive title to a variable, while `FORMAT` specifies how the data should appear, such as commas for large numbers. Labels and formats are especially useful in reporting or when preparing datasets for further analysis.

Here’s how to set labels and formats on a new variable during its creation:

```sas
proc sql;
    create table myTable as 
    select sic2, fyear, 
           median(sale) as sale_median 
               LABEL="Industry median sales" 
               format=comma20. 
    from a_comp 
    group by sic2, fyear;
quit;
```

#### Explanation:
- `median(sale) as sale_median`: Creates a new variable, `sale_median`, to store the median sales.
- `LABEL="Industry median sales"`: Provides a label to clarify that this variable represents the industry median.
- `format=comma20.`: Formats the median sales with commas and allows up to 20 digits for readability.



## Using `CALCULATED` to Reference New Variables <a name="calculated"></a>

In SAS, the `CALCULATED` keyword is used to reference a newly created variable within the same `PROC SQL` step. This feature is helpful when creating new calculations or indicators based on other derived variables. By using `CALCULATED`, it’s possible to avoid repeating expressions and ensure accuracy when working with variables defined earlier in the `SELECT` clause.

Here’s how `CALCULATED` is used to reference a variable that is constructed in the `select` portion of the query:

```sas
proc sql;
    create table myTable3 as 
        select *, 
               median(sale) as sale_median LABEL="Industry median sales" format=comma20.,
               max(sale) as sale_max, 
               min(sale) as sale_min,
               /* Create a binary variable (dummy) set to 1 if firm size exceeds the median size for industry-year */
               (sale > calculated sale_median) as large
        from a_comp 
        group by sic2, fyear;
quit;
```

#### Explanation:
- `median(sale) as sale_median`: Creates `sale_median` as the median sale amount for each industry-year.
- `CALCULATED sale_median`: Refers to the `sale_median` variable without recalculating it.
- `(sale > calculated sale_median) as large`: Creates a binary variable `large`, set to 1 if `sale` exceeds `sale_median`, helping to quickly identify larger-than-median firms within the specified group.

## Dataset Management and Indexing in PROC SQL <a name="indexing"></a>

In SAS, `PROC SQL` provides various capabilities for managing datasets and working with indices, enabling you to streamline data management tasks effectively. Here are some common operations:

### Managing Datasets

- **Deleting Datasets**: Use the `DROP TABLE` statement within `PROC SQL` to delete datasets from your library.
  ```sas
  proc sql;
      drop table myTable1, myTable2;
  quit;
  ```
  This removes the datasets permanently from the library.


### Working with Indices

- **Creating Indexes**: You can create indexes to improve query performance, particularly on large datasets. Using `CREATE INDEX` allows faster data retrieval when using `WHERE` conditions on indexed columns.

  ```sas
  proc sql;
   	create index gvkey_fyear on a_comp(gvkey, fyear);
  quit;
  ```

  Here, an index 'gvkey_fyear' is made for 'gvkey' and 'fyear' for faster data access when these variables are part of filtering conditions.

- **Dropping Indexes**: To remove an index, use the `DROP INDEX` command, specifying the index and the dataset from which it should be removed.

  ```sas
  proc sql;
      drop index gvkey_fyear from a_comp;
  quit;
  ```





