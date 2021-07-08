# This script generates a table that summarizes data.
#
# Usage:
#   Rscript summary_data_as_table.R <output dir path>
#

source('util.R')

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop('USAGE: Rscript summary_data_as_table.R <output dir path>')
}

OUTPUT_DIR_PATH <- args[1]

# Load data
df <- load_exps_data()
# Process mutation data
df <- process_targets_mutation_data(df)

# --------------------------------------------------------------- summarize data

write_table_content <- function(df, entries, column) {
  agg_sum  <- aggregate(as.formula(paste('cbind(num_mutants, killed, survived_covered, survived_not_covered, incompetent, timeout, total_time) ~ ', column, sep='')), df, FUN=sum)
  agg_mean <- aggregate(as.formula(paste('cbind(mutation_score_ignoring_survided_status, mutation_score_ignoring_survided_not_covered, num_lines_mutated, num_mutants_per_line_number) ~ ', column, sep='')), df, FUN=mean)
  mutation_df <- merge(agg_sum, agg_mean, by=column, all=TRUE)

  for (entry in entries) {
    mask <- mutation_df[[column]] == entry
    cat(replace_string(entry, '_', '\\\\_'), sep='')

    num_mutants <- mutation_df$'num_mutants'[mask]
    if (dim(mutation_df[mask, ])[1] == 0 || num_mutants == 0) {
      cat(' & ', '0', sep='')
      cat(' & ', '---', sep='')
      cat(' & ', '---', sep='')
      cat(' & ', '---', sep='')
      cat(' & ', '---', sep='')
      if (column == 'short_target') {
        cat(' & ', '---', sep='')
        cat(' & ', '---', sep='')
        cat(' & ', '---', sep='')
      }
      cat(' \\\\\n', sep='')
      next
    }

    num_mutants_killed               <- mutation_df$'killed'[mask]
    num_mutants_survived_covered     <- mutation_df$'survived_covered'[mask]
    num_mutants_survived_not_covered <- mutation_df$'survived_not_covered'[mask]
    num_mutants_incompetent          <- mutation_df$'incompetent'[mask]
    num_mutants_timeout              <- mutation_df$'timeout'[mask]
    stopifnot(num_mutants <= num_mutants_killed + num_mutants_survived_covered + num_mutants_survived_not_covered + num_mutants_incompetent + num_mutants_timeout)

    cat(' & ', num_mutants, sep='')
    if (column == 'short_target') {
      cat(' & ', sprintf("%.0f", round(mutation_df$'num_lines_mutated'[mask], 0)), sep='')
      cat(' (', sprintf("%.2f", round(mutation_df$'num_mutants_per_line_number'[mask], 2)), ')', sep='')
    }
    cat(' & ', num_mutants_killed, sep='')
    cat(' & ', num_mutants_survived_covered, ' / ', num_mutants_survived_not_covered, sep='')
    cat(' & ', num_mutants_incompetent, sep='')
    cat(' & ', num_mutants_timeout, sep='')

    if (column == 'short_target') {
      time_in_seconds                              <- mutation_df$'total_time'[mask]
      time_in_minutes                              <- time_in_seconds / 60.0
      mutation_score_ignoring_survided_status      <- mutation_df$'mutation_score_ignoring_survided_status'[mask]
      mutation_score_ignoring_survided_not_covered <- mutation_df$'mutation_score_ignoring_survided_not_covered'[mask]
      cat(' & ', sprintf("%.2f", round(mutation_score_ignoring_survided_status, 2)), ' / ', sprintf("%.2f", round(mutation_score_ignoring_survided_not_covered, 2)), sep='')
      cat(' & ', sprintf("%.2f", round(time_in_minutes, 2)), sep='')
    }

    cat(' \\\\\n', sep='')
  }
}

# at algorithm level

per_algorithm_tex_file <- paste(OUTPUT_DIR_PATH, .Platform$file.sep, 'summary_mutation_results_per_algorithm.tex', sep='')
unlink(per_algorithm_tex_file)
sink(per_algorithm_tex_file, append=FALSE, split=TRUE)

cat('\\begin{tabular}{@{\\extracolsep{\\fill}} l rrrrrrrr} \\toprule\n', sep='')
cat('\\multicolumn{1}{c}{Algorithm} & \\multicolumn{1}{c}{\\# Mutants} & \\multicolumn{1}{c}{\\# Mutated LOC} & \\multicolumn{1}{c}{\\# Killed} & \\multicolumn{1}{c}{\\# Survived} & \\multicolumn{1}{c}{\\# Incompetent} & \\multicolumn{1}{c}{\\# Timeout} & \\multicolumn{1}{c}{\\% Score} & \\multicolumn{1}{c}{Runtime} \\\\\n', sep='')

for (type in c(TRADITIONAL_MUTATION_OPERATOR_TYPE_STR, QUANTUM_MUTATION_OPERATOR_TYPE_STR)) {
  cat('\\midrule\n', sep='')
  cat('\\rowcolor{gray!25}\n', sep='')
  cat('\\multicolumn{9}{c}{\\textbf{\\textit{', type, ' mutants}}} \\\\\n', sep='')
  targets <- sort(unique(df$'short_target'), decreasing=TRUE)
  write_table_content(df[df$'mutation_operator_type' == type, ], targets, 'short_target')
}

cat('\\bottomrule\n', sep='')
cat('\\end{tabular}\n', sep='')

sink()

# at operator level

per_mutation_operator_tex_file <- paste(OUTPUT_DIR_PATH, .Platform$file.sep, 'summary_mutation_results_per_mutation_operator.tex', sep='')
unlink(per_mutation_operator_tex_file)
sink(per_mutation_operator_tex_file, append=FALSE, split=TRUE)

cat('\\begin{tabular}{@{\\extracolsep{\\fill}} l rrrrr} \\toprule\n', sep='')
cat('\\multicolumn{1}{c}{Operator} & \\multicolumn{1}{c}{\\# Mutants} & \\multicolumn{1}{c}{\\# Killed} & \\multicolumn{1}{c}{\\# Survived} & \\multicolumn{1}{c}{\\# Incompetent} & \\multicolumn{1}{c}{\\# Timeout} \\\\\n', sep='')

for (type in c(TRADITIONAL_MUTATION_OPERATOR_TYPE_STR, QUANTUM_MUTATION_OPERATOR_TYPE_STR)) {
  cat('\\midrule\n', sep='')
  cat('\\rowcolor{gray!25}\n', sep='')
  cat('\\multicolumn{6}{c}{\\textbf{\\textit{', type, ' mutants}}} \\\\\n', sep='')
  operators <- sort(unique(df$'operator'[df$'mutation_operator_type' == type]), decreasing=FALSE)
  write_table_content(df[df$'mutation_operator_type' == type, ], operators, 'operator')
}

cat('\\bottomrule\n', sep='')
cat('\\end{tabular}\n', sep='')

sink()

# EOF
