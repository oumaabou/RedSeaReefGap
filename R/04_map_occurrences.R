# 04_map_occurrences.R
# ---------------------------------------------------------------------------
# Geospatial view of the verified sample occurrences (n = 19) against Red Sea
# coastlines. This map is illustrative, not a density map of the full
# dataset: it plots a small, individually-verified sample of real GBIF
# records (see data/raw/sample_occurrences.csv), while the actual gap
# analysis in 02/03 uses the complete aggregate counts for every matching
# record. See README.md ("Scope and limitations") for why the two are kept
# separate rather than presented as one map of "all occurrences".
#
# Uses the base `maps` package (bundled with R, no extra basemap download)
# rather than sf/rnaturalearth, to keep the dependency footprint small.
# ---------------------------------------------------------------------------

library(dplyr)
library(readr)
library(ggplot2)
library(maps)

proc_dir <- "data/processed"
out_dir  <- "output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

samples <- read_csv(file.path(proc_dir, "sample_occurrences_clean.csv"), show_col_types = FALSE)

world <- map_data("world")

bbox <- list(lon = c(30, 46), lat = c(10, 32))

region <- world %>%
  filter(long >= bbox$lon[1] - 2, long <= bbox$lon[2] + 2,
         lat  >= bbox$lat[1] - 2, lat  <= bbox$lat[2] + 2)

p_map <- ggplot() +
  geom_polygon(data = region, aes(x = long, y = lat, group = group),
               fill = "#f0ead6", color = "grey50", linewidth = 0.2) +
  geom_point(data = samples, aes(x = lon, y = lat, color = family),
             size = 3, alpha = 0.85) +
  coord_quickmap(xlim = bbox$lon, ylim = bbox$lat) +
  labs(
    title = "Verified sample occurrences (n = 19) in the Red Sea region",
    subtitle = "One illustrative GBIF record shown per point; full record counts are in output/spatial_gap_by_country.png",
    x = NULL, y = NULL, color = "Family",
    caption = "Source: GBIF Occurrence API (iNaturalist research-grade observations, Jan 2026)."
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank())

ggsave(file.path(out_dir, "sample_occurrence_map.png"), p_map, width = 9, height = 8, dpi = 150)

# --- Cluster check -----------------------------------------------------
# Almost all sample points fall within a few kilometers of each other on the
# Sinai coast. This is quantified explicitly rather than left to visual
# inspection of the map.
dist_km <- function(lat1, lon1, lat2, lon2) {
  # Haversine formula
  R <- 6371
  to_rad <- pi / 180
  dlat <- (lat2 - lat1) * to_rad
  dlon <- (lon2 - lon1) * to_rad
  a <- sin(dlat / 2)^2 + cos(lat1 * to_rad) * cos(lat2 * to_rad) * sin(dlon / 2)^2
  2 * R * asin(sqrt(a))
}

sinai_ref <- c(lat = 27.91, lon = 34.35)  # approx Sharm el-Sheikh / Ras Mohammed cluster
samples <- samples %>%
  mutate(km_from_sinai_cluster = dist_km(sinai_ref["lat"], sinai_ref["lon"], lat, lon))

n_within_20km <- sum(samples$km_from_sinai_cluster <= 20)

write_csv(samples, file.path(out_dir, "sample_occurrences_with_distance.csv"))
message(sprintf("%d of %d sample records (%.0f%%) fall within 20km of the Sharm el-Sheikh / Ras Mohammed cluster.",
                 n_within_20km, nrow(samples), 100 * n_within_20km / nrow(samples)))

message("04_map_occurrences.R complete. Outputs written to output/.")
