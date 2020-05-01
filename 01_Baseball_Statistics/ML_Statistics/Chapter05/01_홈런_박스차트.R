library(tidyverse)
library(Lahman)

a <- Batting %>% 
  filter(playerID == 'rodrial01' | playerID == 'pujolal01' | playerID == 'mcgwima01')

a$playerID <- factor(a$playerID, 
                     levels = c('rodrial01', 'pujolal01', 'mcgwima01'),
                     labels = c('Rodriguez', 'Pujols', 'McGwire'))

ggplot(a) + 
  geom_boxplot(mapping = aes(x = playerID, y = HR))