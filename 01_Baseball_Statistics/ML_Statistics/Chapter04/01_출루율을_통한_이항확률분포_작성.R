library(tidyverse)
library(gridExtra)

obp_list <- seq(0.2, 0.5, 0.1)

for(i in 1:4){
  
  obp <- obp_list[i]
  base <- seq(0, 5)
  p <- obp^base*(1-obp)^(5-base)
  case <- choose(5, base)
  ev <- p*case
  df <- tibble(base = base, ev = ev)
  
  graph <- ggplot(data = df, mapping = aes(x = base, y = ev)) +
    geom_bar(stat = 'identity') +
    labs(title = paste0('OBP = ',obp,' (',round(p[3]*100, 2),'%)'),
         x = '',
         y = 'Probability')
  graph_name <- paste0('p', i)
  assign(graph_name, graph)
  
}

grid.arrange(p1, p2, p3, p4, ncol = 2)