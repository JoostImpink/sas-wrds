%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

   data a_comp (keep = gvkey fyear datadate sich roa mtb size sale at ni prcc_f csho miss_sich);
   set comp.funda;

   /* require fyear to be within 2010-2013 */
   if 2010 <=fyear <= 2013;
   /* require assets, sales, equity and net income to be non-missing */
   if cmiss (of at sale ceq ni) eq 0;
   /* prevent double records */
   if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;

   /* construct some variables */
   roa = ni / at;
   mtb = csho * prcc_f / ceq;
   size = log(csho * prcc_f);
   miss_sich = missing(sich);
   run;

   proc download data=a_comp out=a_comp;run;
endrsubmit;


data b_large (rename=(gvkey = company_id) keep = gvkey sale );
set a_comp (where=(sale>100));
run;

data b_large;
set a_comp ;
where sale > 100; 
keep gvkey sale company_id;    
/* drop unwanted_var; * not used here */
rename gvkey = company_id; 
run;

data _NULL_;
	if 0 then set work.a_comp nobs=n;
   /* set macro variable nrows to n (nobs) */
	call symputx('nrows',n);
	stop;
run;
/* display a message with the number of observations */
%put The number of observations is &nrows;

data myTable2;
set a_comp;
/* create counter */
counter = _N_;
/* keep the first 100 obs */
if _N_ <= 100;
run;

rsubmit;
PROC CONTENTS DATA=comp.funda;
RUN;
endrsubmit;

rsubmit;

/* where will benefit from indices */
data test;
set comp.funda;
where gvkey eq "001004";
run;

/* if will read the full dataset */
data test;
set comp.funda;
if gvkey eq "001004";
run;

endrsubmit;

DATA a_comp2;
    SET a_comp;
    /* Creating an indicator for high sales */
    large = (sale > 116.084);
RUN;

data a_comp2 (keep = gvkey fyear sale sale_prev increase);
set a_comp;
retain sale_prev;
/* create indicator */
increase = (sale > sale_prev);
/* update sale_prev to be used in the next record */
sale_prev = sale;
run;

/* sort by gvkey */
proc sort data=a_comp; by gvkey fyear;run;

/* add increase indicator */
data a_comp2 (keep = gvkey fyear sale sale_prev increase);
set a_comp;
/* add by statement */
by gvkey;
/* variable to retain */
retain sale_prev;
/* just like before */
increase = (sale > sale_prev); 
/* guard against initial record for each firm
set increase to missing */
if first.gvkey then increase = .;
/* set retained variable for next observation */
sale_prev = sale; 
run;

data test;
x = 1; y='a'; output; output; output;
x = 2; y='b'; output; output; output;
run;
proc print;run;


data a_comp3 (keep = gvkey avgSale numObs sumSale);
set a_comp;
by gvkey;
retain sumSale numObs;
/* initializing */
if first.gvkey then do;
   sumSale = 0;
   numObs = 0;
end;
/* processing data */
sumSale = sumSale + sale;
numObs = numObs + 1;
/* last record */
if last.gvkey then do;
   avgSale = sumSale / numObs;
   output;
end;
run;

data somedata;
  input @01 id        1.
        @03 year2010  4.
		@08 year2011  4.
        @13 year2012  4.
		@18 year2013  4.
	;
datalines;
1 1870 1242 2022 1325
2 9822 3186 1505 8212
3      1221 4321 9120
4 4701 2323 3784
run;

data long (keep = id year value);
set somedata;
value = year2010; year = 2010; output;
value = year2011; year = 2011; output;
value = year2012; year = 2012; output;
value = year2013; year = 2013; output;
run;


rsubmit;

	/* rename fyear to fyearq for merge later on */
   data myTable (keep = gvkey fyearq datadate sich roa mtb size sale at ni prcc_f csho);
   set comp.funda;

   /* require fyear to be within 2010-2013 */
   if 2010 <=fyear <= 2013;
   /* require assets, sales, equity and net income to be non-missing */
   if cmiss (of at sale ceq ni) eq 0;
   /* prevent double records */
   if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;

   /* construct some variables */
   roa = ni / at;
   mtb = csho * prcc_f / ceq;
   size = log(csho * prcc_f);
   miss_sich = missing(sich);
   /* for merge with fundq (uses fyearq) */
   fyearq = fyear;
   run;

   /* fundq is not properly sorted  */
   proc sort data=comp.fundq (where=(2010 <= fyearq <= 2013) keep=gvkey fyearq atq ceqq niq) out=myq ; by gvkey fyearq; run;

   /* merge it with comp.fundq */
   data myTable2;
   merge myTable myq;
   by gvkey fyearq;
   run;
 proc download data=myTable2 out=myTable2;run;

 endrsubmit;

