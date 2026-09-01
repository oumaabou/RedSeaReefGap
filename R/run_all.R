# run_all.R
# Runs the full pipeline in order. Intended to be run from the project root:
#   Rscript R/run_all.R
scripts <- c(
  "R/01_load_clean.R",
  "R/02_spatial_gap_analysis.R",
  "R/03_temporal_gap_analysis.R",
  "R/04_map_occurrences.R"
)

for (s in scripts) {
  message(sprintf("\n==== Running %s ====", s))
  source(s)
}

message("\nAll scripts completed. See data/processed/ and output/ for results.")
