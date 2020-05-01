library(tidyverse)
library(Lahman)
library(pwr)
library(gridExtra)

teams_df <- Teams %>% 
  filter(yearID > 1990) %>% 
  mutate(att_avg = attendance / G,
         category = paste(lgID, divID))

t.test(teams_df[teams_df$category == "NL W", "att_avg"], teams_df[teams_df$category == "AL C", "att_avg"])
t.test(teams_df[teams_df$category == "AL E", "att_avg"], teams_df[teams_df$category == "NL C", "att_avg"])

p1 <- ggplot(data = teams_df, mapping = aes(x = att_avg)) +
  geom_density(position = 'identity') +
  geom_vline(xintercept = c(11800, 14500, 18700), linetype = 'dashed')

p2 <- ggplot(data = teams_df, mapping = aes(x = att_avg)) +
  geom_density(position = 'identity') +
  theme(axis.text.x = element_blank()) + 
  facet_grid(~ category)

p3 <- ggplot(data = teams_df, mapping = aes(x = category, y = att_avg)) + 
  geom_boxplot()

p4 <-  ggplot(data = teams_df, mapping = aes(x = W, y = att_avg)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  facet_wrap(~ category, ncol = 3)

grid.arrange(p1, p2, p3, p4, ncol = 2)