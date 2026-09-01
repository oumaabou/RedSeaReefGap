# 01_load_clean.R
# ---------------------------------------------------------------------------
# Loads the raw GBIF-derived CSVs (data/raw/), checks them for internal
# consistency, standardizes types, and writes cleaned versions to
# data/processed/ for the downstream analysis scripts.
#
# Data provenance: all raw files were built from live queries against the
# GBIF Occurrence API (https://api.gbif.org/v1/occurrence/search), restricted
# to a Red Sea bounding box (decimalLatitude 12-30 N, decimalLongitude 32-44 E)
# and six reef-fish families. See README.md for full methodology and caveats.
# ---------------------------------------------------------------------------

library(dplyr)
library(readr)
library(tidyr)
library(tibble)

raw_dir <- "data/raw"
out_dir <- "data/processed"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

totals   <- read_csv(file.path(raw_dir, "family_totals.csv"), show_col_types = FALSE)
by_country <- read_csv(file.path(raw_dir, "family_country_counts.csv"), show_col_types = FALSE)
by_year  <- read_csv(file.path(raw_dir, "family_year_counts.csv"), show_col_types = FALSE)
samples  <- read_csv(file.path(raw_dir, "sample_occurrences.csv"), show_col_types = FALSE)

# --- Consistency checks --------------------------------------------------
# The per-country and per-year facet counts are independent GBIF queries
# against the same filter, so their totals should reconcile with
# family_totals.csv. This function reports (not silently fixes) mismatches,
# since GBIF facet totals are sometimes computed on a slightly different
# snapshot of the index a few seconds apart.
check_totals <- function(breakdown, label) {
  reconciled <- breakdown %>%
    group_by(family) %>%
    summarise(sum_count = sum(count), .groups = "drop") %>%
    left_join(totals, by = "family") %>%
    mutate(diff = sum_count - gbif_count_bbox)

  mismatches <- reconciled %>% filter(diff != 0)
  if (nrow(mismatches) > 0) {
    message(sprintf("[check_totals] %s: %d familie(s) with non-zero diff vs family_totals.csv:",
                     label, nrow(mismatches)))
    print(mismatches)
  } else {
    message(sprintf("[check_totals] %s: all families reconcile with family_totals.csv.", label))
  }
  reconciled
}

country_check <- check_totals(by_country, "family_country_counts")
year_check    <- check_totals(by_year, "family_year_counts")

write_csv(country_check, file.path(out_dir, "country_totals_check.csv"))
write_csv(year_check,    file.path(out_dir, "year_totals_check.csv"))

# --- Country code -> country name + Red Sea littoral flag -----------------
# ZZ = GBIF's code for "unknown/unrecorded country" (usually pelagic/at-sea
# GPS points with no resolvable country polygon). ET (Ethiopia) and KE (Kenya)
# are not on the Red Sea proper -- almost certainly coordinate-uncertainty
# edge cases at the southern bbox boundary near the Bab-el-Mandeb strait /
# Gulf of Aden, and are flagged rather than dropped, to stay transparent.
country_lookup <- tribble(
  ~country_code, ~country_name,          ~red_sea_littoral,
  "EG", "Egypt",                          TRUE,
  "SA", "Saudi Arabia",                   TRUE,
  "SD", "Sudan",                          TRUE,
  "ER", "Eritrea",                        TRUE,
  "YE", "Yemen",                          TRUE,
  "DJ", "Djibouti",                       TRUE,
  "IL", "Israel",                         TRUE,
  "JO", "Jordan",                         TRUE,
  "ET", "Ethiopia",                       FALSE,
  "KE", "Kenya",                          FALSE,
  "ZZ", "Unknown / unresolved",           NA
)

by_country_clean <- by_country %>%
  left_join(country_lookup, by = "country_code") %>%
  mutate(
    country_name = coalesce(country_name, country_code),
    red_sea_littoral = coalesce(red_sea_littoral, FALSE)
  )

by_year_clean <- by_year %>%
  mutate(
    year = as.integer(year),
    decade = (year %/% 10) * 10
  )

samples_clean <- samples %>%
  mutate(
    lat = as.numeric(lat),
    lon = as.numeric(lon),
    eventDate = as.Date(eventDate)
  )

write_csv(by_country_clean, file.path(out_dir, "family_country_counts_clean.csv"))
write_csv(by_year_clean,    file.path(out_dir, "family_year_counts_clean.csv"))
write_csv(samples_clean,    file.path(out_dir, "sample_occurrences_clean.csv"))
write_csv(totals,           file.path(out_dir, "family_totals_clean.csv"))

message("01_load_clean.R complete. Cleaned files written to data/processed/.")
