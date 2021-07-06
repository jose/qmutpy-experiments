# This script generates a table that summarizes the subjects used in the study.
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

# Load data
df <- load_exps_data()
# Process coverage data
df <- process_targets_coverage_data(df)

unlink(OUTPUT_FILE_PATH)
sink(OUTPUT_FILE_PATH, append=FALSE, split=TRUE)

cat('\\begin{tabular}{@{\\extracolsep{\\fill}} lrrrr} \\toprule\n', sep='')
cat('\\multicolumn{1}{c}{Algorithm} & \\multicolumn{1}{c}{LOC} & \\multicolumn{1}{c}{\\# Tests} & \\multicolumn{1}{c}{Time (seconds)} & \\multicolumn{1}{c}{\\% Coverage} \\\\\n\\midrule\n', sep='')

for (short_target in unique(df$'short_target')) {
  mask <- df$'short_target' == short_target
  row <- df[mask, ]

  # Pretty print row
  short_target <- replace_string(short_target, '_', '\\\\_')
  num_lines    <- row$'num_lines'
  num_tests    <- row$'number_of_tests'
  coverage     <- row$'line_coverage'
  time_to      <- row$'time_to_run_tests_on_non_mutated_code'

  cat(short_target,
      ' & ', num_lines,
      ' & ', num_tests,
      ' & ', sprintf("%.2f", round(time_to, 2)),
      ' & ', sprintf("%.2f", round(coverage, 2)),
      ' \\\\\n', sep='')
}

cat('\\bottomrule\n', sep='')
cat('\\end{tabular}\n', sep='')

sink()

# EOF
