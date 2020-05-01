library(tidyverse)
library(xts)
library(PerformanceAnalytics)

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

ret <- Return.calculate(kor_price) %>% xts::last(252)
ret_12m <- sapply(ret, function(x) {
  prod(1 + x) - 1
  })

invest_mom <- rank(-ret_12m) <= 30

file_path <- paste0(
  getwd(),
  '/03_R을_이용한_퀀트_투자_포트폴리오_만들기/',
  'Chapter_05/files/KOR_sector.csv'
  )

kor_sector <- read.csv(
  file_path,
  fileEncoding = 'utf-8',
  stringsAsFactors = FALSE
  ) %>%
  mutate(CMP_CD = str_pad(CMP_CD, 6,
                          'left', 0))

data_market <- left_join(
  kor_ticker, kor_sector,
  by = c('종목코드' = 'CMP_CD')
  )

data_market[invest_mom, ] %>%
  select(SEC_NM_KOR) %>%
  group_by(SEC_NM_KOR) %>%
  summarise(n = n()) %>%
  ggplot(aes(x = reorder(SEC_NM_KOR, n),
             y = n, label = n)) +
  geom_col() +
  geom_text(size = 4, hjust = -0.3) +
  xlab(NULL) +
  ylab(NULL) +
  coord_flip() +
  scale_y_continuous(expand = c(0, 0, 0.1, 0)) +
  theme_classic()

sector_neutral <- data_market %>%
  select(종목코드, SEC_NM_KOR) %>%
  mutate(ret = ret_12m) %>%
  group_by(SEC_NM_KOR) %>%
  mutate(scale_per_sector = scale(ret),
         scale_per_sector = ifelse(is.na(SEC_NM_KOR),
                                   NA, scale_per_sector))

invest_mom_neutral <- rank(sector_neutral$scale_per_sector) <= 30

data_market[invest_mom_neutral, ] %>%
  select(SEC_NM_KOR) %>% 
  group_by(SEC_NM_KOR) %>% 
  summarise(n = n()) %>%
  ggplot(aes(x = reorder(SEC_NM_KOR, n),
             y = n, label = n)) +
  geom_col() +
  geom_text(size = 4, hjust = -0.3) +
  xlab(NULL) +
  ylab(NULL) +
  coord_flip() +
  scale_y_continuous(expand = c(0, 0, 0.1, 0)) +
  theme_classic()
