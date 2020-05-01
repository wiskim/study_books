library(quantmod)
library(PerformanceAnalytics)
library(timeSeries)
library(tidyverse)

symbols = c('SPY', # 미국 주식
            'TLT'  # 미국 장기채
            )

getSymbols(symbols, src = 'yahoo')

price <- do.call(
  cbind, 
  lapply(symbols, function(x) {Ad(get(x))})
  ) %>%
  setNames(symbols)

rets <- Return.calculate(price) %>% na.omit()

cor(rets)

portfolio <- Return.portfolio(
  R = rets,
  weights = c(0.6, 0.4),
  rebalance_on = 'years',
  verbose = TRUE)

portfolios <- cbind(rets, portfolio$returns) %>%
  setNames(c('주식', '채권', '60대 40'))

charts.PerformanceSummary(
  portfolios, main = '60대 40 포트폴리오'
  )

turnover <- xts(
  rowSums(
    abs(portfolio$BOP.Weight # 당일 시작시점 비중
        - timeSeries::lag(portfolio$EOP.Weight)), # 전일 종료시점 비중
    na.rm = TRUE),
  order.by = index(portfolio$EOP.Weight)
  ) # 리밸런싱이 없었으면 0, 리밸런싱 비중 변화가 커질수록 높아짐

chart.TimeSeries(turnover)
