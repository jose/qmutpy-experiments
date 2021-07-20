# ------------------------------------------------------------------------------
# A set of utility functions.
# ------------------------------------------------------------------------------

set.seed(1)

# Common external packages
library('data.table') # install.packages('data.table')
library('stringr') # install.packages('stringr')
library('ggplot2') # install.packages('ggplot2')

# -------------------------------------------------------------------------- Env

QISKIT_AQUA_SUBJECTS_FILE      <- '../qiskit-aqua-support/subjects.csv'
stopifnot(file.exists(QISKIT_AQUA_SUBJECTS_FILE))
QMUTPY_MUTATION_OPERATORS_FILE <- '../qmutpy-support/mutation-operators.csv'
stopifnot(file.exists(QMUTPY_MUTATION_OPERATORS_FILE))

# --------------------------------------------------------------------- Wrappers

'%!in%' <- function(x,y)!('%in%'(x,y)) # Wrapper to 'not in'

load_CSV <- function(csv_path) {
  return (read.csv(csv_path, header=TRUE, stringsAsFactors=FALSE))
}

replace_string <- function(string, find, replace) {
  gsub(find, replace, string)
}

embed_fonts_in_a_pdf <- function(pdf_path) {
  library('extrafont') # install.packages('extrafont')
  embed_fonts(pdf_path, options='-dSubsetFonts=true -dEmbedAllFonts=true -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dMaxSubsetPct=100')
}

# ------------------------------------------------------------------------- Plot

#
# Plots the provided text on a dedicated page.  This function is usually used to
# separate plots for multiple analyses in the same PDF.
#
plot_label <- function(text) {
  library('ggplot2') # install.packages('ggplot2')
  p <- ggplot() + annotate('text', label=text, x=4, y=25, size=8) + theme_void()
  print(p)
}

#
# Set relative widths of the facet columns based on how many unique x-axis
# values are in each facet.  It requires a ggplot object as input.
#
# Based on: https://stackoverflow.com/a/52422707/998816
#
set_relative_widths_to_all_facet_columns <- function(plot) {
  library('ggpubr') # install.packages('ggpubr')

  # Convert ggplot object to grob object
  ggplot <- ggplotGrob(plot)

  # Get gtable columns corresponding to the facets
  facet.columns <- ggplot$'layout'$'l'[grepl('panel', ggplot$'layout'$'name')]

  # Get the number of unique x-axis values per facet
  x.var <- sapply(ggplot_build(plot)$'layout'$'panel_scales_x', function(l) length(l$'range'$'range'))

  # Change the relative widths of the facet columns based on how many unique x-axis values are in each facet
  ggplot$'widths'[facet.columns] <- ggplot$'widths'[facet.columns] * x.var

  return(ggplot)
}

# ---------------------------------------------------------------- Study related

CLASSIC_MUTATION_OPERATOR_TYPE_STR <- 'Classic'
QUANTUM_MUTATION_OPERATOR_TYPE_STR <- 'Quantum-oriented'

