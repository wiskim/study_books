library(quantmod)
library(PerformanceAnalytics)
library(magrittr)
library(tidyverse)

symbols = c('TLT',
            'IEF',
            'VT',
            'GLD',
            'DBC'
)
getSymbols(symbols, src = 'yahoo', from = '2020-01-01')

prices <- do.call(cbind, 
                  lapply(symbols, function(x) Ad(get(x)))) %>% 
  setNames(symbols)

ret <- Return.calculate(prices) %>% na.omit()

library(tidyr)
library(corrplot)

cor(ret) %>% 
  corrplot(method = 'color', type = 'upper',
           addCoef.col = 'black', number.cex = 0.7,
           tl.cex = 0.6, tl.srt = 45, tl.col = 'black',
           col = colorRampPalette(c('blue', 'white', 'red'))(200),
           mar = c(0, 0, 0.5, 0))

covmat = cov(ret)

get_rc = function(w, covmat) {
  port_vol = t(w) %*% covmat %*% w
  port_std = sqrt(port_vol)
  
  mrc = (covmat %*% w) / as.numeric(port_std)
  rc = mrc * w
  rc = c(rc / sum(rc))
  
  return(rc)
}


rc = get_rc(c(0.4, 0.15, 0.3, 0.075, 0.075), covmat)
rc = round(rc, 4)

print(rc)

library(cccp)

opt = rp(x0 = rep(0.2, 5),
         P = covmat,
         mrc = rep(0.2, 5))

w = getx(opt) %>% drop()

w = (w / sum(w)) %>% 
  round(., 4) %>% 
  setNames(colnames(ret))

print(w)

get_rc(w, covmat)
