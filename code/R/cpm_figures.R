# Figures 5, 6 and S5 (CPM) and the bootstrap confidence intervals.
#
# Usage:  Rscript code/R/cpm_figures.R <repository folder>
#
# Inputs (written by code/analysis/a05_cpm.m):
#   results/cpm/<model>_predictions.csv, <model>_neg_consistency.csv,
#   <model>_null.csv (only when the permutation test was run),
#   results/tables/cpm_summary.csv
# Outputs:
#   results/figures/figure5.png, figure6.png, figureS5.png
#   results/tables/cpm_bootstrap_ci.csv  (Spearman r with its 95% BCa bootstrap
#                                         CI: 5000 resamples, seed 123)
#
# Author: Orhan Soyuhos, 2026
# License: GPL-3.0 (see LICENSE)

script_dir <- local({
  f <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(f)) dirname(normalizePath(sub("^--file=", "", f[1]))) else file.path(getwd(), "code", "R")
})
source(file.path(script_dir, "common.R"))
suppressPackageStartupMessages(library(boot))

summary_cpm <- read_result(dir_tables, "cpm_summary.csv")

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

plot_perm_hist <- function(perm_values, observed_value, binwidth = 0.05) {
  df <- data.frame(perm_value = as.numeric(perm_values))
  min_val <- round(min(df$perm_value), 2)
  max_val <- round(max(df$perm_value), 2)
  ggplot(df, aes(x = perm_value)) +
    geom_histogram(binwidth = binwidth, fill = "gray80", color = "black", alpha = 0.7) +
    geom_vline(xintercept = observed_value, color = "black", linetype = "dashed", linewidth = 1.5) +
    theme_custom() +
    theme(axis.ticks.y = element_blank(), axis.text.y = element_blank(),
          axis.title.y = element_blank(), axis.line.y = element_blank(),
          axis.title.x = element_blank()) +
    scale_x_continuous(breaks = c(min_val, 0, max_val),
                       labels = function(x) ifelse(x == 0, "0", sprintf("%.2f", x)))
}

plot_scatter_with_fit <- function(actual, predicted, perm_p_value, corr_coef, x_label, y_label,
                                  dot_color = "black", vjust = -4.5, hjust = -0.05) {
  corr_coef <- round(corr_coef, 2)
  df <- data.frame(Predicted = predicted, Actual = actual)
  p <- ggplot(df, aes(x = Predicted, y = Actual)) +
    geom_point(color = dot_color, size = 6, alpha = 0.6) +
    geom_smooth(method = "lm", formula = y ~ x, color = "black", linetype = "solid", se = TRUE) +
    labs(x = x_label, y = y_label) +
    theme_custom()
  if (is.na(perm_p_value)) {
    rp_label <- bquote(italic(r) == .(corr_coef))
  } else {
    rp_label <- bquote(atop(italic(r) == .(corr_coef), italic(p) == .(round(perm_p_value, 3))))
  }
  n_label <- bquote(italic(N) == .(length(actual)))
  p +
    annotate("label", x = -Inf, y = -Inf, label = deparse(rp_label), parse = TRUE,
             hjust = hjust, vjust = vjust, size = 8, fill = "white", color = "black",
             label.padding = unit(0.25, "lines"), label.r = unit(0.15, "lines"), family = font_family) +
    annotate("label", x = Inf, y = -Inf, label = deparse(n_label), parse = TRUE,
             hjust = 1, vjust = -0.2, size = 8, fill = "white", color = "black",
             label.padding = unit(0.25, "lines"), label.r = unit(0.15, "lines"), family = font_family) +
    coord_cartesian(clip = "off")
}

# Region order of the matrix and bar plots: alphabetical, ignoring case.
label_levels <- function(x) {
  u <- unique(x)
  u[order(tolower(u), u)]
}

plot_heatmap <- function(mat, labels, axes_label) {
  short_labels <- sub("^[RL]-", "", labels)
  groups <- ifelse(startsWith(labels, "R"), "RH", "LH")
  rownames(mat) <- labels
  colnames(mat) <- labels
  df <- as.data.frame(as.table(mat))
  colnames(df) <- c("Var1_Full", "Var2_Full", "Freq")
  df$Var1_Short <- factor(sub("^[RL]-", "", df$Var1_Full), levels = rev(label_levels(short_labels)))
  df$Var2_Short <- factor(sub("^[RL]-", "", df$Var2_Full), levels = label_levels(short_labels))
  df$Var1_Group <- factor(ifelse(startsWith(as.character(df$Var1_Full), "R"), "RH", "LH"), levels = c("LH", "RH"))
  df$Var2_Group <- factor(ifelse(startsWith(as.character(df$Var2_Full), "R"), "RH", "LH"), levels = c("LH", "RH"))
  ggplot(df, aes(x = Var2_Short, y = Var1_Short, fill = Freq)) +
    geom_tile(color = "gray80", linewidth = 0.1) +
    facet_grid(Var1_Group ~ Var2_Group, scales = "free", space = "free") +
    scale_fill_gradientn(colours = c("white", "black"), values = c(0, 1), limits = c(0, 1),
                         breaks = c(0, 1), name = "Selection consistency") +
    guides(fill = guide_colorbar(direction = "vertical", barheight = unit(5, "cm"),
                                 barwidth = unit(0.5, "cm"), title.position = "right")) +
    labs(x = axes_label, y = axes_label) +
    theme_custom() +
    theme(axis.text.x = element_text(size = 18, angle = 90, hjust = 1, vjust = 0.5, color = "gray20"),
          axis.text.y = element_text(size = 18, hjust = 1, vjust = 0.5, color = "gray20"),
          strip.background = element_rect(fill = "white", color = "black"),
          panel.spacing = unit(0.1, "lines"),
          legend.title = element_text(size = 20, color = "gray20", angle = 90, hjust = 0.5, vjust = 0.5))
}

