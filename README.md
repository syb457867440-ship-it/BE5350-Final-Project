# BE5350 Final Project: IgAN tubulointerstitial RNA-seq analysis

**Author:** Yibo Shi  
**Dataset:** GSE175759  
**Documentation updated:** 16 November 2026

[Final report (PDF)](Final_Writeup.pdf) · [Editable report](Final_Writeup.docx) ·
[Submission details](SUBMISSION.md)

This project examines gene-expression differences between IgA nephropathy
(IgAN) and control kidney tubulointerstitial samples. It includes sample quality
control, DESeq2 differential-expression analysis, an eGFR-adjusted sensitivity
analysis, and directional Gene Ontology Biological Process (GO BP) enrichment.
The analysis begins with the study's supplied gene-count files and sample
metadata; read alignment and gene quantification are upstream of this project.

## Project files

```text
BE5350 Final Project/
|-- README.md
|-- BE5350_Final_Proejct.qmd
|-- BE5350_Final_Proejct.html   # Completed fresh-run report
|-- make_figure1.R             # Combined volcano/GO figure
|-- reproducibility/
|   `-- fresh_run_2026-11-16/   # Validation evidence and previous outputs
|-- Implementation Plan_BE5350_Final_Project.md
|-- data/
|   |-- raw/
|   |   |-- GSE175759_RAW.tar
|   |   `-- GSE175759_series_matrix.txt.gz
|   `-- counts/                 # Created/populated by the notebook
`-- results/
    |-- tables/                # CSV results and figure source data
    |-- figures/               # PDF and 300-dpi PNG exports
    |-- objects/               # RDS analysis objects
    |-- sessionInfo.txt        # Written by the export section
    `-- README.txt             # Generated output inventory and export time
```

The notebook filename is `BE5350_Final_Proejct.qmd`, including the existing
spelling. The implementation plan records the prospective workflow, completed
analyses, findings, decisions, and remaining work. Generated files in the tree
above appear after the corresponding notebook chunks run.

## Data setup

Open the [GSE175759 GEO record](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE175759)
and download the supplementary count archive `GSE175759_RAW.tar` and the series
matrix metadata file `GSE175759_series_matrix.txt.gz`. Place both files in
`data/raw/`, retaining their names and compression. Both original files are included in this repository under `data/raw/`.
The GEO download instructions also provide an independent way to obtain them.

The notebook extracts the archive into `data/counts/`, combines the sample count
files, and matches their GEO accessions to the metadata. The original count
matrix contains 57,820 genes across 90 samples. The primary cohort retains
samples labelled `IgAN` or `Control` with `technical_outlier == "No"`, yielding
43 IgAN samples and 22 controls. Other diagnoses are outside this comparison.

## Software setup

Install R and Quarto. RStudio is optional and provides a convenient editor and
Render button. Quarto executes the R notebook through knitr; see the
[Quarto R guide](https://quarto.org/docs/computations/r.html).

Run the following in R to install the required packages:

```r
install.packages(c(
  "BiocManager", "ggplot2", "dplyr", "tibble", "tidyr",
  "ggrepel", "scales", "knitr", "rmarkdown",
  "patchwork", "ragg", "svglite", "jsonlite"
))

