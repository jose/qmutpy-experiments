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

load_exps_data <- function(data_file='../data/qiskit-aqua-all-mutation-operators.csv') {
  # Load data
  df <- load_CSV(data_file)
  # target,test,number_of_tests,
  # time_to_run_tests_on_non_mutated_code,time_to_create_targets_ast,time_to_create_mutated_modules,time_to_run_tests_on_mutated_modules,time_to_generate_mutated_asts,time_to_mutate_module,total_time,
  # mutation_id,line_number,operator,status,killer,exception_traceback,number_of_tests_executed,time_to_run_tests_on_mutated_module

  # Runtime check
  stopifnot(nrow(df[is.na(df$'operator'), ]) == 0)
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
  #  - survived-covered: mutants that survived and are covered/exercised by the test suite
  #  - survived-not-covered: mutants that survived and are not covered/exercised by the test suite
  df$'status'[!is.na(df$'status') & df$'status' == 'survived' & !is.na(df$'covered') & df$'covered' == 1] <- 'survived-covered'
  df$'status'[!is.na(df$'status') & df$'status' == 'survived' & !is.na(df$'covered') & df$'covered' == 0] <- 'survived-not-covered'
  # Set status' factors
  df$'status' <- factor(df$'status', levels=c('incompetent', 'killed', 'survived-covered', 'survived-not-covered', 'timeout'))

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

# EOF
