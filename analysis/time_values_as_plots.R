# This script plots time values as boxplots.
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
# Discard any row for which there is no mutation data
df <- df[!is.na(df$'operator') & !is.na(df$'line_number'), ]
# Discard 'incompetent' mutants
df <- df[df$'status' != 'incompetent', ]
# Compute relative times as some targets require more time to mutate, e.g.,
# because they have many more place to mutate
df$'time_to_generate_mutated_ast'  <- NA
df$'time_to_create_mutated_module' <- NA
for (operator in unique(df$'operator')) {
  for (target in unique(df$'target')) {
    mask        <- df$'operator' == operator & df$'target' == target
    num_mutants <- length(unique(df$'mutation_id'[mask]))

    if (num_mutants == 0) {
      df$'time_to_generate_mutated_ast'[mask]  <- 0
      df$'time_to_create_mutated_module'[mask] <- 0
    } else {
      df$'time_to_generate_mutated_ast'[mask]  <- df$'time_to_generate_mutated_asts'[mask] / num_mutants
      df$'time_to_create_mutated_module'[mask] <- df$'time_to_create_mutated_modules'[mask] / num_mutants
    }
  }
}
# Select relevant columns
df <- subset(df, select=c(target, operator, mutation_operator_type, time_to_generate_mutated_ast, time_to_create_mutated_module))

reshape_and_melt <- function(df, vars) {
  melt <- reshape2::melt(df, id.vars=vars)

  # Un-factorize
  melt$'variable' <- as.character(melt$'variable')
  # Pretty print legent items
  melt$'variable'[melt$'variable' == 'time_to_generate_mutated_ast']  <- 'Generate mutant'
  melt$'variable'[melt$'variable' == 'time_to_create_mutated_module'] <- 'Create mutated module'
  # Re-factorize with the factor
  melt$'variable' <- factor(melt$'variable', level=unique(melt$'variable'))

  return(melt)
}

unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=15, height=5)
plot_label('Time values')

# ------------------------------------------------------------------- as boxplot

melt <- reshape_and_melt(df, c('operator', 'mutation_operator_type', 'target'))

# Label
plot_label('Distribution as boxplot')
# Basic box plot with colors by groups
p <- ggplot(melt, aes(x=operator, y=value, fill=variable)) + geom_violin()
# Facets
p <- p + facet_grid( ~ mutation_operator_type, scale='free', space='free')
# Change x axis label
p <- p + scale_x_discrete(name='Operator')
# Change y axis label and control its scale
p <- p + scale_y_continuous(name='Time (seconds)\nlog scale', trans='log', labels=function(x) format(round(x, 2), scientific=FALSE))
# Remove legend's title and move it to the top
p <- p + theme(legend.title=element_blank(), legend.position='top')
# Plot it
print(p)

dev.off()
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
