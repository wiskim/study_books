# Bruech-Pagan test : 
# H0 : homoscedasticity
# H1 : heteroscedasticity
# p-value < level of significance(보통 5%) -> H0  is rejected
# p-value > level of significance(보통 5%) -> fail to reject H0
# 즉 p-value가 클수록 등분산성이 높음

library(tidyverse)
library(gridExtra)
library(Lahman)
library(lmtest)
library(caret)

df1 <- Teams %>% 
  filter(yearID == 2014) %>% 
  mutate(WP = W/G)
lm1 <- lm(WP ~ R, df1)
bp1 <- bptest(lm1)
p1 <- ggplot(data = df1, mapping = aes(R, WP)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  labs(title = paste0('P-Value = ', round(bp1$p.value, 5)))

bct <- BoxCoxTrans(df1$WP)
WP_ADJ = predict(bct, df1$WP)
df2 <- cbind(df1, WP_ADJ)
lm2 <- lm(WP_ADJ ~ R, df2)
bp2 <- bptest(lm2)
p2 <- ggplot(data = df2, mapping = aes(R, WP_ADJ)) + 
  geom_point() +
  geom_smooth(method = 'lm') +
  labs(title = paste0('P-Value = ', round(bp2$p.value, 5)))

grid.arrange(p1, p2, ncol = 2)
print(bp1)
print(bp2)
