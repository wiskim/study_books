library(tidyverse)
library(Lahman)
library(pwr)

power.t.test(NULL, 0.2, 2, 0.05, 0.95, type = c('two.sample'))

al <- Batting %>% 
  filter(yearID > 1972, lgID == 'AL', G > 10) %>% 
  sample_n(2600)

nl <- Batting %>% 
  filter(yearID > 1972, lgID == 'NL', G > 10) %>% 
  sample_n(2600)

t.test(al$HBP, nl$HBP)