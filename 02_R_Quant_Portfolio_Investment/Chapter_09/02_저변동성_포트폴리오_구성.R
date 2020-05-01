library(stringr)
library(xts)
library(PerformanceAnalytics)
library(magrittr)
library(dplyr)
library(ggplot2)

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

ret <- Return.calculate(kor_price)

std_12m_daily <- xts::last(ret, 252) %>%
  apply(., 2, sd) %>%
  multiply_by(sqrt(252))

std_12m_daily[std_12m_daily == 0] <- NA

ggplot(data = std_12m_daily %>% as.data.frame(), 
       mapping = aes(x = `.`)) +
  geom_histogram(binwidth = 0.01) +
  geom_vline(xintercept = median(std_12m_daily,
                                 na.rm = TRUE),
             color = 'blue',
             size = 0.05) +
  labs(x = '일간 수익률 표준편차',
       y = '기업 수')

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

invest_lowvol <-
  std_12m_daily[rank(std_12m_daily) <= 30] %>% 
  as.data.frame() %>%
  rownames_to_column('종목코드') %>%
  rename(변동성 = '.') %>%
  mutate(종목코드 = str_remove_all(종목코드, 'X'),
         변동성 = round(변동성, 4)) %>% 
  left_join(kor_ticker, by = '종목코드') %>%
  select(종목코드, 종목명, 변동성) %>%
  arrange(변동성)
  