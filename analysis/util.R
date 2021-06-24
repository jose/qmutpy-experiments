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

load_data <- function(data_file) {
  # Load data
  df <- load_CSV(data_file)
  # target,test,number_of_tests,mutation_score,
  # total_time,time_create_mutant_module,time_create_target_ast,time_mutate_module,time_run_tests_with_mutant,
  # mutation_id,lineno,operator,status,killer,exception_traceback,tests_run,time

  # Runtime check
  stopifnot(nrow(df[is.na(df$'operator'), ]) == 0)

  # Replace empty cells with NA
  df[df == ''] <- NA
  # Fix mutation-score of non-executions
  df$'mutation_score'[is.na(df$'mutation_id')] <- NA
  # Short names to plot
  df$'short_target' <- sapply(df$'target', get_short_name)
  # Set factors
  df$'status' <- factor(df$'status', levels=c('incompetent', 'killed', 'survived', 'timeout'))

  # TODO Is mutation time per mutant
  #   time_create_mutant_module + time_create_target_ast + time_mutate_module + time_run_tests_with_mutant
  #   or just
  #   time?  or is time that same sum?
  # TODO do we want to report time on minutes or seconds? better way to answer this is to try to plot both

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
