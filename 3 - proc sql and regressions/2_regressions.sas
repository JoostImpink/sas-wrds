%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

data a_comp (keep = gvkey fyear datadate sich roa mtb size sale at ni prcc_f csho sic2);
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


proc reg data=a_comp_wins outest=model1 edf;   
  model roa = size mtb;  
quit;

proc reg data=a_comp_wins outest=model1;   
  model roa = size mtb;  
  /* Save input data, predicted values, and residuals to an output dataset */
  output out=model1_predicted predicted=predicted residual=residual;
quit;


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


/* Step 1: Sort the data by the grouping variable (fyear) */
proc sort data=a_comp_wins; 
  by fyear;
run;

/* Step 2: Perform regression with group-specific analysis */
proc reg data=a_comp_wins outest=model2;   
  model roa = size mtb / noprint;
  by fyear; /* Specifies the grouping variable */
run;





proc surveyreg data=a_comp_wins;   
  class fyear sic2;
  model  roa = size mtb fyear sic2 / solution;  
  ods output  
    ParameterEstimates = _surv_params 
    FitStatistics = _surv_fit
    DataSummary = _surv_summ;
quit;


proc surveyreg data=a_comp_wins;   
  /*class fyear sic2;*/
  model  roa = size mtb fyear sic2 / solution;  
  ods output  
    ParameterEstimates = _surv_params 
    FitStatistics = _surv_fit
    DataSummary = _surv_summ;
quit;

data test;
set a_comp_wins;
problemvar = roa - mtb;
run;

proc surveyreg data=test;   
  model  roa = problemvar size mtb / solution;  
quit;


/* Sort the dataset by firm identifier before using PROC GLM */
proc sort data=a_comp_wins; by gvkey; run;

/* Use PROC GLM with ABSORB for firm fixed effects */
proc glm data=a_comp_wins;
    absorb gvkey;
    model roa = size mtb / solution;
quit;


