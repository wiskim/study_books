library(quantmod)
library(PerformanceAnalytics)
library(magrittr)
library(ggplot2)

symbols <- c('102110.KS', '039490.KS')

getSymbols(symbols)

prices <- do.call(
  cbind,
  lapply(symbols, function(x) {
    Cl(get(x))
  })
)

ret <- Return.calculate(prices)
ret <-  ret['2016-01::2018-12']

reg <- lm(ret$X039490.KS.Close 
          ~ ret$X102110.KS.Close)
summary(reg)

ggplot(ret, 
       aes(x = X102110.KS.Close, 
           y = X039490.KS.Close)) +
  geom_point(size = 2.5, 
             alpha = 0.4, 
             stroke = 0) +
  geom_smooth(method = 'lm', 
              se = FALSE,
              color = 'red') +
  geom_abline(slope = 1, 
              intercept = 0, 
              lty = 'dashed') +
  coord_cartesian(xlim = c(-0.02, 0.02), 
                  ylim = c(-0.02, 0.02)) +
  labs(x = 'KOSPI 200',
       y = 'Individual Stock')
  
