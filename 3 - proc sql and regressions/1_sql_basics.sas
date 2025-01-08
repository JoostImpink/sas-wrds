 
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


proc sql;
    create table b_test1 as 

        select gvkey, fyear, sale 
        from a_comp;
    
    create table b_test2 as 
        select gvkey, fyear, at 
        from a_comp;
quit;

proc sql;
  create table work.dsOut as 
    select gvkey, fyear, sale, max(sale) as highest, count(*) as numObs 
    from a_comp
    group by gvkey; /* proc sql doesn't require sorting */
quit;

rsubmit;endrsubmit;
rsubmit;
proc sql;
  create table work.b_comp as 
  select a.*, b.fic, b.sic, b.ipodate
  from work.a_comp a, comp.company b
  where a.gvkey = b.gvkey;
quit;
proc download data=b_comp out=b_comp;run;
endrsubmit;

proc sql;
  create table b_growth as 
  select a.*, a.sale / b.sale - 1 as sales_growth, b.sale as sale_prev, b.fyear as prev_fyear
  from a_comp a left join a_comp b
  on  a.gvkey = b.gvkey
  and a.fyear - 1 = b.fyear; 
quit;

proc sql;
    create table myTable4 as 
        select *, 
            median(sale) as sale_median label="Industry median sales" format=comma20.,
            max(sale) as sale_max, 
            min(sale) as sale_min,
			count(*) as numobs
        from a_comp 
        group by sic2, fyear;
quit;


proc sql;
    create table myTable4 as 
        select *, 
            median(sale) as sale_median label="Industry median sales" format=comma20.,
            max(sale) as sale_max, 
            min(sale) as sale_min,
			count(*) as numobs
        from a_comp 
		where missing(sale) eq 0 and missing(sic2) eq 0
        group by sic2, fyear
        having 
            sale = max(sale)          /* selects observations with the highest sale in each industry-year */
            and count(*) > 5;         /* only includes industries with more than 5 observations */
quit;


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

proc sql;
    create table test3 as 
    select gvkey, fyear, sale
    from a_comp
    where fyear IN (2020, 2022);
quit;


proc sql;
    create table test3 as 
    select gvkey, fyear, sale
    from mytable
    where fyear NOT IN ( select max(fyear) from mytable );
quit;

proc sql /*outobs=50 */;

    create table test3 as
    select distinct sic2, fyear
    from a_comp;
quit;

proc sql outobs=50 ;

    create table test3 as
    select distinct gvkey, fyear
    from a_comp;
quit;


proc sql;
    create table test2 as 
    select a.*, (sale > median(sale)) as large, median(sale) as sale_median, count(*) as numobs
    from a_comp a
    where missing(sic2) eq 0
    group by sic2, fyear; 
quit;


proc sql;
    create table myTable as 
    select sic2, fyear, 
           median(sale) as sale_median 
               LABEL="Industry median sales" 
               format=comma20. 
    from a_comp 
    group by sic2, fyear;
quit;

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

proc sql;
    drop table test2, test3;
quit;

proc sql;
 	create index gvkey_fyear on a_comp(gvkey, fyear);
quit;

proc sql;
    drop index gvkey_fyear from a_comp;
quit;
