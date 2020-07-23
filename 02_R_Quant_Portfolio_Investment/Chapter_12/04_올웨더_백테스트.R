library(quantmod)
library(PerformanceAnalytics)
library(cccp)
library(dplyr)

symbols = c('TLT',
            'IEF',
            'VT',
            'GLD',
            'DBC')
getSymbols(symbols, src = 'yahoo', from = '2008-07-01')

prices = do.call(cbind, lapply(symbols, function(x) Ad(get(x)))) %>% 
  setNames(symbols)

rets = Return.calculate(prices) %>% na.omit()


# 순정 올웨더 백테스트

portfolio = Return.portfolio(R = rets,
                             weights = c(0.4, 0.15, 0.3, 0.075, 0.075),
                             rebalance_on = 'years',
                             verbose = TRUE)

charts.PerformanceSummary(portfolio$returns,
                          main = '순정 올웨더')

Return.cumulative(portfolio$returns)
Return.annualized(portfolio$returns)
SharpeRatio.annualized(portfolio$returns)
table.Drawdowns(portfolio$returns)
apply.yearly(portfolio$returns, Return.cumulative)

write.csv(data.frame(portfolio$returns),
          paste0(getwd(),
                 '/02_R_Quant_Portfolio_Investment',
                 '/Chapter_12',
                 '/files',
                 '/allWeather_original.csv'),
          row.names = TRUE,
          fileEncoding = 'UTF-8')


# 리스크 패리티 올웨더 백테스트

ep = endpoints(rets, on = 'months')
wts = list()
lookback = 12

for (i in (lookback+1) : length(ep)) {
  sub_ret = rets[ep[i-lookback] : ep[i], ]
  covmat = cov(sub_ret)
  opt = rp(x0 = rep(0.2, 5),
           P = covmat,
           mrc = rep(0.2, 5))
  wt = getx(opt) %>% drop()
  wt = (wt / sum(wt)) %>% round(., 4)
  wts[[i]] = xts(t(wt), order.by = index(rets[ep[i]]))
}

wts = do.call(rbind, wts) %>% setNames(symbols)

portfolio = Return.portfolio(rets, wts, verbose = TRUE)

charts.PerformanceSummary(portfolio$returns, 
                          main = "리스크 패리티 올웨더")

Return.cumulative(portfolio$returns)
Return.annualized(portfolio$returns)
SharpeRatio.annualized(portfolio$returns)
table.Drawdowns(portfolio$returns)
apply.yearly(portfolio$returns, Return.cumulative)

write.csv(data.frame(portfolio$returns),
          paste0(getwd(),
                 '/02_R_Quant_Portfolio_Investment',
                 '/Chapter_12',
                 '/files',
                 '/allWeather_riskparity.csv'),
          row.names = TRUE,
          fileEncoding = 'UTF-8')