BiocManager::install(c(
  "DESeq2", "apeglm", "AnnotationDbi", "org.Hs.eg.db",
  "clusterProfiler", "GO.db", "GOSemSim",
  "S4Vectors", "SummarizedExperiment"
))
```

Use a compatible R/Bioconductor installation following the
[Bioconductor installation guide](https://bioconductor.org/install/).
The plan records clusterProfiler 4.20.3, org.Hs.eg.db 3.23.1, and GO.db 3.23.1
for the completed enrichment analysis. Installation commands do not pin these
versions; annotation updates can change mappings and GO results. The export
section saves the versions used in each run to `results/sessionInfo.txt`.
The PDF exports require Cairo support in R (`capabilities("cairo")`).

## Run the analysis

1. Open `BE5350_Final_Proejct.qmd` and confirm the project path near the beginning:

   ```r
   project_dir <- "D:/Yibo Main/BE5350 Final Project"
   ```

   Change this value if running the project in a different location. Input and
   export paths are constructed from this directory.

2. Start a fresh R session without restoring `.RData`. Execute the notebook
   chunks in order, or use **Render** in RStudio to run the complete notebook
   and create its HTML output. A terminal alternative is:

   ```powershell
   Set-Location -LiteralPath 'D:\Yibo Main\BE5350 Final Project'
   $env:LC_ALL = "English_United States.utf8"
   $env:LANG = "English_United States.utf8"
   quarto render "BE5350_Final_Proejct.qmd" --to html --execute --no-cache
   ```

3. Run the final **Save analysis outputs** section after all preceding chunks.
   A complete render includes this section automatically. It creates the results
   subdirectories and overwrites existing exports with matching filenames.

4. Regenerate the combined report figure after the notebook completes:

   ```r
   source("D:/Yibo Main/BE5350 Final Project/make_figure1.R")
   ```

   If the project has moved, run the script from a terminal with the new path:
   `Rscript --vanilla make_figure1.R "path/to/project"`.

5. Inspect the exported figures for complete labels and captions at the size
   used in the report. Review the result tables and retain `sessionInfo.txt`
   alongside them.

The notebook reads local input files; it does not download them automatically.
Back up `results/` before rerunning. The locale settings above are for this
Windows installation and preserve Unicode figure captions. On another platform,
use its supported UTF-8 locale. The fresh-run test retained the installed package
versions; package installation is not needed for each rerun.

## Analysis workflow

| Stage | Implemented approach |
| --- | --- |
| Input checks | Nonnegative finite integer counts; unique gene/sample IDs; metadata aligned to count columns |
| Sample QC | Library size, detected genes, top-10-gene count concentration, VST and PCA |
| Gene filter | At least 10 counts in at least 22 samples; 18,756 genes retained |
| Normalization | DESeq2 median-of-ratios size factors |
| Exploratory transformation | VST with `blind = TRUE`; PCA using the 500 most variable genes |
| Primary model | `~ diagnosis`, with Control as reference; Wald tests and BH-adjusted p < 0.05 |
| Effect-size display | apeglm-shrunken log2 fold changes; significance from the primary Wald-test results |
| Labelled-gene inspection | Ten named genes: five smallest raw p-values per direction among BH-significant genes; sample counts, Cook's distances, and replacement checks |
| Sensitivity analysis | Matched unadjusted and eGFR-adjusted models using identical counts and size factors |
| GO enrichment | Higher- and lower-expression lists analysed separately using a mapped tested-gene background |
| GO presentation | Wang similarity cutoff 0.7; eight retained representative terms per direction |

The sensitivity model uses `~ egfr_10 + diagnosis`, where eGFR is mean-centred
and divided by 10. Both sensitivity fits disable count replacement
(`minReplicatesForReplace = Inf`), and both result calls disable Cook's-distance
filtering and independent filtering. This controlled comparison is separate
from the primary analysis, which retains its original settings.

For GO analysis, version suffixes are removed from Ensembl IDs before mapping
to Entrez IDs. Unmapped and ambiguous mappings are excluded, Entrez IDs are
deduplicated, and IDs represented in both significant directions are removed
from the directional lists while retained in the background. The background
starts from primary-result genes with finite adjusted p-values and uses the
same mapping rules as the directional lists.

`enrichGO()` tests BP terms with gene-set sizes 10–500. Reporting cutoffs are
set to 1 to retain the returned terms, followed by selection at BH-adjusted
p < 0.05 separately within each direction. Simplification affects the displayed
term selection; full enrichment tables are preserved.

## Recorded findings and interpretation

The following findings are recorded in the implementation plan:

- Primary differential expression: 6,167 significant genes, including 2,897
  higher and 3,270 lower in IgAN.
- eGFR sensitivity comparison: Pearson correlation of diagnosis log2 fold
  changes was 0.998, with a median absolute difference of 0.00842. There were
  5,925 genes significant in both sensitivity models, 244 in the unadjusted
  model only, and 151 in the adjusted model only. These counts refer to the
  controlled sensitivity pair, whose settings differ from the primary model.
- GO BP: 250 significant terms for higher-expression genes and 150 for
  lower-expression genes; simplification retained 82 and 59 representative
  terms. Higher-expression genes showed immune-related enrichment, while
  lower-expression genes showed mitochondrial and energy-related enrichment.

Disease and control samples differ in tissue acquisition context: biopsies
versus non-cancer-affected nephrectomy cortex, as documented in the plan's
literature review. This affects interpretation of diagnosis-associated
expression, including the immediate-early genes among the leading lower-in-IgAN
results. eGFR adjustment does not resolve this tissue-source difference.

For “negative regulation of myoblast fusion” (GO:1901740), all 37 contributing
genes were recovered from the installed annotation database and carried NAS
(Non-traceable Author Statement) evidence. The contributors were 36 RPL genes
and UBA52. The term is retained and interpreted through these ribosomal genes;
its enrichment among lower-expression genes and its regulatory wording do not
establish increased myoblast fusion in kidney tissue.

## Output guide

| Output | Contents |
| --- | --- |
| `results/tables/primary_DE_unshrunken.csv` | Primary DESeq2 Wald-test results with explicit gene IDs |
| `results/tables/primary_DE_apeglm_annotated.csv` | Shrunken effects with Ensembl IDs and gene symbols |
| `results/tables/sensitivity_*.csv` | Both sensitivity results, comparisons, significance counts, and selected-gene inspections |
| `results/tables/go_*.csv` | Mapping records, submitted lists, full/significant/representative GO terms, contributors, and evidence review |
| Other CSV tables | Sample QC, filtering, PCA, eGFR, labelled-gene counts, and count-replacement summaries |
| `results/figures/` | QC, PCA, MA, volcano, labelled-gene, sensitivity, GO, and diagnostic plots as PDF and PNG |
| `results/objects/deseq2_analysis.rds` | Primary and sensitivity models, VST, and result objects |
| `results/objects/go_analysis.rds` | GO enrichment objects, mappings, and gene lists |
| `results/objects/analysis_tables.rds` | Exported tables with original R column structures |
| `results/objects/ggplot_figures.rds` | ggplot objects for later inspection or re-export |

CSV mapping candidates are separated by semicolons. The corresponding RDS
tables retain list columns. Load an RDS file with `readRDS()` in a compatible
R environment.

## Reproducibility status and AI assistance

A complete clean fresh run passed on **16 November 2026**, using R 4.6.1 and
Quarto 1.10.18. Quarto executed every notebook chunk with caching disabled in
an isolated directory containing only the source files and raw inputs. No
workspace, saved analysis objects, extracted count files, or previous results
were restored. Only the staged project path was changed; analysis code and
settings were unchanged. The separate Figure 1 script also completed.

- **52 CSV tables:** exact matches to the previous files.
- **48 model/GO-object checks:** all passed at numerical tolerance 1e-8.
- **16 PNG figures, including Figure 1:** byte-identical matches.

The cohort, 18,756 retained genes, 6,167 significant primary genes, sensitivity
results, and GO findings were unchanged. A full repeat with the Windows UTF-8
locale corrected a caption symbol from the initial headless run. The two GO
warnings about automatically calculating semantic-similarity data were expected.
Figure 1 passed panel-alignment and visual review; its collision-audit warnings
concerned harmless white legend backgrounds.

See the [validation report](reproducibility/fresh_run_2026-11-16/README.md),
[table comparisons](reproducibility/fresh_run_2026-11-16/table_comparison.csv),
and [model checks](reproducibility/fresh_run_2026-11-16/model_object_comparison.csv).
That folder also contains execution logs, input/source hashes, comparison
scripts. The large pre-run backup (`previous_results/`) is retained locally
and is intentionally excluded from this repository. Refreshed outputs are
in `results/`, and the complete rendered notebook is
[BE5350_Final_Proejct.html](BE5350_Final_Proejct.html).

This validates the current installed environment and local raw inputs.
Installation on a new machine and reproduction from a public repository clone
remain separate checks.

ChatGPT/Codex assisted with code review, debugging, interpretation, and
documentation. The implementation plan records analysis decisions and their
rationale. The dated records `AI_Chat_History_2026-11-16.md` and
`AI_Prompts_2026-11-16.md` include the fresh-run discussion and supplement the
earlier AI records. Retain these records and the implementation plan with the
course submission.
