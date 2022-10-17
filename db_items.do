clear all
set more off
cls

capture mkdir items
capture mkdir dic
**cd items

local itemslist : dir "items" files "*.tsv", respectcase
local nitems : word count `itemslist'
di `nitems'

foreach f of local itemslist {
  local item : subinstr local f "ESTAT_" ""
  local item : subinstr local item "_en.tsv" ""
  di "`item'"
  local item = lower("`item'")

  import delimited "items/`f'", clear encoding(UTF-8) stringcols(_all) delimiter(tab) varnames(nonames)

  **alcuni errori da correggere:
  if "`f'"=="ESTAT_INDIC_IN_en.tsv" replace v2=subinstr(v2,`"innovation""', "innovation",1)
  if "`f'"=="ESTAT_NET_SEG_en.tsv" replace v2=subinstr(v2,`"""', "'",.)

  qui describe
  assert r(k)==2
  duplicates report v1
  assert r(unique_value)==r(N)
  *! regola per avere nomi compatibili
  di "`f'"
  if "`f'" == "ESTAT_ICD10_en.tsv" {
    replace v1="C54__C55" if v1=="C54-C55"
    replace v1="F00__F03" if v1=="F00-F03"
    replace v1="G40__G41" if v1=="G40-G41"
  }
  if "`f'" == "ESTAT_LCSTRUCT_en.tsv" replace v1="D12__D4_MD5" if v1=="D12-D4_MD5"
  if "`f'" == "ESTAT_NACE_R1_en.tsv" {
    replace v1="C__E" if v1=="C-E"
    replace v1="L__Q" if v1=="L-Q"
  }
  if "`f'" == "ESTAT_NACE_R2_en.tsv" {
    replace v1="B06__B09" if v1=="B06-B09"
    replace v1="O__U" if v1=="O-U"
  }
  if "`f'" == "ESTAT_UNIT_en.tsv" replace v1="MIO__EUR__NSA" if v1=="MIO-EUR-NSA"

  **forse è un errore la presenza di _2000W01 dato che sono date
  if "`f'" == "ESTAT_TIME_en.tsv" drop if v1=="_2000W01"

  replace v1 = ustrtoname(v1,1)

  duplicates report v1
  assert r(unique_value)==r(N)

  gen labelvar = "cap label var " + v1 + `" ""' + v2 + `"""'

   **variable è una reserved word, quindi si rinomina in VARIABLE
  if "`item'"=="variable" local item VARIABLE
  outfile labelvar using "dic/labvar_`item'.do", replace noquote
}

exit