plot_number_edges <- function(mat, labels, axis_label, left_color = "gray80", right_color = "black",
                              legend_pos = c(0.95, 0.9)) {
  short_labels <- sub("^[RL]-", "", labels)
  df <- data.frame(Short_Label = factor(short_labels, levels = label_levels(short_labels)),
                   Group = ifelse(startsWith(labels, "R"), "RH", "LH"),
                   Total = rowSums(mat))
  ggplot(df, aes(x = Short_Label, y = Total, fill = Group)) +
    geom_bar(stat = "identity", color = "black", width = 0.7) +
    labs(x = axis_label, y = "Node strength") +
    scale_fill_manual(values = c("LH" = left_color, "RH" = right_color)) +
    theme_custom() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 20),
          legend.position = "inside", legend.position.inside = legend_pos)
}

bootstrap_spearman_ci <- function(x, y, R = 5000, conf = 0.95, seed = 123) {
  df <- na.omit(data.frame(x = x, y = y))
  set.seed(seed)
  stat_fun <- function(data, idx) cor(data$x[idx], data$y[idx], method = "spearman")
  b <- boot::boot(data = df, statistic = stat_fun, R = R)
  ci <- boot::boot.ci(b, conf = conf, type = "bca")
  c(r = unname(b$t0), ci_low = unname(ci$bca[4]), ci_high = unname(ci$bca[5]))
}

# ---------------------------------------------------------------------------
# Load one model
# ---------------------------------------------------------------------------

load_model <- function(id) {
  pred <- read_result(dir_cpm, paste0(id, "_predictions.csv"))
  cons <- read_result(dir_cpm, paste0(id, "_neg_consistency.csv"))
  labels <- cons$label
  mat <- as.matrix(cons[, -1])
  null_file <- file.path(dir_cpm, paste0(id, "_null.csv"))
  null <- if (file.exists(null_file)) read_result(null_file)$r_neg else NULL
  row <- summary_cpm[summary_cpm$model == id, ]
  r <- row$r_neg
  p <- if (is.null(null)) NA else mean(null >= r)   # one-sided, iteration 1 = observed model
  list(id = id, actual = pred$actual, predicted = pred$predicted_neg, labels = labels, mat = mat,
       null = null, r = r, p = p)
}

scatter_panel <- function(m, color, x_label, y_label, vjust = -4.5, hjust = -0.05, inset = NULL) {
  p <- plot_scatter_with_fit(m$actual, m$predicted, m$p, m$r, x_label, y_label, color, vjust, hjust)
  if (!is.null(m$null) && !is.null(inset)) {
    p <- p + inset_element(plot_perm_hist(m$null, m$r), left = inset[1], bottom = inset[2],
                           right = inset[3], top = inset[4])
  }
  p
}

red <- "#CD0000"
blue <- "#0000CD"
inset_right <- c(0.6, 0.7, 1, 1.05)
inset_left <- c(0.02, 0.7, 0.34, 1.05)
inset_left_narrow <- c(0.02, 0.7, 0.25, 1.05)
y_face <- "Actual RT in face-matching task (ms)"
y_0bk <- "Actual RT in 0-back scene task (ms)"
y_2bk <- "Actual RT in 2-back scene task (ms)"

# ---------------------------------------------------------------------------
# Bootstrap confidence intervals of all models
# ---------------------------------------------------------------------------

ci <- do.call(rbind, lapply(summary_cpm$model, function(id) {
  m <- load_model(id)
  b <- bootstrap_spearman_ci(m$actual, m$predicted)
  data.frame(model = id, r = b[["r"]], ci_low = b[["ci_low"]], ci_high = b[["ci_high"]],
             p_perm = m$p, N = length(m$actual))
}))
write.csv(ci, file.path(dir_tables, "cpm_bootstrap_ci.csv"), row.names = FALSE)
print(ci, digits = 3)

# ---------------------------------------------------------------------------
# Figure 5: face-matching RT
# ---------------------------------------------------------------------------

