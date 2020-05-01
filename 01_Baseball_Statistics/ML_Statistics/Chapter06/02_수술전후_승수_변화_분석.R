library(tidyverse)
library(Lahman)

surgery <- tibble(playerID = c('johnto01', 
                               'smoltjo01',
                               'zimmejo02',
                               'strasst01',
                               'carpech01'),
                  surgery_year = c(1974,
                                   2000,
                                   2009,
                                   2010,
                                   2007))

surgery <- left_join(surgery, Pitching, by = 'playerID')
surgery$age <- surgery$yearID - surgery$surgery_year
surgery <- filter(surgery, age > -6 & age < 6)

ggplot(data = surgery, mapping = aes(x = age, y = W)) +
  geom_point() +
  geom_smooth(method = 'loess', formula = y ~ x, se = FALSE)

reg <- lm(formula = W ~ I(age) + I(age^2) + I(age^3) + I(age^4), data = surgery)
summary(reg)
