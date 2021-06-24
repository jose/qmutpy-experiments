# This script generates a table that summarizes subjects used in the study.
#
# Usage:
#   Rscript subjects_as_table.R <output tex file>
#

source('util.R')

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop('USAGE: Rscript subjects_as_table.R <output tex file>')
}

OUTPUT_FILE_PATH <- args[1]

# algorithm_full_name,test_suite_full_name,number_of_tests,file,line,covered,excluded
df <- load_CSV('../qiskit-aqua-support/tests-coverage.csv')
df$'algorithm' <- sapply(df$'algorithm_full_name', get_short_name)

unlink(OUTPUT_FILE_PATH)
sink(OUTPUT_FILE_PATH, append=FALSE, split=TRUE)

cat('\\begin{tabular}{@{\\extracolsep{\\fill}} lrrr} \\toprule\n', sep='')
cat('\\multicolumn{1}{c}{Algorithm} & \\multicolumn{1}{c}{LOC} & \\multicolumn{1}{c}{\\# Tests} & \\multicolumn{1}{c}{\\% Coverage} \\\\\n\\midrule\n', sep='')

for (algorithm in sort(unique(df$'algorithm'))) {
  mask <- df$'algorithm' == algorithm

  algorithm  <- replace_string(algorithm, '_', '\\\\_')
  loc        <- nrow(df[mask, ])
  test_suite <- replace_string(get_short_name(unique(df$'test_suite_full_name'[mask])), '_', '\\\\_')
  covered    <- sum(df$'covered'[mask])
  excluded   <- sum(df$'excluded'[mask])
  stopifnot(excluded == 0)
  coverage   <- covered / loc * 100.0
  num_tests  <- unique(df$'number_of_tests'[mask])

  cat(algorithm,
      ' & ', loc,
      # ' & ', test_suite,
      ' & ', num_tests,
      ' & ', sprintf("%.2f", round(coverage, 2)),
      ' \\\\\n',
      sep='')
}

cat('\\bottomrule\n', sep='')
cat('\\end{tabular}\n', sep='')

sink()

# EOF
