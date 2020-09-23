library(quantmod)
library(PerformanceAnalytics)
library(cccp)
library(dplyr)

symbols = c('TLT',
            'LTPZ',
            'VT',
            'GLD',
            'DBC')
getSymbols(symbols, src = 'yahoo', from = '2008-07-01')

prices = do.call(cbind, lapply(symbols, function(x) Ad(get(x)))) %>% 
  setNames(symbols)

rets = Return.calculate(prices) %>% na.omit()


# 순정 올웨더 백테스트

portfolio = Return.portfolio(R = rets,
                             weights = c(0.35, 0.15, 0.35, 0.075, 0.075),
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


# 단테 올웨더 백테스트

symbols = c(
  'VT',    # 전세계주식
  'EDV',   # 제로쿠폰장기채
  'VCLT',  # 회사장기채
  'EMLC',  # 이머징국가장기채(로컬화폐)
  'LTPZ',  # 물가연동장기채
  'DBC',   # 원자재 (BCI가 2017년에 상장, 장기 백테스트를 위해 DBC로 바꿈)
  'IAU'    # 금
)
getSymbols(symbols, src = 'yahoo')

prices = do.call(cbind, lapply(symbols, function(x) Ad(get(x)))) %>% 
  setNames(symbols)

rets = Return.calculate(prices) %>% na.omit()

library(tidyr)
library(corrplot)

cor(rets) %>% 
  corrplot(method = 'color', type = 'upper',
           addCoef.col = 'black', number.cex = 0.7,
           tl.cex = 0.6, tl.srt = 45, tl.col = 'black',
           col = colorRampPalette(c('blue', 'white', 'red'))(200),
           mar = c(0, 0, 0.5, 0))

portfolio = Return.portfolio(R = rets,
                             weights = c(
                               0.400,   # VT
                               0.250,   # EDV
                               0.075,   # VCLT
                               0.075,   # EMLC
                               0.100,   # LTPZ
                               0.050,   # BCI
                               0.050    # IAU
                             ),
                             rebalance_on = 'years',
                             verbose = TRUE)

charts.PerformanceSummary(portfolio$returns,
                          main = '단테 올웨더')

Return.cumulative(portfolio$returns)
Return.annualized(portfolio$returns)
SharpeRatio.annualized(portfolio$returns)
table.Drawdowns(portfolio$returns)
apply.yearly(portfolio$returns, Return.cumulative)
