# Implementation plan: IgAN bulk RNA-seq analysis

## Disclosure

I wrote most of the code in this project myself and used ChatGPT/Codex mainly
to check it. Codex generated a smaller part of the code: the count-matrix
assembly, the Cook's-distance and count-replacement checks, the two
sensitivity models, the `enrichGO()` call, and the final export section. It
also drafted the README and helped update this plan. I reviewed each
suggestion before adopting it, and I am responsible for the analysis choices
and their interpretation.

All AI use for this project is recorded in `AI_Chat_History.md` and
`AI_Prompts.md`, with attachments in `AI_Chat_Attachments/`. Code in the
notebook that does not appear in that history was written by me without AI
assistance.

## Research question

I want to investigate how gene expression in kidney tubulointerstitial tissue 
differs between patients with IgA nephropathy and controls. I will also examine 
whether the differentially expressed genes are associated with particular 
biological processes.

## Dataset and feasibility

I propose to use GSE175759, a public bulk RNA-seq dataset with gene-count files 
and sample metadata.

Before beginning statistical analysis, I will confirm:

- What tissue and sample groups were collected.
- Whether the supplied values are unnormalised gene counts suitable for DESeq2.
- Which clinical and technical variables are available.
- Whether the study identifies samples that should be excluded.
- Whether the dataset supports an interpretable IgAN-versus-control comparison.

I will document the original study’s processing and identify where my analysis
begins.

## Status of this document

The proposed workflow below is retained as the prospective plan. Dated updates
record completed work, results, and decisions made after inspecting the data.
The 12 November 2026 documentation review reconciled these updates with the
current notebook and the results discussed during the analysis. It did not rerun
the analysis or change the primary statistical results.

## Proposed workflow

### 1. Prepare the data

I will import the count files, combine them into a matrix, and match each sample 
to its metadata. I will check identifiers, missing values, count types, and 
sample order before proceeding.

### 2. Assess sample quality

I will examine library sizes, detected genes, and overall expression patterns 
using PCA.

Unusual samples will be investigated. Any exclusion beyond the original authors’ 
recommendations will require a documented reason. Separation from the expected 
diagnosis group alone will not be sufficient.

### 3. Analyse differential expression

I plan to use DESeq2 to compare IgAN with controls.

Before examining differential-expression results, I will document:

- The low-expression filtering rule.
- The reference group.
- The model formula and rationale for included covariates.
- The significance threshold and multiple-testing correction.

The proposed significance threshold is a Benjamini–Hochberg adjusted p-value 
below 0.05. I will consider effect sizes alongside statistical significance.

### 4. Examine robustness

After inspecting the metadata, I will decide whether additional clinical or 
technical variables warrant sensitivity analyses.

If results depend strongly on model choices or individual observations, I will 
investigate and document that dependence. Sensitivity analyses will be reported 
separately from the primary analysis.

### 5. Interpret biological patterns

I will annotate genes and perform functional enrichment if the differential-
expression results provide suitable input.

I will document the annotation source, gene-list criteria, background genes, 
and multiple-testing correction. I will distinguish enrichment of gene 
annotations from direct evidence of biological activity.

### 6. Present and reproduce the findings

I expect to produce:

- A documented analysis notebook.
- Sample-quality summaries.
- Differential-expression and enrichment tables.
- Figures addressing the biological question.
- A README with data-access and execution instructions.
- A short report explaining the findings and limitations.

## Update, 12 November 2026: sample-quality findings and decisions (steps 1–2)

This section documents observations made after inspecting the sample-quality 
results. The date identifies this documentation update, not necessarily the date 
each analysis was performed.

### Samples analysed

After restricting the dataset to IgAN and Control and removing the three samples 
labelled as technical outliers by the original authors, 65 samples remained: 43 
IgAN and 22 Control. Sample IDs were unique, and the metadata order matched the 
count matrix. The excluded samples were GSM5345911 (IgAN_sample10),
GSM5345919 (IgAN_sample18), and GSM5345921 (IgAN_sample20), as flagged in the
deposited metadata.

### Library size and gene detection

Total gene-assigned counts ranged from approximately 27.2 million to 58.4 
million. Two IgAN samples were investigated:

