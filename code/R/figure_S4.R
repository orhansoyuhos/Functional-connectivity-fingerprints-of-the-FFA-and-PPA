# Figure S4 and the RT-accuracy correlations of Section 2.4.
#
# Usage:  Rscript code/R/figure_S4.R <repository folder>
#
# Input:  results/tables/behaviour_final_samples.csv (code/analysis/a06_behaviour.m):
#         the subjects of each CPM sample (mean FD <= 0.15 mm, scores available)
# Output: results/figures/figureS4.png
#         results/tables/behaviour_rt_accuracy.csv
#
# RT-accuracy relation: Spearman correlation.
#
# Author: Orhan Soyuhos, 2026
# License: GPL-3.0 (see LICENSE)

script_dir <- local({
  f <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(f)) dirname(normalizePath(sub("^--file=", "", f[1]))) else file.path(getwd(), "code", "R")
})
source(file.path(script_dir, "common.R"))

S <- read_result(dir_tables, "behaviour_final_samples.csv")
tasks <- list(
  list(task = "face-matching", color = "#CD0000", x = "Face-matching RT (ms)", y = "Face-matching accuracy (%)",
       ann = c(Inf, -Inf, 1.1, -0.5)),
  list(task = "0-back scene", color = "#0000CD", x = "0-back scene RT (ms)", y = "0-back scene accuracy (%)",
       ann = c(Inf, -Inf, 1.1, -0.5)),
  list(task = "2-back scene", color = "#0000CD", x = "2-back scene RT (ms)", y = "2-back scene accuracy (%)",
       ann = c(-Inf, -Inf, -0.1, -0.5)))

format_pval <- function(p) {
  if (p < 0.001) "p < 0.001" else if (p < 0.01) "p < 0.01" else if (p < 0.05) "p < 0.05" else sprintf("p = %.2f", p)
}

rows <- list()
stats <- list()
for (t in tasks) {
  df <- S[S$task == t$task, ]
  df <- na.omit(data.frame(v1 = df$rt, v2 = df$accuracy))
  ct <- cor.test(df$v1, df$v2, method = "spearman", exact = FALSE)
  stats[[t$task]] <- data.frame(task = t$task, score_rt = S$score_rt[S$task == t$task][1],
                                N = nrow(df), r = unname(ct$estimate), p = ct$p.value)
  txt <- sprintf("r = %.2f\n%s", ct$estimate, format_pval(ct$p.value))
  p1 <- ggplot(df, aes(x = v1)) +
    geom_histogram(bins = 15, fill = t$color, color = "white", alpha = 0.8) +
    annotate("text", x = Inf, y = Inf, label = sprintf("N = %d", nrow(df)), hjust = 1.1, vjust = 1.5,
             size = 7, family = font_family) +
    labs(x = t$x, y = "Count") + theme_custom(12) +
    theme(plot.margin = margin(t = 10, r = 20, b = 10, l = 10, unit = "pt"))
  p2 <- ggplot(df, aes(x = v2)) +
    geom_histogram(bins = 15, fill = t$color, color = "white", alpha = 0.8) +
    labs(x = t$y, y = "Count") + theme_custom(12) +
    theme(plot.margin = margin(t = 10, r = 20, b = 10, l = 10, unit = "pt"))
  p3 <- ggplot(df, aes(x = v1, y = v2)) +
    geom_point(alpha = 0.6, size = 3, color = t$color) +
    geom_smooth(method = "lm", formula = y ~ x, color = "black", linewidth = 1) +
    annotate("text", x = t$ann[1], y = t$ann[2], label = txt, hjust = t$ann[3], vjust = t$ann[4],
             size = 7, fontface = "italic", family = font_family) +
    labs(x = t$x, y = t$y) + theme_custom(12) +
    theme(plot.margin = margin(t = 10, r = 20, b = 10, l = 10, unit = "pt"))
  rows[[length(rows) + 1]] <- wrap_elements(p1 + p2 + p3)
}

res <- do.call(rbind, stats)
write.csv(res, file.path(dir_tables, "behaviour_rt_accuracy.csv"), row.names = FALSE)
print(res, digits = 3)

figS4 <- rows[[1]] / rows[[2]] / rows[[3]] + plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(size = 30, face = "plain", family = font_family))
save_png(figS4, "figureS4", 18, 20)
