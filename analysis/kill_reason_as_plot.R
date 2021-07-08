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
df <- df[!is.na(df$'operator'), ]
# Selected mutants that have been 'killed'
df <- df[!is.na(df$'status') & df$'status' == 'killed', ]
# Select only relevant columns
df <- subset(df, select=c(
  short_target, operator, mutation_operator_type, exception_traceback
))

# TODO
df$'killer_type' <- NA
for (error in c(
  # Quantum-based
  'AquaError: ',
  'QiskitOptimizationError: ',
  'QiskitError: ',
  'CircuitError: ',
  'MissingOptionalLibraryError: ',
  # Python-based
  'NotImplementedError',
  'IndexError: ',
  'ValueError: ',
  'AttributeError: ',
  'IsADirectoryError: ',
  'ZeroDivisionError: ',
  'OverflowError: ',
  'UnboundLocalError: ',
  'RuntimeError: ',
  'NameError: ',
  'KeyError: ',
  # NumPy
  'AxisError: '
)) {
  df$'killer_type'[grep(error, df$'exception_traceback')] <- 'Error'
}
# AssertErrors
df$'killer_type'[grep("AssertionError: ", df$'exception_traceback')] <- 'Assertion'
# Runtime check whether there is any error not label
stopifnot(is.na(df$'killer_type') == FALSE)
# Select only relevant columns
df <- subset(df, select=c(
  short_target, operator, mutation_operator_type, killer_type
))

unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=15, height=5)
plot_label('Killed by')

# ------------------------------------------------------------------- as boxplot

# Label
plot_label('By type')
# Basic box plot with colors by groups
p <- ggplot(df, aes(x=killer_type)) + geom_bar(colour='black')
# # Change x axis label
p <- p + scale_x_discrete(name='')
# Change y axis label
p <- p + scale_y_continuous(name='# Occurrences')
# Increase label size
p <- p + theme(
  axis.text.x=element_text(size=16,  hjust=0.5, vjust=0.5),
  axis.text.y=element_text(size=16,  hjust=1.0, vjust=0.0),
  axis.title.x=element_text(size=18, hjust=0.5, vjust=0.0),
  axis.title.y=element_text(size=18, hjust=0.5, vjust=0.5)
)
# Make it horizontal
p <- p + coord_flip()
# Plot it
print(p)

# Label
plot_label('By operator')
# Basic box plot with colors by groups
p <- ggplot(df, aes(x=operator, fill=killer_type)) + geom_bar(colour='black', position='dodge')
# Facets
p <- p + facet_grid( ~ mutation_operator_type, scale='free', space='free')
# Change x axis label
p <- p + scale_x_discrete(name='Operator')
# Change y axis label
p <- p + scale_y_continuous(name='# Occurrences\n(log2 scale)', trans='log2', labels=function(x) format(round(x, 2), scientific=FALSE))
# Remove legend's title and move it to the top
p <- p + theme(legend.title=element_blank(), legend.position='top')
# Plot it
print(p)

dev.off()
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
