# Shared settings and helpers for the R figures and tables.
# Sourced by cpm_figures.R, figure_S4.R and tables.R.
#
# Author: Orhan Soyuhos, 2026
# License: GPL-3.0 (see LICENSE)

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
})

# Repository root: first command-line argument, else the working directory.
args <- commandArgs(trailingOnly = TRUE)
repo <- if (length(args) >= 1) normalizePath(args[1]) else normalizePath(".")
dir_results <- file.path(repo, "results")
dir_tables  <- file.path(dir_results, "tables")
dir_cpm     <- file.path(dir_results, "cpm")
dir_figures <- file.path(dir_results, "figures")
dir.create(dir_figures, showWarnings = FALSE, recursive = TRUE)
dir.create(dir_tables,  showWarnings = FALSE, recursive = TRUE)

# Arial when the system has it, otherwise the default sans-serif font.
font_family <- tryCatch({
  if ("Arial" %in% systemfonts::system_fonts()$family) "Arial" else "sans"
}, error = function(e) "sans")

dpi_value <- 300

theme_custom <- function(base_size = 14) {
  theme_bw(base_size = base_size) +
    theme(
      text = element_text(family = font_family),
      strip.text = element_text(size = 21),
      axis.title.x = element_text(size = 24, margin = margin(t = 10), color = "gray20"),
      axis.title.y = element_text(size = 24, margin = margin(r = 5), color = "gray20"),
      axis.text.x = element_text(size = 21, color = "gray20"),
      axis.text.y = element_text(size = 21, color = "gray20"),
      plot.title = element_text(size = 25, hjust = 0.5, color = "gray20", margin = margin(b = 15)),
      legend.title = element_blank(),
      legend.text = element_text(size = 20, color = "gray20"),
      legend.position = "right",
      legend.background = element_blank(),
      legend.key = element_blank(),
      legend.key.height = unit(0.8, "cm"),
      legend.box.background = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.border = element_blank(),
      axis.line = element_line(color = "gray20", linewidth = 0.5),
      axis.ticks.x = element_line(color = "gray20", linewidth = 0.5),
      axis.ticks.y = element_line(color = "gray20", linewidth = 0.5)
    )
}

save_png <- function(plot, name, width, height) {
  file <- file.path(dir_figures, paste0(name, ".png"))
  ggsave(file, plot = plot, device = "png", width = width, height = height, units = "in", dpi = dpi_value)
  cat("Saved", file, "\n")
}

read_result <- function(...) read.csv(file.path(...), check.names = FALSE, stringsAsFactors = FALSE)
