# Stata Code

The completed dissertation analysis uses Stata 18 and `ppmlhdfe`.

## Scripts from the completed project

| Script | Purpose | Public-release action |
|---|---|---|
| `run_africa_gcc_ppml_revised.do` | Runs the revised UN DESA-BACI PPMLHDFE specifications for Africa-to-GCC and GCC-to-Africa exports. Reports current stock, lagged stock, migration-flow, origin/destination/year FE, origin-year/destination-year FE, and pair-FE robustness models. | Included as a sanitized public version; set the root macro before running. |
| `run_ppmlhdfe_worldbank_imf_wdi_decades.do` | Runs World Bank migration + IMF DOTS + WDI robustness models, including primary pooled models, decade-specific regressions, and stricter pair + origin-year + destination-year FE specifications. | Included as a sanitized public version; set the root macro before running. |

## Required Stata packages

```stata
ssc install ftools, replace
ssc install reghdfe, replace
ssc install ppmlhdfe, replace
ssc install estout, replace
```

## Run order

1. Run `run_africa_gcc_ppml_revised.do` after constructing or restoring the UN DESA-BACI PPML-ready datasets.
2. Run `run_ppmlhdfe_worldbank_imf_wdi_decades.do` after constructing or restoring the World Bank-IMF-WDI PPML-ready datasets.

The public repository should include code and metadata sufficient to reproduce results, but not restricted raw data.

