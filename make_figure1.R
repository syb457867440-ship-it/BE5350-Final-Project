# Combine the primary volcano and selected GO BP terms for the final report.
# Run from R: source("make_figure1.R")
# Or: Rscript make_figure1.R "D:/Yibo Main/BE5350 Final Project"
# Optional second CLI argument specifies an alternative figure output folder.
library(ggplot2)
library(patchwork)
library(ggrepel)

args <- commandArgs(trailingOnly = TRUE)
project_dir <- if (length(args) >= 1) args[1] else "D:/Yibo Main/BE5350 Final Project"
figure_dir <- if (length(args) >= 2) args[2] else file.path(project_dir, "results", "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
tables_dir <- file.path(project_dir, "results", "tables")
volcano <- read.csv(file.path(tables_dir, "volcano_source_data.csv"), check.names = FALSE)
labels <- read.csv(file.path(tables_dir, "labelled_genes.csv"), check.names = FALSE)
go <- read.csv(file.path(tables_dir, "go_selected_terms.csv"), check.names = FALSE)
stopifnot(nrow(labels) == 10, nrow(go) == 16,
          all(labels$gene_id %in% volcano$gene_id))
# Match the original label selection; no genes or GO terms are reselected.
label_data <- volcano[match(labels$gene_id, volcano$gene_id), ]
lower_labels <- label_data[label_data$significance == "Lower in IgAN", ]
higher_labels <- label_data[label_data$significance == "Higher in IgAN", ]
higher_labels$label_y <- c(TRIM25 = 70, ABCG1 = 58, PPP1R3C = 46,
                          MIR23B = 34, MIR27B = 22)[higher_labels$gene_symbol]
volcano <- volcano[order(volcano$significance != "Not significant"), ]

common_theme <- theme_classic(base_size = 9, base_family = "sans") +
  theme(axis.text = element_text(color = "black"),
        axis.line = element_line(linewidth = 0.3),
        axis.ticks = element_line(linewidth = 0.3),
        plot.title = element_text(face = "bold", size = 10),
        plot.title.position = "plot",
        legend.text = element_text(size = 8),
        legend.title = element_text(size = 8),
        plot.margin = margin(5, 7, 5, 7))

p_a <- ggplot(volcano, aes(log2FoldChange, neg_log10_padj)) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "grey65", linewidth = 0.3) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "grey65", linewidth = 0.3) +
  geom_point(aes(color = significance), size = 0.7, alpha = 0.6) +
  scale_color_manual(values = c("Higher in IgAN" = "#D55E00",
    "Lower in IgAN" = "#0072B2", "Not significant" = "grey75"),
    breaks = c("Higher in IgAN", "Lower in IgAN", "Not significant")) +
  geom_text_repel(data = lower_labels, aes(label = gene_symbol),
    size = 2.7, fontface = "italic", box.padding = 0.5,
    point.padding = 0.2, min.segment.length = 0, segment.color = "grey50",
    segment.size = 0.25, max.overlaps = Inf, seed = 5350,
    nudge_y = 5,
    max.iter = 30000, max.time = 5, show.legend = FALSE) +
  geom_segment(data = higher_labels,
    aes(xend = 3.8, yend = label_y), color = "grey55", linewidth = 0.25) +
  geom_text(data = higher_labels, aes(x = 4, y = label_y, label = gene_symbol),
    hjust = 0, size = 2.7, fontface = "italic") +
  scale_x_continuous(limits = range(c(volcano$log2FoldChange, -8, 7)),
                     breaks = c(-7.5, -5, -2.5, 0, 2.5, 5)) +
  scale_y_continuous(expand = expansion(mult = c(0.015, 0.10))) +
  labs(title = "A  Differential expression", x = "Shrunken log2 fold change (IgAN / Control)",
       y = "-log10(BH-adjusted p)", color = NULL) +
  common_theme +
  theme(legend.position = "top", legend.justification = "left",
        legend.margin = margin(0, 0, 0, 0), legend.key.height = grid::unit(3, "mm")) +
  guides(color = guide_legend(override.aes = list(size = 2, alpha = 1), nrow = 1))

go$direction <- factor(go$direction, levels = c("Higher in IgAN", "Lower in IgAN"))
go <- go[order(go$direction, go$p.adjust), ]
go$gene_ratio <- vapply(strsplit(go$GeneRatio, "/", fixed = TRUE),
  function(x) as.numeric(x[1]) / as.numeric(x[2]), numeric(1))
go$score <- -log10(pmax(go$p.adjust, .Machine$double.xmin))
go$key <- paste(go$direction, go$ID, sep = "__")
term_labels <- setNames(vapply(go$Description,
  function(x) paste(strwrap(x, width = 38), collapse = "\n"), character(1)), go$key)
