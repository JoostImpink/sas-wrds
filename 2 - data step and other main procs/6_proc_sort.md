# `PROC SORT` in SAS

## Overview of `PROC SORT` <a name="sort"></a>

`PROC SORT` is the primary SAS procedure for organizing dataset observations by one or more variables. This is essential for many subsequent procedures, such as the data step, `PROC MEANS`, `PROC REG`, and any processes requiring sorted data for `BY` group processing. `PROC SORT` can arrange data in ascending or descending order, remove duplicates, and create sorted output datasets.

### Syntax

```sas
proc sort data=dataset_name out=output_dataset;
    by <descending> variable1 <descending> variable2 ...;
run;
```

- **`data`**: Specifies the input dataset.
- **`out`**: Specifies the output dataset (optional; if omitted, the input dataset is overwritten).
- **`by`**: Specifies the sorting variable(s).
- **`descending`**: Sorts specified variables in descending order.

In ascending order, missing values appear first; in descending, they appear last.

#### Example

```sas
proc sort data=a_comp; by sich fyear; run;
```

---

## Removing Duplicates: `NODUPKEY` and `NODUPREC` <a name="nodupkey"></a>

`PROC SORT` can remove duplicate observations using `NODUPKEY` and `NODUPREC`.

### Using `NODUPKEY`
`NODUPKEY` eliminates duplicates based on `BY` variables. For instance, after sorting by `gvkey` and `fiscal_year`, adding `NODUPKEY` keeps only the first observation for each key.

#### Example
In audit fee datasets, researchers often keep the highest audit fee for each firm-year:

```sas
rsubmit;
data auditfee (keep=company_fkey fiscal_year AUDIT_FEES);
    set audit.feed03_audit_fees;
run;

/* Sort by company and year, keeping highest audit fee first */
proc sort data=auditfee; 
    by COMPANY_FKEY fiscal_year descending AUDIT_FEES; 
run;

/* Remove duplicates, keeping first (highest fee) observation */
proc sort data=auditfee nodupkey dupout=dropped; 
    by COMPANY_FKEY fiscal_year; 
run;

endrsubmit;
```

- **First Sort**: Orders by `COMPANY_FKEY`, `fiscal_year`, and highest `AUDIT_FEES`.
- **Second Sort**: Keeps only the top fee per firm-year.
- **`dupout=`**: Specifies the dataset to capture dropped duplicates.

### Using `NODUPREC`
`NODUPREC` removes rows that are complete duplicates across all variables, not just `BY` variables.

---

## Handling Large Datasets with `FORCE` <a name="force"></a>

For large datasets, memory constraints may hinder sorting. The `FORCE` option compels SAS to sort regardless, though disk swapping may occur, slowing performance.

```sas
proc sort data=large_data force;
    by var1 var2;
run;
```

### Performance Tips
- **Sort Essential Variables Only**: Use `KEEP` or `DROP` to limit sorted variables.
- **Subset Data**: Use a filtered dataset for sorting if feasible.
- **Indexes**: Use indexing for repeated access in specific orders.
- **`NODUPKEY` and `NODUPREC`**: Efficient but resource-intensive, especially for large datasets.

---

## No support for `WHERE` clause <a name="where"></a>

`PROC SORT` does **not** support `WHERE` clauses for in-procedure filtering:

```sas
/* Does NOT work */
proc sort data=auditfee (where=(fiscal_year >= 2000)); 
    by COMPANY_FKEY fiscal_year; 
run;
```

To apply filters, first create a subset, then perform the sort.






