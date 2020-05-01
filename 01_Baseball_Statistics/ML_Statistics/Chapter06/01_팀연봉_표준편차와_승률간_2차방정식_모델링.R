library(tidyverse)
library(Lahman)

salary_df <- as_tibble(Salaries) %>% 
  filter(yearID > 2010) %>% 
  mutate(teamID = as.character(teamID)) %>% 
  select(-lgID)

# Lahman Salaries 데이터 중 2016년도 teamID가 franchID로 잘못 들어가 있어 teamID로 수정 (ex. NYY -> NYA)

teamID_df <- as_tibble(Teams) %>% 
  filter(yearID > 2010) %>% 
  mutate(teamID = as.character(teamID),
         franchID = as.character(franchID)) %>% 
  select(yearID, teamID, franchID)

salary_df2 <- left_join(x = salary_df, y = teamID_df, by = c('teamID' = 'franchID', 'yearID'))
salary_df2 <- salary_df2 %>% 
  mutate(teamID = ifelse(!is.na(teamID.y), teamID.y, teamID)) %>% 
  select(-teamID.y)
salary_df2$teamID[salary_df2$teamID == 'TBR'] <- "TBA"

batting_df <- as_tibble(Batting) %>% 
  filter(yearID > 2010, AB > 400) %>% 
  mutate(teamID = as.character(teamID))

batting_df <- left_join(x = batting_df, y = salary_df2, by = c('yearID', 'teamID', 'playerID'))

salary_sd_df <- batting_df %>% 
  group_by(teamID, yearID) %>% 
  summarise(salary_sd = sd(salary, na.rm = TRUE))

team_df <- as_tibble(Teams) %>% 
  filter(yearID > 2010) %>% 
  mutate(WP = W / G,
         teamID = as.character(teamID))

team_df <- left_join(x = team_df, y = salary_sd_df, by = c('yearID', 'teamID'))
team_df <- team_df[!is.na(team_df$salary_sd), ]

ggplot(data = team_df, mapping = aes(x = salary_sd, y = WP)) + 
  geom_point() +
  geom_smooth(method = 'loess', formula = y ~ x)

summary(lm(formula = WP ~ salary_sd, data = team_df))
summary(lm(formula = WP ~ I(salary_sd) + I(salary_sd^2), data = team_df))
