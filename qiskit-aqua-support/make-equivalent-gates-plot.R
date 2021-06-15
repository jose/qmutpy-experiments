# Required packages
require('igraph')

# ------------------------------------------------------------------------- Util

#
# Embed any font in the pdf file.
#
embed_fonts_in_a_pdf <- function(pdf_path) {
  library('extrafont') # install.packages('extrafont')
  embed_fonts(pdf_path, options="-dSubsetFonts=true -dEmbedAllFonts=true -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dMaxSubsetPct=100")
}

#
# Plots the provided text on a dedicated page.  This function is usually used to
# separate plots for multiple analyses in the same PDF.
#
plot_label <- function(text) {
  library('ggplot2') # install.packages('ggplot2')
  p <- ggplot() + annotate("text", label=text, x=4, y=25, size=8) + theme_void()
  print(p)
}

# ------------------------------------------------------------------------- Main

df <- read.csv('equivalent-gates.csv', header=TRUE, stringsAsFactors=FALSE)

PDF_PATH <- "equivalent-gates.pdf"
unlink(PDF_PATH)
pdf(file=PDF_PATH, family="Helvetica", width=10, height=10)

#
# Heatmap
#

plot_label("as heatmap")
p <- ggplot(df, aes(x=gate, y=equivalent_gate)) + geom_tile(color="white", size=0.01)
# Remove x-axis and y-axis label
p <- p + theme(axis.title.x=element_blank(),
               axis.title.y=element_blank(),
               axis.text.y = element_text(size=12),
               axis.text.x = element_text(angle=45, vjust=1, hjust=1, size=12))
# Remove border space 
p <- p + scale_y_discrete(expand=c(0,0)) + scale_x_discrete(expand=c(0,0))
# Same size per square
p <- p + coord_fixed()
# Plot it
plot(p)

#
# Network graph
#

plot_label("as network graph")

network <- graph_from_data_frame(df, directed=FALSE)
plot_label("network graph :: random")
plot(network, layout=layout.random)
plot_label("network graph :: grid")
plot(network, layout=layout.grid)

dev.off()
embed_fonts_in_a_pdf(PDF_PATH)
