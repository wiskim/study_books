library(quantmod)
library(PerformanceAnalytics)
library(timeSeries)
library(tidyverse)

symbols <- c('SPY', 'SHY')
getSymbols(symbols, src = 'yahoo')

prices <- do.call(cbind, lapply(symbols, function(x){Ad(get(x))}))
rets <- Return.calculate(prices) %>% na.omit()
ep <- endpoints(rets, on = 'months')
wts <- list()
lookback <- 10

for (i in (lookback + 1) : length(ep)) {
  sub_price = prices[ep[i - lookback] : ep[i], 1]
  sma = mean(sub_price)
  wt = rep(0, 2)
  wt[1] = ifelse(last(sub_price) > sma, 1, 0)
  wt[2] = 1 - wt[1]
  wts[[i]] = xts(t(wt), order.by = index(rets[ep]))
}

wts <- do.call(rbind, wts)

tactical <- Return.portfolio(rets, wts, verbose = TRUE)

portfolios <- cbind(rets[, 1], tactical$returns) %>% na.omit() %>%
  setNames(c('매수 후 보유', '시점 선택 전략'))

charts.PerformanceSummary(portfolios,
                          main = "Buy & Hold vs Tactical")

turnover <- xts(
  rowSums(abs(tactical$BOP.Weight
              - timeSeries::lag(tactical$EOP.Weight)),
          na.rm = TRUE),
  order.by = index(tactical$BOP.Weight)
  )

chart.TimeSeries(turnover)
