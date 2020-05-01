library(tidyverse)
library(Lahman)
library(showtext)

df <- Teams %>% 
  filter(yearID > 2014) %>% 
  mutate(div_w = ifelse(DivWin == "Y", 1, 0)) %>% 
  select(div_w, ERA)

lr <- glm(formula = div_w ~ ERA, data = df, family = binomial(link = "logit"))
summary(lr)

df <- df %>% 
  mutate(logit = summary(lr)$coefficient[1] + summary(lr)$coefficient[2] * ERA,
         prob = exp(logit) / (1 + exp(logit)))

font_add_google("Noto Serif KR", "notoserifkr")
showtext_auto()
windows()

ggplot(data = df) +
  geom_line(mapping = aes(x = ERA, y = prob)) +
  geom_point(mapping = aes(x = ERA, y = div_w)) +
  labs(title = "팀 방어율과 디비젼 우승확률 로지스틱 회귀분석",
       x = "ERA",
       y = "우승확률")