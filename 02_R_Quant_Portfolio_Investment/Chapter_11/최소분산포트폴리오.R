library(quantmod)
library(PerformanceAnalytics)
library(magrittr)
library(tidyverse)

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

prices <- do.call(cbind, 
                  lapply(symbols, function(x) Ad(get(x)))) %>% 
  setNames(symbols)

ret <- Return.calculate(prices) %>% na.omit()
