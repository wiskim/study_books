library(tidyverse)
library(Lahman)

a <- Teams %>% 
  filter(teamID == 'PIT') %>% 
  mutate(AVG = H / AB)

reg <- lm(R ~ AVG, a)
plot(reg)

plot(reg, which = 4)