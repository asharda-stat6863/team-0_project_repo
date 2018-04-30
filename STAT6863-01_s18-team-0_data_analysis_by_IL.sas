*******************************************************************************;
**************** 80-character banner for column width reference ***************;
* (set window width to banner width to calibrate line length to 80 characters *;
*******************************************************************************;

* set relative file import path to current directory (using standard SAS trick);
X "cd ""%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))))""";

* load external file that will generate final analytic file;
%include '.\STAT6863-01_s18-team-0_data_preparation.sas';


*******************************************************************************;
* Research Question Analysis Starting Point;
*******************************************************************************;
*
Question: What are the top five schools that experienced the biggest increase
in "Percent (%) Eligible Free (K-12)" between AY2014-15 and AY2015-16?

Rationale: This should help identify schools to consider for new outreach based
upon increasing child-poverty levels.

Note: This compares the column "Percent (%) Eligible Free (K-12)" from frpm1415
to the column of the same name from frpm1516.

Limitations: Values of "Percent (%) Eligible Free (K-12)" equal to zero should
be excluded from this analysis, since they are potentially missing data values 
;

proc sql outobs=5;
    select
         School_Name
        ,District_Name
        ,sum(Percent_Eligible_FRPM_K12_1415)
         AS Percent_Eligible_FRPM_K12_1415
         format percent12.2
        ,sum(Percent_Eligible_FRPM_K12_1516)
         AS Percent_Eligible_FRPM_K12_1516
         format percent12.2
        ,(calculated Percent_Eligible_FRPM_K12_1516)
         -
         (calculated Percent_Eligible_FRPM_K12_1415)
         AS Percentage_Point_Increase
         format percent12.2
    from
        frpm1415_and_frpm1516_v2
    group by
         CDS_Code
        ,School_Name
        ,District_Name
    having
        calculated Percent_Eligible_FRPM_K12_1415 > 0
        and
        calculated Percent_Eligible_FRPM_K12_1516 > 0
    order by
        Percentage_Point_Increase desc
    ;
quit;


*******************************************************************************;
* Research Question Analysis Starting Point;
*******************************************************************************;
*
Question: Can "Percent (%) Eligible FRPM (K-12)" be used to predict the
proportion of high school graduates earning a combined score of at least 1500
on the SAT?

Rationale: This would help inform whether child-poverty levels are associated
with college-preparedness rates, providing a strong indicator for the types of
schools most in need of college-preparation outreach.

Note: This compares the column "Percent (%) Eligible Free (K-12)" from frpm1415
to the column PCTGE1500 from sat15.

Limitations: Values of "Percent (%) Eligible Free (K-12)" equal to zero should
be excluded from this analysis, since they are potentially missing data values,
and missing values of PCTGE1500 should also be excluded
;
* note to learners: Because the columns being compared in this research
  question don't appear together in the horizontal or vertical combinations
  created in the date-prep file, a "first pass" is made at finding a
  correlation by comparing the five-number summaries of the variables
  Percent_Eligible_FRPM_K12 and PCTGE1500 within each decile.
;

proc rank
        groups=10
        data=frpm1415
        out=frpm1415_ranked
    ;
    var Percent_Eligible_FRPM_K12;
    ranks Percent_Eligible_FRPM_K12_rank;
run;
proc means min q1 median q3 max data=frpm1415_ranked;
    class Percent_Eligible_FRPM_K12_rank;
    var Percent_Eligible_FRPM_K12;
run;

proc sql;
    create table sat15_cleaned as
        select
            input(PCTGE1500, best12.) as PCTGE1500
        from 
            sat15
    ;
quit;
proc rank
        groups=10
        data=sat15_cleaned
        out=sat15_cleaned_and_ranked
    ;
    var PCTGE1500;
    ranks PCTGE1500_rank;
run;
proc means min q1 median q3 max data=sat15_cleaned_and_ranked;
    class PCTGE1500_rank;
    var PCTGE1500;
run;


*******************************************************************************;
* Research Question Analysis Starting Point;
*******************************************************************************;
*
Question: What are the top ten schools were the number of high school graduates
taking the SAT exceeds the number of high school graduates completing UC/CSU
entrance requirements?

Rationale: This would help identify schools with significant gaps in
preparation specific for California's two public university systems, suggesting
where focused outreach on UC/CSU college-preparation might have the greatest
impact.

Note: This compares the column NUMTSTTAKR from sat15 to the column TOTAL from
gradaf15.

Limitations: Values of NUMTSTTAKR and TOTAL equal to zero should be excluded
from this analysis, since they are potentially missing data values
;

proc sql outobs=10;
    select
         School
        ,District
        ,Number_of_SAT_Takers /* NUMTSTTAKR from sat15 */
        ,Number_of_Course_Completers /* TOTAL from gradaf15 */
        ,Number_of_SAT_Takers - Number_of_Course_Completers
         AS Difference
        ,(calculated Difference)/Number_of_Course_Completers
         AS Percent_Difference format percent12.1
    from
        sat_and_gradaf15_v2
    where
        Number_of_SAT_Takers > 0
        and
        Number_of_Course_Completers > 0
    order by
        Difference desc
    ;
quit;
