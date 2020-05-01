library(tidyverse)
library(Lahman)

sample_size <- 1302

sample <- Teams %>% 
  filter(lgID == 'AL' | lgID == 'NL') %>% 
  sample_n(sample_size) %>% 
  mutate(avg = H/AB, 
         wp = W / G)

reg <- lm(wp~avg, sample)
summary(reg)

# 신뢰구간 : 2할 7푼을 기록하는 팀들의 표본으로 예측할 수 있는 2할 7푼 모집단의 팀승률이 해당될 수 있는 범위

rmse <- sqrt(sum(reg$residuals^2) / reg$df.residual)
avg_est <- 0.27
wp_est <- reg$coefficients[1] + reg$coefficients[2] * avg_est
se_ci <- rmse * (sqrt((1/sample_size) + ((avg_est - mean(sample$avg))^2 / sum((sample$avg - mean(sample$avg))^2))))
ci <- paste0('[', wp_est - 1.96 * se_ci, ' - ', wp_est + 1.96 * se_ci, ']')
cat(ci)

predict(reg, data.frame(avg = avg_est), level = 0.95, interval = 'confidence')

# 예측구간 : 다음 시즌에 콜로라도 로키스가 2할 7푼의 팀타율을 기록한다면 그 팀이 해당 시즌에 만들 수 있는 팀승률의 범위

se_prdct <- rmse * (sqrt(1 + (1/sample_size) + ((avg_est - mean(sample$avg))^2 / sum((sample$avg - mean(sample$avg))^2))))
prdct <- paste0('[', wp_est - 1.96 * se_prdct, ' - ', wp_est + 1.96 * se_prdct, ']')
cat(prdct)

predict(reg, data.frame(avg = avg_est), level = 0.95, interval = 'predict')

