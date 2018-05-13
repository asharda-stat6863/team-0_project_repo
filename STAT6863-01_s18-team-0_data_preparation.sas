*******************************************************************************;
**************** 80-character banner for column width reference ***************;
* (set window width to banner width to calibrate line length to 80 characters *;
*******************************************************************************;

* 
[Dataset 1 Name] frpm1415

[Dataset Description] Student Poverty Free or Reduced Price Meals (FRPM) Data,
AY2014-15

[Experimental Unit Description] California public K-12 schools in AY2014-15

[Number of Observations] 10,393      

[Number of Features] 28

[Data Source] The file http://www.cde.ca.gov/ds/sd/sd/documents/frpm1415.xls
was downloaded and edited to produce file frpm1415-edited.xls by deleting
worksheet "Title Page", deleting row 1 from worksheet "FRPM School-Level Data",
reformatting column headers in "FRPM School-Level Data" to remove characters
disallowed in SAS variable names, and setting all cell values to "Text" format

[Data Dictionary] http://www.cde.ca.gov/ds/sd/sd/fsspfrpm.asp

[Unique ID Schema] The columns "County Code", "District Code", and "School
Code" form a composite key, which together are equivalent to the unique id
column CDS_CODE in dataset gradaf15, and which together are also equivalent to
the unique id column CDS in dataset sat15.
;
%let inputDataset1DSN = frpm1415_raw;
%let inputDataset1URL =
https://github.com/stat6250/team-0_project2/blob/master/data/frpm1415-edited.xls?raw=true
;
%let inputDataset1Type = XLS;


*
[Dataset 2 Name] frpm1516

[Dataset Description] Student Poverty Free or Reduced Price Meals (FRPM) Data,
AY2015-16

[Experimental Unit Description] California public K-12 schools in AY2015-16

[Number of Observations] 10,453     

[Number of Features] 28

[Data Source] The file http://www.cde.ca.gov/ds/sd/sd/documents/frpm1516.xls
was downloaded and edited to produce file frpm1516-edited.xls by deleting
worksheet "Title Page", deleting row 1 from worksheet "FRPM School-Level Data",
reformatting column headers in "FRPM School-Level Data" to remove characters
disallowed in SAS variable names, and setting all cell values to "Text" format

[Data Dictionary] http://www.cde.ca.gov/ds/sd/sd/fsspfrpm.asp

[Unique ID Schema] The columns "County Code", "District Code", and "School
Code" form a composite key, which together are equivalent to the unique id
column CDS_CODE in dataset gradaf15, and which together are also equivalent to
the unique id column CDS in dataset sat15.
;
%let inputDataset2DSN = frpm1516_raw;
%let inputDataset2URL =
https://github.com/stat6250/team-0_project2/blob/master/data/frpm1516-edited.xls?raw=true
;
%let inputDataset2Type = XLS;


*
[Dataset 3 Name] gradaf15

[Dataset Description] Graduates Meeting UC/CSU Entrance Requirements, AY2014-15

[Experimental Unit Description] California public K-12 schools in AY2014-15

[Number of Observations] 2,490

[Number of Features] 15

[Data Source] The file
http://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2014-15&cCat=UCGradEth&cPage=filesgradaf.asp
was downloaded and edited to produce file gradaf15.xls by importing into Excel
and setting all cell values to "Text" format

[Data Dictionary] http://www.cde.ca.gov/ds/sd/sd/fsgradaf09.asp

[Unique ID Schema] The column CDS_CODE is a unique id.
;
%let inputDataset3DSN = gradaf15_raw;
%let inputDataset3URL =
https://github.com/stat6250/team-0_project2/blob/master/data/gradaf15.xls?raw=true
;
%let inputDataset3Type = XLS;


*
[Dataset 4 Name] sat15

[Dataset Description] SAT Test Results, AY2014-15

[Experimental Unit Description] California public K-12 schools in AY2014-15

[Number of Observations] 2,331

[Number of Features] 12

[Data Source]  The file http://www3.cde.ca.gov/researchfiles/satactap/sat15.xls
was downloaded and edited to produce file sat15-edited.xls by opening in Excel
and setting all cell values to "Text" format

[Data Dictionary] http://www.cde.ca.gov/ds/sp/ai/reclayoutsat.asp

[Unique ID Schema] The column CDS is a unique id.
;
%let inputDataset4DSN = sat15_raw;
%let inputDataset4URL =
https://github.com/stat6250/team-0_project2/blob/master/data/sat15-edited.xls?raw=true
;
%let inputDataset4Type = XLS;


* set global system options;
options fullstimer;


* load raw datasets over the wire, if they doesn't already exist;
%macro loadDataIfNotAlreadyAvailable(dsn,url,filetype);
    %put &=dsn;
    %put &=url;
    %put &=filetype;
    %if
        %sysfunc(exist(&dsn.)) = 0
    %then
        %do;
            %put Loading dataset &dsn. over the wire now...;
            filename
                tempfile
                "%sysfunc(getoption(work))/tempfile.&filetype."
            ;
            proc http
                method="get"
                url="&url."
                out=tempfile
                ;
            run;
            proc import
                file=tempfile
                out=&dsn.
                dbms=&filetype.;
            run;
            filename tempfile clear;
        %end;
    %else
        %do;
            %put Dataset &dsn. already exists. Please delete and try again.;
        %end;
%mend;
%macro loadDatasets;
    %do i = 1 %to 4;
        %loadDataIfNotAlreadyAvailable(
            &&inputDataset&i.DSN.,
            &&inputDataset&i.URL.,
            &&inputDataset&i.Type.
        )
    %end;
%mend;
%loadDatasets


* check frpm1415_raw for bad unique id values, where the columns County_Code,
District_Code, and School_Code are intended to form a composite key;
proc sql;
    /* check for duplicate unique id values; after executing this query, we
       see that frpm1415_raw_dups only has one row, which just happens to 
       have all three elements of the composite key missing, which we can
       mitigate as part of eliminating rows having missing unique id component
       in the next query */
    create table frpm1415_raw_dups as
        select
             County_Code
            ,District_Code
            ,School_Code
            ,count(*) as row_count_for_unique_id_value
        from
            frpm1415_raw
        group by
             County_Code
            ,District_Code
            ,School_Code
        having
            row_count_for_unique_id_value > 1
    ;
    /* remove rows with missing unique id components, or with unique ids that
       do not correspond to schools; after executing this query, the new
       dataset frpm1415 will have no duplicate/repeated unique id values,
       and all unique id values will correspond to our experimental units of
       interest, which are California Public K-12 schools; this means the 
       columns County_Code, District_Code, and School_Code in frpm1415 are 
       guaranteed to form a composite key */
    create table frpm1415 as
        select
            *
        from
            frpm1415_raw
        where
            /* remove rows with missing unique id value components */
            not(missing(County_Code))
            and
            not(missing(District_Code))
            and
            not(missing(School_Code))
            and
            /* remove rows for District Offices and non-public schools */
            School_Code not in ("0000000","0000001")
    ;
quit;


* check frpm1516_raw for bad unique id values, where the columns County_Code,
District_Code, and School_Code form a composite key;
proc sql;
    /* check for duplicate unique id values; after executing this query, we
       see that frpm1516_raw_dups contains now rows, so no mitigation is
       needed to ensure uniqueness */
    create table frpm1516_raw_dups as
        select
             County_Code
            ,District_Code
            ,School_Code
            ,count(*) as row_count_for_unique_id_value
        from
            frpm1516_raw
        group by
             County_Code
            ,District_Code
            ,School_Code
        having
            row_count_for_unique_id_value > 1
    ;
    /* remove rows with missing unique id components, or with unique ids that
       do not correspond to schools; after executing this query, the new
       dataset frpm1516 will have no duplicate/repeated unique id values,
       and all unique id values will correspond to our experimental units of
       interest, which are California Public K-12 schools; this means the 
       columns County_Code, District_Code, and School_Code in frpm1516 are 
       guaranteed to form a composite key */
    create table frpm1516 as
        select
            *
        from
            frpm1516_raw
        where
            /* remove rows with missing unique id value components */
            not(missing(County_Code))
            and
            not(missing(District_Code))
            and
            not(missing(School_Code))
            and
            /* remove rows for District Offices and non-public schools */
            School_Code not in ("0000000","0000001")
    ;
quit;


* check gradaf15_raw for bad unique id values, where the column CDS_CODE is 
intended to be a primary key;
proc sql;
    /* check for unique id values that are repeated, missing, or correspond to
       non-schools; after executing this query, we see that
       gradaf15_raw_bad_unique_ids only has non-school values of CDS_Code that
       need to be removed */
    /* note to learners: the query below uses an in-line view together with a
       left join (see Chapter 3 for definitions) to isolate all problematic
       rows within a single query; it would have been just as valid to use
       multiple queries, as above, but it's often convenient to use a single
       query to create a table with specific properties; in particular, in the
       above two examples, we blindly eliminated rows having specific
       properties when creating frpm1415 and frpm1516, whereas the query below
       allows us to build a fit-for-purpose mitigation step with no guessing
       or unnecessary effort */
    create table gradaf15_raw_bad_unique_ids as
        select
            A.*
        from
            gradaf15_raw as A
            left join
            (
                select
                     CDS_CODE
                    ,count(*) as row_count_for_unique_id_value
                from
                    gradaf15_raw
                group by
                    CDS_CODE
            ) as B
            on A.CDS_CODE=B.CDS_CODE
        having
            /* capture rows corresponding to repeated primary key values */
            row_count_for_unique_id_value > 1
            or
            /* capture rows corresponding to missing primary key values */
            missing(CDS_CODE)
            or
            /* capture rows corresponding to non-school primary key values */
            substr(CDS_CODE,8,7) in ("0000000","0000001")
    ;
    /* remove rows with primary keys that do not correspond to schools; after
       executing this query, the new dataset gradaf15 will have no
       duplicate/repeated unique id values, and all unique id values will
       correspond to our experimental units of interest, which are California
       Public K-12 schools; this means the column CDS_Code in gradaf15 is 
       guaranteed to form a primary key */
    create table gradaf15 as
        select
            *
        from
            gradaf15_raw
        where
            /* remove rows for District Offices and non-public schools */
            substr(CDS_CODE,8,7) not in ("0000000","0000001")
    ;
quit;


* check sat15_raw for bad unique id values, where the column CDS is intended
to be a primary key;
proc sql;
    /* check for unique id values that are repeated, missing, or correspond to
       non-schools; after executing this query, we see that
       sat15_raw_bad_unique_ids only has non-school values of CDS that need to
       be removed */
    create table sat15_raw_bad_unique_ids as
        select
            A.*
        from
            sat15_raw as A
            left join
            (
                select
                     CDS
                    ,count(*) as row_count_for_unique_id_value
                from
                    sat15_raw
                group by
                    CDS
            ) as B
            on A.CDS=B.CDS
        having
            /* capture rows corresponding to repeated primary key values */
            row_count_for_unique_id_value > 1
            or
            /* capture rows corresponding to missing primary key values */
            missing(CDS)
            or
            /* capture rows corresponding to non-school primary key values */
            substr(CDS,8,7) in ("0000000","0000001")
    ;
    /* remove rows with primary keys that do not correspond to schools; after
       executing this query, the new dataset gradaf15 will have no
       duplicate/repeated unique id values, and all unique id values will
       correspond to our experimental units of interest, which are California
       Public K-12 schools; this means the column CDS in sat15 is guaranteed
       to form a primary key */
    create table sat15 as
        select
            *
        from
            sat15_raw
        where
            /* remove rows for District Offices */
            substr(CDS,8,7) ne "0000000"
    ;
quit;


* inspect columns of interest in cleaned versions of datasets;
    /*
    title "Inspect Percent_Eligible_Free_K12 in frpm1415";
    proc sql;
        select
             min(Percent_Eligible_Free_K12) as min
            ,max(Percent_Eligible_Free_K12) as max
            ,mean(Percent_Eligible_Free_K12) as max
            ,median(Percent_Eligible_Free_K12) as max
            ,nmiss(Percent_Eligible_Free_K12) as missing
        from
            frpm1415
        ;
    quit;
    title;

    title "Inspect Percent_Eligible_Free_K12 in frpm1516";
    proc sql;
        select
             min(Percent_Eligible_Free_K12) as min
            ,max(Percent_Eligible_Free_K12) as max
            ,mean(Percent_Eligible_Free_K12) as max
            ,median(Percent_Eligible_Free_K12) as max
            ,nmiss(Percent_Eligible_Free_K12) as missing
        from
            frpm1516
        ;
    quit;
    title;

    title "Inspect PCTGE1500, after converting to numeric values, in sat15";
    proc sql;
        select
             min(input(PCTGE1500,best12.)) as min
            ,max(input(PCTGE1500,best12.)) as max
            ,mean(input(PCTGE1500,best12.)) as max
            ,median(input(PCTGE1500,best12.)) as max
            ,nmiss(input(PCTGE1500,best12.)) as missing
        from
            sat15
        ;
    quit;
    title;

    title "Inspect NUMTSTTAKR, after converting to numeric values, in sat15";
    proc sql;
        select
             input(NUMTSTTAKR,best12.) as Number_of_testers
            ,count(*)
        from
            sat15
        group by
            calculated Number_of_testers
        ;
    quit;
    title;

    title "Inspect TOTAL, after converting to numeric values, in gradaf15";
    proc sql;
        select
             input(TOTAL,best12.) as Number_of_course_completers
            ,count(*)
        from
            gradaf15
        group by
            calculated Number_of_course_completers
        ;
    quit;
    title;
    */

/*
    * combine sat15 and gradaf15 horizontally using a data-step match-merge;
    * note: After running the data step and proc sort step below several times
      and averaging the fullstimer output in the system log, they tend to take
      about 0.04 seconds of combined "real time" to execute and a maximum of
      about 1.8 MB of memory (1100 KB for the data step vs. 1800 KB for the
      proc sort step) on the computer they were tested on;
    data sat_and_gradaf15_v1;
        retain
            CDS_Code
            School
            District
            Number_of_SAT_Takers
            Number_of_Course_Completers
        ;
        keep
            CDS_Code
            School
            District
            Number_of_SAT_Takers
            Number_of_Course_Completers
        ;
        merge
            gradaf15
            sat15(
                rename=(
                    CDS=CDS_Code
                    sname=School
                    dname=District
                )
            )
        ;
        by CDS_Code;

        Number_of_SAT_Takers = input(NUMTSTTAKR, best12.);

        Number_of_Course_Completers = input(TOTAL, best12.);

    run;
    proc sort data=sat_and_gradaf15_v1;
        by CDS_Code;
    run;


    * combine sat15 and gradaf15 horizontally using proc sql;
    * note: After running the proc sql step below several times and averaging
      the fullstimer output in the system log, they tend to take about 0.04
      seconds of "real time" to execute and about 9 MB of memory on the computer
      they were tested on. Consequently, the proc sql step appears to take roughly
      the same amount of time to execute as the combined data step and proc sort
      steps above, but to use roughly five times as much memory;
    * note to learners: Based upon these results, the proc sql step is preferable
      if memory performance isn't critical. This is because less code is required,
      so it's faster to write and verify correct output has been obtained;
    proc sql;
        create table sat_and_gradaf15_v2 as
            select
                 coalesce(A.CDS,B.CDS_Code) as CDS_Code
                ,coalesce(A.sname,B.SCHOOL) as School
                ,coalesce(A.dname,B.DISTRICT) as District
                ,input(A.NUMTSTTAKR,best12.) as Number_of_SAT_Takers
                ,input(B.TOTAL,best12.) as Number_of_Course_Completers
            from
                sat15 as A
                full join
                gradaf15 as B
                on A.CDS=B.CDS_Code
            order by
                CDS_Code
        ;
    quit;


    * verify that sat_and_gradaf15_v1 and sat_and_gradaf15_v2 are identical;
    proc compare
            base=sat_and_gradaf15_v1
            compare=sat_and_gradaf15_v2
            novalues
        ;
    run;


    * combine frpm1415 and frpm1516 vertically using a data-step interweave,
      combining composite key values into a single primary key value;
    * note: After running the data step and proc sort step below several times
      and averaging the fullstimer output in the system log, they tend to take
      about 0.1 seconds of combined "real time" to execute and a maximum of
      about 6 MB of memory (1200 KB for the data step vs. 6000 KB for the
      proc sort step) on the computer they were tested on;
    data frpm1415_and_frpm1516_v1;
        retain
            Year
            CDS_Code
            School_Name
            District_Name
            Percent_Eligible_FRPM_K12_1415
            Percent_Eligible_FRPM_K12_1516
        ;
        keep
            Year
            CDS_Code
            School_Name
            District_Name
            Percent_Eligible_FRPM_K12_1415
            Percent_Eligible_FRPM_K12_1516
        ;
        label
            Percent_Eligible_FRPM_K12_1415=" "
            Percent_Eligible_FRPM_K12_1516=" "
        ;
        length    
            Year $9.
            CDS_Code $14.
            District_Name $75.
        ;
        set
            frpm1516(
                in = ay2015_data_row
                rename = (
                    District_Name = District_Name_1516
                    Percent_Eligible_FRPM_K12 = Percent_Eligible_FRPM_K12_1516
                )
            )
            frpm1415(
                rename = (
                    District_Name = District_Name_1415
                    Percent_Eligible_FRPM_K12 = Percent_Eligible_FRPM_K12_1415
                )
            )
        ;
        by
            County_Code
            District_Code
            School_Code
        ;

        CDS_Code = cats(County_Code,District_Code,School_Code);

        if
            ay2015_data_row=1
        then
            do;
                Year = "AY2015-16";
                District_Name = District_Name_1516;
            end;
        else
            do;
                Year = "AY2014-15";
                District_Name = District_Name_1415;
            end;
    run;
    proc sort data=frpm1415_and_frpm1516_v1;
        by CDS_Code Year;
    run;


    * combine frpm1415 and frpm1516 vertically using proc sql;
    * note: After running the proc sql step below several times and averaging
      the fullstimer output in the system log, they tend to take about 0.04
      seconds of "real time" to execute and about 9 MB of memory on the computer
      they were tested on. Consequently, the proc sql step appears to take roughly
      half as much time to execute as the combined data step and proc sort steps
      above, but to use slightly more memory;
    * note to learners: Based upon these results, the proc sql step is preferable
      if memory performance isn't critical. This is because less code is required,
      so it's faster to write and verify correct output has been obtained. In
      addition, because proc sql doesn't create a PDV with the length of each
      column determined by the column's first appearance, less care is needed for
      issues like columns lengths being different in the input datasets. In
      particular, the length of District_Name in frpm1516 is less than the length
      of District_Name in frpm1415. This means a "drop and swap" must be used in
      the data-step version in order to keep values of District_Name in frpm1415
      from being truncated;
    proc sql;
        create table frpm1415_and_frpm1516_v2 as
            (
                select
                     "AY2014-15"
                     AS
                     Year
                    ,cats(County_Code,District_Code,School_Code)
                     AS CDS_Code
                     length 14
                    ,School_Name
                    ,District_Name
                    ,Percent_Eligible_FRPM_K12
                     AS Percent_Eligible_FRPM_K12_1415
                     label " "
                from
                    frpm1415
            )
            outer union corr
            (
                select
                     "AY2015-16"
                     AS
                     Year
                    ,cats(County_Code,District_Code,School_Code)
                     AS CDS_Code
                     length 14
                    ,School_Name
                    ,District_Name
                    ,Percent_Eligible_FRPM_K12
                     AS Percent_Eligible_FRPM_K12_1516
                     label " "
                from
                    frpm1516
            )
            order by
                 CDS_Code
                ,Year
        ;
    quit;


    * verify that frpm1415_and_frpm1516_v1 and frpm1415_and_frpm1516_v2 are
      identical;
    proc compare
            base=frpm1415_and_frpm1516_v1
            compare=frpm1415_and_frpm1516_v2
            novalues
        ;
    run;
*/
