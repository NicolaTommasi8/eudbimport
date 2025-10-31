*! version 2.2  Nicola Tommasi  07jan2025
*               download databases in compress format (.gz) --> new option compressed
*               Python required

*! version 2.1  Nicola Tommasi  03apr2024
*               ability to retrive database info --> new option info

*! version 2.0  Nicola Tommasi  28dec2023
*               ability to import database with $ in DBNAME (Type=EXTRACTION) --> new option dollar()
*               new missing's coding (__labmiss)

*! version 1.9  Nicola Tommasi  01mar2023
*               new option strrec: destring some variables (decl, freq, s_adj, sex ...)

*! version 1.8  Nicola Tommasi  13feb2023
*               ability to import prodcom data (DS-*) - experimental
*               some minor fix

*! version 1.7  Nicola Tommasi  03jan2023
*               prevent host not found error
*               prevent file not found error
*               tested all present db as of December 2023

*! version 1.6  Nicola Tommasi  21nov2022
*               error in variable labelling

*! version 1.5  Nicola Tommasi  02nov2022
*               add erase option
*               eudbimport_labvar.do not found error
*               error in elpased time calculation
*               minor changes
*! version 1.1b  Nicola Tommasi  26sep2022
*! version 1.0b  Nicola Tommasi  01sep2022

program eudbimport
version 17.0

syntax anything,  ///
       [reshapevar(name max=1) rawdata(string) outdata(string)    ///
        download select(string asis) timeselect(string asis) ///
        nosave erase strrec dollar(string) info compressed ///
        nodestring /*undocumented*/ ///
        debug /*undocumented*/ ]

**pay attention #1: local nodestring is destring
**pay attention #2: local nosave is save

set tracedepth 1

local D : subinstr local dollar "$" "_S_"

capture which fre
if _rc==111 {
  di in yellow "fre not installed.... installing..."
  ssc inst fre
}

capture which gtools
if _rc==111 {
  di in yellow "gtools not installed.... installing..."
  ssc inst gtools
}

capture which missings
if _rc==111 {
  di in yellow "missings not installed... installing..."
  ssc inst missings
}


local check0 : word count `anything'
if `check0'!=1 {
  di in red "Specify only one DBNAME"
  exit
}

