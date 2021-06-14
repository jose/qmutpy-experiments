# R repository
repository="http://cran.us.r-project.org"
# Install packages
install.packages('extrafont', repos=repository)
install.packages('ggplot2', repos=repository)
install.packages('igraph', repos=repository)
# Load libraries (aka runtime sanity check)
library('extrafont')
library('ggplot2')
library('igraph')
# Exit
quit(save="no", status=0)