load_exps_data <- function(data_file='../data/qiskit-aqua-all-mutation-operators.csv') {
  # Load data
  df <- load_CSV(data_file)
  # target,test,number_of_tests,
  # time_to_run_tests_on_non_mutated_code,time_to_create_targets_ast,time_to_create_mutated_modules,time_to_run_tests_on_mutated_modules,time_to_generate_mutated_asts,time_to_mutate_module,total_time,
  # mutation_id,line_number,operator,status,killer,exception_traceback,number_of_tests_executed,time_to_run_tests_on_mutated_module

  # Runtime checks
  stopifnot(nrow(df[is.na(df$'operator'), ]) == 0)
  df$'number_of_tests_executed' <- abs(df$'number_of_tests_executed')
  stopifnot(min(df$'number_of_tests_executed', na.rm=TRUE) >= 0)
  # Replace empty cells with NA
  df[df == ''] <- NA

  #
  # Augment experiments' data with code coverage data
  #
  # algorithm_full_name,test_suite_full_name,number_of_tests,file,statement,line,covered,excluded
  tests_coverage <- load_CSV('../qiskit-aqua-support/tests-coverage.csv')
  # Rename some columns to ease merge
  names(tests_coverage)[names(tests_coverage) == 'algorithm_full_name']  <- 'target'
  names(tests_coverage)[names(tests_coverage) == 'test_suite_full_name'] <- 'test'
  names(tests_coverage)[names(tests_coverage) == 'line']                 <- 'line_number'
  # Drop some columns
  tests_coverage <- subset(tests_coverage, select=-c(number_of_tests, file, statement))
  # Merge data
  df <- merge(df, tests_coverage, by=c('target', 'test', 'line_number'), all=TRUE)
  # Runtime check, number of NaNs must be exactly the same
  stopifnot(nrow(df[is.na(df$'line_number'), ]) == nrow(df[is.na(df$'covered'), ]))
  # Short names to plot
  df$'short_target' <- sapply(df$'target', get_short_name)
  # Set short names' factors and sort them
  df$'short_target' <- factor(df$'short_target', levels=sort(unique(df$'short_target'), decreasing=TRUE))
  # Create two new 'survived' status:
  #  - survived_covered: mutants that survived and are covered/exercised by the test suite
  #  - survived_not_covered: mutants that survived and are not covered/exercised by the test suite
  df$'status'[!is.na(df$'status') & df$'status' == 'survived' & !is.na(df$'covered') & df$'covered' == 1] <- 'survived_covered'
  df$'status'[!is.na(df$'status') & df$'status' == 'survived' & !is.na(df$'covered') & df$'covered' == 0] <- 'survived_not_covered'
  # Set status' factors
  df$'status' <- factor(df$'status', levels=c('incompetent', 'killed', 'survived_covered', 'survived_not_covered', 'timeout'))

  #
  # Augment experiments' data with mutation operators' data
  #
  # mutation_operator_description,mutation_operator_id,mutation_operator_type
  mutation_operators <- load_CSV('../qmutpy-support/mutation-operators.csv')
  # Rename column 'mutation_operator_id' to ease merge
  names(mutation_operators)[names(mutation_operators) == 'mutation_operator_id'] <- 'operator'
  # Pretty print mutants' type
  mutation_operators$'mutation_operator_type'[mutation_operators$'mutation_operator_type' == 'classic'] <- CLASSIC_MUTATION_OPERATOR_TYPE_STR
  mutation_operators$'mutation_operator_type'[mutation_operators$'mutation_operator_type' == 'quantum'] <- QUANTUM_MUTATION_OPERATOR_TYPE_STR
  # Select relevant columns
  mutation_operators <- subset(mutation_operators, select=c(operator, mutation_operator_type))
  # Augment data.frame
  df <- merge(df, mutation_operators, by='operator', all=TRUE)
  # Set operator type's factor
  df$'mutation_operator_type' <- factor(df$'mutation_operator_type', levels=c(CLASSIC_MUTATION_OPERATOR_TYPE_STR, QUANTUM_MUTATION_OPERATOR_TYPE_STR))
  # Set and sort operator's factors
  df$'operator' <- factor(df$'operator', levels=c(
    # First, classic mutation operators
    'AOD', 'AOR', 'ASR', 'BCR', 'COD', 'COI', 'CRP', 'DDL', 'EHD', 'EXS', 'IHD', 'IOD', 'IOP', 'LCR', 'LOD', 'LOR', 'ROR', 'SCD', 'SCI', 'SIR',
    # Then, quantum-oriented mutation operators
    'QGD', 'QGI', 'QGR', 'QMD', 'QMI'
  ))

  return(df)
}

#
# Given a full/canonical name of an algorithm or a test suite, it returns its
# name.  I.e., if a algorithm is named 'qiskit.optimization.algorithms.grover_optimizer',
# it returns 'grover_optimizer'.
#
get_short_name <- function(full_name) {
  l <- unlist(strsplit(full_name, "\\."))
  return(l[[length(l)]])
}

