# LYNCS

**Special schools and social assistance across Ontario**

**Question:** Where are the selected specialised schools, and how do OW and ODSP caseloads vary across Ontario’s covered metropolitan areas?

An interactive layout for a provincial policy analyst. Select an area to explore its school records, assistance history and family composition.

## Plan

| View | What it shows |
| --- | --- |
| Map | School locations and assistance coverage. |
| Area comparison | Caseloads and school-record counts across 15 areas. |
| History | Quarterly changes in the selected area. |
| School list | Names, codes, stages and unavailable information. |

## Data

Three [course files](https://github.com/mjmoon/sta313-project-datasets): school information, Ontario Works (OW) and Ontario Disability Support Program (ODSP) case characteristics. Schools cover 2017–2018 to 2024–2025; assistance covers March 2003 to March 2026.

External geographical data already used:

- **[Statistics Canada 2021 CMA boundaries](https://geo.statcan.gc.ca/geo_wa/rest/services/2021/Cartographic_boundary_files/MapServer/6):** `cma-boundaries.geojson`, covering the Ontario portions of the 15 areas. Used to assign school coordinates to areas and draw the map.
- **[Statistics Canada 2021 province boundaries](https://geo.statcan.gc.ca/geo_wa/rest/services/2021/Cartographic_boundary_files/MapServer/0):** `ontario-outline.geojson`, the Ontario outline used as the map background.

A school record is not necessarily a separate campus. Assistance cases represent people or family units, not pupils.

External datasets under consideration:

- **[Population, Table 17-10-0148-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1710014801):** annual estimates, 2001–2025; possible cases-per-1,000 comparisons after checking dates and boundaries.
- **[Low income, Table 11-10-0018-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1110001801):** annual percentages; our extract covers all 15 areas from 2006–2023.
- **[Disability, Table 13-10-0750-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1310075001):** 2017 and 2022 estimates with confidence intervals, ages 15+. Ottawa includes Quebec; geography and caution flags need attention.
- **[Unemployment, Table 14-10-0459-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410045901):** monthly series from 2011, reported as three-month moving averages; possible context for OW histories.

These four datasets are not yet included in the webpage.

## Next

- Review the layout and replace placeholder prose.
- Explore age and time on assistance using existing columns.
- Check population and income data before adding further comparisons.

## Files

```text
web/
├── analysis/              R code and findings.md
│   └── figures/           Four figures from the analysis
├── site/                  Webpage: open index.html
│   ├── data/              R exports for the charts and map
│   └── vendor/            Local D3 library
├── development-plan.md    Draft paragraph for report.pdf
├── .github/workflows/     GitHub Pages setup
└── scratch/               Rough work and source downloads; ignored
```