if "`info'"== "info" {
  quietly {
    tempfile catalogue
    copy "https://ec.europa.eu/eurostat/api/dissemination/catalogue/toc/xml" `catalogue', replace
    import delimit `catalogue', delim("|||") bindquote(nobind) clear
    gen db=1 if strmatch(v1,`"*<nt:leaf type="table">"')
    replace db=2 if strmatch(v1,`"*<nt:leaf type="dataset">"')
    replace db=0 if strmatch(v1,`"*</nt:leaf>"')
    gen db_id=_n if db!=.
    carryforward db_id db, replace
    drop if db==0
    gen metainfo=1 if strmatch(v1,"*<nt:code>*") & db_id!=.
    gen metainfocode=regexs(1) if regexm(v1,`"<nt:code>([a-zA-Z0-9_-]+)"') & db_id!=.
    summ db_id if upper(metainfocode)==upper("`anything'")
    keep if db_id==r(min) /* a volte il db è presente + volte */
    replace metainfo=2 if strmatch(v1,`"*<nt:title language="en">*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:title language="en">(.*)</nt:title"') & db_id!=.
    replace metainfo=3 if strmatch(v1,`"*<nt:title language="fr">*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:title language="fr">(.*)</nt:title"') & db_id!=.
    replace metainfo=4 if strmatch(v1,`"*<nt:title language="de">*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:title language="de">(.*)</nt:title"') & db_id!=.
    replace metainfo=5 if strmatch(v1,`"*<nt:lastUpdate>*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:lastUpdate>([0-9\.]+)"') & db_id!=.
    replace metainfo=6 if strmatch(v1,`"*<nt:lastModified>*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:lastModified>([0-9\.]+)"') & db_id!=.
    replace metainfo=7 if strmatch(v1,`"*<nt:dataStart>*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:dataStart>([a-z A-Z0-9_-]+)"') & db_id!=.
    replace metainfo=8 if strmatch(v1,`"*<nt:dataEnd>*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:dataEnd>([a-z A-Z0-9_-]+)"') & db_id!=.
    replace metainfo=9 if strmatch(v1,`"*<nt:values>*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:values>([a-z A-Z0-9_-]+)"') & db_id!=.
    replace metainfo=10 if strmatch(v1,`"*<nt:metadata format="html">*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:metadata format="html">(.*)</nt:metadata"') & db_id!=.
    replace metainfo=11 if strmatch(v1,`"*<nt:metadata format="sdmx">*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:metadata format="sdmx">(.*)</nt:metadata"') & db_id!=.
    replace metainfo=12 if strmatch(v1,`"*<nt:downloadLink format="tsv">*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:downloadLink format="tsv">(.*)</nt:downloadLink"') & db_id!=.
    replace metainfo=13 if strmatch(v1,`"*<nt:downloadLink format="sdmx">*"') & db_id!=.
    replace metainfocode=regexs(1) if regexm(v1,`"<nt:downloadLink format="sdmx">(.*)</nt:downloadLink"') & db_id!=.
    drop if metainfo==.
    drop v1 db
    reshape wide metainfocode, i(db_id) j(metainfo)
    capture local endesc = metainfocode2 in 1
    capture local frdesc = metainfocode3 in 1
    capture local dedesc = metainfocode4 in 1
    capture local lastup = metainfocode5 in 1
    capture local lastmod = metainfocode6 in 1
    capture local start = metainfocode7 in 1
    capture local end = metainfocode8 in 1
    capture local values = metainfocode9 in 1 /*?*/
    capture local values : display %15.0fc `values'
    capture local metahtml = metainfocode10 in 1
    capture local metasdmx = metainfocode11 in 1
    capture local downtsv = metainfocode12 in 1
    capture local downsdmx = metainfocode13 in 1
  }
  di "{bf:Database}: `anything'"
  di "{bf:EN desc}: `endesc'"
  di "{bf:FR desc}: `frdesc'"
  di "{bf:DE desc}: `dedesc'"
  di "{bf:Last Update}: `lastup'"
  di "{bf:Last Modified}: `lastmod'"
  di "{bf:Data Start}: `start'"
  di "{bf:Data end}: `end'"

  di "{bf:Values}: `values'"
  if "`metahtml'"=="" di as txt `"{bf:Metadata in html}: n.a. "'
  else di as txt `"{bf:Metadata in html}: {ul:{bf:{browse `"`metahtml'"':`metahtml'}}} "'

  if "`metasdmx'"=="" di as txt `"{bf:Metadata in sdmx}: n.a. "'
  else di as txt `"{bf:Metadata in sdmx}: {ul:{bf:{browse `"`metasdmx'"':`metasdmx'}}} "'

  if "`downtsv'"=="" di as txt `"{bf:Download in tsv format}: n.a. "'
  else di as txt `"{bf:Download in tsv format}: {ul:{bf:{browse `"`downtsv'"':`downtsv'}}} "'

  if "`downsdmx'"=="" di as txt `"{bf:Download in sdmx format}: n.a. "'
  else di as txt `"{bf:Download in sdmx format}: {ul:{bf:{browse `"`downsdmx'"':`downsdmx'}}} "'

  di _newline(2)
  **return
  qui erase `catalogue'
  **qui clear
}

if "`debug'"!="" {
  timer clear
  timer on 1
}

**! DOWNLOAD !**
if "`download'"!="" {
  if "`debug'"!="" timer on 10
  di "I'm downloading the file..."


  if "`compressed'"=="" {
    if strmatch("`anything'","DS-*") qui capture copy "https://ec.europa.eu/eurostat/api/comext/dissemination/sdmx/2.1/data/`anything'/?format=TSV&compressed=false" "`rawdata'`anything'.tsv", replace
    else qui capture copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`anything'`macval(dollar)'/?format=TSV&compressed=false" "`rawdata'`anything'`D'.tsv", replace

    if _rc==631 {
      sleep 60000
      if strmatch("`anything'","DS-*") qui capture copy "https://ec.europa.eu/eurostat/api/comext/dissemination/sdmx/2.1/data/`anything'/?format=TSV&compressed=false" "`rawdata'`anything'.tsv", replace
      else qui copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`anything'`macval(dollar)'/?format=TSV&compressed=false" "`rawdata'`anything'`D'.tsv", replace
    }
    if _rc==601 {
      di "`anything'`macval(dollar)' not found in https://ec.europa.eu/eurostat site"
      exit
    }
  }


  else {
    if strmatch("`anything'","DS-*") qui capture copy "https://ec.europa.eu/eurostat/api/comext/dissemination/sdmx/2.1/data/`anything'/?format=TSV&compressed=true" "`rawdata'`anything'.gz", replace
    else qui capture copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`anything'`macval(dollar)'/?format=TSV&compressed=true" "`rawdata'`anything'`D'.gz", replace

    if _rc==631 {
      sleep 60000
      if strmatch("`anything'","DS-*") qui capture copy "https://ec.europa.eu/eurostat/api/comext/dissemination/sdmx/2.1/data/`anything'/?format=TSV&compressed=true" "`rawdata'`anything'.gz", replace
      else qui copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`anything'`macval(dollar)'/?format=TSV&compressed=true" "`rawdata'`anything'`D'.gz", replace
    }
    if _rc==601 {
      di "`anything'`macval(dollar)' not found in https://ec.europa.eu/eurostat site"
      exit
    }
    python: gzextract(r"`rawdata'`anything'`D'.gz",r"`rawdata'`anything'`D'.tsv")
    capture erase "`rawdata'`anything'`D'.gz"
  }

  if "`debug'"!="" {
    timer off 10
    qui timer list 10
    local t_down : display %8.3f `r(t10)'
    **di _newline
  }
}

**! IMPORT !**
di "I'm importing data..."
if "`debug'"!="" timer on 11
qui import delimited "`rawdata'`anything'`D'.tsv", varnames(1) delimiter(tab) clear stringcols(_all)
if "`debug'"!="" {
  timer off 11
  qui timer list 11
  local t_imp : display %8.3f `r(t11)'
  **di _newline
}
di _newline(1) "Database: `anything'`macval(dollar)'"

**! KEEP TIME VAR (FREQ) !**
qui ds
local first_var : word 1 of `r(varlist)'
qui split `first_var', generate(ind_) parse(",")
local nind = `r(k_new)'
local splitvars: variable label `first_var'
**discard after \
local splitvars : subinstr local splitvars "," " ", all
local splitvars : subinstr local splitvars "\" " "
if strmatch("`splitvars'","* variable *") local splitvars : subinstr local splitvars "variable" "VARIABLE", word

forvalues j=1/`nind' {
  local varname : word `j' of `splitvars'
  rename ind_`j' `varname'
}

**clean splitvars
local lastvar : word `++nind' of `splitvars'
local splitvars : list splitvars - lastvar
di as result "Selection's variables: `splitvars'"
drop `first_var'

qui glevelsof freq, local(freq_presel)
local freq_presel : list clean freq_presel

if `"`select'"'!="" qui `select'

**elenco delle altre variabili
qui ds
local vl = "`r(varlist)'"
local vl : list vl - splitvars

qui glevelsof freq, local(freq) clean
tempname index

foreach V of varlist `vl' {
  local varlab : variable label `V'
  local varlab = trim("`varlab'")

  if wordcount("`freq_presel'")==1 & strlen("`freq'")==1 {
    if      "`freq'"=="M" local vn : subinstr local varlab "-" "m"
    **else if "`freq'"=="Q" local vn : subinstr local varlab "-" "q"
    else if "`freq'"=="Q" local vn : subinstr local varlab "-Q" "q"
    else if "`freq'"=="S" local vn : subinstr local varlab "-S" "h"
    else if "`freq'"=="W" local vn : subinstr local varlab "-W" "w"
    else if "`freq'"=="D" local vn : subinstr local varlab "-" "", all
    else if "`freq'"=="A" local vn `varlab' /**per freq=A non serve fare nulla**/

   rename `V' `index'`vn'
  }

  else if wordcount("`freq_presel'")>=2 & strlen("`freq'")>=2 {
    local vn  Y`varlab'
    if regexm("`varlab'","[0-9][0-9][0-9][0-9]-[0-9][0-9]")   local vn : subinstr local vn "-" "M"
    if regexm("`varlab'","[0-9][0-9][0-9][0-9]-Q[0-9]")  local vn : subinstr local vn "-Q" "Q"
    if regexm("`varlab'","[0-9][0-9][0-9][0-9]-S[0-9]")  local vn : subinstr local vn "-S" "H"
    if regexm("`varlab'","[0-9][0-9][0-9][0-9]-W[0-9][0-9]")  local vn : subinstr local vn "-W" "W"
    if regexm("`varlab'","[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]") { /** not tested */
      local vn : subinstr local vn "-" "M"
      local vn : subinstr local vn "-" "D"
    }
   rename `V' `index'`vn'
  }

  else if wordcount("`freq_presel'")>=2  & strlen("`freq'")==1 {
    if "`freq'"=="M" {
      if regexm("`varlab'","[0-9][0-9][0-9][0-9]-[0-9][0-9]") {
        local vn : subinstr local varlab "-" "m"
        rename `V' `index'`vn'
      }
      else drop `V'
    }
    else if "`freq'"=="Q" {
      if regexm("`varlab'","[0-9][0-9][0-9][0-9]-Q[0-9]") {
        local vn : subinstr local varlab "-Q" "q"
        rename `V' `index'`vn'
      }
      else drop `V'
    }
    else if "`freq'"=="A" {
      if regexm("`varlab'","[0-9][0-9][0-9][0-9]$") {
        rename `V' `index'`varlab'
      }
      else drop `V'
    }
    else if "`freq'"=="S" {
      if regexm("`varlab'","[0-9][0-9][0-9][0-9]-S[0-9]$") {
        local vn : subinstr local varlab "-S" "h"
        rename `V' `index'`vn'
      }
      else drop `V'
    }
    else if "`freq'"=="W" {
      if regexm("`varlab'","[0-9][0-9][0-9][0-9]-W[0-9][0-9]$") {
        local vn : subinstr local varlab "-W" "w"
        rename `V' `index'`vn'
      }
      else drop `V'
    }
    else if "`freq'"=="D" {
      if regexm("`varlab'","[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$") {
        local vn : subinstr local varlab "-" "", all
        rename `V' `index'`vn' /*qui trova maniera di indicare che la cosa da cercare è esattamente una stringa con soli 4 numeri*/
      }
      else drop `V'
    }
  }
}
di as result "Time Period: `freq'"

**! RESHAPE LONG !**
**questo dopo è da togliere o da mettere sotto condizione debug, serve x non dover indicare una reshapevar x forza
if "`reshapevar'"=="" {
  local n_splitvars : word count `splitvars'
  local varsel = runiformint(2,`n_splitvars')
  local reshapevar : word `varsel' of `splitvars'
}
di as result "Reshape variable: `reshapevar'"
local widevars : list splitvars - reshapevar
**qui replace `reshapevar' = subinstr(`reshapevar',"-","__",.)

di "I'm reshaping long..."
tempvar tmpdt

if "`timeselect'"!="" {
  if strlen("`timeselect'")==4 keep `splitvars' `index'`timeselect'*
  else {
    local timeselect `index'`timeselect'
    local timeselect = subinstr("`timeselect'","-","-`index'",1)
    keep `splitvars' `timeselect'
  }
}

if "`debug'"!="" timer on 12
qui greshape long `index'@, by(`splitvars') keys(`tmpdt') string
if "`debug'"!="" {
  timer off 12
  qui timer list 12
  local r_long : display %8.3f `r(t12)'
  **di _newline
}

**! RESHAPE WIDE !**
qui {
  if "`reshapevar'" == "icd10" {
    replace `reshapevar'="C54__C55" if `reshapevar'=="C54-C55"
    replace `reshapevar'="F00__F03" if `reshapevar'=="F00-F03"
    replace `reshapevar'="G40__G41" if `reshapevar'=="G40-G41"
  }
  if "`reshapevar'" == "lcstruct" replace `reshapevar'="D12__D4_MD5" if `reshapevar'=="D12-D4_MD5"
  if "`reshapevar'" == "nace_r1" {
    replace `reshapevar'="C__E" if `reshapevar'=="C-E"
    replace `reshapevar'="L__Q" if `reshapevar'=="L-Q"
  }
  if "`reshapevar'" == "nace_r2" {
    replace `reshapevar'="B06__B09" if `reshapevar'=="B06-B09"
    replace `reshapevar'="O__U" if `reshapevar'=="O-U"
  }

  **forse è un errore la presenza di _2000W01 dato che sono date
  if "`reshapevar'" == "time" drop if `reshapevar'=="_2000W01"
  if "`reshapevar'" == "unit" replace `reshapevar'="MIO__EUR__NSA" if `reshapevar'=="MIO-EUR-NSA"
  replace `reshapevar' = ustrtoname(`reshapevar',1)
}
qui replace `reshapevar' = subinstr(`reshapevar',"-","__",.)

 /* le variabili *FLAG dei databases DS-* non possono essere convertite in numeriche */
qui glevelsof `reshapevar' if strmatch(`reshapevar',"*FLAG")!=1, local(VtoDESTR) clean
**anche la variabile QNTUNIT dei databases DS-* non può essere convertita in numerica
local VtoDESTR : subinstr local VtoDESTR " QNTUNIT" "", all

if "`reshapevar'"=="na_item" {
  qui replace `reshapevar'="D2_D5_D91tmp1" if `reshapevar'=="D2_D5_D91_D61_M_D611V_D612_M_M_D"
  qui replace `reshapevar'="D2_D5_D91tmp2" if `reshapevar'=="D2_D5_D91_D61_M_D612_M_D614_M_D9"
}
if "`reshapevar'"=="indic_sbs" {
  qui replace `reshapevar'="EMP_SALGEtmp1" if `reshapevar'=="EMP_SALGE1_SRVL_YBRTH_CHB_NR"
  qui replace `reshapevar'="EMP_SALGEtmp2" if `reshapevar'=="EMP_SALGE1_SRVL_YBRTH_Y3_NR"
  qui replace `reshapevar'="ENT_SALGEtmp1" if `reshapevar'=="ENT_SALGE1_BRTH_EMPSIZE_NR"
  qui replace `reshapevar'="ENT_SALGE_DTHtmp1" if `reshapevar'=="ENT_SALGE1_DTH_EMPSIZE_NR"
  qui replace `reshapevar'="ENT_SALGE_SRVtmp1" if `reshapevar'=="ENT_SALGE1_SRVLR_BRTH_CHB_PC"
  qui replace `reshapevar'="ENT_SALGE_SRVtmp2" if `reshapevar'=="ENT_SALGE1_SRVL_EMPSIZE_NR"
  qui replace `reshapevar'="ENT_SALGE_SRVtmp3" if `reshapevar'=="ENT_SALGE1_SRVL_EMPSIZE_Y3_NR"
  qui replace `reshapevar'="ENT_SALGE_SRVtmp4" if `reshapevar'=="ENT_SALGE1_SRVLR_BRTH_Y3_PC"
  qui replace `reshapevar'="GRW_EMPtmp1" if `reshapevar'=="GRW_EMP_SALGE1_SRVL_CHB_PC"
  qui replace `reshapevar'="GRW_EMPtmp2" if `reshapevar'=="GRW_EMP_SALGE1_SRVL_Y3_PC"
}
if "`reshapevar'"=="offer" {
  qui replace `reshapevar'="FI_MBPStmp1" if `reshapevar'=="FI_MBPS12_30_PS1C30GB1"
  qui replace `reshapevar'="FI_MBPStmp2" if `reshapevar'=="FI_MBPS30_100_PS1C30GB1"
  qui replace `reshapevar'="FI_MBPStmp3" if `reshapevar'=="FI_MBPS30_100_PS2C100GB2"
  qui replace `reshapevar'="FI_MBPStmp4" if `reshapevar'=="FI_MBPS30_100_PS1C30GB5"
  qui replace `reshapevar'="FI_MBPStmp5" if `reshapevar'=="FI_MBPS100_200_PS1C30GB5"
  qui replace `reshapevar'="FI_MBPStmp6" if `reshapevar'=="FI_MBPS100_200_PS1C100GB2"
  qui replace `reshapevar'="FI_MBPStmp7" if `reshapevar'=="FI_MBPS100_200_PS1C300GB5"
  qui replace `reshapevar'="FI_MBPStmp8" if `reshapevar'=="FI_MBPS100_200_PS2C100GB10"
  qui replace `reshapevar'="FI_MBPStmp9" if `reshapevar'=="FI_MBPS200_999_PS1C100GB10"
  qui replace `reshapevar'="FI_MBPStmp10" if `reshapevar'=="FI_MBPS200_999_PS1C300GB20"
  qui replace `reshapevar'="FI_MBPStmp11" if `reshapevar'=="FI_MBPS30_100_PS1C100GB2TV"
  qui replace `reshapevar'="FI_MBPStmp12" if `reshapevar'=="FI_MBPS100_200_PS1C300GB5TV"
  qui replace `reshapevar'="FI_MBPStmp13" if `reshapevar'=="FI_MBPS100_200_PS2C300GB5TV"
  qui replace `reshapevar'="FI_MBPStmp14" if `reshapevar'=="FI_MBPS100_200_PS1C100GB10TV"
  qui replace `reshapevar'="FI_MBPStmp15" if `reshapevar'=="FI_MBPS_GT200_PS1C300GB5TV"
  qui replace `reshapevar'="FI_MBPStmp16" if `reshapevar'=="FI_MBPS200_999_PS1C300GB20TV"
  qui replace `reshapevar'="FI_MBPStmp17" if `reshapevar'=="FI_MBPS200_999_PS2C300GB20TV"
  qui replace `reshapevar'="FI_GBPStmp1" if `reshapevar'=="FI_GBPS_GE1_PS1C300GB20TV"
}
if "`reshapevar'"=="acl18" {
  qui replace `reshapevar'="AC711_712tmp1" if `reshapevar'=="AC711_712_719_731_732_739"
}

di "I'm reshaping wide..."
qui drop if `reshapevar'==""
if "`debug'"!="" timer on 13
qui greshape wide `index'@, by(`widevars' `tmpdt') keys(`reshapevar')
if "`debug'"!="" {
  timer off 13
  qui timer list 13
  local r_wide : display %8.3f `r(t13)'
**  di _newline
}
qui rename `index'* *
if "`reshapevar'"=="na_item" {
  capture rename D2_D5_D91tmp1 D2_D5_D91_D61_M_D611V_D612_M_M_D
  capture rename D2_D5_D91tmp2 D2_D5_D91_D61_M_D612_M_D614_M_D9
}
if "`reshapevar'"=="indic_sbs" {
  capture rename EMP_SALGEtmp1 EMP_SALGE1_SRVL_YBRTH_CHB_NR
  capture rename EMP_SALGEtmp2 EMP_SALGE1_SRVL_YBRTH_Y3_NR
  capture rename ENT_SALGEtmp1 ENT_SALGE1_BRTH_EMPSIZE_NR
  capture rename ENT_SALGE_DTHtmp1 ENT_SALGE1_DTH_EMPSIZE_NR
  capture rename ENT_SALGE_SRVtmp1 ENT_SALGE1_SRVLR_BRTH_CHB_PC
  capture rename ENT_SALGE_SRVtmp2 ENT_SALGE1_SRVL_EMPSIZE_NR
  capture rename ENT_SALGE_SRVtmp3 ENT_SALGE1_SRVL_EMPSIZE_Y3_NR
  capture rename ENT_SALGE_SRVtmp4 ENT_SALGE1_SRVLR_BRTH_Y3_PC
  capture rename GRW_EMPtmp1 GRW_EMP_SALGE1_SRVL_CHB_PC
  capture rename GRW_EMPtmp2 GRW_EMP_SALGE1_SRVL_Y3_PC
}
if "`reshapevar'"=="offer" {
  qui capture rename FI_MBPStmp1  FI_MBPS12_30_PS1C30GB1
  qui capture rename FI_MBPStmp2  FI_MBPS30_100_PS1C30GB1
  qui capture rename FI_MBPStmp3  FI_MBPS30_100_PS2C100GB2
  qui capture rename FI_MBPStmp4  FI_MBPS30_100_PS1C30GB5
  qui capture rename FI_MBPStmp5  FI_MBPS100_200_PS1C30GB5
  qui capture rename FI_MBPStmp6  FI_MBPS100_200_PS1C100GB2
  qui capture rename FI_MBPStmp7  FI_MBPS100_200_PS1C300GB5
  qui capture rename FI_MBPStmp8  FI_MBPS100_200_PS2C100GB10
  qui capture rename FI_MBPStmp9  FI_MBPS200_999_PS1C100GB10
  qui capture rename FI_MBPStmp10 FI_MBPS200_999_PS1C300GB20
  qui capture rename FI_MBPStmp11 FI_MBPS30_100_PS1C100GB2TV
  qui capture rename FI_MBPStmp12 FI_MBPS100_200_PS1C300GB5TV
  qui capture rename FI_MBPStmp13 FI_MBPS100_200_PS2C300GB5TV
  qui capture rename FI_MBPStmp14 FI_MBPS100_200_PS1C100GB10TV
  qui capture rename FI_MBPStmp15 FI_MBPS_GT200_PS1C300GB5TV
  qui capture rename FI_MBPStmp16 FI_MBPS200_999_PS1C300GB20TV
  qui capture rename FI_MBPStmp17 FI_MBPS200_999_PS2C300GB20TV
  qui capture rename FI_GBPStmp1  FI_GBPS_GE1_PS1C300GB20TV
}
if "`reshapevar'"=="acl18" {
  qui capture rename AC711_712tmp1  AC711_712_719_731_732_739
}



**! DESTRING !**
if "`destring'"=="" {
  capture label drop __labmiss
  label define __labmiss .a "not available" ///
                         .b "break in time series" ///
                         .c "confidential" ///
                         .d "definition differs" ///
                         .e "estimated" ///
                         .m "missing value; data cannot exist" ///
                         .n "not significant" ///
                         .p "provisional" ///
                         .u "low reliability" ///
                         .z "not applicable"

  di "I'm destringing variables..."
  if "`debug'"!="" timer on 14
  foreach VtD of local VtoDESTR {
    qui replace `VtD' = ".a" if inlist(`VtD',": ",":","",": @C")
    qui replace `VtD' = ".b" if strmatch(lower(`VtD'),": b*")
    qui replace `VtD' = ".c" if strmatch(lower(`VtD'),": c*")
    qui replace `VtD' = ".d" if strmatch(lower(`VtD'),": d*")
    qui replace `VtD' = ".e" if strmatch(lower(`VtD'),": e*")
    qui replace `VtD' = ".m" if strmatch(lower(`VtD'),": m*")
    qui replace `VtD' = ".n" if strmatch(lower(`VtD'),": n*")
    qui replace `VtD' = ".p" if strmatch(lower(`VtD'),": p*")
    qui replace `VtD' = ".u" if strmatch(lower(`VtD'),": s*")
    qui replace `VtD' = ".u" if strmatch(lower(`VtD'),": u*") | strmatch(lower(`VtD'),":u*")
    qui replace `VtD' = ".z" if strmatch(lower(`VtD'),": z*")
    qui replace `VtD'=regexreplace(`VtD'," [a-z]+$","")
    qui count if strmatch(`VtD',"*high*")==1 | strmatch(`VtD',"*low*")==1
    if r(N)>0 {
      di "Some values in `VtD' variable aren't convertible in numeric, NO DESTRING"
      fre `VtD' if strmatch(`VtD',"*high*") | strmatch(`VtD',"*low*")
    }
    else {
      qui destring `VtD', replace
      confirm numeric variable `VtD'
      local frmt : format `VtD' /*preserve variable format after label values*/
      label values `VtD' __labmiss
      format `VtD' `frmt'
    }
  }

  if "`debug'"!="" {
      timer off 14
      qui timer list 14
      local t_dest : display %8.3f `r(t14)'
      **di _newline
  }
}
qui missings dropobs `VtoDESTR', force

qui {
  if "`freq'"=="D" {
    gen date = date(`tmpdt', "YMD")
    format date %td
  }
  else if "`freq'"=="W" {
    gen date = weekly(`tmpdt', "YW")
    format date %tw
  }
  else if "`freq'"=="M" {
    replace `tmpdt'=subinstr(`tmpdt',"`freq'","-",.)
    replace `tmpdt'=subinstr(`tmpdt',"Y","",1) /*by multitime selection*/
    gen date = monthly(`tmpdt', "Y`freq'")
    format date %tm
    drop if date==.  /*by multitime selection*/
  }
  else if "`freq'"=="Q" {
    gen date = quarterly(`tmpdt', "Y`freq'")
    replace `tmpdt'=subinstr(`tmpdt',"Y","",1) /*by multitime selection*/
    format date %tq
  }
  else if "`freq'"=="S" {
    gen date = halfyearly(`tmpdt', "YH")
    format date %th
  }
  else if "`freq'"=="A" {
    rename `tmpdt' date
    count if strmatch(date,"*_FLAG")
    if r(N)>0 {
      glevelsof date if strmatch(date,"*_FLAG"), local(VtoLAB)
      local VtoLAB : list clean VtoLAB
      local VtoLAB : subinstr local VtoLAB "_FLAG" ""
      replace date = "3000" if strmatch(date,"*_FLAG")
      capture destring date, replace ignore("Y")
      label define __date 3000 "`VtoLAB'"
      label values date __date
    }
    capture destring date, replace ignore("Y")
    format date %ty
  }

  else rename `tmpdt' date
}
if inlist("`freq'","M","Q","S","W","D") confirm numeric variable date
order `widevars' date

**! LABEL !**
qui {
  include "`c(sysdir_plus)'e/eudbimport_labvar.do" /*vars != reshapevar*/
  tempfile labvarfile
  if strmatch("`anything'`macval(dollar)'","DS-*") copy "https://raw.githubusercontent.com/NicolaTommasi8/eudbimport/main/dic/labvar_cxt_`reshapevar'.do" `labvarfile', replace
  else copy "https://raw.githubusercontent.com/NicolaTommasi8/eudbimport/main/dic/labvar_`reshapevar'.do" `labvarfile', replace
  include `labvarfile'
  capture drop `tmpdt'
  compress
  if "`save'"=="" save `outdata'`anything'`macval(dollar)', replace
  if "`erase'"!=""  erase `rawdata'`anything'`D'.tsv
}

**! INFOS !**
if "`debug'"!="" {
  **describe
  **summarize
  qui ds
  foreach V in `r(varlist)' {
    local varlab : variable label `V'
    if "`varlab'"=="" di as error "Variable `V' without label in `anything'`macval(dollar)'"
  }
  timer off 1
  **di _newline(2)
  qui timer list 1
  local minutes = int(`r(t1)'/60)
  local seconds = `r(t1)' - `minutes'*60
  local seconds = round(`seconds',1)
  if `minutes'>=60 {
    local hours=int(`minutes'/60)
    local minutes = `minutes' - `hours'*60
  }
  if "`hours'"=="" & "`minutes'"=="" di in ye "Elapsed time was `seconds' seconds."
  else if "`hours'"=="" & `minutes'<. di in ye "Elapsed time was `minutes' minutes, `seconds' seconds."
  else di in ye "Elapsed time was `hours' hours, `minutes' minutes, `seconds' seconds."
  **            dbname;time_download;time_import;resh_long;resh_wide;destring;time_total
  local t_tot : display %8.3f `r(t1)'
  di in ye "`anything'`macval(dollar)';`splitvars';`reshapevar';`t_down';`t_imp';`r_long';`r_wide';`t_dest';`t_tot'"
}


end


/*******
python:
import gzip
import shutil
with gzip.open('`rawdata'`anything'`D'.gz', 'rb') as f_in:
  with open('`rawdata'`anything'`D'.tsv', 'wb') as f_out:
    shutil.copyfileobj(f_in, f_out)
`end'
***************/

version 17.0
python:

import gzip
import shutil

def gzextract(filename: str, temp_file: str) -> None:
	with gzip.open(filename,'rb') as f_in:
		with open(temp_file,'wb') as f_out:
			shutil.copyfileobj(f_in,f_out)

end






exit
