# This script plots coverage vs. mutation score per target and per mutation
# operator.
#
# Usage:
#   Rscript var_X_vs_var_Y.R <output pdf file>
#

source('util.R')

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop('USAGE: Rscript var_X_vs_var_Y.R <output pdf file>')
}

OUTPUT_FILE <- args[1]

# Load data
df <- load_exps_data()
# Ignore mutations that resulted in 'incompetent' mutants as they do not count
# for the mutation score
df <- df[df$'status' != 'incompetent', ]

#
# Compute mutation data
#
mutation_df <- subset(process_targets_mutation_data(df), select=c(
  short_target, operator, mutation_score_ignoring_survided_status
))
mutation_df <- aggregate(. ~ short_target + operator, mutation_df, FUN=mean)

#
# Compute coverage data
#
coverage_df <- subset(process_targets_coverage_data(df), select=c(
  short_target, line_coverage
))

# Merge mutation and coverage data to ease plot
cov_mut_df <- merge(mutation_df, coverage_df, by='short_target', all=TRUE)
cov_mut_df$'short_target' <- factor(cov_mut_df$'short_target', levels=sort(unique(cov_mut_df$'short_target'), decreasing=TRUE))

#
# Plots
#

# Remove and create pdf file
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=8)
plot_label('Var X vs Var Y \n Scatter Plots')

# Overall Coverage vs MutationScore
kendall  <- cor.test(cov_mut_df$'line_coverage', cov_mut_df$'mutation_score_ignoring_survided_status', method=c('kendall'))
spearman <- cor.test(cov_mut_df$'line_coverage', cov_mut_df$'mutation_score_ignoring_survided_status', method=c('spearman'), exact=FALSE)
plot_label(paste('Overall Coverage vs Mutation Score', '\n',
  'kendall (p-value): ', kendall$'p.value', '\n',
  'kendall (tau): ', kendall$'estimate', '\n',
  'spearman (p-value): ', spearman$'p.value', '\n',
  'spearman (tau): ', spearman$'estimate', '\n', sep=''))

# Basic scatter plot
p <- ggplot(aggregate(. ~ short_target, cov_mut_df, FUN=mean), aes(x=line_coverage, y=mutation_score_ignoring_survided_status, color=short_target, shape=short_target)) + geom_point(size=3) + scale_size_area()
# Legend
p <- p + scale_shape_manual(values = c(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,15,16,17,18,15))
p <- p + theme(legend.title=element_blank(), legend.position='top') +
         guides(color=guide_legend(nrow=4, byrow=TRUE),
                shape=guide_legend(nrow=4, byrow=TRUE))
# Add regression lines
# p <- p + geom_smooth(method=lm)
# Axis
p <- p + scale_x_continuous(name='% Coverage')
p <- p + scale_y_continuous(name='% Mutation Score')
plot(p)

# Coverage vs MutationScore
plot_label('Coverage vs Mutation Score')
# Basic scatter plot
p <- ggplot(cov_mut_df, aes(x=line_coverage, y=mutation_score_ignoring_survided_status, color=short_target, shape=short_target)) + geom_point(size=2) + scale_size_area()
# Legend
p <- p + scale_shape_manual(values = c(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,15,16,17,18,15))
p <- p + theme(legend.title=element_blank(), legend.position='top') +
         guides(color=guide_legend(ncol=6, byrow=TRUE),
                shape=guide_legend(ncol=6, byrow=TRUE))
# Facets
p <- p + facet_wrap(~ operator, ncol=4)
# Axis
p <- p + scale_x_continuous(name='% Coverage')
p <- p + scale_y_continuous(name='% Mutation Score')
plot(p)

dev.off()
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
