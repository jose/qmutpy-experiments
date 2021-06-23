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
exps_data          <- load_data('../data/qiskit-aqua-all-mutation-operators.csv')
mutation_operators <- load_CSV('../qmutpy-support/mutation-operators.csv')
names(mutation_operators)[names(mutation_operators) == 'mutation_operator_id'] <- 'operator'
# Merge data
df <- merge(exps_data, mutation_operators, by='operator')

# ------------------------------------------------------ summarize targets' data

# at algorithm level

write_table_content <- function(df, column) {
  for (column_value in sort(unique(df[[column]]))) {
    mask <- !is.na(df$'status') & df[[column]] == column_value
    cat(replace_string(column_value, '_', '-'), sep='')

    num_mutants <- nrow(df[mask, ])
    cat(' & ', num_mutants, sep='')
    if (num_mutants == 0) {
      if (column == 'short_target') {
        cat(' & --- & --- & --- & --- & --- & ---', sep='')
      } else if (column == 'operator') {
        cat(' & --- & --- & --- & ---', sep='')
      }
      cat(' \\\\\n', sep='')
      next
    }

    num_mutants_killed <- nrow(df[mask & df$'status' == 'killed', ])
    cat(' & ', num_mutants_killed, sep='')

    num_mutants_survived <- nrow(df[mask & df$'status' == 'survived', ])
    cat(' & ', num_mutants_survived, sep='')

    num_mutants_incompetent <- nrow(df[mask & df$'status' == 'incompetent', ])
    cat(' & ', num_mutants_incompetent, sep='')

    num_mutants_timeout <- nrow(df[mask & df$'status' == 'timeout', ])
    cat(' & ', num_mutants_timeout, sep='')

    if (column == 'short_target') {
      mutation_score <- (num_mutants_killed / (num_mutants - num_mutants_incompetent)) * 100.0
      if (is.nan(mutation_score)) {
        cat(' & ---', sep='')
      } else {
        cat(' & ', sprintf("%.2f", round(mutation_score, 2)), sep='')
      }

      time_in_seconds <- sum(df$'time'[mask])
      time_in_minutes <- time_in_seconds / 60
      cat(' & ', sprintf("%.2f", round(time_in_minutes, 2)), sep='')
    }

    cat(' \\\\\n', sep='')
  }
}

per_algorithm_tex_file <- paste(OUTPUT_DIR_PATH, 'summary_mutation_results_per_algorithm.tex', sep='')
unlink(per_algorithm_tex_file)
sink(per_algorithm_tex_file, append=FALSE, split=TRUE)

cat('\\begin{tabular}{@{\\extracolsep{\\fill}} l rrrrrrr} \\toprule\n', sep='')
cat('\\multicolumn{1}{c}{Algorithm} & \\multicolumn{1}{c}{\\# Mutants} & \\multicolumn{1}{c}{\\# Killed} & \\multicolumn{1}{c}{\\# Survived} & \\multicolumn{1}{c}{\\# Incompetent} & \\multicolumn{1}{c}{\\# Timeout} & \\multicolumn{1}{c}{\\% Score} & \\multicolumn{1}{c}{Runtime (minutes)} \\\\\n', sep='')

cat('\\midrule\n', sep='')
cat('\\rowcolor{gray!25}\n', sep='')
cat('\\multicolumn{8}{c}{\\textbf{\\textit{Traditional mutants}}} \\\\\n', sep='')
write_table_content(df[df$'mutation_operator_type' == 'traditional', ], 'short_target')

cat('\\midrule\n', sep='')
cat('\\rowcolor{gray!25}\n', sep='')
cat('\\multicolumn{8}{c}{\\textbf{\\textit{Quantum-based mutants}}} \\\\\n', sep='')
write_table_content(df[df$'mutation_operator_type' == 'quantum', ], 'short_target')

cat('\\bottomrule\n', sep='')
cat('\\end{tabular}\n', sep='')

sink()

# at operator level

per_mutation_operator_tex_file <- paste(OUTPUT_DIR_PATH, 'summary_mutation_results_per_mutation_operator.tex', sep='')
unlink(per_mutation_operator_tex_file)
sink(per_mutation_operator_tex_file, append=FALSE, split=TRUE)

cat('\\begin{tabular}{@{\\extracolsep{\\fill}} l rrrrr} \\toprule\n', sep='')
cat('\\multicolumn{1}{c}{Operator} & \\multicolumn{1}{c}{\\# Mutants} & \\multicolumn{1}{c}{\\# Killed} & \\multicolumn{1}{c}{\\# Survived} & \\multicolumn{1}{c}{\\# Incompetent} & \\multicolumn{1}{c}{\\# Timeout} \\\\\n', sep='')

cat('\\midrule\n', sep='')
cat('\\rowcolor{gray!25}\n', sep='')
cat('\\multicolumn{6}{c}{\\textbf{\\textit{Traditional mutants}}} \\\\\n', sep='')
write_table_content(df[df$'mutation_operator_type' == 'traditional', ], 'operator')

cat('\\midrule\n', sep='')
cat('\\rowcolor{gray!25}\n', sep='')
cat('\\multicolumn{6}{c}{\\textbf{\\textit{Quantum-based mutants}}} \\\\\n', sep='')
write_table_content(df[df$'mutation_operator_type' == 'quantum', ], 'operator')

cat('\\bottomrule\n', sep='')
cat('\\end{tabular}\n', sep='')

sink()

# EOF
