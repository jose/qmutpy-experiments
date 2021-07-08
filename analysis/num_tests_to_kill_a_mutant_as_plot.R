# This script plots the number of tests required to kill each mutant as boxplots.
#
# Usage:
#   Rscript num_tests_to_kill_a_mutant_as_plot.R <output pdf file>
#

source('util.R')

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop('USAGE: Rscript num_tests_to_kill_as_plot.R <output pdf file>')
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
  short_target, operator, mutation_operator_type, number_of_tests_executed
))

# Remove and create pdf file
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family="Helvetica", width=15, height=5)
plot_label("Number of tests required to kill each mutant")

# Label
plot_label('Distribution as boxplot\nper mutation operator')
# Basic box plot with colors by groups
p <- ggplot(df, aes(x=operator, y=number_of_tests_executed)) + geom_violin(fill='#A4A4A4')
# Facets
p <- p + facet_grid(. ~ mutation_operator_type, scale='free', space='free')
# Change x axis label
p <- p + scale_x_discrete(name='Operator')
# Change y axis label and control its scale
p <- p + scale_y_continuous(name='# Tests\nlog2 scale', trans='log2', labels=function(x) format(round(x, 2), scientific=FALSE))
# Add mean and median points
p <- p + stat_summary(fun=median, geom='point', shape=16, size=2, fill='black', color='black')
p <- p + stat_summary(fun=mean, geom='point', shape=8, size=2, fill='black', color='black')
# Remove legend
p <- p + theme(legend.title=element_blank(), legend.position='none')
# Plot it
print(p)

# Label
plot_label('Distribution as boxplot\nper target')
# Basic box plot with colors by groups
p <- ggplot(df, aes(x=short_target, y=number_of_tests_executed)) + geom_violin(fill='#A4A4A4')
# Facets
# p <- p + facet_wrap( ~ mutation_operator_type, scale='free', ncol=1)
p <- p + facet_grid(mutation_operator_type ~ ., scale='free_x', space='free_x')
# Change x axis label
p <- p + scale_x_discrete(name='Algorithm')
# Change y axis label and control its scale
p <- p + scale_y_continuous(name='# Tests\nlog2 scale', trans='log2', labels=function(x) format(round(x, 2), scientific=FALSE))
# Add mean and median points
p <- p + stat_summary(fun=median, geom='point', shape=16, size=2, fill='black', color='black')
p <- p + stat_summary(fun=mean, geom='point', shape=8, size=2, fill='black', color='black')
# Remove legend and rotate x-axis 45 degrees
p <- p + theme(legend.title=element_blank(), legend.position='none', axis.text.x=element_text(angle=45, hjust=1))
# Plot it
print(p)

dev.off()
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
