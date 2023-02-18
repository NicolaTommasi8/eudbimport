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

**TODO#1 destring & label declarant in DS-*
**TODO#2 exclude *FLAG from destring (local VtoDESTR)  in DS-*


program eudbimport
version 17

syntax anything /*(min=1 max=1)*/,  ///
       [rawdata(string) outdata(string) reshapevar(name max=1)    ///
        download select(string asis) timeselect(string asis) ///
        nosave erase ///
        compress(string) decompress(string) /*undocumented*/ ///
        nodestring /*undocumented*/ ///
        debug /*undocumented*/ ]

**pay attention #1: local nodestring is destring
**pay attention #2: local nosave is save

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

**set tracedepth 1
if "`debug'"!="" {
  timer clear
  timer on 1
}

local check0 : word count `anything'
if `check0'!=1 {
  di in red "Specify only one DBNAME"
  exit
}



if "`download'"!="" {
  if "`debug'"!="" timer on 10
  di "I'm downloading the file..."
  if strmatch("`anything'","DS-*") qui capture copy "https://ec.europa.eu/eurostat/api/comext/dissemination/sdmx/2.1/data/`anything'/?format=TSV" "`rawdata'`anything'.tsv", replace
  else qui capture copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`anything'/?format=TSV" "`rawdata'`anything'.tsv", replace
  if _rc==631 {
    sleep 60000
    if strmatch("`anything'","DS-*") qui capture copy "https://ec.europa.eu/eurostat/api/comext/dissemination/sdmx/2.1/data/`anything'/?format=TSV" "`rawdata'`anything'.tsv", replace
    else qui copy "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/`anything'/?format=TSV" "`rawdata'`anything'.tsv", replace
  }
  if _rc==601 {
    di "`anything' not found in https://ec.europa.eu/eurostat site"
    exit
  }


  if "`debug'"!="" {
    timer off 10
    timer list 10
    di _newline
  }
}
else {
  qui if "`c(os)'" == "Unix" shell 7zz e -y "`rawdata'`anything'.7z" -o`rawdata'
  else if "`c(os)'"== "Windows" qui shell "$E7z" e -y "`rawdata'`anything'.7z" -o`rawdata'
  else shell 7zz e -y "`rawdata'`anything'.7z" -o`rawdata' /*mac?*/
}

di "I'm importing data..."
if "`debug'"!="" timer on 11
qui import delimited "`rawdata'`anything'.tsv", varnames(1) delimiter(tab) clear stringcols(_all)
if "`debug'"!="" {
  timer off 11
  timer list 11
  di _newline
}

di _newline(1) "Database: `anything'"

**keep first var
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

**qui levelsof freq, local(freq) clean
qui glevelsof freq, local(freq)
local freq : list clean freq
tempname index

foreach V of varlist `vl' {
  local varlab : variable label `V'
  local varlab = trim("`varlab'")

  if wordcount("`freq_presel'")==1 & strlen("`freq'")==1 {
    if      "`freq'"=="M" local vn : subinstr local varlab "-" "m"
    else if "`freq'"=="Q" local vn : subinstr local varlab "-" "q"
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

**questo dopo è da togliere o da mettere sotto condizione debug
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

qui glevelsof `reshapevar', local(VtoDESTR)
local VtoDESTR : list clean VtoDESTR


if "`reshapevar'"=="na_item" {
  qui replace `reshapevar'="D2_D5_D91tmp1" if `reshapevar'=="D2_D5_D91_D61_M_D611V_D612_M_M_D"
  qui replace `reshapevar'="D2_D5_D91tmp2" if `reshapevar'=="D2_D5_D91_D61_M_D612_M_D614_M_D9"
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



if "`destring'"=="" {
  di "I'm destringing variables..."
  if "`debug'"!="" timer on 14
  if strmatch("`anything'","DS-*") qui destring `VtoDESTR', replace ignore(",: CEHNRU") float
  else qui destring `VtoDESTR', replace ignore(",: bcdefnprsuz") float
  cap confirm numeric variable `VtoDESTR'
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

qui {
  include "`c(sysdir_plus)'e/eudbimport_labvar.do"
  tempfile labvarfile
  if strmatch("`anything'","DS-*") copy "https://raw.githubusercontent.com/NicolaTommasi8/eudbimport/main/dic/labvar_cxt_`reshapevar'.do" `labvarfile', replace
  else copy "https://raw.githubusercontent.com/NicolaTommasi8/eudbimport/main/dic/labvar_`reshapevar'.do" `labvarfile', replace
  include `labvarfile'
  capture drop `tmpdt'
  compress
  if "`save'"=="" save `outdata'`anything', replace
  if "`erase'"!=""  erase `rawdata'`anything'.tsv
}


if "`debug'"!="" {
  describe
  summarize

  qui ds
  foreach V in `r(varlist)' {
    local varlab : variable label `V'
    if "`varlab'"=="" di "variabile `V' senza label in `anything'"
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
}


end
exit
