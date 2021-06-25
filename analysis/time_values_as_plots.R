# This script plots times as boxplots and barplots.
#
# Usage:
#   Rscript time_values_as_plots.R <output pdf file>
#

source('util.R')

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop('USAGE: Rscript time_values_as_plots.R <output pdf file>')
}

OUTPUT_FILE <- args[1]

# Load data
df <- load_exps_data()
# target,test,number_of_tests,mutation_score,
# total_time,time_create_mutant_module,time_create_target_ast,time_mutate_module,time_run_tests_with_mutant,
# mutation_id,lineno,operator,status,killer,exception_traceback,tests_run,time

agg <- aggregate(cbind(time_create_mutant_module, time_create_target_ast, time_mutate_module) ~ target + operator, df, FUN=mean)
# TODO compute relative times as some target require more time to mutate, e.g.,
# because they have many more place to mutate

reshape_and_melt <- function(df, vars) {
  melt <- reshape2::melt(df, id.vars=vars)

  # Sort operators
   # TODO sort operators based on the order in ../qmutpy-support/mutation-operators.csv
  melt$'operator' <- factor(melt$'operator', levels=c(
    # Traditional mutants
    'AOD', 'AOR', 'ASR', 'BCR', 'COD', 'COI', 'CRP', 'DDL', 'EHD', 'EXS', 'IHD', 'IOD', 'IOP', 'LCR', 'LOD', 'LOR', 'ROR', 'SCD', 'SCI', 'SIR',
    # Quantum-based mutants
    'QGD', 'QGI', 'QGR', 'QMD', 'QMI'
  ))
  melt$'type' <- NA # TODO get this info from ../qmutpy-support/mutation-operators.csv
  melt$'type'[melt$'operator' %in% c('AOD', 'AOR', 'ASR', 'BCR', 'COD', 'COI', 'CRP', 'DDL', 'EHD', 'EXS', 'IHD', 'IOD', 'IOP', 'LCR', 'LOD', 'LOR', 'ROR', 'SCD', 'SCI', 'SIR')] <- 'Traditional'
  melt$'type'[melt$'operator' %in% c('QGD', 'QGI', 'QGR', 'QMD', 'QMI')] <- 'Quantum-based'

  # Un-factorize
  melt$'variable' <- as.character(melt$'variable')
  # Pretty print legent items
  melt$'variable'[melt$'variable' == 'time_create_mutant_module'] <- 'Create mutant module'
  melt$'variable'[melt$'variable' == 'time_create_target_ast']    <- 'Create target AST'
  melt$'variable'[melt$'variable' == 'time_mutate_module']        <- 'Mutate module'
  # Re-factorize with the factor
  melt$'variable' <- factor(melt$'variable', level=unique(melt$'variable'))

  return(melt)
}

unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=15, height=5)
plot_label('Time values')

# ------------------------------------------------------------------- as boxplot

melt <- reshape_and_melt(agg, c('operator', 'target'))

# Label
plot_label('Distribution as boxplot')
# Basic box plot with colors by groups
p <- ggplot(melt, aes(x=operator, y=value, fill=variable)) + geom_boxplot()
# Facets
p <- p + facet_grid( ~ type, scale='free', space='free')
# Change x axis label
p <- p + scale_x_discrete(name='Operator')
# Change y axis label and control its scale
p <- p + scale_y_continuous(name='Time (seconds)\nlog2 scale', trans='log2', labels=function(x) format(round(x, 2), scientific=FALSE))
# Remove legend's title and move it to the top
p <- p + theme(legend.title=element_blank(), legend.position='top')
# Plot it
print(p)

# ------------------------------------------------------------------ as geom-bar

agg <- aggregate(cbind(time_create_mutant_module, time_create_target_ast, time_mutate_module) ~ operator, agg, FUN=mean)
melt <- reshape_and_melt(agg, c('operator'))

# Label
plot_label('As geom-bars')
# Basic box plot with colors by groups
p <- ggplot(data=melt, aes(x=operator, y=value, fill=variable)) + geom_bar(stat='identity', color='white', size=0.01)
# Facets
p <- p + facet_grid( ~ type, scale='free', space='free')
# Change x axis label
p <- p + scale_x_discrete(name='Operator')
# Change y axis label and control its scale
p <- p + scale_y_continuous(name='Time (seconds)\nlog2 scale', trans='log2', labels=function(x) format(round(x, 2), scientific=FALSE))
# Remove legend's title and move it to the top
p <- p + theme(legend.title=element_blank(), legend.position='top')
# Plot it
print(p)

dev.off()
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
