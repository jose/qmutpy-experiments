# This script plots mutation raw data as boxplot.
#
# Usage:
#   Rscript raw_data_as_heatmaps.R <output pdf file>
#

source('util.R')

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop('USAGE: Rscript raw_data_as_heatmaps.R <output pdf file>')
}

OUTPUT_FILE <- args[1]

# Load data
df <- load_exps_data()

# Annotate each mutant with a unique ID to ease plotting
df$'status_operator'    <- paste(df$'status', df$'operator', sep='-')
df$'status_operator_id' <- NA
for (target in unique(df$'target')) {
  for (status_operator in unique(df$'status_operator'[df$'target' == target])) {
    mask <- df$'target' == target & df$'status_operator' == status_operator
    df$'seq'[mask] <- seq_len(nrow(df[mask, ]))
    df$'status_operator_id'[mask] <- paste(df$'status_operator'[mask], df$'seq'[mask], sep='-')
  }
}
# Order IDs
df$'status_operator_id' <- factor(df$'status_operator_id', levels=unique(str_sort(df$'status_operator_id', decreasing=FALSE, numeric=TRUE)))

# TODO
# In an ideal world the following grid set would be automatically identified, as
# I am not aware of any R package or know how to develop some code to automatically
# do it, here is a non-automated version.
operators_grid <- list(
  c(unique(df$'operator')),
  c('CRP'),
  c('AOR'),
  c('SIR', 'SCI', 'BCR', 'EHD', 'ASR', 'COD', 'IOP', 'LOD'),
  c('COI', 'IOD', 'AOD', 'SCD', 'LOR'),
  c('ROR', 'DDL', 'LCR', 'EXS', 'IHD'),
  c('QGI'),
  c('QGR', 'QGD', 'QMI', 'QMD')
)

unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=20, height=25)

plot_label('Raw data as heatmaps')

# ---------------------------------------------------------------- as geom-tiles

plot_label('Heatmaps as geom-tiles')

geom_tiles_plots <- list(); i <- 1
for (operators in operators_grid) {
  p <- ggplot(df[df$'operator' %in% operators, ], aes(x=status_operator_id, y=short_target, fill=status)) +
         geom_tile(color='white', size=0.01) +
         theme(axis.title.x=element_blank(),
           axis.text.x=element_blank(),
           axis.ticks.x=element_blank(),
           axis.title.y=element_blank(),
           legend.title=element_blank(),
           legend.position='top') +
         scale_fill_discrete(drop=FALSE) +
         scale_y_discrete(expand=c(0,0)) + scale_x_discrete(expand=c(0,0))

  if (i > 1) {
    p <- p + theme(legend.position='none')
    p <- p + facet_wrap( ~ operator, scales='free_x', ncol=length(operators))
  }

  # Adapt the widths to all facet columns
  gp <- set_relative_widths_to_all_facet_columns(p)

  geom_tiles_plots[[i]] <- gp
  i <- i + 1
}

# Plot them
ggarrange(plotlist=geom_tiles_plots, ncol=1, align='v')

# ----------------------------------------------------------------- as geom-bars

plot_label('Heatmaps as geom-bars')

geom_bar_plots <- list(); i <- 1
for (operators in operators_grid) {
  p <- ggplot(df[df$'operator' %in% operators, ], aes(y=short_target, fill=status)) +
         geom_bar(color='white', size=0.01) +
         theme(axis.title.x=element_blank(),
           axis.text.x=element_blank(),
           axis.ticks.x=element_blank(),
           axis.title.y=element_blank(),
           legend.title=element_blank(),
           legend.position='top') +
         scale_fill_discrete(drop=FALSE) +
         scale_y_discrete(expand=c(0,0)) + scale_x_discrete(expand=c(0,0))

  if (i > 1) {
    p <- p + theme(legend.position='none')
    p <- p + facet_grid( ~ operator, scale='free', space='free')
  }

  geom_bar_plots[[i]] <- p
  i <- i + 1
}

# Plot them
ggarrange(plotlist=geom_bar_plots, ncol=1, align='v')

dev.off()
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