go$key <- factor(go$key, levels = rev(go$key))
p_b <- ggplot(go, aes(gene_ratio, key, size = Count, color = score)) +
  geom_point() +
  facet_grid(direction ~ ., scales = "free_y", space = "free_y") +
  scale_y_discrete(labels = term_labels) +
  scale_x_continuous(labels = scales::label_percent(accuracy = 1),
    breaks = c(0.02, 0.05, 0.08), expand = expansion(mult = c(0.08, 0.12))) +
  scale_size_area(max_size = 4.5, breaks = c(50, 100, 200), name = "Contributing genes") +
  scale_color_viridis_c(option = "C", end = 0.9, name = "-log10(BH-adjusted p)") +
  labs(title = "B  GO Biological Process enrichment",
    x = "GO BP-annotated input genes (%)", y = NULL) +
  common_theme +
  theme(panel.grid.major.x = element_line(color = "grey90", linewidth = 0.25),
    panel.border = element_rect(color = "grey50", fill = NA, linewidth = 0.3),
    axis.line = element_blank(), axis.ticks.y = element_blank(),
    axis.text.y = element_text(size = 7.5, lineheight = 0.9),
    strip.background = element_rect(fill = "grey95", color = NA),
    strip.text = element_text(size = 8, face = "bold"),
    panel.spacing.y = grid::unit(2.5, "mm"),
    legend.position = "right", legend.box.spacing = grid::unit(2, "mm"),
    legend.key.height = grid::unit(4, "mm"), legend.key.width = grid::unit(3, "mm")) +
  guides(color = guide_colorbar(barheight = grid::unit(22, "mm"), barwidth = grid::unit(3, "mm")),
         size = guide_legend(override.aes = list(color = "grey25")))

# A connects gene-level effects to the biological annotations summarized in B.
# The plots share left/right plot-area boundaries; the GO facets retain shared scales.
combined <- p_a / p_b + plot_layout(heights = c(1, 1.8))
figure_width <- 7
figure_height <- 8
stem <- file.path(figure_dir, "Figure1_volcano_GO")

# Measure actual panel viewports on a matching Cairo device for layout QA.
if (nzchar(Sys.getenv("FIGURE_QA_DIR"))) {
  qa_dir <- Sys.getenv("FIGURE_QA_DIR")
  dir.create(qa_dir, recursive = TRUE, showWarnings = FALSE)
  grDevices::cairo_pdf(file.path(qa_dir, "layout_probe.pdf"),
                      width = figure_width, height = figure_height)
  print(combined)
  grid::grid.force()
  viewports <- unique(grid::grid.ls(viewports = TRUE, grobs = FALSE, print = FALSE)$name)
  panel_names <- grep("^panel(-[0-9]+)*\\.", viewports, value = TRUE)
  panels <- lapply(seq_along(panel_names), function(i) {
    grid::seekViewport(panel_names[i])
    lower <- grid::deviceLoc(grid::unit(0, "npc"), grid::unit(0, "npc"), valueOnly = TRUE)
    upper <- grid::deviceLoc(grid::unit(1, "npc"), grid::unit(1, "npc"), valueOnly = TRUE)
    grid::upViewport(0)
    list(id = letters[i], bbox_pt = c(lower$x, lower$y, upper$x, upper$y) * 72)
  })
  grDevices::dev.off()
  stopifnot(length(panels) == 3)
  manifest <- list(schema_version = 1, backend = "r-grid",
    figure = list(width_pt = figure_width * 72, height_pt = figure_height * 72),
    # The main-panel gap includes A's axis and B's title. It intentionally
    # differs from the small gap between the two GO facets.
    panels = panels, column_groups = list(c("a", "b"), c("b", "c")))
  jsonlite::write_json(manifest, file.path(qa_dir, "panel_layout.json"),
                      pretty = TRUE, auto_unbox = TRUE)
  # Optional audit_panel_alignment.py CLI supplied by the figure-review environment.
  if (nzchar(Sys.getenv("FIGURE_ALIGNMENT_AUDITOR"))) {
    status <- system2(Sys.getenv("FIGURE_QA_PYTHON"), c(
      shQuote(Sys.getenv("FIGURE_ALIGNMENT_AUDITOR")),
      shQuote(file.path(qa_dir, "panel_layout.json")),
      "--json-out", shQuote(file.path(qa_dir, "alignment.json")), "--strict"))
    stopifnot(status == 0)
  }
}
ggsave(paste0(stem, ".pdf"), combined, device = grDevices::pdf, useDingbats = FALSE,
       width = figure_width, height = figure_height, units = "in", bg = "white")
svglite::svglite(paste0(stem, ".svg"), width = figure_width, height = figure_height, bg = "white")
print(combined)
grDevices::dev.off()
ggsave(paste0(stem, ".png"), combined, device = ragg::agg_png, dpi = 300,
       width = figure_width, height = figure_height, units = "in", bg = "white")
saveRDS(combined, paste0(stem, ".rds"))
message("Saved: ", stem, ".pdf and .png (7 x 8 inches)")