#
# Given a data.frame with target's mutation data, it summarizes data in a
# dataframe (including several mutation scores).
#
process_targets_mutation_data <- function(df) {
  # Exclude data points with no mutation operator information (i.e., lines of
  # code for each there was no mutant)
  df <- df[!is.na(df$'operator'), ]

  # Compute line mutation data
  #   - Number of lines with at least one mutant
  #   - Average number of mutants per mutated line
  # Number of mutants per lines of code
  num_mutants_per_line_number <- aggregate(mutation_id ~ short_target + mutation_operator_type + line_number, df, FUN=length)
  names(num_mutants_per_line_number)[names(num_mutants_per_line_number) == 'mutation_id'] <- 'num_mutants_per_line_number'
  avg_mutants_per_line_number <- aggregate(num_mutants_per_line_number ~ short_target + mutation_operator_type, num_mutants_per_line_number, FUN=mean)
  # Number of mutated lines
  num_lines_mutated <- aggregate(line_number ~ short_target + mutation_operator_type, num_mutants_per_line_number, FUN=length)
  names(num_lines_mutated)[names(num_lines_mutated) == 'line_number'] <- 'num_lines_mutated'
  # Merge distribution of mutated lines
  mutants_distribution_df <- merge(num_lines_mutated, avg_mutants_per_line_number, by=c('short_target', 'mutation_operator_type'))

  # Reshape data at mutation operator level, as for each mutation operator we
  # might have a different number of mutations
  dcast_df <- reshape2::dcast(df, short_target + operator + mutation_operator_type + total_time ~ status, value.var='status')
  if (c('incompetent') %!in% colnames(dcast_df)) {
    dcast_df$'incompetent' <- 0
  }
  dcast_df$'num_mutants'                                  <- dcast_df$'killed' + dcast_df$'incompetent' + dcast_df$'timeout' + dcast_df$'survived_covered' + dcast_df$'survived_not_covered'
  dcast_df$'mutation_score_ignoring_survided_status'      <- dcast_df$'killed' / (dcast_df$'num_mutants' - dcast_df$'incompetent') * 100.0
  dcast_df$'mutation_score_ignoring_survided_not_covered' <- dcast_df$'killed' / (dcast_df$'num_mutants' - dcast_df$'incompetent' - dcast_df$'survived_not_covered') * 100.0
  # Fix divisions by zero
  dcast_df$'mutation_score_ignoring_survided_status'[is.nan(dcast_df$'mutation_score_ignoring_survided_status')]           <- 0
  dcast_df$'mutation_score_ignoring_survided_not_covered'[is.nan(dcast_df$'mutation_score_ignoring_survided_not_covered')] <- 0
  # Data points with no mutant must have a 0 mutation score
  dcast_df$'mutation_score_ignoring_survided_status'[dcast_df$'num_mutants' == 0]      <- NA
  dcast_df$'mutation_score_ignoring_survided_not_covered'[dcast_df$'num_mutants' == 0] <- NA
  # Runtime check
  stopifnot(max(dcast_df$'mutation_score_ignoring_survided_status', na.rm=TRUE) <= 100.0)
  stopifnot(max(dcast_df$'mutation_score_ignoring_survided_not_covered', na.rm=TRUE) <= 100.0)

  # Merge mutation data with distribution of mutated lines
  n <- nrow(dcast_df)
  dcast_df <- merge(dcast_df, mutants_distribution_df, by=c('short_target', 'mutation_operator_type'), all.x=TRUE)
  stopifnot(n == nrow(dcast_df))

  # TODO in case we might need to compute non-relative mutation score, we first
  # need to aggregate data and only then apply a reshape2::dcast

  return(dcast_df)
}

#
# Given a data.frame with target's test coverage data, it summarizes data in a
# dataframe.
#
process_targets_coverage_data <- function(df) {
  # Aggregate data at line level, as for each line we could have several mutations
  agg_df    <- aggregate(cbind(covered, excluded, number_of_tests, time_to_run_tests_on_non_mutated_code) ~ short_target + line_number, df, FUN=mean, na.action=na.pass)
  # short_target,line_number,covered,excluded,number_of_tests,time_to_run_tests_on_non_mutated_code
  # simon,1,1,0,NA,NA
  # simon,2,1,0,NA,NA
  # simon,3,0,0,48,11.95624

  # Count number of unique lines per target
  agg_count <- aggregate(line_number ~ short_target, agg_df, FUN=length)
  # Rename 'line_number' -> 'num_lines'
  names(agg_count)[names(agg_count) == 'line_number'] <- 'num_lines'
  # short_target,num_lines
  # simon,89

  # Compute total number of lines covered by the test suite
  agg_sum   <- aggregate(cbind(covered, excluded) ~ short_target, agg_df, FUN=sum)
  # short_target,covered,excluded
  # simon,88,0

  # Compute number of tests and average runtime
  # number_of_tests, time_to_run_tests_on_non_mutated_code
  agg_mean <- aggregate(cbind(number_of_tests, time_to_run_tests_on_non_mutated_code) ~ short_target, agg_df, FUN=mean)

  # Merge all data.frames
  cov_df    <- merge(agg_mean, merge(agg_count, agg_sum, by='short_target'), by='short_target')
  # Compute line coverage
  cov_df$'line_coverage' <- cov_df$'covered' / cov_df$'num_lines' * 100.0
  stopifnot(cov_df$'line_coverage' <= 100.0)
  # short_target,number_of_tests,time_to_run_tests_on_non_mutated_code,num_lines,covered,excluded,line_coverage
  # simon,48,17.20753,89,88,0,98.8764

  # Return computed coverage data
  return(cov_df)
}

# EOF
