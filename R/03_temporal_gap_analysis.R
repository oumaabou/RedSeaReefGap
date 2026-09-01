# 03_temporal_gap_analysis.R
# ---------------------------------------------------------------------------
# Temporal sampling-effort gap analysis: how is GBIF occurrence coverage for
# each family distributed across time? Citizen-science platforms (iNaturalist
# in particular) mean modern record counts mostly reflect recent app usage
# and dive tourism, not species abundance -- so a "recent-heavy" pattern is
# a sampling-effort artifact, not evidence that a family is more common now.
# ---------------------------------------------------------------------------

library(dplyr)
library(readr)
library(ggplot2)
library(scales)

proc_dir <- "data/processed"
out_dir  <- "output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

by_year <- read_csv(file.path(proc_dir, "family_year_counts_clean.csv"), show_col_types = FALSE)

# --- Recency bias metric ----------------------------------------------------
# share_2015_plus: fraction of a family's (year-resolved) records from 2015
# onward, roughly when iNaturalist usage in the Red Sea region took off.
# pre_1990_share: fraction from before 1990, i.e. from historical
# museum/expedition specimens rather than digital-era observations.
recency <- by_year %>%
  group_by(family) %>%
  summarise(
    n_year_resolved_records = sum(count),
    n_distinct_years = n(),
    earliest_year = min(year),
    latest_year = max(year),
    share_2015_plus = sum(count[year >= 2015]) / sum(count),
    share_pre_1990 = sum(count[year < 1990]) / sum(count),
    .groups = "drop"
  ) %>%
  arrange(desc(share_2015_plus))

write_csv(recency, file.path(out_dir, "temporal_recency_by_family.csv"))
message("Share of records from 2015 onward, per family:")
print(recency)

# --- Decade-level record counts, for plotting ------------------------------
by_decade <- by_year %>%
  group_by(family, decade) %>%
  summarise(count = sum(count), .groups = "drop")

write_csv(by_decade, file.path(out_dir, "records_by_decade.csv"))

p_temporal <- ggplot(by_decade, aes(x = decade, y = count, fill = family)) +
  geom_col() +
  scale_y_continuous(labels = label_number(big.mark = ",")) +
  scale_x_continuous(breaks = seq(1820, 2020, by = 20)) +
  facet_wrap(~family, scales = "free_y", ncol = 2) +
  labs(
    title = "Red Sea reef-fish occurrence records by decade",
    subtitle = "GBIF records with a resolvable collection year, grouped into decades",
    x = "Decade", y = "Occurrence records",
    caption = "Source: GBIF Occurrence API. Recent decades are inflated by citizen-science (iNaturalist) growth, not by increased species abundance."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none", strip.text = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(out_dir, "temporal_gap_by_decade.png"), p_temporal, width = 10, height = 9, dpi = 150)

message("03_temporal_gap_analysis.R complete. Outputs written to output/.")
