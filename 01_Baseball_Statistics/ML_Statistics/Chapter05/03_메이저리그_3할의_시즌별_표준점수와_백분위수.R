library(tidyverse)
library(Lahman)
library(gridExtra)

a <- Batting %>% 
  filter(yearID > 1975 & yearID < 2017 & AB > 400) %>% 
  select(yearID, AB, H, G) %>% 
  mutate(AVG = H / AB) %>% 
  na.omit() %>% 
  group_by(yearID) %>% 
  summarise(sd = sd(AVG), mean = mean(AVG)) %>% 
  mutate(z = (0.3 - mean) / sd,
         per = pnorm(0.3, mean, sd, lower.tail = TRUE))

p1 <- ggplot(a, mapping = aes(x = yearID, y = z)) +
  geom_point(size = 2.5) +
  geom_smooth(method = 'loess', se = FALSE) +
  labs(x = 'Year',
       y = 'Z Score of 0.3 AVG')

p2 <- ggplot(a, mapping = aes(x = yearID, y = per)) +
  geom_point(size = 2.5) +
  geom_smooth(method = 'loess', se = FALSE) +
  labs(x = 'Year',
       y = 'Percentile of 0.3 AVG')

grid.arrange(p1, p2, ncol = 2)