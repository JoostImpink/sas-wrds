proc sort data=a_comp; by sich fyear; run;

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
