/* example dataset */

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

DATA b_comp;
SET a_comp;
    /* define the length of variable type */
    length type $10;
    
    IF sale >= 300 THEN type = 'Enterprise';
    ELSE IF sale >= 100 THEN type = 'Large';
    ELSE IF sale >= 50 THEN type = 'Medium';
    ELSE type = 'Small';
RUN;

data b_comp (where =(growth ne .)); /* filter on output dataset: only obs where growth is calculated */
set a_comp (where = (sale > 0)); /* filter on input dataset to drop obs where sale is 0 or missing */
by gvkey;
retain sale_prev;
/* for the first row of each gvkey set sale_prev to missing */
if first.gvkey then sale_prev = .;
/* calculate growth; it will be missing for each first year */
growth = sale / sale_prev - 1;
/* set sale_prev so it can be used in the next record */
sale_prev = sale;
run;

DATA c_classification;
SET b_comp;
length status $13;
SELECT;
	/* Star: High sales (market share) and high growth */
	WHEN (sale > 100 AND growth > 0.05) DO;
		status = 'Star';
	END;

	/* Cash Cow: High sales (market share) and low growth */
	WHEN (sale > 100 AND growth <= 0.05) DO;
		status = 'Cash Cow';
	END;

	/* Question Mark: Low sales (market share) but high growth */
	WHEN (sale <= 100 AND growth > 0.05) DO;
		status = 'Question Mark';
	END;

	/* Dog: Low sales (market share) and low growth */
	OTHERWISE DO;
		status = 'Dog';
	END;
END;
RUN;

DATA example;
    DO i = 1 TO 10;
        total = i * 5;
        OUTPUT;
    END;
RUN;

DATA example;
    x = 0;
    DO UNTIL (x >= 50);
        x + 5;
        OUTPUT;
    END;
RUN;

DATA example;
    x = 1;
    DO WHILE (x < 20);
        x = x * 2;
        OUTPUT;
    END;
RUN;

data randomSales;
do id = 1 to 100;
   do year = 1 to 10;
	   x = 2010 + year;
	   u = rand("Uniform"); /* generates a random number between 0 and 1 from a uniform distribution */
	   sales =  100 * u;  /* scales the random number to a range between 0 and 100 */
	   output; /* writes a new record for each iteration */
   end; /* end of year loop */	  
end; /* end of id loop */
run;
