library(tidyverse)
library(xts)
library(PerformanceAnalytics)
library(magrittr)

file_path <- paste0(
  getwd(),
  '/03_R을_이용한_퀀트_투자_포트폴리오_만들기/',
  'Chapter_07/files/KOR_price.csv'
  )

kor_price <- read.csv(
  file_path,
  fileEncoding = 'utf-8',
  stringsAsFactors = FALSE
  ) %>%
  column_to_rownames('X') %>%
  as.xts()

file_path <- paste0(
  getwd(),
  '/03_R을_이용한_퀀트_투자_포트폴리오_만들기/',
  'Chapter_05/files/KOR_ticker.csv'
  )

kor_ticker <- read.csv(
  file_path,
  fileEncoding = 'utf-8',
  stringsAsFactors = FALSE
  ) %>%
  mutate(종목코드 = str_pad(종목코드, 6, 
                            'left', 0))

ret_daily <- Return.calculate(kor_price) %>%
  xts::last(252)

ret_cum <- ret_daily %>%
  apply(., 2, function(x) {prod(1 + x) - 1})

vol <- ret_daily %>%
  apply(., 2, sd) %>%
  multiply_by(sqrt(252))

result_df <- data.frame(ret_cum, vol) %>%
  rownames_to_column('ticker') %>% 
  mutate(ticker = str_remove_all(ticker, 'X'),
         ret_sharpe = ret_cum / vol) %>%
  arrange(desc(ret_sharpe)) %>%
  left_join(kor_ticker,
            by = c('ticker' = '종목코드')) %>%
  rename(name = 종목명, indst = 산업분류) %>%
  select(ticker, name, indst,
         ret_cum, vol, ret_sharpe)

colnames(kor_price) <- colnames(kor_price) %>%
  str_remove_all('X')

plot_df <-
  kor_price[, result_df$ticker[1:30] %>% c()] %>%
  xts::last(252) %>%
  fortify.zoo() %>%
  gather(ticker, price, -Index)

ggplot(plot_df, aes(x = Index, y = price)) +
  geom_line() +
  facet_wrap(. ~ ticker, scales = 'free') +
  xlab(NULL) +
  ylab(NULL) +
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank())