library(quantmod)
library(PerformanceAnalytics)
library(RiskPortfolios)
library(tidyr)
library(dplyr)
library(ggplot2)

symbols = c('SPY', # 미국 주식
            'IEV', # 유럽 주식 
            'EWJ', # 일본 주식
            'EEM', # 이머징 주식
            'TLT', # 미국 장기채
            'IEF', # 미국 중기채
            'IYR', # 미국 리츠
            'RWX', # 글로벌 리츠
            'GLD', # 금
            'DBC'  # 상품
            )

getSymbols(symbols, src = 'yahoo')

prices = do.call(cbind,
                 lapply(symbols, function(x) Ad(get(x)))) %>%
  setNames(symbols)

rets = Return.calculate(prices) %>% na.omit()

ep = endpoints(rets, on = 'months')
wts = list()
lookback = 12
wt_zero = rep(0, 10) %>% setNames(colnames(rets))

for (i in (lookback + 1) : length(ep)) {
  
  sub_ret = rets[ep[i - lookback] : ep[i], ]
  cum = Return.cumulative(sub_ret)
  
  k = rank(-cum) <= 5
  covmat = cov(sub_ret[, k])
  
  wt = wt_zero
  wt[k] = optimalPortfolio(covmat,
                           control = list(type = 'minvol',
                                          constraint = 'user',
                                          LB = rep(0.1, 5),
                                          UB = rep(0.3, 5)))
  wts[[i]] = xts(t(wt), order.by = index(rets[ep[i]]))
  
}

wts = do.call(rbind, wts)

GDAA = Return.portfolio(rets, wts, verbose = TRUE)
charts.PerformanceSummary(GDAA$returns, main = '동적자산배분')

wts %>% fortify.zoo() %>% 
  gather(key, value, -Index) %>%
  mutate(Index = as.Date(Index)) %>%
  mutate(key = factor(key, levels = unique(key))) %>%
  ggplot(aes(x = Index, y = value)) +
  geom_area(aes(color = key, fill = key), position = 'stack') +
  xlab(NULL) + ylab(NULL) + theme_bw() +
  scale_x_date(date_breaks = 'years', date_labels = '%Y',
               expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  theme(plot.title = element_text(hjust = 0.5,
                                  size = 12),
        legend.position = 'bottom',
        legend.title = element_blank(),
        axis.text.x = element_text(angle = 45,
                                   hjust = 1,
                                   size = 8),
        panel.grid.minor.x = element_blank()) +
  guides(color = guide_legend(byrow = TRUE))

GDAA$turnover = xts(
  rowSums(abs(GDAA$BOP.Weight - timeSeries::lag(GDAA$EOP.Weight)),
          na.rm = TRUE),
  order.by = index(GDAA$BOP.Weight)
)

chart.TimeSeries(GDAA$turnover)

fee = 0.0030
GDAA$net = GDAA$returns - GDAA$turnover * fee

cbind(GDAA$returns, GDAA$net) %>%
  setNames(c('No Fee', 'After Fee')) %>%
  charts.PerformanceSummary(main = 'GDAA')
