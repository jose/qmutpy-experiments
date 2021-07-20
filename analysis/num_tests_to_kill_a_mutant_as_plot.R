# This script plots the number of tests required to kill each mutant as violinplots.
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
pdf(file=OUTPUT_FILE, family='Helvetica', width=15, height=5)
plot_label('Number of tests required to kill each mutant')

# Label
plot_label('Distribution as violinplot\nper mutation operator')
# Basic box plot with colors by groups
p <- ggplot(df, aes(x=operator, y=number_of_tests_executed)) + geom_violin(fill='#A4A4A4')
# Facets
p <- p + facet_grid(. ~ mutation_operator_type, scale='free', space='free')
# Change x axis label
p <- p + scale_x_discrete(name='Operator')
# Change y axis label and control its scale
p <- p + coord_trans(y='log10', expand=TRUE) + scale_y_continuous(name='# Tests', breaks=c(1, 2, 3, 4, 5, 10, 25, 50, 100, 250, 500))
# Add mean and median points
p <- p + stat_summary(fun=median, geom='point', shape=16, size=2, fill='darkorange', color='darkorange')
p <- p + stat_summary(fun=mean, geom='point', shape=8, size=2, fill='darkgreen', color='darkgreen')
# Add labels to mean and median points, and max value
p <- p + stat_summary(fun.data=function(x) data.frame(y=median(x), label=round(median(x),0)), geom='text', hjust=2, color='darkorange')
p <- p + stat_summary(fun.data=function(x) data.frame(y=mean(x), label=round(mean(x),0)), geom='text', hjust=-1, color='darkgreen')
p <- p + stat_summary(fun=max, geom='text', label=aggregate(number_of_tests_executed ~ operator, df, FUN=max)$'number_of_tests_executed', vjust=-0.5, color='purple')
# Display overall avarege as a horizontal line.  To achieve that, and because
# there are different facets, a data.frame must be create with positions of those
# lines.
hlines <- data.frame()
for (mutation_operator_type in unique(df$'mutation_operator_type')) {
  mask <- df$'mutation_operator_type' == mutation_operator_type
  y <- NA
  if (nrow(df[mask, ]) > 0) {
    y <- mean(df$'number_of_tests_executed'[mask])
  }
  hlines <- rbind(hlines, data.frame(mutation_operator_type=mutation_operator_type, y=y))
}
hlines$'mutation_operator_type' <- factor(hlines$'mutation_operator_type', levels=c(CLASSIC_MUTATION_OPERATOR_TYPE_STR, QUANTUM_MUTATION_OPERATOR_TYPE_STR))
p <- p + geom_hline(data=hlines, mapping=aes(yintercept=y), color='red')
# Label horizontal line
p <- p + geom_text(data=aggregate(. ~ mutation_operator_type, hlines, FUN=function(y) round(mean(y), 0)), aes(x=0.60, y=y, label=y), vjust=-0.50, color='red')
# Remove legend
p <- p + theme(legend.title=element_blank(), legend.position='none')
# Plot it
print(p)

# Label
plot_label('Distribution as violinplot\nper target')
# Basic box plot with colors by groups
p <- ggplot(df, aes(x=short_target, y=number_of_tests_executed)) + geom_violin(fill='#A4A4A4')
# Facets
# p <- p + facet_wrap( ~ mutation_operator_type, scale='free', ncol=1)
p <- p + facet_grid(mutation_operator_type ~ ., scale='free_x', space='free_x')
# Change x axis label
p <- p + scale_x_discrete(name='Algorithm')
# Change y axis label and control its scale
p <- p + coord_trans(y='log10', expand=TRUE) + scale_y_continuous(name='# Tests', breaks=c(1, 5, 10, 25, 50, 100, 250, 500))
# Ensure max y value is included
p <- p + expand_limits(y=c(1, max(df$'number_of_tests_executed')+ (max(df$'number_of_tests_executed')/2)))
# Add mean and median points
p <- p + stat_summary(fun=median, geom='point', shape=16, size=2, fill='darkorange', color='darkorange')
p <- p + stat_summary(fun=mean, geom='point', shape=8, size=2, fill='darkgreen', color='darkgreen')
# Add labels to mean and median points, and max value
p <- p + stat_summary(fun.data=function(x) data.frame(y=median(x), label=round(median(x),0)), geom='text', hjust=2, color='darkorange')
p <- p + stat_summary(fun.data=function(x) data.frame(y=mean(x), label=round(mean(x),0)), geom='text', hjust=-1, color='darkgreen')
p <- p + stat_summary(fun=max, geom='text', label=aggregate(number_of_tests_executed ~ short_target + mutation_operator_type, df, FUN=max)$'number_of_tests_executed', vjust=-0.5, color='purple')
# Display overall avarege as a horizontal line
p <- p + geom_hline(data=hlines, mapping=aes(yintercept=y), color='red')
# Label horizontal line
p <- p + geom_text(data=aggregate(. ~ mutation_operator_type, hlines, FUN=function(y) round(mean(y), 0)), aes(x=0.60, y=y, label=y), vjust=-0.50, color='red')
# Remove legend and rotate x-axis 45 degrees
p <- p + theme(legend.title=element_blank(), legend.position='none', axis.text.x=element_text(angle=30, hjust=1))
# Plot it
print(p)

dev.off()
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
