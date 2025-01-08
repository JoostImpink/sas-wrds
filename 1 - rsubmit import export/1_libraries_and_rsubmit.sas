/* Libraries and rsubmit */


/* Creating a library */

/* make sure the folder exists */
libname h "E:\temp\today";

/* Referencing files in a library */

/* This will create hello.sas7bdat in the folder */
data h.hello;
x = 1;
msg = 'hi there';
run;

/* This will make a copy of the dataset in the (temporary) work library */
data hellocopy;
set h.hello;
run;

/* rsubmit */

/* sign on */

/* Remote access: setup, defining the connection */
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

/* An empty rsubmit block will test if the connection is still active 
If it is no longer active, then the sign on will ask for credentials
*/
rsubmit; endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

/* Example of rsubmit where a message gets logged */

/* rsubmit, endrsubmit block */
rsubmit;
	/* this code runs on WRDS */
	%put hi;

endrsubmit;

/* rsubmit example Funda */
rsubmit;

	/* this code runs on WRDS */
	
	data a_comp (keep = gvkey fyear datadate cik conm sich sale at ni ceq prcc_f csho xrd curcd);
	set comp.funda;
	/* years 2010 and later*/
	if fyear >= 2010;

	/* prevent double records (specific to Compustat Funda only, other datasets do't need this) */
	if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
	run;

	proc download data = a_comp out= a_comp;run;

endrsubmit;

/* proc upload and proc download */

rsubmit;
   /* This will download a_comp to the local work library */
   proc download data=a_comp out=a_comp;
   run;
endrsubmit;

/* Upload sas code within an rsubmit block - example */

/* make sure the connection is active */
rsubmit; endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

/* rsubmit-endrsubmit block */
rsubmit;

/* full path to file, relative paths doesn't work */
proc upload 
	infile='C:\git\sas-wrds\1 - rsubmit import export\1 example rsubmit\example rsubmit.sas' 
	outfile='~/example.sas'; /* doesn't have to be the same file name */
run;

/* run it, it will create a_comp, the screen may 'freeze' on the upload of the code while it runs */
%include '~/example.sas';

/* download the dataset that was created */
proc download data=a_comp out=a_comp;run;

endrsubmit;

/* remote viewing */

/* remote library assignment: this allows us to browse the remote work folder  */

libname rwork slibref=work server=wrds;
libname rcrsp slibref=crsp server=wrds;

