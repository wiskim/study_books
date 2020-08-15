library(tidyverse)
library(httr)
library(rvest)
library(lubridate)
library(scales)
library(gridExtra)

# Comparing Capital Gains of Multiple Securities Over Time

ticker_list = c('kospi', '005930', '035720', '051910')
name_list = c('코스피', '삼성전자', '카카오', 'LG화학')
prices = list()

for (i in seq(1, length(ticker_list))){
  url = paste0(
    'https://fchart.stock.naver.com/sise.nhn?symbol=',
    ticker_list[i],'&timeframe=day&count=500&requestType=0'
    )
  resp = GET(url)
  ohlc = read_html(resp, encoding = 'euc-kr') %>% 
    html_nodes('item') %>% 
    html_attr('data') %>% 
    read_delim(delim = '|', col_names = FALSE)
  colnames(ohlc) = c(
    'DATE', 'OPEN', 'HIGH', 
    'LOW', 'CLOSE', 'VOLUME'
    )
  prices[[name_list[i]]] = ohlc[, c(1, 5)]
}

prices = prices %>% 
  imap(.x = ., ~ set_names(.x, c('DATE', .y))) %>% 
  reduce(full_join, by = 'DATE')

prices$DATE = ymd(prices$DATE)

prices = prices[prices$DATE>='2020-01-01', ]

for (name in name_list){
  prices[[paste0(name, '_IDX')]] = 
    prices[[name]] / 
    prices[[name]][1]
}

prices = gather(prices, 
                key = 'STOCK_CD', 
                value = 'IDX', 
                ends_with('_IDX')) %>% 
  select(DATE, STOCK_CD, IDX)

prices$STOCK_CD = str_remove_all(prices$STOCK_CD, '_IDX')

theme_set(theme_minimal(base_family='NanumGothic'))

# Chart 1

ggplot(prices, mapping = aes(DATE, IDX, color = STOCK_CD)) +
  geom_line(size = 1) +
  labs(x = '일자', y = '주가', color = element_blank()) +
  theme(legend.position = c(0.15, 0.8)) +
  scale_x_date(labels = date_format('%m-%d'))

# Chart 2

plots = list()

for (i in seq(1, length(name_list))){
  plots[[i]] = ggplot() +
    geom_line(prices, 
              mapping = aes(DATE, IDX, group = STOCK_CD), 
              alpha = 0.3) +
    geom_line(prices[prices$STOCK_CD == name_list[i], ],
              mapping = aes(DATE, IDX),
              color = 'blue',
              size = 1.2) +
    geom_hline(yintercept = 1) + 
    labs(title = paste0('[', name_list[i], ']'), x = '일자', y = '주가') +
    scale_x_date(labels = date_format('%m-%d')) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank())
}

do.call('grid.arrange', c(plots, ncol = 2))
