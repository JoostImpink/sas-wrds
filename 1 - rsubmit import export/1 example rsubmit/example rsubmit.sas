/* This code will be uploaded and then included (%include) on WRDS
So there is no need for rsubmit and endrsubmit */

data a_comp (keep = gvkey fyear datadate cik conm sich sale at ni ceq prcc_f csho xrd curcd);
set comp.funda;

/* years 2010 and later*/
if fyear >= 2010;

/* prevent double records (specific to Compustat Funda only, other datasets do't need this) */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;

