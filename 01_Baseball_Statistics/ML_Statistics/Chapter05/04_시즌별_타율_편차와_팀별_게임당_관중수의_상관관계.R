library(tidyverse)
library(Lahman)
library(gridExtra)

batting_df <- as_tibble(Batting) %>% 
  filter(yearID > 1975 & yearID < 2017 & AB > 400) %>% 
  select(yearID, AB, H, G) %>% 
  mutate(AVG = H / AB) %>% 
  na.omit() %>% 
  group_by(yearID) %>% 
  summarise(sd = sd(AVG), mean = mean(AVG)) %>% 
  mutate(z = (0.3 - mean) / sd,
         per = pnorm(0.3, mean, sd, lower.tail = TRUE))

team_list <- as_tibble(Teams) %>% 
  filter(yearID > 1975 & yearID < 2017) %>% 
  group_by(yearID) %>% 
  distinct(teamID) %>% 
  mutate(check = 1) %>% 
  spread(key = teamID, value = check)
team_list <- team_list[, colSums(is.na(team_list)) == 0]
team_list <- colnames(team_list)[-1]

att_df <- Teams %>% 
  filter(yearID > 1975 & yearID < 2017 & teamID %in% team_list) %>% 
  group_by(yearID) %>% 
  summarise(G = sum(G), att = sum(attendance)) %>% 
  mutate(att_avg = att / G)

result_df <- inner_join(batting_df, att_df, by = "yearID") %>% 
  mutate(att_avg_change = att_avg / lag(att_avg)) %>% 
  filter(yearID != 1976 & yearID != 1994 & yearID != 1995 & yearID != 1996)

ggplot(data = result_df, mapping = aes(x = sd, y = att_avg_change)) +
  geom_point(size = 3, alpha = 0.3) +
  geom_smooth(method = 'lm', formula = y ~ x, se = FALSE, color = "black")

summary(lm(att_avg_change ~ sd + mean + yearID, result_df))
