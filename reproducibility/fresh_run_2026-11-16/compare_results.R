args <- commandArgs(trailingOnly=TRUE)
baseline <- args[1]
fresh <- args[2]
audit <- args[3]
dir.create(audit, recursive=TRUE, showWarnings=FALSE)
old_files <- list.files(file.path(baseline,'tables'),pattern='\\.csv$')
new_files <- list.files(file.path(fresh,'tables'),pattern='\\.csv$')
stopifnot(setequal(old_files,new_files))
details <- list()
rows <- lapply(old_files,function(f) {
  a <- read.csv(file.path(baseline,'tables',f),check.names=FALSE,stringsAsFactors=FALSE)
  b <- read.csv(file.path(fresh,'tables',f),check.names=FALSE,stringsAsFactors=FALSE)
  same_shape <- identical(dim(a),dim(b)) && identical(names(a),names(b))
  equal <- isTRUE(all.equal(a,b,tolerance=1e-8,check.attributes=TRUE))
  exact <- identical(a,b)
  max_abs <- 0
  if(same_shape) for(n in names(a)) if(is.numeric(a[[n]]) && is.numeric(b[[n]])) {
    delta <- abs(a[[n]]-b[[n]])
    if(any(is.finite(delta))) max_abs <- max(max_abs,delta[is.finite(delta)])
  }
  if(!exact) details[[f]] <- all.equal(a,b,tolerance=1e-8,check.attributes=TRUE)
  data.frame(file=f,rows=nrow(b),columns=ncol(b),same_shape=same_shape,
             exact_values=exact,equal_tolerance_1e_8=equal,max_absolute_difference=max_abs)
})
comparison <- do.call(rbind,rows)
write.csv(comparison,file.path(audit,'table_comparison.csv'),row.names=FALSE)
capture.output(details,file=file.path(audit,'comparison_details.txt'))
print(comparison[!comparison$exact_values,],row.names=FALSE)
cat('CSV tables:',nrow(comparison),'Exact:',sum(comparison$exact_values),
    'Within tolerance:',sum(comparison$equal_tolerance_1e_8),'\n')
for (f in c('gene_filtering_summary.csv','primary_count_replacement_summary.csv',
            'sensitivity_significance_counts.csv','sensitivity_agreement.csv',
            'go_enrichment_summary.csv','go_redundancy_summary.csv')) {
  cat('\n',f,'\n'); print(read.csv(file.path(fresh,'tables',f)))
}
de <- read.csv(file.path(fresh,'tables','primary_DE_unshrunken.csv'))
cat('\nPrimary significant higher/lower:',sum(de$padj<.05 & de$log2FoldChange>0,na.rm=TRUE),
    sum(de$padj<.05 & de$log2FoldChange<0,na.rm=TRUE),'\n')
if(!all(comparison$equal_tolerance_1e_8)) quit(status=2)
