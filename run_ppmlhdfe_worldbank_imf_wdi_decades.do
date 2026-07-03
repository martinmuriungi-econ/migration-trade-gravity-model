clear all
set more off
version 18

* Public replication note: set ROOT to the cloned repository path before running.
global ROOT "C:/path/to/africa-gcc-migration-trade"
global IN   "$ROOT/data/processed"
global OUT  "$ROOT/output/regression_tables"

capture log close _all
log using "$OUT/worldbank_imf_wdi_decade_ppmlhdfe.log", replace text

display as text "World Bank migration + IMF DOTS + WDI decade robustness"
display as text "Run date: $S_DATE $S_TIME"

capture which ppmlhdfe
if _rc {
    display as error "ppmlhdfe is not installed. Install with: ssc install ppmlhdfe, replace"
    log close
    exit 499
}

capture which esttab
if _rc {
    display as error "esttab/estout is not installed. Install with: ssc install estout, replace"
    log close
    exit 499
}

tempname coeffs
postfile `coeffs' ///
    str30 direction ///
    str12 model_id ///
    str32 model_group ///
    str70 model_name ///
    str35 migrant_variable ///
    str70 fixed_effects ///
    int decade ///
    double coefficient std_error z_stat p_value ///
    str3 significance ///
    long n_obs ///
    str80 status ///
    using "$OUT/coefficient_summary_decades.dta", replace
global POSTH "`coeffs'"