- **GSM5345942** had the largest library, with 58.4 million counts. It had 
27,752 detected genes, and its ten most abundant genes accounted for 27.8% of 
counts. These checks provided no technical reason to exclude it.
- **GSM5345939** had fewer detected genes, 19,631, despite a library size of 
approximately 36.7 million counts. Its top-ten count share was 38.0%, below 
several controls with shares of approximately 46–57%. This sample was not extreme by the top-ten concentration metric across the
selected cohort. The metric did not establish the cause of its lower gene
detection, which remains unresolved.

Both samples were retained. No samples were excluded beyond the original 
authors’ outlier labels.

### Group-level observations

The five samples with the highest top-ten count shares were controls, and 
controls tended to have fewer detected genes. These differences could reflect 
biological or technical factors.

The observations warrant checking expression composition and normalisation. 
They do not, by themselves, establish that DESeq2 normalisation is invalid.

### Low-expression filtering

The applied rule retained genes with at least 10 counts in at least 22 samples, 
corresponding to the smaller group size. It retained 18,756 of the original 
57,820 genes.

The count threshold was applied across samples without requiring expression in 
both groups.

## Update, 12 November 2026: PCA findings and follow-up (step 2)

This section was written after viewing the PCA results.

PCA used variance-stabilised counts with `blind = TRUE` and the 500 most 
variable genes. PC1 explained 23.4% and PC2 explained 14.7% of the variance.

IgAN and Control samples showed partial separation along PC1, with substantial 
overlap. Several controls fell within the region occupied by IgAN samples. 
Controls varied mainly along PC1, while IgAN samples showed greater variation 
along PC2.

GSM5345939 and GSM5345942 fell among the other IgAN samples rather than 
appearing isolated. Both were retained.

Possible follow-up checks include associations between PC1 and top-ten count 
share, and between PC2 and eGFR. These checks would be exploratory because they 
were proposed after viewing the PCA. Associations with a principal component 
would not establish the biological or technical cause of that component.

## Update, 12 November 2026: model settings, diagnostics, and primary results (step 3)

This section records the model settings and observations after inspecting the 
fitted model and differential-expression results.

### Applied model settings

- Low-expression filter: at least 10 counts in at least 22 samples.
- Reference group: Control.
- Contrast: IgAN relative to Control.
- Primary design: `~ diagnosis`.
- Normalisation: DESeq2 default median-of-ratios size factors; checks confirmed
  that all size factors were finite and positive.
- Statistical testing: negative-binomial models with the default Wald test.
- Effect-size visualisation: apeglm shrinkage of the diagnosis coefficient;
  original Wald p-values and BH-adjusted p-values were retained.
- Significance threshold: Benjamini–Hochberg adjusted p-value below 0.05.

The primary model estimates the overall difference between the sampled groups.
An eGFR-adjusted model addresses a different question: whether expression 
differences remain after accounting for measured kidney function. The completed
sensitivity analysis is documented separately below.

### Model diagnostics

The model converged for all 18,756 retained genes.

Dispersion estimates decreased with mean expression and levelled off near 0.1. 
Most final estimates were moderated toward the fitted trend, while some 
high-dispersion genes remained unshrunk.

The raw p-value distribution had a peak near zero and an approximately flat tail. 
This pattern is compatible with widespread differential expression, but it does 
not establish that the model is correctly specified or that confounding is absent.

### Primary result

At adjusted p-value < 0.05, 6,167 genes were significant:

- 2,897 had higher expression in IgAN.
- 3,270 had lower expression in IgAN.

This represents approximately 33% of the retained genes. I will report effect 
sizes alongside significance and clearly identify any additional effect-size 
threshold.

A large fraction of significant genes warrants attention to normalisation and 
tissue composition, but the percentage alone does not demonstrate a failure of 
the size-factor estimates.

## Update, 12 November 2026: inspection of the labelled genes (step 3)

This update was written after viewing the differential-expression results. 
The checks below were motivated by those results and were not part of the 
proposed workflow above.

### What I did

I labelled the five named genes with the smallest raw p-values in each direction
among genes with BH-adjusted p < 0.05, then examined their per-sample normalised
counts using group medians, minimum and maximum values, and the number of samples
with zero counts. The volcano caption now matches this selection rule.

I also generated a ten-panel plot showing every sample, with boxplots and
horizontally jittered points on a log10(normalised count + 1) scale. Each panel
uses its own y-axis range. This transformation retains zero-count observations
for display and does not alter the counts used for model fitting.

