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
version 17

syntax anything,  ///
       [reshapevar(name max=1) rawdata(string) outdata(string)    ///
        download select(string asis) timeselect(string asis) ///
        nosave erase strrec dollar(string) ///
        compress(string) decompress(string) /*undocumented*/ ///
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

if "`debug'"!="" {
  timer clear
  timer on 1
}

local check0 : word count `anything'
if `check0'!=1 {
  di in red "Specify only one DBNAME"
  exit
}

**! DOWNLOAD !**
if "`download'"!="" {
  if "`debug'"!="" timer on 10
  di "I'm downloading the file..."
  if strmatch("`anything'","DS-*") qui capture copy "https://ec.europa.eu/eurostat/api/comext/dissemination/sdmx/2.1/data/`anything'/?format=TSV" "`rawdata'`anything'.tsv", replace
  else qui capture copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`anything'`macval(dollar)'/?format=TSV" "`rawdata'`anything'`D'.tsv", replace

  if _rc==631 {
    sleep 60000
    if strmatch("`anything'","DS-*") qui capture copy "https://ec.europa.eu/eurostat/api/comext/dissemination/sdmx/2.1/data/`anything'/?format=TSV" "`rawdata'`anything'.tsv", replace
    else qui copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`anything'`macval(dollar)'/?format=TSV" "`rawdata'`anything'`D'.tsv", replace
  }
  if _rc==601 {
    di "`anything'`macval(dollar)' not found in https://ec.europa.eu/eurostat site"
    exit
  }

  if "`debug'"!="" {
    timer off 10
    timer list 10
    di _newline
  }
}

**! IMPORT !**
di "I'm importing data..."
if "`debug'"!="" timer on 11
qui import delimited "`rawdata'`anything'`D'.tsv", varnames(1) delimiter(tab) clear stringcols(_all)
if "`debug'"!="" {
  timer off 11
  timer list 11
  di _newline
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
  timer list 12
  di _newline
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
  qui replace `reshapevar'="GRW_EMPtmp1" if `reshapevar'=="GRW_EMP_SALGE1_SRVL_CHB_PC"
  qui replace `reshapevar'="GRW_EMPtmp2" if `reshapevar'=="GRW_EMP_SALGE1_SRVL_Y3_PC"
}

di "I'm reshaping wide..."
qui drop if `reshapevar'==""
if "`debug'"!="" timer on 13
qui greshape wide `index'@, by(`widevars' `tmpdt') keys(`reshapevar')
if "`debug'"!="" {
  timer off 13
  timer list 13
  di _newline
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
  capture rename GRW_EMPtmp1 GRW_EMP_SALGE1_SRVL_CHB_PC
  capture rename GRW_EMPtmp2 GRW_EMP_SALGE1_SRVL_Y3_PC
}

**! DESTRING !**
if "`destring'"=="" {
  capture label drop __labmiss
  label define __labmiss .a "not available" ///
                         .b "break in time series" ///
                         .c "confidential" ///
                         .d "definition differs" ///
                         .e "estimated" ///
                         .n "not significant" ///
                         .p "provisional" ///
                         .u "low reliability" ///
                         .z "not applicable"

  di "I'm destringing variables..."
  if "`debug'"!="" timer on 14
  foreach VtD of local VtoDESTR {
    qui replace `VtD' = ".a" if inlist(`VtD',": ",":","")
    qui replace `VtD' = ".b" if strmatch(lower(`VtD'),": b*")
    qui replace `VtD' = ".c" if strmatch(lower(`VtD'),": c*")
    qui replace `VtD' = ".d" if strmatch(lower(`VtD'),": d*")
    qui replace `VtD' = ".e" if strmatch(lower(`VtD'),": e*")
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
      label values `VtD' __labmiss
    }
  }

  if "`debug'"!="" {
      timer off 14
      timer list 14
      di _newline
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
    if "`varlab'"=="" di "Variable `V' without label in `anything'`macval(dollar)'"
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
  di in ye "Database: `anything'`macval(dollar)' `r(t1)' seconds."
}


end
exit
