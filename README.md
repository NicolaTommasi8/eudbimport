# eudbimport
A Stata package to import EUROSTAT databases

Example:

    eudbimport AVIA_GOEXCC, rawdata("data/raw_data/") outdata("data/out_data/") ///
      select(keep if freq=="A") nodestring reshapevar(tra_meas)