m1 <- load_model("face_FFA37")
m2 <- load_model("face_PPA23")
a <- scatter_panel(m1, red, "RT predicted from FFA network (ms)", y_face, vjust = -6.5, inset = inset_right)
b <- scatter_panel(m2, blue, "RT predicted from PPA network (ms)", y_face, vjust = -6.5, inset = inset_right)
c1 <- plot_heatmap(m1$mat, m1$labels, "FFA network")
c2 <- plot_number_edges(m1$mat, m1$labels, "FFA network", legend_pos = c(0.9, 0.9))
row1 <- (wrap_elements((plot_spacer() | a | plot_spacer()) + plot_layout(widths = c(0.03, 1, 0.03))) |
         wrap_elements((plot_spacer() | b | plot_spacer()) + plot_layout(widths = c(0.03, 1, 0.03))))
row2 <- (wrap_elements(c1) | wrap_elements(c2)) + plot_layout(widths = c(1.7, 1))
fig5 <- (row1 / row2) + plot_layout(heights = c(1, 1.25)) + plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(size = 35, family = font_family))
save_png(fig5, "figure5", 18.5, 19)

# ---------------------------------------------------------------------------
# Figure 6: 0-back and 2-back scene RT
# ---------------------------------------------------------------------------

m0 <- load_model("0bk_PPA23")
m2 <- load_model("2bk_PPA23")
f0 <- load_model("0bk_FFA37")
f2 <- load_model("2bk_FFA37")
r1 <- (wrap_elements(scatter_panel(m0, blue, "RT predicted from PPA network (ms)", y_0bk, inset = inset_left)) |
       wrap_elements(plot_heatmap(m0$mat, m0$labels, "PPA network")) |
       wrap_elements(plot_number_edges(m0$mat, m0$labels, "PPA network", legend_pos = c(0.1, 0.9)))) +
  plot_layout(widths = c(1, 1.05, 0.65))
r2 <- (wrap_elements(scatter_panel(m2, blue, "RT predicted from PPA network (ms)", y_2bk, inset = inset_left)) |
       wrap_elements(plot_heatmap(m2$mat, m2$labels, "PPA network")) |
       wrap_elements(plot_number_edges(m2$mat, m2$labels, "PPA network"))) +
  plot_layout(widths = c(1, 1.05, 0.65))
s0 <- scatter_panel(f0, red, "RT predicted from FFA network (ms)", y_0bk, vjust = -7, hjust = -5, inset = inset_left_narrow)
s2 <- scatter_panel(f2, red, "RT predicted from FFA network (ms)", y_2bk, vjust = -7, hjust = -5, inset = inset_left_narrow)
r3 <- (wrap_elements((plot_spacer() | s0 | plot_spacer()) + plot_layout(widths = c(0.025, 1, 0.025))) |
       wrap_elements((plot_spacer() | s2 | plot_spacer()) + plot_layout(widths = c(0.025, 1, 0.025))))
fig6 <- (r1 / r2 / r3) + plot_layout(heights = c(1, 1, 1)) + plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(size = 32, family = font_family))
save_png(fig6, "figure6", 24, 27)

# ---------------------------------------------------------------------------
# Figure S5: seed-excluded networks
# ---------------------------------------------------------------------------

e1 <- load_model("face_FFA35")
e2 <- load_model("0bk_PPA21")
e3 <- load_model("2bk_PPA21")
net_f <- "Face network (excluding FFA)"
net_s <- "Scene network (excluding PPA)"
q1 <- (wrap_elements(scatter_panel(e1, red, "RT predicted from face network (excluding FFA) (ms)", y_face,
                                   vjust = -6.5, hjust = -3.5, inset = inset_left)) |
       wrap_elements(plot_heatmap(e1$mat, e1$labels, net_f)) |
       wrap_elements(plot_number_edges(e1$mat, e1$labels, net_f, legend_pos = c(0.9, 0.9)))) +
  plot_layout(widths = c(0.9, 1.1, 0.65))
q2 <- (wrap_elements(scatter_panel(e2, blue, "RT predicted from scene network (excluding PPA) (ms)", y_0bk,
                                   vjust = -6.5, hjust = -3.5, inset = inset_left)) |
       wrap_elements(plot_heatmap(e2$mat, e2$labels, net_s)) |
       wrap_elements(plot_number_edges(e2$mat, e2$labels, net_s, legend_pos = c(0.1, 0.9)))) +
  plot_layout(widths = c(0.9, 1.1, 0.65))
q3 <- (wrap_elements(scatter_panel(e3, blue, "RT predicted from scene network (excluding PPA) (ms)", y_2bk,
                                   vjust = -0.1, inset = inset_left)) |
       wrap_elements(plot_heatmap(e3$mat, e3$labels, net_s)) |
       wrap_elements(plot_number_edges(e3$mat, e3$labels, net_s))) +
  plot_layout(widths = c(0.9, 1.1, 0.65))
figS5 <- (q1 / q2 / q3) + plot_layout(heights = c(1, 1, 1)) + plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(size = 32, family = font_family))
save_png(figS5, "figureS5", 26, 29)
