# Tables 1, S2 and S3 as formatted tables (gt), from the result CSV files.
#
# Usage:  Rscript code/R/tables.R <repository folder>
#
# Inputs:  results/tables/table1_FFA_vs_PPA.csv, table_S2_FFA_seed_map.csv,
#          table_S3_PPA_seed_map.csv
#          data/atlas/region_names.csv (the region descriptions of the tables)
# Outputs: results/tables/table1.html, table_S2.html, table_S3.html
#          (and .png when the webshot2 package and Chrome are available)
#
# z-scores are rounded to 4 and then to 2 decimals. p-values are FDR-adjusted.
#
# Author: Orhan Soyuhos, 2026
# License: GPL-3.0 (see LICENSE)

script_dir <- local({
  f <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(f)) dirname(normalizePath(sub("^--file=", "", f[1]))) else file.path(getwd(), "code", "R")
})
source(file.path(script_dir, "common.R"))
suppressPackageStartupMessages(library(gt))

names_tab <- read_result(repo, "data", "atlas", "region_names.csv")
region_name <- function(parcel, column) {
  out <- names_tab[[column]][match(parcel, names_tab$parcel)]
  ifelse(is.na(out) | out == "", "", out)
}
p_label <- function(p) {
  ifelse(is.na(p), "\u2013", ifelse(p < 0.001, "<0.001", ifelse(p < 0.01, "<0.01",
         ifelse(p < 0.05, "<0.05", paste0("=", round(p, 3))))))
}
z_label <- function(z) ifelse(is.na(z), "\u2013", formatC(round(round(z, 4), 2), format = "f", digits = 2))

style <- function(tab) {
  tab |>
    tab_options(table.border.top.color = "black", table.border.bottom.color = "black",
                column_labels.border.bottom.color = "black", column_labels.border.bottom.width = px(3),
                data_row.padding = px(6), table.font.size = px(14)) |>
    opt_table_font(font = list(font_family, default_fonts()))
}

save_table <- function(tab, name) {
  html <- file.path(dir_tables, paste0(name, ".html"))
  gtsave(tab, html)
  cat("Saved", html, "\n")
  if (requireNamespace("webshot2", quietly = TRUE)) {
    png <- file.path(dir_tables, paste0(name, ".png"))
    ok <- tryCatch({ gtsave(tab, png); TRUE }, error = function(e) FALSE)
    if (ok) cat("Saved", png, "\n") else cat("PNG of", name, "not made (needs Chrome for webshot2)\n")
  }
}

hemi_table <- function(file, name_column) {
  T <- read_result(dir_tables, file)
  data.frame(Parcellation = T$parcel,
             `Brain Region` = region_name(T$parcel, name_column),
             `P-value (LH)` = p_label(T$L_p_fdr), `Z-score (LH)` = z_label(T$L_z),
             `P-value (RH)` = p_label(T$R_p_fdr), `Z-score (RH)` = z_label(T$R_z),
             check.names = FALSE, stringsAsFactors = FALSE,
             network = if ("network" %in% names(T)) T$network else NA)
}

# Table 1
t1 <- hemi_table("table1_FFA_vs_PPA.csv", "table1")
t1$Group <- ifelse(t1$network == "FFA", "FFA-network: areas predominantly connected with FFA",
                   "PPA-network: areas predominantly connected with PPA")
t1$network <- NULL
save_table(style(gt(t1, groupname_col = "Group")), "table1")

# Tables S2 and S3
for (x in list(c("table_S2_FFA_seed_map.csv", "table_S2", "table_S2"),
               c("table_S3_PPA_seed_map.csv", "table_S3", "table_S3"))) {
  t <- hemi_table(x[1], x[2])
  t$network <- NULL
  save_table(style(gt(t)), x[3])
}

