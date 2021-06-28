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

df <- load_exps_data()
# Exclude data points with no line number information (i.e., mutation analysis
# that were not even performed because no mutant was generated)
df <- df[!is.na(df$'line_number'), ]
# Select relevant columns for this script
df <- subset(df, select=c(
  short_target, line_number,
  test, number_of_tests, time_to_run_tests_on_non_mutated_code,
  covered, excluded
))
# Aggregate data at line level
df <- aggregate(. ~ short_target + test + line_number, df, FUN=mean, na.action=na.pass)

# Count number of unique lines per target
agg_count <- aggregate(line_number ~ short_target, df, FUN=length)
# Compute average time a test suite took to run per target
agg_time  <- aggregate(cbind(time_to_run_tests_on_non_mutated_code, number_of_tests) ~ short_target, df, FUN=mean)
# Compute total number of lines covered by the test suite
agg_cov   <- aggregate(cbind(covered, excluded) ~ short_target, df, FUN=sum)
# Merge all data.frames
df <- Reduce(function(x, y) merge(x, y, by='short_target', all=TRUE), list(agg_count, agg_time, agg_cov))
# Compute line coverage
df$'line_coverage' <- df$'covered' / df$'line_number' * 100.0
stopifnot(df$'line_coverage' <= 100.0)

unlink(OUTPUT_FILE_PATH)
sink(OUTPUT_FILE_PATH, append=FALSE, split=TRUE)

cat('\\begin{tabular}{@{\\extracolsep{\\fill}} lrrrr} \\toprule\n', sep='')
cat('\\multicolumn{1}{c}{Algorithm} & \\multicolumn{1}{c}{LOC} & \\multicolumn{1}{c}{\\# Tests} & \\multicolumn{1}{c}{Time (seconds)} & \\multicolumn{1}{c}{\\% Coverage} \\\\\n\\midrule\n', sep='')

for (short_target in sort(unique(df$'short_target'), decreasing=TRUE)) {
  mask <- df$'short_target' == short_target
  row <- df[mask, ]

  # Pretty print row
  algorithm <- replace_string(short_target, '_', '\\\\_')
  num_lines <- row$'line_number'
  num_tests <- row$'number_of_tests'
  coverage  <- row$'line_coverage'
  time_to   <- row$'time_to_run_tests_on_non_mutated_code'

  cat(algorithm,
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
