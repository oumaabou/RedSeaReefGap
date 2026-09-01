# 02_spatial_gap_analysis.R
# ---------------------------------------------------------------------------
# Spatial sampling-effort gap analysis: for each reef-fish family, how are
# GBIF occurrence records distributed across Red Sea littoral countries?
# A family with 90%+ of its records from one country is not a family that is
# "rare" in the other seven -- it is a family that is undersampled there.
# ---------------------------------------------------------------------------

library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)
library(scales)

proc_dir <- "data/processed"
out_dir  <- "output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

by_country <- read_csv(file.path(proc_dir, "family_country_counts_clean.csv"), show_col_types = FALSE)

# --- Per-family concentration metrics --------------------------------------
# top_share: fraction of a family's records contributed by its single
# best-sampled country. herfindahl: sum of squared country shares (0-1);
# closer to 1 means sampling is concentrated in very few countries, closer
# to 1/n_countries means it is spread evenly.
family_concentration <- by_country %>%
  group_by(family) %>%
  mutate(total = sum(count), share = count / total) %>%
  summarise(
    n_countries_present = n(),
    top_country = country_code[which.max(count)],
    top_share = max(share),
    herfindahl = sum(share^2),
    littoral_share = sum(share[red_sea_littoral %in% TRUE]),
    .groups = "drop"
  ) %>%
  arrange(desc(top_share))

write_csv(family_concentration, file.path(out_dir, "spatial_concentration_by_family.csv"))

# --- Which littoral countries are effectively missing? ----------------------
# For each family, list littoral countries with fewer than 1% of that
# family's records -- i.e. countries where the species group is present in
# the wider region but essentially unsampled in GBIF.
littoral_countries <- c("EG", "SA", "SD", "ER", "YE", "DJ", "IL", "JO")

undersampled <- by_country %>%
  filter(country_code %in% littoral_countries) %>%
  group_by(family) %>%
  mutate(total = sum(count), share = count / total) %>%
  ungroup() %>%
  complete(family, country_code = littoral_countries, fill = list(count = 0, share = 0)) %>%
  filter(share < 0.01) %>%
  select(family, country_code, count, share) %>%
  arrange(family, country_code)

write_csv(undersampled, file.path(out_dir, "undersampled_littoral_countries.csv"))

message("Countries below 1% share of records, per family (candidate sampling gaps):")
print(undersampled)

# --- Plot: country-level record counts per family (log scale) --------------
# Countries are ordered globally by their total record count across all six
# families combined, so the ordering is stable and comparable across facets
# (a per-facet reorder would need the tidytext package, which this project
# intentionally avoids to keep the dependency list small).
country_order <- by_country %>%
  group_by(country_name) %>%
  summarise(total = sum(count), .groups = "drop") %>%
  arrange(total) %>%
  pull(country_name)

plot_df <- by_country %>%
  mutate(
    country_name = factor(country_name, levels = country_order),
    family = factor(family, levels = c("Acanthuridae","Scaridae","Serranidae",
                                        "Carangidae","Lutjanidae","Scombridae"))
  )

p_spatial <- ggplot(plot_df, aes(x = country_name, y = count, fill = red_sea_littoral)) +
  geom_col() +
  scale_y_log10(labels = label_number(big.mark = ",")) +
  scale_fill_manual(values = c("TRUE" = "#2166ac", "FALSE" = "#b2182b", "NA" = "grey60"),
                     na.value = "grey60", name = "Red Sea littoral state") +
  coord_flip() +
  facet_wrap(~family, scales = "free", ncol = 2) +
  labs(
    title = "GBIF occurrence records by country, per reef-fish family",
    subtitle = "Red Sea bounding box (12-30N, 32-44E) | log10 scale",
    x = NULL, y = "Occurrence records (log10)",
    caption = "Source: GBIF Occurrence API. ZZ = unresolved/at-sea coordinates."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", strip.text = element_text(face = "bold"))

ggsave(file.path(out_dir, "spatial_gap_by_country.png"), p_spatial, width = 10, height = 9, dpi = 150)

message("02_spatial_gap_analysis.R complete. Outputs written to output/.")