### What I found

- **Lower in IgAN:** DUSP1, FOS, NR4A1, FOSB, and EGR1. Their apeglm-shrunken 
estimates correspond to approximately 17- to 145-fold lower expression in IgAN. 
Adjusted p-values ranged from approximately \(1.24 \times 10^{-156}\) to
\(6.14 \times 10^{-75}\). For DUSP1, FOS, and NR4A1, the lowest control value 
exceeded the highest IgAN value. FOSB and EGR1 had overlapping ranges.
- **Higher in IgAN:** TRIM25, ABCG1, and PPP1R3C showed approximately 1.4- to 
2.1-fold increases, with no zero counts. Ratios of group medians were broadly 
consistent with the model estimates.
- **MIR23B and MIR27B:** These genes showed significant increases at low abundance. 
Their control medians were approximately 0 and 3.5, respectively, and MIR23B had 
zero counts in 13 of 22 controls. Their distributions need to be interpreted with 
their low abundance in mind. They remain separate gene-level results.
- **FOS:** The shrunken model estimate corresponded to approximately 85-fold lower
expression in IgAN, compared with a control-to-IgAN median ratio of about 44. 
These summaries estimate different quantities. The control distribution was 
right-skewed. The Cook's-distance checks below found no observations above the
default diagnostic cutoff for FOS. This finding does not attribute the
difference between the model estimate and median ratio to particular samples.

### Cook’s-distance and count-replacement checks

Cook’s distances were available for every sample for all ten labelled genes. 
None exceeded the default diagnostic cutoff, and no counts were replaced for 
these genes. The primary analysis was retained unchanged.

These checks found no observations flagged by this diagnostic. They do not 
resolve the potential confounding between diagnosis and tissue acquisition.

### Interpretation

