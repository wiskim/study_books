library(tidyverse)
library(gridExtra)
library(Lahman)

reg_data <- Batting %>% 
  filter(yearID == 2015 | yearID == 2016) %>% 
  arrange(playerID, yearID, stint)

n <- ncol(reg_data)

for(i in 1:n){
  reg_data[, i + n] = lag(reg_data[, i])
}

for(k in (n+1):(n*2)){
  names(reg_data)[k] = paste0("lag_", names(reg_data)[k-n]) 
}

reg_data <- reg_data %>% 
  filter(playerID == lag_playerID,
         teamID != lag_teamID,
         AB > 400,
         lag_AB > 400) %>% 
  mutate(change_rbi = RBI / lag_RBI,
         lag_avg = lag_H / lag_AB,
         sac = lag_SF + lag_SH)

cor1 <- cor(reg_data$change_rbi, reg_data$lag_avg)
cor2 <- cor(reg_data$change_rbi, reg_data$sac)

p1 <- ggplot(reg_data, mapping = aes(x = lag_avg, y = change_rbi)) +
  geom_point(mapping = aes(color = lgID), size = 3) +
  geom_smooth(method = 'lm', se = F) +
  labs(title = paste0("Correlation : ", round(cor1, 5)),
       x = "Batting Average of Prior Year",
       y = "Change in RBI",
       color = "League")
p2 <- ggplot(reg_data, mapping = aes(x = sac, y = change_rbi)) +
  geom_point(mapping = aes(color = lgID), size = 3) +
  geom_smooth(method = 'lm', se = F) +
  labs(title = paste0("Correlation : ", round(cor2, 5)),
       x = "Sacrifice Flies & Hits of Prior Year",
       y = "Change in RBI",
       color = "League")
grid.arrange(p1, p2, ncol = 2)