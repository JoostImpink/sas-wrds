# Regressions

In SAS, `PROC REG` and `PROC SURVEYREG` can be used for linear regression, but they are tailored for different types of data and purposes. 

**`PROC REG`**: Designed for standard linear regression analysis on data that is **independently and identically distributed (IID)**. It assumes that observations are uncorrelated and drawn from a single population without complex survey design features.

**`PROC SURVEYREG`**: Tailored for survey data and complex sampling designs, like **stratified, clustered, or weighted samples**. It accounts for these structures in its regression models, making it suitable for analyses where data has non-random sampling or multistage selection methods.

> The `CLUSTER` option in `PROC SURVEYREG` allows you to specify one or more variables that define clustering, such as year and firm. However, this implementation differs from the two-way clustering commonly applied in econometrics. For robust two-way clustering, tools like the `cluster2` package for Stata, developed by Petersen, are more appropriate. For details, see the [Stata Two-Way Clustering by Petersen](https://www.kellogg.northwestern.edu/faculty/petersen/htm/papers/se/se_programming.htm).

**`PROC GLM`**: Provides a general framework for **linear models** that can handle both continuous and categorical (class) variables, making it versatile for analyzing a variety of designs, including ANOVA, ANCOVA, and regression. It is suited for situations where the data is IID and can accommodate unbalanced designs, fixed-effects models, and interaction effects across different levels of categorical factors. However, it is not designed to handle complex survey features like stratification or clustering.

When you need to do a standard OLS regression you can use either one. To do a 'robust regression', `PROC SURVEYREG` is a better option.

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
## OLS regression using `PROC REG` <a name="ols_reg"></a>

The following code will run an OLS regression for the sample dataset, as well as a winsorized version of that dataset:

```sas
proc reg data=a_comp;   
  model roa = size mtb;  
quit;

/* Winsorize macro */
filename m3 url 'https://gist.githubusercontent.com/JoostImpink/497d4852c49d26f164f5/raw/11efba42a13f24f67b5f037e884f4960560a2166/winsorize.sas';
%include m3;

/*	Invoke winsorize */
%winsor(dsetin=a_comp, byvar=fyear, dsetout=a_comp_wins, vars=roa size mtb, type=winsor, pctl=1 99);

proc reg data=a_comp_wins;   
  model roa = size mtb;  
quit;
```

## Capturing Coefficients, R-Squared, and Degrees of Freedom <a name="reg_capture"></a>

The `OUTEST=` option in `PROC REG` allows you to save the estimated coefficients into a new dataset. By adding the `EDF` keyword, you can also include metrics like the R-squared value and degrees of freedom, which are essential for evaluating model fit. Degrees of freedom are calculated as the sample size minus the number of estimated parameters in the model.

For detailed documentation on all `OUTEST=` options, see [SAS PROC REG documentation](https://v8doc.sas.com/sashtml/stat/chap55/sect27.htm).

```sas
proc reg data=a_comp_wins outest=model1 edf;   
  model roa = size mtb;  
quit;
```

---

### Fitted Values and Residuals

To include fitted values (predicted values) and residuals in the output dataset, use the `OUTPUT` statement within `PROC REG`. This feature is helpful for diagnostics, allowing you to assess model performance directly from the data.

```sas
proc reg data=a_comp_wins outest=model1;   
  model roa = size mtb;  
  /* Save input data, predicted values, and residuals to an output dataset */
  output out=model1_predicted predicted=predicted residual=residual;
quit;
```

The `OUTPUT` dataset includes:
- Original input data
- Predicted values for the dependent variable
- Residuals (differences between actual and predicted values)

---

### Output Delivery System (ODS)

The Output Delivery System (ODS) in SAS provides a flexible way to direct output tables and results to various destinations, such as datasets, HTML, or PDF files. With `PROC REG`, you can use ODS to capture specific statistics like parameter estimates, fit statistics, and sample size into separate datasets for further analysis.

To learn more about ODS tables for `PROC REG`, see [SAS Documentation on ODS Table Names for PROC REG](https://documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=9.4_3.4&docsetId=statug&docsetTarget=statug_reg_details52.htm&locale=en).

Example:

```sas
proc reg data=a_comp_wins outest=model1;   
  model roa = size mtb;  
  /* Save predicted and residual values */
  output out=model1_predicted predicted=predicted residual=residual;
  
  /* Save key statistics to separate datasets */
  ods output 	
    ParameterEstimates=_surv_params 
    FitStatistics=_surv_fit
    NObs=_surv_summ;
quit;
```

Key features of this example:
- **`ParameterEstimates`**: Captures estimated coefficients for each predictor.
- **`FitStatistics`**: Includes R-squared and other model evaluation metrics.
- **`NObs`**: Provides the number of observations used in the analysis.

---


## Regression `by` group <a name="by_group"></a>

When performing Ordinary Least Squares (OLS) regression, you may need to analyze data by specific groups, such as firms (e.g., estimating beta using monthly returns), years, industries, or combinations like industry-year. To achieve this in SAS, you can use the `BY` statement in `PROC REG`, which enables separate regressions for each group within the data. However, the dataset must first be sorted by the grouping variable(s).

> **Important:** Using the `BY` statement with many groups can significantly slow down ODS processing when capturing output.

### Example: OLS Regression by Year
The following example demonstrates how to perform a group-specific regression by fiscal year:

```sas
/* Step 1: Sort the data by the grouping variable (fyear) */
proc sort data=a_comp_wins; 
  by fyear;
run;

/* Step 2: Perform regression with group-specific analysis */
proc reg data=a_comp_wins outest=model2;   
  model roa = size mtb / noprint;
  by fyear; /* Specifies the grouping variable */
run;
```

### Key Points:
- **Sorting Requirement:** The dataset must be sorted by the `BY` variable(s) before running `PROC REG`.
- **Output Dataset (`outest=`):** Captures estimated coefficients for each group, stored in a separate dataset (`model2` in this example).
- **Performance Considerations:** Processing time may increase substantially for large datasets with many groups due to the volume of regressions performed.

This method is ideal when you need to understand relationships or coefficients that vary across distinct categories or time periods.

---

## Robust regression <a name="robust"></a>

 In the context of Ordinary Least Squares (OLS), a “robust regression”  refers to an OLS regression that uses methods to handle heteroscedasticity—unequal variances in the residuals. When data exhibit heteroscedasticity, OLS standard errors can be biased, which affects statistical inference (like confidence intervals and hypothesis tests). A robust regression corrects for this by adjusting the standard errors to provide more reliable estimates.

One common approach is the use of *robust standard errors*, also called *heteroscedasticity-consistent standard errors*. This adjustment does not alter the coefficient estimates but recalculates the standard errors to account for heteroscedasticity, making the regression “robust” to violations of the homoscedasticity assumption. These robust methods are implemented in statistical packages (including SAS, Stata, and R) and help produce more accurate p-values and confidence intervals when data deviations occur.

`PROC SURVEYREG` will do a 'robust' regression by default. This affects the standard errors of the estimates, and not the coefficients itself; these will be the same regardless which procedure is used.

```sas
/*
	Same regression, using proc surveyreg which gives robust standard errors by default
	(coefficients are not affected, but normally t-values are smaller)

	ODS table names: https://v8doc.sas.com/sashtml/stat/chap62/sect26.htm
*/
proc surveyreg data=a_comp_wins;   
  model roa =  size mtb / solution;  
  output out = model2_p  predicted=predicted residual=residual ;
  ods output 	
    ParameterEstimates = _surv_params 
    FitStatistics = _surv_fit
    DataSummary = _surv_summ; /* for surveyreg, number of obs is in datasummary */
quit;
```
---

## Fixed effects using  `CLASS` statement <a name="class"></a>


Incorporating year and industry fixed effects in SAS models can be easily managed using the `CLASS` statement. By using the `CLASS` statement, SAS automatically creates indicator (dummy) variables for each level of the categorical variables specified. This is ideal for year and industry fixed effects without requiring manual transformations.

To include these effects in a regression model:

- **`PROC SURVEYREG`** and **`PROC GLM`**: Both procedures support the `CLASS` statement, which enables the automatic generation of indicator variables for categorical factors. This is essential when the model includes categorical variables such as year and industry, allowing SAS to handle fixed effects conveniently. `PROC SURVEYREG` is particularly suited for survey data with complex designs, while `PROC GLM` handles general linear models with categorical factors effectively.

- **`PROC REG`**: This procedure does not support the `CLASS` statement. As a result, categorical variables such as year and industry must be manually converted to dummy variables before including them in models in `PROC REG`. 


### Example year and industry effects

```sas
proc surveyreg data=a_comp_wins;   
  class fyear sic2;
  model  roa = size mtb fyear sic2 / solution;  
  ods output  
    ParameterEstimates = _surv_params 
    FitStatistics = _surv_fit
    DataSummary = _surv_summ;
quit;
```

---

## Firm Fixed Effects <a name="firm_fixed"></a>

To control for firm-specific characteristics in panel data, **firm fixed effects** can be included in a regression model to account for unobserved heterogeneity across firms. In SAS, this can be implemented in various ways, depending on the procedure and the size of the dataset.

- **Using `PROC SURVEYREG` with `CLASS`**: Including firm fixed effects in `PROC SURVEYREG` can be done by specifying `CLASS gvkey` and adding `gvkey` to the model statement. This approach allows SAS to estimate a separate coefficient for each firm. However, it can become slow when there are a large number of unique firm identifiers (e.g., `gvkeys`), as each firm's fixed effect is individually estimated. 

- **Using `PROC GLM` with `ABSORB`**: For datasets with numerous firms, it is often more efficient to use `PROC GLM` with the `ABSORB` statement. This method "absorbs" firm-specific fixed effects by demeaning the dependent and independent variables for each firm. While `PROC GLM` does not output the firm fixed effects coefficients individually, it effectively removes firm-level variation, allowing the model to focus on within-firm differences. 

    When using `ABSORB`, SAS partitions the dataset by each unique firm identifier (e.g., `gvkey`), subtracting the mean of each variable within each firm. This method reduces computational time significantly, as it does not require estimating a dummy variable for each firm.

### Example of Firm Fixed Effects Using `PROC GLM` with `ABSORB`

```sas
/* Sort the dataset by firm identifier before using PROC GLM */
proc sort data=a_comp_wins; by gvkey; run;

/* Use PROC GLM with ABSORB for firm fixed effects */
proc glm data=a_comp_wins;
    absorb gvkey;
    model roa = size mtb / solution;
quit;
```

In this example, `PROC GLM` automatically absorbs each firm’s average values, providing a streamlined approach for fixed effects without calculating a separate coefficient for each firm.







