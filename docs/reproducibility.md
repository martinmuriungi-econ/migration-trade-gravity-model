# Reproducibility Notes

The dissertation is designed for reproducible applied econometrics, with a separation between restricted data, code, and public outputs.

## 1. Obtain source data

Acquire the datasets listed in `data/README.md` and `docs/data_availability.md`. Store them locally under `data/raw/`. This folder is ignored by Git.

## 2. Prepare local paths

Use a local configuration file, for example:

```stata
global project_root "C:/path/to/africa-gcc-migration-trade"
global raw_data     "$project_root/data/raw"
global processed    "$project_root/data/processed"
global output       "$project_root/output"
```

Do not commit local path files.

## 3. Install Stata dependencies

```stata
ssc install ftools, replace
ssc install reghdfe, replace
ssc install ppmlhdfe, replace
ssc install estout, replace
```

## 4. Run analysis

Expected run order:

```text
code/stata/run_africa_gcc_ppml_revised.do
code/stata/run_ppmlhdfe_worldbank_imf_wdi_decades.do
```

## 5. Expected outputs

The main output files are listed in `output/regression_tables/README.md`.

## 6. Interpretation standard

The repository should describe results as associations estimated using demanding fixed-effect specifications. It should avoid language implying definitive causal effects unless supported by an explicit identification strategy.

