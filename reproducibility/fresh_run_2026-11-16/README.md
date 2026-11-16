# Clean fresh-run validation — 16 November 2026

Status: PASS for the numerical analysis and regenerated PNG figures in the current installed software environment.

## Execution

The notebook was rendered from beginning to end in a separate Quarto R process,
with caching disabled. A new staging directory initially contained only the
notebook, figure script, and the two raw inputs. No .RData, saved RDS results,
extracted count files, or prior outputs were supplied to that directory. Only
the project_dir string in the staged notebook was changed to the staging path;
the project notebook and statistical code were not modified. Counts were freshly
extracted from the TAR archive. The HTML render and every export section completed
successfully. make_figure1.R then ran in a separate Rscript --vanilla process.

Software: R 4.6.1; Quarto 1.10.18; DESeq2 1.52.0; apeglm 1.34.0;
clusterProfiler 4.20.3; org.Hs.eg.db 3.23.1; GO.db 3.23.1.
Full session information is in results/sessionInfo.txt.

The first successful render reproduced all 52 CSV tables exactly but used a
fallback C locale. This displayed the plus/minus character in the standalone
volcano caption as <U+00B1>. The entire analysis was rerun from raw inputs in a
second empty staging directory with LC_ALL and LANG set to
English_United States.utf8. This corrected the caption without changing code
or results. Both render logs are retained.

## Comparisons with the previous outputs

- All 52 CSV tables have identical imported values, row/column order, and missing
  values. No numerical tolerance was needed for these tables.
- All 48 model/GO-object checks passed (numerical tolerance 1e-8), covering gene
  and sample IDs, metadata, count assays, fitted means, leverage, Cook's distances,
  replacement assays, size factors, dispersions, convergence, VST, DE results,
  GO results, mappings, and submitted gene lists.
- All 16 previously exported PNG figures, including Figure 1, are byte-identical
  to the baseline after the UTF-8 rerun. PDF/RDS byte identity is not required:
  document metadata and serialized environments can differ without data changes.
- Primary DE remains 6,167 significant genes: 2,897 higher and 3,270 lower in IgAN.
- Cohort and filtering remain 43 IgAN + 22 controls and 18,756 retained genes.
- Primary replacement remains 65 counts in 53 genes, affecting 27 samples.
- Sensitivity categories remain 5,925 significant in both, 244 unadjusted only,
  151 eGFR-adjusted only, and 12,436 neither. Pearson r = 0.9980354;
  median absolute log2-fold-change difference = 0.008424732.
- GO significance remains 250 higher-expression and 150 lower-expression terms;
  simplification retains 82 and 59 terms, respectively.

## Figure and warning review

Figure 1 passed its R-measured panel-alignment check. The PDF collision audit
reported zero failures and three warnings from white legend/background fills;
visual inspection confirmed readable, unobscured labels. The regenerated
standalone volcano plot was checked after correcting the locale.

The two notebook warning blocks state that GO semantic-similarity data were not
provided and were calculated automatically. These are expected and the resulting
GO tables match. Package startup/masking and mapping-multiplicity messages are
preserved in the HTML. The unqualified select() call ran successfully because
clusterProfiler masks AnnotationDbi's select in the current library order;
qualifying it as dplyr::select remains optional code cleanup, not a run blocker.

## Files and scope

The regenerated outputs are in results/. The completed HTML report is
BE5350_Final_Proejct.html with its accompanying _files directory. This folder
contains comparison scripts and CSVs, input/source hashes, warning review,
and render logs. The pre-run baseline (`previous_results/`) and earlier
`results-before-fresh-run` backup remain in the local project and are excluded
from GitHub; hashes and comparison results document the baseline comparison.

This check establishes a successful clean-session run with the installed
packages and local raw inputs. It does not test a new machine, package
installation from scratch, automatic data downloading, or the public GitHub
repository. No analytical settings or conclusions changed.
