clear all
set more off


capture mkdir data
capture mkdir data/raw_data
capture mkdir data/out_data

import delimited "Full_Items_List_EN.txt", clear varnames(1)

cd data/raw_data
drop in 1/1840
qui count
forvalues i=1/`r(N)' {
  local urltsv = datadownloadurltsv in `i'
  **local urlcsv = datadownloadurlcsv in `i'
  local filename = code  in `i'
  di "Download file `filename' - `i' of `r(N)'"
  copy "`urltsv'" `filename'.tsv, replace
  **copy "`urlcsv'" `filename'.csv, replace

  if "`c(os)'" == "Unix" shell 7zz a -t7z `filename'.7z `filename'.tsv  -mx9 -bb1
  else shell "$E7z" a -t7z `filename'.7z `filename'.tsv  -mx9 -bb1
  erase `filename'.tsv
}
cd ../..


exit

