# RedSeaReefGap

A data-cleaning and gap-analysis project on Red Sea reef-fish occurrence
records, built in R. It asks a simple question: **for six common reef-fish
families, where and when does the public biodiversity record (GBIF) actually
have data, and where is it silent?**

Rather than mapping where these fish live, this project maps where they have
been *recorded* — which, for citizen-science-heavy data like this, is a very
different and much more revealing question.

## Families analyzed

| Family | Common name | GBIF familyKey |
|---|---|---|
| Acanthuridae | Surgeonfishes | 4233 |
| Scombridae | Tunas & mackerels | 8596 |
| Scaridae | Parrotfishes | 4504 |
| Carangidae | Jacks & trevallies | 4253 |
| Serranidae | Groupers | 8597 |
| Lutjanidae | Snappers | 8542 |

## Key findings

- **Spatial concentration:** across all six families, 70–85% of every
  family's GBIF records in the Red Sea bounding box come from a single
  country — Egypt — driven almost entirely by dive-tourism hotspots on the
  Sinai coast (Sharm el-Sheikh, Ras Mohammed National Park). Sudan, Eritrea,
  Yemen and Djibouti combined typically contribute under 5% of records per
  family, despite together accounting for a large share of Red Sea
  coastline. See `output/spatial_gap_by_country.png` and
  `output/undersampled_littoral_countries.csv`.
- **Temporal concentration:** 70–82% of year-resolved records per family
  date from 2015 onward, coinciding with the growth of iNaturalist. Records
  before 1990 make up under 11% of any family's data, and what does exist
  from that period is sparse, single-digit-per-year museum/expedition
  specimens going back intermittently to the 1820s. See
  `output/temporal_gap_by_decade.png` and
  `output/temporal_recency_by_family.csv`.
- **Practical implication:** any apparent trend in these families' relative
  abundance or distribution that's read directly off raw GBIF record counts
  is, to a large extent, a trend in tourist dive traffic and app usage —
  not necessarily a trend in the fish.

## Data source and methodology

All data comes from the [GBIF Occurrence API](https://www.gbif.org/developer/occurrence),
queried live and restricted to a Red Sea bounding box
(`decimalLatitude=12,30`, `decimalLongitude=32,44`) with `hasCoordinate=true`.
Two kinds of query were used:

1. **Aggregate facet counts** (`facet=country`, `facet=year`) — these cover
   **every** matching record for each family, not a sample, and are the
   basis for the spatial and temporal gap analysis in scripts `02` and `03`.
2. **A small verified sample of individual records** (`data/raw/sample_occurrences.csv`,
   n = 19, 3-4 per family) — pulled to illustrate what the data actually
   looks like (species, coordinates, date, observer, GBIF/iNaturalist links)
   and used only for the point map in script `04`.

These two are kept deliberately separate and are not mixed: the gap-analysis
conclusions above are based on complete aggregate counts, while the map is
explicitly labeled as an illustrative sample.

### Pipeline

```
R/01_load_clean.R              -> reads data/raw/*.csv, checks internal
                                   consistency, writes data/processed/*.csv
R/02_spatial_gap_analysis.R    -> country-level concentration metrics + plot
R/03_temporal_gap_analysis.R   -> decade-level recency metrics + plot
R/04_map_occurrences.R         -> point map of the verified sample + a
                                   distance-clustering check
R/run_all.R                    -> runs all four in order
```

## Reproducing this

This project was developed without a local R + tidyverse environment
available to run the scripts directly. To keep the results honest and
independently checkable rather than just asserted, the analysis runs for
real on GitHub Actions on every push — see
`.github/workflows/r-analysis.yml` and the workflow's **Actions** tab for
the actual output artifacts (plots + processed CSVs) from a real R run.

To run it yourself locally:

```bash
Rscript -e 'install.packages(c("dplyr","readr","tidyr","tibble","ggplot2","scales","maps"))'
Rscript R/run_all.R
```

Outputs land in `data/processed/` (cleaned tables) and `output/` (plots +
summary CSVs).

## Scope and limitations

- **GBIF only.** This does not query OBIS, national museum databases, or
  literature-mined records — only what GBIF indexes. GBIF itself is
  dominated here by one iNaturalist-fed dataset, so this is really closer to
  a citizen-science coverage analysis than a comprehensive occurrence
  analysis.
- **Bounding box, not exact Red Sea polygon.** The lat/lon box
  (12–30N, 32–44E) catches a rectangular area that includes parts of the
  Gulf of Aqaba, Gulf of Suez, and a sliver of the Gulf of Aden near the
  Bab-el-Mandeb strait. A handful of records fall in Ethiopia (ET) and Kenya
  (KE) — almost certainly coordinate-uncertainty edge cases near the
  southern boundary — and are flagged rather than silently dropped (see
  `country_lookup` in `R/01_load_clean.R`).
  `ZZ` is GBIF's code for occurrences whose coordinates didn't resolve to
  any country polygon (typically open-water GPS points).
- **Year facet is not 100% reconciled with total record counts.** A small
  fraction of records per family (1–2%) have no resolvable year and are
  excluded from the temporal facet entirely; `01_load_clean.R` prints this
  reconciliation check rather than hiding the gap.
- **The 19-record sample is illustrative, not representative.** It was
  drawn from the same over-sampled Sinai dive sites that dominate the full
  dataset, and is explicitly not used to support any of the gap-analysis
  conclusions above — only the aggregate facet counts are.
- **No local R execution during authoring.** The scripts were written and
  their logic verified against equivalent Python computations on the same
  raw CSVs (not shown here), but the actual R/tidyverse/ggplot2 execution
  happens in CI (see above), not on the author's machine.

## Author

Built by Oumalkaire Aboubakar as a follow-on to prior R/data-cleaning work
([data-cleaning-and-visualisation](https://github.com/oumaabou/data-cleaning-and-visualisation)),
extending into geospatial and ecological-sampling gap analysis.
