# Findings

First pass for the layout, using the course data. Run from `web/`:

```sh
Rscript analysis/run.R
```

Requires ggplot2, jsonlite and sp. Source downloads and temporary work stay in scratch/.

## Checked

- School selection: 138 records across eight school years, 2017-2018 to 2024-2025.
- 2024-2025: 16 records at five reported coordinates. Records are not campus counts.
- Toronto, London and Brantford each contain four records. Belleville's four records are outside the 15-area assistance coverage.
- 10 selected records have no coordinates, all in 2017-2018 or 2018-2019. Keep these in the list, not on the map.
- Each programme has 1,395 rows: 15 areas and 93 quarters, March 2003 to March 2026.
- No duplicate area/programme/quarter keys or missing case totals. Family and age counts sum to total cases.

## March 2025

- OW totals range from 1,950 in Guelph to 129,740 in Toronto. These are counts, not population rates.
- OW single-parent share ranges from 18.7% in Toronto to 28.6% in Brantford, using all cases in each area as the denominator.
- ODSP totals range from 3,591 in Guelph to 117,547 in Toronto. These are counts, not population rates.
- ODSP single-parent share ranges from 8.1% in Ottawa-Gatineau (Ontario) to 11.5% in Brantford, using all cases in each area as the denominator.

## Figures and layout

- 01: school records and reported locations need separate labels. Four records can share one coordinate.
- 02: common count scales preserve area differences, but Toronto dominates. Keep an exact value on every row and offer a percentage measure separately.
- 03: histories show change within each area. The index sets March 2003 to 100; it does not compare absolute caseload size.
- 04: family shares use a shared 0-100% scale, with OW and ODSP distinguished by both shape and colour.

## Still open

- Population rates: confirm assistance boundary definitions and choose compatible reference dates before adding Table 17-10-0148-01. No rates are displayed yet.
- 2021 boundaries are reference geography; equivalence to historical assistance areas is unconfirmed.
- School filters change school records only. They cannot filter assistance to pupils or their families.
- The pitch's policy-impact and cost-effectiveness questions cannot be answered by these files. No funding, rejected applications or pupil-to-case links are supplied.
- No selected records in an area does not mean no special education is available there.
- Test the layout with the group, replace placeholder prose and agree on the final chart states.

## Sources

- [Course snapshot](https://github.com/mjmoon/sta313-project-datasets/tree/064cf60c13e7ddfbd20c5cbfd1ec220bec200d92)
- [2021 CMA boundaries](https://geo.statcan.gc.ca/geo_wa/rest/services/2021/Cartographic_boundary_files/MapServer/6/query?where=PRUID%3D%2735%27%20AND%20CMAUID%20IN%20%28%27505%27,%27521%27,%27529%27,%27532%27,%27535%27,%27537%27,%27539%27,%27541%27,%27543%27,%27550%27,%27555%27,%27559%27,%27568%27,%27580%27,%27595%27%29&outFields=CMAUID,CMANAME,PRUID&outSR=4326&f=geojson&geometryPrecision=6)
- [Ontario outline](https://geo.statcan.gc.ca/geo_wa/rest/services/2021/Cartographic_boundary_files/MapServer/0/query?where=PRUID%3D%2735%27&outFields=PRUID,PRNAME&outSR=4326&f=geojson&maxAllowableOffset=0.01&geometryPrecision=5)

Source fingerprints (MD5):

```
          scratch/ont-school-demo-info.csv 
        "17d2d65d2e2d400d61ca866264cd9997" 
  scratch/ont-sa-characteristic-ow-cma.csv 
        "d17181a60dc6b39de54c2f941b9e9158" 
scratch/ont-sa-characteristic-odsp-cma.csv 
        "c7457733802ca352197704c3299069fb" 
            scratch/cma-boundaries.geojson 
        "d3476b403c638651a34e2e93c158a0b9" 
           scratch/ontario-outline.geojson 
        "4d4513eb26f430dbf1b501c2fb0561fb" 
```

Run with R version 4.6.2 (2026-10-29) and ggplot2 4.0.3
