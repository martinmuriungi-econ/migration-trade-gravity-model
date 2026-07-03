# Data Availability

This project uses third-party data sources. The public GitHub repository should provide code and documentation, but not redistribute raw data unless the relevant provider terms explicitly allow it.

| Data source | Role | Access / licensing guidance |
|---|---|---|
| UN DESA International Migrant Stock Database, 2024 Revision | Main bilateral migration panel for 2000-2024 | Cite UN DESA. Do not publish bulk extracts without checking redistribution terms. |
| BACI/CEPII | Main bilateral trade panel at HS92 product level | Cite BACI/CEPII. Follow BACI terms for redistribution. |
| World Development Indicators | GDP and population controls | Cite World Bank WDI. Prefer scripts or source instructions over raw-data redistribution. |
| World Bank Global Bilateral Migration Database | Historical migration robustness for 1960-2000 | Cite World Bank source. Do not redistribute restricted extracts. |
| IMF Direction of Trade Statistics | Historical bilateral trade robustness | IMF DOTS may be subject to access restrictions; do not commit raw DOTS extracts. |
| Rauch product classification | Product heterogeneity | Cite Rauch (1999) and the classification file source. |

## Recommended public-release approach

- Commit source instructions and code.
- Commit final regression tables and non-sensitive coefficient summaries if permitted.
- Do not commit raw data, licensed extracts, or large merged `.dta` files.
- If a replication package is needed, provide a script that rebuilds local analysis files after users obtain the underlying datasets.

