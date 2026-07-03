/********************************************************************
Project: Revised UN DESA + BACI Africa-GCC gravity analysis
Purpose: Implement supervisor-requested PPMLHDFE specifications

This do-file uses the existing PPML-ready datasets. It does not rebuild
or alter the raw panel.

Main specifications:
  1-3. Origin FE + destination FE + year FE
  4-6. Origin-year FE + destination-year FE

Migration measures:
  - Current migrant stock: ln_migrants = ln(migrants + 1)
  - Lagged migrant stock: ln_L_migrants = ln(L_migrants + 1)
  - Change in migrant stock: delta_migrants = migrants_t - migrants_t-1

Appendix robustness:
  7. Pair FE + year FE using current migrant stock
********************************************************************/

version 18
clear all
set more off
set linesize 255

* Public replication note: set project_root to the cloned repository path before running.
global project_root "C:/path/to/africa-gcc-migration-trade"
global datadir "$project_root/data/processed"
global outdir  "$project_root/output/regression_tables"
global workdir "$project_root/output/intermediate"

capture mkdir "$outdir"
capture mkdir "$workdir"

capture log close
log using "$outdir/africa_gcc_ppml_revised.log", replace text

foreach command in ppmlhdfe esttab estadd {
    capture which `command'
    if _rc {
        di as error "`command' is required but is not installed."
        di as error "Install ppmlhdfe and the estout package before rerunning."
        exit 199
    }
}

