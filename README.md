# Do Migrants Promote Trade? Evidence from Africa-Gulf Bilateral Trade Flows

This repository documents an MSc Economics dissertation project on the relationship between African migration to the Gulf Cooperation Council (GCC) and bilateral merchandise trade. The project is designed as a reproducible applied-econometrics portfolio: it combines structural gravity modelling, PPML estimation, high-dimensional fixed effects, alternative migration and trade datasets, and product-level heterogeneity analysis.

The empirical work is complete. This repository separates public replication code and outputs from restricted raw data and private dissertation drafts.

## Project Overview

The dissertation studies whether African migrant communities in GCC countries are associated with bilateral trade between African economies and the Gulf. The analysis focuses on African-origin migrants residing in Bahrain, Kuwait, Oman, Qatar, Saudi Arabia, and the United Arab Emirates, and estimates separate trade-flow models for:

- African exports to GCC countries.
- GCC exports to African countries.

The project is motivated by a central idea in the migration-trade literature: migrants may reduce informational frictions, search costs, and trust barriers that otherwise constrain international trade. The Africa-GCC corridor is a useful setting because it combines large migrant labour markets, growing Africa-Gulf economic ties, and relatively limited existing evidence compared with Europe, North America, and East Asia.

## Research Question

**Do African migrants residing in GCC countries promote bilateral trade between African economies and Gulf countries?**

The dissertation evaluates this question through three related empirical exercises:

1. A contemporary UN DESA-BACI gravity panel for 2000, 2005, 2010, 2015, 2020, and 2024.
2. A historical robustness panel using World Bank bilateral migration data, IMF DOTS trade data, and WDI controls for 1960-2000.
3. A Rauch product-classification extension comparing differentiated and non-differentiated goods.

## Motivation and Policy Relevance

Migration policy and trade policy are often studied separately. In the Africa-GCC corridor, however, labour mobility and market access are closely connected. GCC economies are highly migrant-dependent, while African governments increasingly view Gulf markets as destinations for export diversification, investment links, and diaspora engagement.

If migrant networks help African firms identify buyers, understand demand conditions, and build trust with counterparties, migration may complement formal export-promotion and trade-facilitation policies. The results should not be read as definitive causal estimates, but they provide evidence on whether migration-trade associations are visible after increasingly demanding controls for origin-year and destination-year shocks.

## Data Sources

| Source | Role in the project | Coverage used | Public-release status |
|---|---|---:|---|
| UN DESA International Migrant Stock Database, 2024 Revision | Main bilateral migrant-stock measure | 2000-2024 benchmark waves | Cite source; do not redistribute raw extracts without checking terms |
| BACI/CEPII trade data | Main bilateral merchandise export data | HS92 bilateral exports | Cite source; redistribute only as permitted by CEPII/BACI terms |
| World Development Indicators | GDP and population controls | Country-year controls | Cite World Bank; avoid redistributing bulk raw downloads |
| World Bank Global Bilateral Migration Database | Historical migration robustness | 1960-2000 benchmark years | Cite source; do not redistribute raw data if terms prohibit it |
| IMF Direction of Trade Statistics | Historical bilateral trade robustness | 1960-2000 | Cite IMF DOTS; do not redistribute licensed extracts |
| Rauch (1999) classification | Product-type heterogeneity | HS92 differentiated vs non-differentiated goods | Cite Rauch classification source |

## Empirical Strategy

The preferred empirical approach is a structural gravity model estimated by Poisson Pseudo-Maximum Likelihood (PPML). PPML is used because bilateral trade data are heteroskedastic and can include zero trade flows. Standard errors are clustered at the Africa-GCC country-pair level.

The main migration variables are:

- `ln_migrants`: log migrant stock, `ln(1 + migrants)`.
- `ln_L_migrants`: lagged log migrant stock from the previous observed migration wave.
- `delta_migrants`: change in migrant stock between consecutive observed waves.

The revised UN DESA-BACI specifications follow the supervisor-requested structure:

- Origin, destination, and year fixed effects.
- Origin-year and destination-year fixed effects.
- Lagged-stock and migration-flow models.
- Pair fixed effects retained only as appendix robustness.

## Main Model Specification

The preferred PPML gravity specification can be written as:

```text
E[X_ijt | .] = exp(beta M_ijt + theta Z_ij + alpha_it + delta_jt)
```

where:

- `X_ijt` is bilateral exports from origin `i` to destination `j` in year `t`.
- `M_ijt` is current migrant stock, lagged migrant stock, or the change in migrant stock.
- `Z_ij` includes bilateral gravity controls where applicable.
- `alpha_it` and `delta_jt` are origin-year and destination-year fixed effects.

In stricter World Bank-IMF robustness specifications, pair, origin-year, and destination-year fixed effects are also reported. These specifications are interpreted as demanding robustness checks rather than a claim of clean causal identification.

## Repository Structure

The clean public repository should use the following structure. The current workspace also contains temporary `work/` and `outputs/` folders created during document preparation; those are intentionally excluded from the public release via `.gitignore`.