DUSP1, FOS, NR4A1, FOSB, and EGR1 are immediate early genes. Porter et al. 
identified all five among genes induced by tissue dissociation in a breast-cancer 
patient-derived xenograft model. This supports investigating processing effects, 
but it does not demonstrate such an effect in these kidney samples. 
[Porter et al., 2020, Table 1](https://doi.org/10.1371/journal.pone.0238594)

Park et al.’s Methods confirm that disease samples came from biopsies and controls 
from non-cancer-affected nephrectomy cortex. Both underwent manual microdissection 
to obtain tubulointerstitial tissue. The authors report the same RNAlater preservation 
protocol, with controls placed in RNAlater immediately after excision. Their 
Results also identify FOS, NR4A1, EGR1, and DUSP1 among strongly downregulated 
genes. That reported comparison included multiple kidney diseases, whereas this 
analysis focuses on IgAN. [Park et al., 2022, sections 2.2–2.3 and 3.3](https://doi.org/10.1111/jcmm.17340)

Within the selected comparison, diagnosis and acquisition procedure are confounded. 
A shared preservation protocol does not establish identical conditions before 
preservation. Conversely, acquisition differences do not establish that handling 
explains the observed expression pattern.

The analysis therefore estimates differences between these sampled groups without 
separating disease effects from acquisition effects. This limitation applies to 
both higher- and lower-expression results. The available evidence does not support 
assigning a quantitative contribution to either explanation.

### Decisions

- No genes or samples are removed, and the primary analysis remains unchanged.
- The volcano plot retains the ten labels. Its caption will identify the five 
leading lower-expression genes as immediate early genes, without implying that 
all labelled genes belong to that category.
- MIR23B and MIR27B will remain separate results.
- An enrichment sensitivity analysis excluding an externally defined immediate 
early gene set remains undecided. If undertaken, I will specify the source, 
complete gene list, and treatment of the enrichment background before running it, 
and report it separately.

### Follow-up status

- Completed: individual-count plots and Cook's-distance/count-replacement
  inspection for the ten labelled genes.
- Preserve the whole-dataset replacement summary separately; zero replacements
  for these ten genes is not a claim about all 18,756 genes.
- Remaining metadata review: available RNA-quality, sequencing-batch, and
  collection-timing information. Record unavailable information explicitly.
- Associations between these genes and PC1 remain optional exploratory checks,
  not prerequisites for the completed enrichment analysis. If performed, check
  whether the genes were among the 500 PCA genes and avoid treating association
  with that component as independent evidence of a handling effect.

## Update, 12 November 2026: eGFR-adjusted sensitivity analysis (step 4)

This update documents a sensitivity analysis completed after inspecting
the primary differential-expression results.

### Model comparison

eGFR was numeric and finite, with no missing or negative values in the included
samples. Group summaries and a boxplot with individual observations showed
overlapping distributions. No samples were removed for missing eGFR.

I compared `~ diagnosis` with `~ egfr_10 + diagnosis`, where eGFR was centred and 
divided by 10. Both sensitivity models used the same samples, retained genes, 
original counts, and size factors. Automatic count replacement, Cook’s-distance 
result filtering, and independent filtering were disabled in both models. The 
original primary analysis remained unchanged.

Input-matching checks and model-convergence checks passed. I compared unshrunken 
diagnosis log₂ fold changes using an identity-line scatter plot, Pearson correlation,
median absolute difference, and inspection of the largest changes. Significance
categories used BH-adjusted p < 0.05.

The adjusted model assumes a common linear eGFR association on the
log-expression scale. Kidney function may be affected by disease, so this is a
conditional association analysis rather than an automatically preferable
estimate of the disease effect.

### Results

Adding eGFR produced little overall change in the estimated diagnosis effects. 
The unshrunken log₂ fold changes had a Pearson correlation of 0.998, and the
median absolute difference was 0.00842 log₂-fold-change
units.

At BH-adjusted p < 0.05, 6,169 genes were significant in the unadjusted sensitivity 
model. Of these, 5,925 remained significant after adjustment and 244 lost 
significance. Another 151 genes became significant,
giving 6,076 significant genes in the eGFR-adjusted model. Another 12,436 genes
were significant in neither model. Approximately 96.0% of genes significant in
the unadjusted sensitivity model remained significant; 395 of 18,756 genes
(2.1%) changed significance category. All 18,756 genes had finite estimates for
the agreement plot.

The 6,169 significant genes in the unadjusted sensitivity model are distinct
from the 6,167 in the original primary analysis. The sensitivity comparison
uses matched diagnostic/filtering settings; it does not overwrite the primary
results.

These findings support overall stability to eGFR adjustment. Changes in significance 
can reflect changes in effect estimates, uncertainty, or both. This analysis does 
not resolve the confounding between
diagnosis and tissue-acquisition procedure.

### Inspection of gene-specific changes

All ten genes labelled on the volcano plot remained significant after eGFR adjustment 
and retained their original direction. Their absolute changes were below 0.043 
log₂-fold-change units, with little change in
standard errors.

Among the ten genes with the largest shifts, eight were nonsignificant in both 
models. SLC14A2 became significant after adjustment: its log₂ fold change increased 
from 1.03 to 1.51, while its standard error remained approximately 0.52. FGG remained 
significant, although its log₂ fold
change decreased from 2.75 to 2.37.

No genes significant in both models reversed direction. These checks support 
overall stability to eGFR adjustment while identifying individual genes whose 
estimated effects changed.

### Decision

The original primary analysis remains unchanged. The eGFR-adjusted
comparison will be reported separately as a sensitivity analysis.

## Update, 12 November 2026: preparing functional enrichment inputs (step 5)

Enrichment inputs were defined from the unchanged primary analysis.
Higher- and lower-expression lists used BH-adjusted p < 0.05 and the
sign of the primary log₂ fold change. The background included genes
with finite primary adjusted p-values and an accepted Entrez mapping.

Ensembl version suffixes were removed before mapping with org.Hs.eg.db.
The same mapping rule was applied to all three lists. Ensembl IDs with
no Entrez mapping or multiple candidate Entrez mappings were excluded,
and these exclusions were counted separately.

Multiple input rows mapping to the same Entrez ID were collapsed to
one ID. An Entrez ID entered a directional list if at least one
contributing row was significant in that direction and none was
significant in the opposite direction. IDs represented in both
significant directions were excluded from both directional lists
and retained in the background.

### Checks and records

All preparation checks passed: both directional lists were subsets of the
background, contained no duplicate or missing IDs, and had no Entrez IDs in
common. The mapping classification before Entrez deduplication was:

| Primary-result group | Single Entrez candidate | Ambiguous | Unmapped | Input rows |
|---|---:|---:|---:|---:|
| Higher in IgAN | 2,626 | 16 | 255 | 2,897 |
| Lower in IgAN | 2,919 | 30 | 321 | 3,270 |
| Other | 10,721 | 149 | 1,719 | 12,589 |
| Total | 16,266 | 195 | 2,295 | 18,756 |

These counts describe input rows, not necessarily distinct Entrez IDs. The
final submitted directional lists contained 2,626 higher-expression and 2,919
lower-expression Entrez IDs. Preserve the notebook's final-list summary for the
submitted unique background count and explicit conflict counts; do not infer
that background count from the pre-deduplication mapping totals.

The reported GO BP ratios used an effective background of 13,719 genes and
effective directional denominators of 2,367 higher-expression and 2,463
lower-expression genes. These denominators reflect annotation eligibility.

Recorded package versions: clusterProfiler 4.20.3, org.Hs.eg.db 3.23.1, and
GO.db 3.23.1. The final notebook will also retain `sessionInfo()`.

## Update, 12 November 2026: GO enrichment results and presentation (step 5)

This update records the enrichment results and presentation choices made after
inspecting them.

### Enrichment settings and results

I tested GO Biological Process enrichment separately for genes with higher and
lower expression in IgAN, using the mapped primary-analysis lists and background
described above. Both tests used Entrez IDs, org.Hs.eg.db, and gene-set sizes of
10 to 500. I used p-value and q-value cutoffs of 1 when retrieving results, then
selected terms with BH-adjusted p < 0.05. Multiple-testing correction was applied
separately within each direction.

The analysis returned 5,109 terms for higher-expression genes and 5,125 for
lower-expression genes, of which 250 and 150, respectively, met the BH-adjusted
p < 0.05 criterion. The leading higher-expression terms described adaptive
immune responses, lymphocyte-mediated immunity, and antigen-receptor signalling.
The leading lower-expression terms described oxidative phosphorylation,
electron transport, ATP synthesis, and mitochondrial/cytoplasmic translation.

For adaptive immune response, GeneRatio was 208/2,367 and BgRatio was
462/13,719 (approximately 2.61-fold enrichment; adjusted p = 9.02e-42).
For oxidative phosphorylation, the corresponding ratios were 87/2,463 and
128/13,719 (approximately 3.79-fold enrichment; adjusted p = 4.35e-32).
Enrichment ratios describe annotation overrepresentation, not expression fold
changes. Overlapping GO terms are not independent biological discoveries.

### Reducing redundancy for presentation

I reduced semantic redundancy separately within each direction using Wang
similarity with a cutoff of 0.7, prioritising terms with smaller adjusted
p-values. This retained 82 representative terms for higher-expression genes and
59 for lower-expression genes. I selected the eight most significant retained
terms per direction for the figure. The complete enrichment results and their
adjusted p-values were preserved.

The selected terms included adaptive immune responses, antigen receptor-mediated
signalling, and B-cell activation among higher-expression genes. Terms among
lower-expression genes included oxidative phosphorylation, mitochondrial
translation, and ATP synthesis. These results describe enrichment of gene
annotations within the expression lists; interpretation will account for tissue
composition and the diagnosis–acquisition confounding discussed above.

### Inspection of contributing genes

I first generated gene-level tables for the five most significant terms in each
direction. I split the contributing Entrez IDs into individual rows and added
gene symbols, retaining the Entrez ID when a unique symbol was unavailable.

After reducing redundancy, I expanded the gene lists for all 16 terms selected
for the figure. The code checks that each term's number of unique contributing
Entrez IDs matches its reported Count.

I examined “negative regulation of myoblast fusion” (GO:1901740) because its name
needed closer interpretation in kidney tissue. Its 37 contributing genes were
36 RPL genes and UBA52, which encodes a ubiquitin–ribosomal protein L40 fusion.
The gene list therefore points to cytosolic ribosomal proteins underlying this
enrichment. [NCBI: UBA52](https://www.ncbi.nlm.nih.gov/gene/7311)

None of these 37 genes overlapped with the contributing genes of the other seven
lower-expression terms selected for the figure. This check covered those seven
selected terms, not all significant GO terms.

### Annotation evidence review and interpretation

I reviewed the annotation evidence for “negative regulation of myoblast fusion”
(GO:1901740). All 37 contributing genes were recovered from the installed
annotation database, and all carried the NAS (Non-traceable Author Statement)
evidence code. I retained the term and its enrichment result, while interpreting
it through its contributing ribosomal genes. Neither its enrichment among
lower-expression genes nor its regulatory wording establishes increased myoblast
fusion in kidney tissue.

The review queried `GOALL`, `EVIDENCEALL`, and `ONTOLOGYALL` in the installed
`org.Hs.eg.db` database and confirmed that annotations were recovered for all
37 distinct Entrez IDs. The full enrichment tables, adjusted p-values, and
primary differential-expression analysis remain unchanged.

### Completed GO figure

I generated the two-panel dot plot of the 16 selected representative terms.
The panels show higher- and lower-expression genes separately. The x-axis is
the percentage of GO BP-annotated input genes contributing to each term
(`GeneRatio` multiplied by 100), not fold enrichment. Point area represents
`Count`, and colour represents -log10 of the original BH-adjusted enrichment
p-value. The panels share x-axis, size, and colour scales; terms are ordered by
adjusted p-value within each panel.

Term selection and Wang redundancy reduction were presentation steps; no
adjusted p-values were recalculated after selecting representative terms. The
caption records eight terms per direction, BH-adjusted p < 0.05, and the Wang
similarity cutoff of 0.7. It uses the exact label "negative regulation of
myoblast fusion" and distinguishes the observed contributor list from a claim
about muscle biology. Long labels and the caption were revised after the first
display was clipped; the layout correction was reported complete. The final
export still needs inspection at the size used in the report.

### Interpretation for the report

Genes higher in IgAN were enriched for immune-response annotations, while
genes lower in IgAN were enriched for mitochondrial energy-production and
translation annotations. In bulk tissue, these patterns can reflect cell
composition, expression within cells, or both. Enrichment does not directly
measure process activity, and the eGFR sensitivity analysis does not resolve
diagnosis-acquisition confounding.

### Code-to-plan consistency review

The current source is `BE5350_Final_Proejct.qmd` (the filename spelling is
preserved). Static inspection confirmed the implemented sequence from count
import through the `GO_final` figure. Numerical findings above are retained
from the recorded analysis outputs; the notebook was not re-executed during
this documentation review.

| Stage | Implementation confirmed in the notebook |
|---|---|
| Input and cohort | Local TAR and compressed GEO metadata; gene-ID alignment; IgAN/Control with `technical_outlier == "No"` |
| Filtering and normalisation | At least 10 counts in at least the smaller group's sample count; median-of-ratios size factors |
| Exploratory QC | Unfiltered library size/detected genes/top-ten concentration; `vst(blind = TRUE)`; PCA with `ntop = 500` |
| Primary inference | `DESeq(dds)` and `results(..., alpha = 0.05)` with default outlier handling and independent filtering |
| Effect display | `lfcShrink(..., type = "apeglm")`; shrunken volcano effects and original adjusted p-values; no extra fold-change significance cutoff |
| Sensitivity | Fresh unadjusted/adjusted datasets; identical original counts and size factors; `minReplicatesForReplace = Inf`, `cooksCutoff = FALSE`, `independentFiltering = FALSE` |
| GO inputs | Primary unshrunken `res`; finite adjusted p-values; BH significance plus effect direction; explicit mapping/conflict rules |
| GO testing | `enrichGO(ont = "BP", universe = background_genes)`; separate BH correction; gene-set sizes 10-500; reporting cutoffs 1 |
| GO presentation | Significant terms simplified separately with Wang 0.7 and `select_fun = min`; eight lowest-adjusted-p retained terms per direction |
| Evidence review | Completed for GO:1901740 using `GOALL`, `EVIDENCEALL`, and `ONTOLOGYALL`; all 37 contributing genes recovered, all carrying NAS evidence |

The notebook reads pre-downloaded files from a hard-coded local project path.
A final export section now writes CSV tables, PDF and 300-dpi PNG figures,
RDS analysis objects, and `sessionInfo.txt` to `results` within the project
directory. The export code has been syntax-checked; execution and visual review
of the resulting files remain to be completed. Data downloading is still a
remaining reproducibility task.
Additional dependencies beyond the initial `library()` calls include
apeglm, ggrepel, tibble, tidyr, scales, S4Vectors, SummarizedExperiment, and grid;
record the complete runtime dependencies and versions for the reproducible run.

## Output code added, 12 November 2026

The final notebook section saves outputs to
`D:/Yibo Main/BE5350 Final Project/results`, using `tables`, `figures`, and
`objects` subfolders. It exports the primary unshrunken results separately from
the annotated apeglm estimates, both sensitivity results and their comparison,
QC and labelled-gene inspections, GO mapping and submitted lists, full and
significant enrichment results, simplified representative terms, contributing
genes, and the GO:1901740 annotation-evidence review. It also records count
replacement across all genes, filtering totals, and PCA variance.

Figures are saved using explicit plot objects and fixed dimensions; base-graphics
diagnostics are drawn inside PDF/PNG devices. RDS files preserve the fitted
DESeq2 models, VST, enrichment objects, table list columns, and ggplot objects.
A results README records the export time and file conventions, and
`sessionInfo.txt` records the R session. Re-running this section replaces files
with the same names. The export section must run after the preceding analysis
chunks; adding this code does not establish that exports have been generated
or visually verified.

## Remaining work after the 12 November 2026 documentation review

1. Remove horizontal jitter from the gene-detection text labels if they
   are intended to align exactly with the unjittered scatter points.
   Before the fresh-session run, qualify the unnamespaced `select()` in the
   sample-QC summary as `dplyr::select()`; AnnotationDbi is also attached and
   exports a function with that name.
2. Preserve the primary and sensitivity DE tables, full enrichment tables,
   representative-term tables, mapping summaries, contributor tables, reviewed
   annotation-evidence output, and diagnostic outputs as distinct reproducible outputs. Retain the whole-dataset
   count-replacement summary and final submitted background size.
3. Export and visually inspect figures at their intended report dimensions,
   including full labels, legends, and captions. Write a concise results narrative
   linking the biological question, differential expression, sensitivity analysis,
   and GO findings without treating term counts as independent discoveries.
4. Complete the README, data-download instructions, software/session records,
   and a fresh-session execution of the Quarto notebook. Report that check only
   after it has been completed.
5. Prepare the course submission: a public, cloneable GitHub repository and a
   report of no more than three pages including display items, with minimum
   11-point font and 0.75-inch margins; references are outside the page limit.
   Include the AI prompt/chat history and implementation plan, as required when
   AI is used. Document my understanding and rationale for analysis decisions.

The optional PCA-association and immediate-early-gene-exclusion analyses remain
undecided. They are not recorded as completed work or required extensions.

## AI assistance and reproducibility

ChatGPT/Codex has assisted with coding, debugging, literature checks, and 
drafting this documentation. I will review the cited papers and analysis decisions 
myself and retain the relevant prompts and conversation.

Fresh-session verification was completed on 16 November 2026; see the validation record below.


## Clean fresh-run validation completed — 16 November 2026

The complete Quarto notebook and separate Figure 1 script ran successfully from
raw inputs in an isolated fresh environment with no restored workspace or saved
analysis objects. The only staged notebook edit was the project directory path;
the project source code and analysis settings were unchanged. This validation
supersedes the earlier pending fresh-session execution status above.

All 52 exported CSV tables matched the previous values exactly. All 48 checks
of the model and GO objects passed at tolerance 1e-8. All 16 PNG figures,
including the report's combined volcano/GO figure, matched the prior PNG files
byte for byte. The cohort, filtering, 6,167 primary DE genes, sensitivity results,
and GO enrichment results were unchanged. Figure 1 also passed the alignment
check and visual review; collision-audit warnings concerned harmless white
legend backgrounds.

An initial run used a fallback C locale and rendered the plus/minus symbol in
the standalone volcano caption incorrectly. A second complete run with
LC_ALL=English_United States.utf8 and LANG=English_United States.utf8 fixed this.
Both runs reproduced the numerical results. The two GO warnings about automatic
semantic-data calculation were expected. The unqualified select() call worked
under the current package load order and did not require a code change.

The refreshed results, sessionInfo.txt, and rendered HTML were saved to the
project. Detailed evidence and the pre-run baseline are in
reproducibility/fresh_run_2026-11-16/, including table_comparison.csv,
model_object_comparison.csv, input/source hashes, and execution logs.

This verifies the local installed environment, not a new-machine installation.
Public repository availability and reproduction from a clean clone remain
separate submission checks. No statistical choices or interpretation changed.