capture program drop post_ppml_result
program define post_ppml_result
    syntax, direction(string) model(integer) specification(string) ///
        measure(string) fixedeffects(string) variable(name)

    tempname b se p n r2
    scalar `b' = _b[`variable']
    scalar `se' = _se[`variable']
    scalar `p' = 2 * normal(-abs(`b' / `se'))
    scalar `n' = e(N)
    capture scalar `r2' = e(r2_p)
    if _rc scalar `r2' = .

    post coeffs ("`direction'") (`model') ("`specification'") ///
        ("`measure'") ("`fixedeffects'") ("`variable'") ///
        (`b') (`se') (`p') (`n') (`r2')
end

postfile coeffs ///
    str30 trade_direction ///
    byte model_number ///
    str70 model_specification ///
    str30 migration_measure ///
    str45 fixed_effects ///
    str25 coefficient_variable ///
    double coefficient std_error p_value observations pseudo_r2 ///
    using "$workdir/africa_gcc_ppml_coefficient_summary.dta", replace

capture program drop run_direction
program define run_direction
    syntax, data(string) direction(string) tabletitle(string) outstem(string)

    use "$datadir/`data'.dta", clear

    * Confirm that the supplied file is already analysis-ready.
    assert ppml_ready == 1
    assert controls_ok == 1
    assert trade_val_usd >= 0
    assert migrants >= 0
    isid pair_id year

    * Trade origin and destination follow the direction of the dependent variable.
    encode exporter_iso3, gen(origin_id)
    encode importer_iso3, gen(destination_id)
    encode pair_id, gen(pair_cluster)

    label var origin_id "Trade origin country"
    label var destination_id "Trade destination country"
    label var pair_cluster "Africa-GCC country pair"

    * Previous observed UN DESA wave within each Africa-GCC pair.
    sort pair_cluster year
    by pair_cluster: gen double L_migrants = migrants[_n-1] if _n > 1
    by pair_cluster: gen double delta_migrants = migrants - migrants[_n-1] if _n > 1
    gen double ln_L_migrants = ln(L_migrants + 1) if !missing(L_migrants)

    * Numeric high-dimensional fixed-effect identifiers.
    egen long origin_year = group(origin_id year), label
    egen long destination_year = group(destination_id year), label

    label var trade_val_usd "BACI exports, USD"
    label var ln_migrants "Current migrant stock"
    label var L_migrants "Lagged migrant stock, previous observed wave"
    label var ln_L_migrants "Lagged migrant stock"
    label var delta_migrants "Change in migrant stock"
    label var origin_year "Origin-year fixed effect"
    label var destination_year "Destination-year fixed effect"

    assert abs(ln_migrants - ln(migrants + 1)) < 1e-10
    assert L_migrants >= 0 if !missing(L_migrants)
    assert !missing(ln_L_migrants) if !missing(L_migrants)

    di as txt "======================================================================"
    di as txt "`tabletitle'"
    di as txt "======================================================================"
    tab year
    summarize trade_val_usd migrants L_migrants ln_migrants ln_L_migrants delta_migrants

    estimates clear

    * Main specification 1: current stock; origin + destination + year FE.
    ppmlhdfe trade_val_usd ln_migrants, ///
        absorb(origin_id destination_id year) vce(cluster pair_cluster)
    estimates store M1
    estadd local migration_measure "Current migrant stock"
    estadd local fixed_effects "Origin + destination + year FE"
    post_ppml_result, direction("`direction'") model(1) ///
        specification("Current stock with origin, destination and year FE") ///
        measure("Current migrant stock") ///
        fixedeffects("Origin + destination + year FE") variable(ln_migrants)

    * Main specification 2: lagged stock; origin + destination + year FE.
    ppmlhdfe trade_val_usd ln_L_migrants, ///
        absorb(origin_id destination_id year) vce(cluster pair_cluster)
    estimates store M2
    estadd local migration_measure "Lagged migrant stock"
    estadd local fixed_effects "Origin + destination + year FE"
    post_ppml_result, direction("`direction'") model(2) ///
        specification("Lagged stock with origin, destination and year FE") ///
        measure("Lagged migrant stock") ///
        fixedeffects("Origin + destination + year FE") variable(ln_L_migrants)

    * Main specification 3: migration flow; origin + destination + year FE.
    ppmlhdfe trade_val_usd delta_migrants, ///
        absorb(origin_id destination_id year) vce(cluster pair_cluster)
    estimates store M3
    estadd local migration_measure "Change in migrant stock"
    estadd local fixed_effects "Origin + destination + year FE"
    post_ppml_result, direction("`direction'") model(3) ///
        specification("Migration flow with origin, destination and year FE") ///
        measure("Change in migrant stock") ///
        fixedeffects("Origin + destination + year FE") variable(delta_migrants)

    * Main specification 4: current stock; origin-year + destination-year FE.
    ppmlhdfe trade_val_usd ln_migrants, ///
        absorb(origin_year destination_year) vce(cluster pair_cluster)
    estimates store M4
    estadd local migration_measure "Current migrant stock"
    estadd local fixed_effects "Origin-year + destination-year FE"
    post_ppml_result, direction("`direction'") model(4) ///
        specification("Current stock with origin-year and destination-year FE") ///
        measure("Current migrant stock") ///
        fixedeffects("Origin-year + destination-year FE") variable(ln_migrants)

    * Main specification 5: lagged stock; origin-year + destination-year FE.
    ppmlhdfe trade_val_usd ln_L_migrants, ///
        absorb(origin_year destination_year) vce(cluster pair_cluster)
    estimates store M5
    estadd local migration_measure "Lagged migrant stock"
    estadd local fixed_effects "Origin-year + destination-year FE"
    post_ppml_result, direction("`direction'") model(5) ///
        specification("Lagged stock with origin-year and destination-year FE") ///
        measure("Lagged migrant stock") ///
        fixedeffects("Origin-year + destination-year FE") variable(ln_L_migrants)

    * Main specification 6: migration flow; origin-year + destination-year FE.
    ppmlhdfe trade_val_usd delta_migrants, ///
        absorb(origin_year destination_year) vce(cluster pair_cluster)
    estimates store M6
    estadd local migration_measure "Change in migrant stock"
    estadd local fixed_effects "Origin-year + destination-year FE"
    post_ppml_result, direction("`direction'") model(6) ///
        specification("Migration flow with origin-year and destination-year FE") ///
        measure("Change in migrant stock") ///
        fixedeffects("Origin-year + destination-year FE") variable(delta_migrants)

    * Appendix robustness: original pair FE + year FE approach.
    ppmlhdfe trade_val_usd ln_migrants, ///
        absorb(pair_cluster year) vce(cluster pair_cluster)
    estimates store M7
    estadd local migration_measure "Current migrant stock"
    estadd local fixed_effects "Pair FE robustness"
    post_ppml_result, direction("`direction'") model(7) ///
        specification("Current stock with pair and year FE; appendix robustness") ///
        measure("Current migrant stock") ///
        fixedeffects("Pair FE robustness") variable(ln_migrants)

    estimates table M1 M2 M3 M4 M5 M6 M7, b(%10.6f) se(%10.6f) stats(N)

    esttab M1 M2 M3 M4 M5 M6 M7 using "$outdir/`outstem'.rtf", ///
        replace rtf label compress ///
        keep(ln_migrants ln_L_migrants delta_migrants) ///
        order(ln_migrants ln_L_migrants delta_migrants) ///
        coeflabels(ln_migrants "Current migrant stock" ///
                   ln_L_migrants "Lagged migrant stock" ///
                   delta_migrants "Change in migrant stock") ///
        mtitles("Current stock" "Lagged stock" "Flow" ///
                "Current stock" "Lagged stock" "Flow" "Pair FE robustness") ///
        b(6) se(6) star(* 0.10 ** 0.05 *** 0.01) ///
        stats(N r2_p migration_measure fixed_effects, ///
              fmt(0 3) ///
              labels("Observations" "Pseudo R-squared" ///
                     "Migration measure" "Fixed effects")) ///
        title("`tabletitle': revised PPMLHDFE estimates") ///
        addnotes("Dependent variable: bilateral exports in current USD." ///
                 "Standard errors clustered by Africa-GCC country pair in parentheses." ///
                 "Models 1-6 are the main specifications; Model 7 is appendix robustness." ///
                 "Lag and change use the previous observed UN DESA migration-stock wave.")
end

run_direction, ///
    data("africa_to_gcc_exports_ppml") ///
    direction("Africa to GCC exports") ///
    tabletitle("Africa to GCC exports") ///
    outstem("ppml_africa_to_gcc_exports_revised")

run_direction, ///
    data("gcc_to_africa_exports_ppml") ///
    direction("GCC to Africa exports") ///
    tabletitle("GCC to Africa exports") ///
    outstem("ppml_gcc_to_africa_exports_revised")

postclose coeffs

use "$workdir/africa_gcc_ppml_coefficient_summary.dta", clear
format coefficient std_error p_value %12.8f
format observations %9.0f
format pseudo_r2 %9.4f
sort trade_direction model_number
export delimited using "$outdir/africa_gcc_ppml_coefficient_summary.csv", ///
    replace datafmt

di as result "All revised PPML models and outputs completed successfully."
log close