```text
.
|-- README.md
|-- LICENSE
|-- LICENSE_RECOMMENDATION.md
|-- .gitignore
|-- code/
|   `-- stata/
|       `-- README.md
|-- data/
|   `-- README.md
|-- docs/
|   |-- README.md
|   |-- data_availability.md
|   |-- public_release_checklist.md
|   |-- reproducibility.md
|   `-- software.md
|-- output/
|   |-- README.md
|   |-- figures/
|   |   `-- README.md
|   `-- regression_tables/
|       `-- README.md
`-- paper/
    `-- README.md
```

Included Stata scripts from the completed analysis:

- `run_africa_gcc_ppml_revised.do`: contemporary UN DESA-BACI PPMLHDFE models.
- `run_ppmlhdfe_worldbank_imf_wdi_decades.do`: World Bank-IMF-WDI historical robustness and decade analysis.

Included regression outputs from the completed analysis:

- `ppml_africa_to_gcc_exports_revised.rtf`
- `ppml_gcc_to_africa_exports_revised.rtf`
- `africa_gcc_ppml_coefficient_summary.csv`
- `ppml_primary_africa_to_gcc_exports.rtf`
- `ppml_primary_gcc_to_africa_exports.rtf`
- `ppml_decade_africa_to_gcc_exports.rtf`
- `ppml_decade_gcc_to_africa_exports.rtf`
- `ppml_structural_fe_africa_to_gcc_exports.rtf`
- `ppml_structural_fe_gcc_to_africa_exports.rtf`
- `coefficient_summary_decades.csv`

## Main Findings

The findings are best interpreted as robust associations, not definitive causal effects.

1. **Africa to GCC exports:** The dissertation narrative and historical robustness exercises support a positive migration-trade association. In the World Bank-IMF panel, pooled migrant stock is positive and statistically significant (`ln_migrants = 0.4578`, p = 0.00024), and lagged migrant stock is also positive and significant (`ln_L_migrants = 0.3811`, p = 0.00150).

2. **Conservative estimates under richer fixed effects:** The revised UN DESA-BACI models become more conservative when origin-year and destination-year fixed effects are introduced. This is consistent with country-year shocks absorbing part of the simpler gravity-model association.

3. **Migration flows are less stable than stocks:** Flow specifications based on changes in migrant stocks are less robust for Africa-to-GCC exports. In the historical robustness exercise, there is no definitive decade-specific flow effect for Africa-to-GCC trade.

4. **Directional asymmetry:** GCC-to-Africa stock models are weaker and less systematic. In the World Bank-IMF robustness analysis, the strongest GCC-to-Africa flow association appears in 1980-1990, including primary interaction, separate-decade, and strict fixed-effect specifications.

5. **Product heterogeneity is suggestive:** The Rauch extension indicates that differentiated goods show more favourable migration coefficients than non-differentiated goods for Africa-to-GCC exports. The evidence is suggestive rather than definitive because most preferred product-type estimates are statistically weak.

## Software and Packages Used

The analysis was run in **Stata 18**. Key Stata packages:

- `ppmlhdfe` for PPML gravity models with high-dimensional fixed effects.
- `esttab` / `estout` for regression table export.
- `estadd` for model metadata.

Documentation and repository materials use:

- Git and GitHub Markdown.
- Microsoft Word / DOCX for dissertation drafting.
- CSV and RTF regression outputs for transparent tabulation.

## Reproducibility Instructions

Raw data are not included in the public repository. To reproduce the analysis:

1. Obtain the source datasets listed in `docs/data_availability.md`.
2. Place restricted raw data in `data/raw/` locally. This directory is ignored by Git.
3. Place cleaned, non-public intermediate files in `data/intermediate/` or `data/processed/` locally. These are also ignored by Git.
4. Install the required Stata packages:

```stata
ssc install ppmlhdfe, replace
ssc install estout, replace
ssc install ftools, replace
ssc install reghdfe, replace
```

5. Run the sanitized Stata scripts in this order:

```text
code/stata/run_africa_gcc_ppml_revised.do
code/stata/run_ppmlhdfe_worldbank_imf_wdi_decades.do
```

6. Compare generated outputs against the expected files listed in `output/regression_tables/README.md`.

The included public do-files use project-root macros. Update only the root path at the top of each do-file before running locally.

## Skills Demonstrated

- Structural gravity modelling for bilateral trade.
- PPML estimation with high-dimensional fixed effects.
- Construction of current, lagged, and flow migration measures.
- Robustness analysis using independent migration and trade data sources.
- Direction-specific trade modelling.
- Product-level heterogeneity using Rauch differentiated-goods classification.
- Stata workflow design, regression table production, and log-based QA.
- Academic literature synthesis and research documentation.
- Reproducible-research repository design with clear data licensing boundaries.

## Data Availability and Licensing

This repository should not redistribute restricted raw data. The recommended public release includes:

- Sanitized Stata code.
- Documentation.
- Non-sensitive regression tables and coefficient summaries.
- Final paper or proposal files only after supervisor approval.

The recommended license is **MIT for code** and a separate documentation/paper license if desired. See `LICENSE_RECOMMENDATION.md` for details. Third-party datasets remain governed by their original providers' licenses and terms of use.

