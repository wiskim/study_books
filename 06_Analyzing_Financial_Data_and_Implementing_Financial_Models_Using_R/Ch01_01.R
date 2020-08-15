library(tidyverse)
library(quantmod)

# Importing Daily Stock Price Data

data.AMZN <- getSymbols('AMZN', 
                        from = '2010-12-31', 
                        to = '2013-12-31',
                        auto.assign = FALSE)


# Subsetting Using Dates

xts.2012 <- subset(data.AMZN,
                   index(data.AMZN) >= '2012-01-01' &
                   index(data.AMZN) <= '2012-12-31')

AMZN.2012 <- cbind(index(data.AMZN),
                   data.frame(data.AMZN[, 4]))
names(AMZN.2012)[1] <- 'date'
rownames(AMZN.2012) <- seq(1, nrow(AMZN.2012))
AMZN.2012 <- subset(AMZN.2012,
                    AMZN.2012$date >= '2012-01-01' &
                    AMZN.2012$date <= '2012-12-31')


# Converting Daily Prices to Weekly and Monthly Prices

wk <- data.AMZN
data.weekly <- to.weekly(wk)

data.AMZN['2011-01-03/2011-01-07']$AMZN.Volume %>% sum()

mo <- data.AMZN
data.monthly <- to.monthly(mo)


# Plotting a Candlestick Chart Using Monthly Data

OHLC <- data.monthly[-1, -6]
AMZN.ohlc <- as.quantmod.OHLC(OHLC, 
                              col.names = c(
                                'Open', 'High', 'Low', 
                                'Close', 'Volume'
                                ))
chartSeries(AMZN.ohlc, 
            theme = 'white.mono', name = 'AMZN PHLC')
