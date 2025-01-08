


proc print data=a_comp (obs=10);
run;

/* summary statistics for full sample */
proc means data=a_comp n mean  median stddev;
 /* OUTPUT OUT=work.meansout n= mean= median= stddev= /autoname; */
  var roa size mtb;
run;


proc means data=a_comp noprint;
  OUTPUT OUT=work.meansout n= mean= median= stddev= /autoname;
  var roa size mtb;
run;

proc sort data=a_comp; by fyear; run;
/* as above, but repeated by a group (requires sorting on that variable) */
proc means data=a_comp noprint;
  OUTPUT OUT=work.meansout n= mean= median= stddev= /autoname;
  var roa size mtb;
  by fyear;
run;

proc rank data=a_comp out=ranked_data groups=10;
    var size;
    ranks size_d;
run;

proc standard data=a_comp out=b_comp mean=0 std=1;
   var roa size mtb;
run;


proc freq data=sashelp.class;
    tables age / nocum nopercent;
run;

proc freq data=sashelp.class;
    tables sex * age / chisq;
run;

proc univariate data=sashelp.class;
    var height;
    histogram height / normal;
    inset mean std / format=5.2;
run;