capture program drop post_current
program define post_current
    syntax, DIRECTION(string) MODELID(string) MODELGROUP(string) ///
        MODELNAME(string) VARIABLE(string) FETYPE(string) [DECADE(integer -1)]

    local b = _b[`variable']
    local se = _se[`variable']
    local z = `b' / `se'
    local p = 2 * normal(-abs(`z'))
    local sig ""
    if `p' < 0.10 local sig "*"
    if `p' < 0.05 local sig "**"
    if `p' < 0.01 local sig "***"
    local n = e(N)
    local post_decade = cond(`decade' == -1, ., `decade')

    post $POSTH ///
        ("`direction'") ///
        ("`modelid'") ///
        ("`modelgroup'") ///
        ("`modelname'") ///
        ("`variable'") ///
        ("`fetype'") ///
        (`post_decade') ///
        (`b') (`se') (`z') (`p') ///
        ("`sig'") ///
        (`n') ///
        ("estimated")
end

capture program drop post_lincom
program define post_lincom
    syntax, DIRECTION(string) MODELID(string) MODELGROUP(string) ///
        MODELNAME(string) VARIABLE(string) FETYPE(string) DECADE(integer) NOBS(integer)

    local b = r(estimate)
    local se = r(se)
    local z = `b' / `se'
    local p = 2 * normal(-abs(`z'))
    local sig ""
    if `p' < 0.10 local sig "*"
    if `p' < 0.05 local sig "**"
    if `p' < 0.01 local sig "***"

    post $POSTH ///
        ("`direction'") ///
        ("`modelid'") ///
        ("`modelgroup'") ///
        ("`modelname'") ///
        ("`variable'") ///
        ("`fetype'") ///
        (`decade') ///
        (`b') (`se') (`z') (`p') ///
        ("`sig'") ///
        (`nobs') ///
        ("estimated")
end

foreach d in africa_to_gcc_exports gcc_to_africa_exports {
    if "`d'" == "africa_to_gcc_exports" {
        local direction "Africa_to_GCC_exports"
        local pretty "Africa -> GCC exports"
    }
    else {
        local direction "GCC_to_Africa_exports"
        local pretty "GCC -> Africa exports"
    }

    display as result "================================================================"
    display as result "`pretty'"
    display as result "================================================================"

    use "$IN/`d'_ppml_ready.dta", clear
    isid pair_id year, sort

    * Rebuild lags from migrant levels. A lag is valid only when the
    * immediately preceding retained benchmark is exactly ten years earlier.
    capture drop L_migrants ln_L_migrants L_ln_migrants delta_migrants decade
    by pair_id (year): gen double L_migrants = migrants[_n-1] ///
        if year - year[_n-1] == 10
    gen double ln_L_migrants = ln(L_migrants + 1) if !missing(L_migrants)
    gen double delta_migrants = migrants - L_migrants if !missing(L_migrants)
    gen int decade = year if inlist(year, 1970, 1980, 1990, 2000) ///
        & !missing(delta_migrants)

    label variable L_migrants "Migrant stock at preceding 10-year benchmark"
    label variable ln_L_migrants "ln(1 + preceding benchmark migrant stock)"
    label variable delta_migrants "Migrant stock change from preceding decade"
    label define decade_lbl ///
        1970 "1960-1970" ///
        1980 "1970-1980" ///
        1990 "1980-1990" ///
        2000 "1990-2000", replace
    label values decade decade_lbl

    egen long origin_id = group(exporter_code), label
    egen long destination_id = group(importer_code), label
    egen long origin_year = group(origin_id year)
    egen long destination_year = group(destination_id year)

    quietly count
    display as text "Input observations: " r(N)
    quietly count if !missing(L_migrants)
    display as text "Valid exact-decade lags/changes: " r(N)
    tabulate decade, missing
    summarize migrants L_migrants delta_migrants trade_val_usd, detail

    local controls "ln_gdp_africa ln_gdp_gcc ln_pop_africa ln_pop_gcc"
    local basefe "origin_id destination_id year"
    local strictfe "pair_id origin_year destination_year"
    local primary_models ""
    local decade_models ""
    local strict_models ""

    eststo clear

    * P1. Pooled benchmark-year stock model with WDI controls.
    capture noisily ppmlhdfe trade_val_usd ln_migrants `controls', ///
        absorb(`basefe') cluster(pair_id)
    if !_rc {
        eststo p1
        local primary_models "`primary_models' p1"
        post_current, direction("`direction'") modelid("P1") ///
            modelgroup("Primary") ///
            modelname("Pooled benchmark-year stock") ///
            variable("ln_migrants") ///
            fetype("Origin FE + destination FE + year FE")
    }
    else display as error "P1 failed for `pretty'; return code " _rc

    * P2. Lagged migrant-stock model.
    capture noisily ppmlhdfe trade_val_usd ln_L_migrants `controls' ///
        if !missing(ln_L_migrants), absorb(`basefe') cluster(pair_id)
    if !_rc {
        eststo p2
        local primary_models "`primary_models' p2"
        post_current, direction("`direction'") modelid("P2") ///
            modelgroup("Primary") ///
            modelname("Lagged migrant stock") ///
            variable("ln_L_migrants") ///
            fetype("Origin FE + destination FE + year FE")
    }
    else display as error "P2 failed for `pretty'; return code " _rc

    * P3. Decadal migration-flow model.
    capture noisily ppmlhdfe trade_val_usd delta_migrants `controls' ///
        if !missing(delta_migrants), absorb(`basefe') cluster(pair_id)
    if !_rc {
        eststo p3
        local primary_models "`primary_models' p3"
        post_current, direction("`direction'") modelid("P3") ///
            modelgroup("Primary") ///
            modelname("Pooled decadal migrant change") ///
            variable("delta_migrants") ///
            fetype("Origin FE + destination FE + year FE")
    }
    else display as error "P3 failed for `pretty'; return code " _rc

    * P4. Pooled decade interaction model. The 1960-1970 cell is excluded
    * because only 66 eligible rows survive and separate PPML cannot identify
    * that decade after fixed effects/separation. Full-slope coding avoids an
    * arbitrary omitted slope for the estimable 1980, 1990, and 2000 decades.
    capture noisily ppmlhdfe trade_val_usd ///
        ibn.decade#c.delta_migrants `controls' ///
        if inlist(decade, 1980, 1990, 2000), ///
        absorb(`basefe') cluster(pair_id)
    if !_rc {
        eststo p4
        local primary_models "`primary_models' p4"
        local p4n = e(N)

        foreach k in 1980 1990 2000 {
            capture noisily lincom `k'.decade#c.delta_migrants
            if !_rc {
                post_lincom, direction("`direction'") ///
                    modelid("P4_`k'") ///
                    modelgroup("Interaction") ///
                    modelname("Interaction slope: change ending `k'") ///
                    variable("delta_migrants") ///
                    fetype("Origin FE + destination FE + year FE") ///
                    decade(`k') nobs(`p4n')
            }
            else display as error "P4 lincom failed for `pretty', decade `k'"
        }
    }
    else display as error "P4 failed for `pretty'; return code " _rc

    * D models. Separate cross-sectional PPML for each completed decade.
    foreach k in 1970 1980 1990 2000 {
        quietly count if decade == `k'
        local eligible_n = r(N)
        capture noisily ppmlhdfe trade_val_usd delta_migrants ///
            if decade == `k', absorb(origin_id destination_id) ///
            cluster(pair_id)
        if !_rc {
            eststo d`k'
            local decade_models "`decade_models' d`k'"
            post_current, direction("`direction'") ///
                modelid("D`k'") ///
                modelgroup("Decade-specific") ///
                modelname("Separate regression: change ending `k'") ///
                variable("delta_migrants") ///
                fetype("Origin FE + destination FE") ///
                decade(`k')
        }
        else {
            display as error "D`k' failed for `pretty'; return code " _rc
            post $POSTH ///
                ("`direction'") ///
                ("D`k'") ///
                ("Decade-specific") ///
                ("Separate regression: change ending `k'") ///
                ("delta_migrants") ///
                ("Origin FE + destination FE") ///
                (`k') ///
                (.) (.) (.) (.) ///
                ("") ///
                (`eligible_n') ///
                ("not estimated: insufficient observations after FE/separation")
        }
    }

    * H models. Structural-gravity-style high-dimensional FE robustness.
    * WDI controls are omitted because origin-year and destination-year FE
    * absorb country-specific time-varying GDP and population controls.
    capture noisily ppmlhdfe trade_val_usd ln_migrants, ///
        absorb(`strictfe') cluster(pair_id)
    if !_rc {
        eststo h1
        local strict_models "`strict_models' h1"
        post_current, direction("`direction'") modelid("H1") ///
            modelgroup("Origin-year/destination-year") ///
            modelname("Pooled stock, structural FE") ///
            variable("ln_migrants") ///
            fetype("Pair FE + origin-year FE + destination-year FE")
    }
    else display as error "H1 failed for `pretty'; return code " _rc

    capture noisily ppmlhdfe trade_val_usd ln_L_migrants ///
        if !missing(ln_L_migrants), absorb(`strictfe') cluster(pair_id)
    if !_rc {
        eststo h2
        local strict_models "`strict_models' h2"
        post_current, direction("`direction'") modelid("H2") ///
            modelgroup("Origin-year/destination-year") ///
            modelname("Lagged stock, structural FE") ///
            variable("ln_L_migrants") ///
            fetype("Pair FE + origin-year FE + destination-year FE")
    }
    else display as error "H2 failed for `pretty'; return code " _rc

    capture noisily ppmlhdfe trade_val_usd delta_migrants ///
        if !missing(delta_migrants), absorb(`strictfe') cluster(pair_id)
    if !_rc {
        eststo h3
        local strict_models "`strict_models' h3"
        post_current, direction("`direction'") modelid("H3") ///
            modelgroup("Origin-year/destination-year") ///
            modelname("Migrant change, structural FE") ///
            variable("delta_migrants") ///
            fetype("Pair FE + origin-year FE + destination-year FE")
    }
    else display as error "H3 failed for `pretty'; return code " _rc

    capture noisily ppmlhdfe trade_val_usd ///
        ibn.decade#c.delta_migrants ///
        if inlist(decade, 1980, 1990, 2000), ///
        absorb(`strictfe') cluster(pair_id)
    if !_rc {
        eststo h4
        local strict_models "`strict_models' h4"
        local h4n = e(N)

        foreach k in 1980 1990 2000 {
            capture noisily lincom `k'.decade#c.delta_migrants
            if !_rc {
                post_lincom, direction("`direction'") ///
                    modelid("H4_`k'") ///
                    modelgroup("Structural interaction") ///
                    modelname("Structural interaction slope ending `k'") ///
                    variable("delta_migrants") ///
                    fetype("Pair FE + origin-year FE + destination-year FE") ///
                    decade(`k') nobs(`h4n')
            }
            else display as error "H4 lincom failed for `pretty', decade `k'"
        }
    }
    else display as error "H4 failed for `pretty'; return code " _rc

    if "`primary_models'" != "" {
        esttab `primary_models' ///
            using "$OUT/ppml_primary_`d'.rtf", replace rtf ///
            keep(*migrants* ln_gdp_africa ln_gdp_gcc ///
                ln_pop_africa ln_pop_gcc) ///
            b(%12.8f) se(%12.8f) ///
            star(* 0.10 ** 0.05 *** 0.01) ///
            mtitles("Pooled stock" "Lagged stock" "Migrant change" ///
                "Decade interaction") ///
            stats(N, fmt(%9.0f) labels("Observations")) ///
            title("`pretty': pooled decade robustness") ///
            addnotes("All models absorb origin, destination, and year fixed effects." ///
                "Standard errors clustered by Africa-GCC pair." ///
                "Stock logs are ln(1 + migrants).")
    }

    if "`decade_models'" != "" {
        esttab `decade_models' ///
            using "$OUT/ppml_decade_`d'.rtf", replace rtf ///
            keep(delta_migrants) ///
            b(%12.8f) se(%12.8f) ///
            star(* 0.10 ** 0.05 *** 0.01) ///
            mtitles("1970-1980" "1980-1990" "1990-2000") ///
            stats(N, fmt(%9.0f) labels("Observations")) ///
            title("`pretty': separate decade regressions") ///
            addnotes("Each model absorbs origin and destination fixed effects." ///
                "Standard errors clustered by Africa-GCC pair.")
    }

    if "`strict_models'" != "" {
        esttab `strict_models' ///
            using "$OUT/ppml_structural_fe_`d'.rtf", replace rtf ///
            keep(*migrants*) ///
            b(%12.8f) se(%12.8f) ///
            star(* 0.10 ** 0.05 *** 0.01) ///
            mtitles("Pooled stock" "Lagged stock" "Migrant change" ///
                "Decade interaction") ///
            stats(N, fmt(%9.0f) labels("Observations")) ///
            title("`pretty': origin-year/destination-year FE robustness") ///
            addnotes("All models absorb pair, origin-year, and destination-year fixed effects." ///
                "WDI controls are absorbed by the country-year fixed effects." ///
                "Standard errors clustered by Africa-GCC pair.")
    }
}

postclose `coeffs'
use "$OUT/coefficient_summary_decades.dta", clear
sort direction model_group model_id decade
format coefficient std_error z_stat p_value %14.8g
export delimited using "$OUT/coefficient_summary_decades.csv", replace

display as result "Completed decade PPMLHDFE analysis."
log close
exit, clear
