library(tidyverse)
library(Lahman)
library(gridExtra)

teams_df <- as_tibble(Teams) %>% 
  mutate(attend = attendance / G,
         lgID = relevel(lgID, ref="AL"))

lm1 <- summary(lm(attend ~ HR, teams_df))
lm1

p1 <- ggplot(data = teams_df, mapping = aes(x = HR, y = attend)) +
  geom_smooth(method = 'lm', formula = y ~ x, se = FALSE)

teams_df2 <- teams_df %>% 
  filter(lgID == 'AL' | lgID == 'NL')

lm2 <- summary(lm(attend ~ HR + lgID, teams_df2))
lm2

p2 <- ggplot(data = teams_df2, mapping = aes(x = HR, y = attend)) +
  geom_point(alpha = 0) + 
  geom_abline(intercept = lm2$coefficient[1], slope = lm2$coefficient[2], color = 'blue', size = 1, lty = 2) +
  geom_abline(intercept = lm2$coefficient[1] + lm2$coefficient[3], slope = lm2$coefficient[2], color = 'blue', size = 1)

grid.arrange(p1, p2, ncol = 2)
