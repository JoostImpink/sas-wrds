data test1;
x = 1;
run;

data test2;
x = 1;
run;

proc datasets library=work;
   delete test1-test2;
quit;


proc contents data=sashelp.class;
run;

proc contents data=sashelp.class position;
run;

proc contents data=sashelp.class out=metadata;
run;
