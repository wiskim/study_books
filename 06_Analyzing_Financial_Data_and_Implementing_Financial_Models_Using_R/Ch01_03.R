library(tidyverse)
library(quantmod)

amzn_ohlc <- getSymbols('AMZN', 
                        from = '2010-12-31', 
                        to = '2013-12-31', 
                        auto.assign = FALSE)

# Trend: Simple Moving Average Crossover

amzn_sma <- amzn_ohlc$AMZN.Close
amzn_sma$sma_50 <- rollmean(amzn_sma$AMZN.Close, 
                            k = 50,
                            fill = NA,
                            align = 'right')
amzn_sma$sma_200 <- rollmean(amzn_sma$AMZN.Close,
                             k = 200,
                             fill = NA,
                             align = 'right')
amzn_sma <- amzn_sma['2012-01-01/']
amzn_sma <- data.frame(date = index(amzn_sma), coredata(amzn_sma))
amzn_sma <- gather(amzn_sma, key = 'key', value = 'value', -date)

ggplot(amzn_sma, aes(date, value, linetype = key)) +
  geom_line() +
  scale_linetype_manual(values = c('solid',
                                   'longdash',
                                   'dashed'),
                        labels = c('AMZN Price',
                                   '200-Day Moving Average',
                                   '50-Day Moving Average'))

# Volatility: Bollinger Bands

amzn_bb <- amzn_ohlc$AMZN.Close
amzn_bb$avg <- rollmean(amzn_bb$AMZN.Close,
                        k = 20,
                        fill = NA,
                        align = 'right')
amzn_bb$sd <- rollapply(amzn_bb$AMZN.Close,
                        width = 20,
                        FUN = sd,
                        fill = NA,
                        align = 'right')
amzn_bb <- amzn_bb['2013-01-01/']
amzn_bb <- data.frame(date = index(amzn_bb), coredata(amzn_bb))
amzn_bb$sd2up <- amzn_bb$avg + 2 * amzn_bb$sd
amzn_bb$sd2down <- amzn_bb$avg - 2 * amzn_bb$sd
amzn_bb <- gather(amzn_bb, key = 'key', value = 'value', -date)

ggplot(amzn_bb[amzn_bb$key != 'sd', ], 
       aes(date, value, linetype = key, color = key)) +
  geom_line() + 
  scale_linetype_manual(values = c('solid', 'dashed', 'solid', 'solid'),
                        labels = c('AMZN Price',
                                   '20-Day Moving Average',
                                   'Up Band',
                                   'Down Band')) +
  scale_color_manual(values = c('black', 'black', 'blue', 'blue'),
                     labels = c('AMZN Price',
                                '20-Day Moving Average',
                                'Up Band',
                                'Down Band'))

# Momentum: Relative Strength Index

amzn_rsi <- amzn_ohlc$AMZN.Close
amzn_rsi$delta <- diff(amzn_rsi$AMZN.Close)
amzn_rsi$up <- ifelse(amzn_rsi$delta > 0, 1, 0)
amzn_rsi$down <- ifelse(amzn_rsi$delta < 0 , 1, 0)
amzn_rsi$up_val <- amzn_rsi$delta * amzn_rsi$up
amzn_rsi$down_val <- abs(amzn_rsi$delta * amzn_rsi$down)
amzn_rsi <- amzn_rsi[-1, ]
amzn_rsi$up_first_avg <- rollmean(amzn_rsi$up_val,
                                  k = 14,
                                  fill = NA,
                                  align = 'right')
amzn_rsi$down_first_avg <- rollmean(amzn_rsi$down_val,
                                    k = 14,
                                    fill = NA,
                                    align = 'right')
amzn_rsi$up_avg <- amzn_rsi$up_first_avg
amzn_rsi$down_avg <- amzn_rsi$down_first_avg
amzn_rsi <- data.frame(date = index(amzn_rsi), coredata(amzn_rsi))
for (i in 15:nrow(amzn_rsi)){
  amzn_rsi$up_avg[i] <- (amzn_rsi$up_avg[i - 1] * 13 + 
                           amzn_rsi$up_val[i]) / 14
}
for (i in 15:nrow(amzn_rsi)){
  amzn_rsi$down_avg[i] <- (amzn_rsi$down_avg[i - 1] * 13 + 
                             amzn_rsi$down_val[i]) / 14
}
amzn_rsi$rs <- amzn_rsi$up_avg / amzn_rsi$down_avg
amzn_rsi$rsi <- 100 - (100 / (1 + amzn_rsi$rs))
amzn_rsi <- amzn_rsi[amzn_rsi$date >= '2012-01-01', ]

ggplot(amzn_rsi, aes(date, rsi)) +
  geom_line() +
  geom_hline(yintercept = c(25, 75))
