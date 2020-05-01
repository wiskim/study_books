library(tidyverse)
library(xts)

# 티커 불러오기

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
# 재무제표 불러오기

file_path <- paste0(
  getwd(),
  '/03_R을_이용한_퀀트_투자_포트폴리오_만들기/',
  'Chapter_07/files/KOR_fs.Rds'
  )

kor_fs <- readRDS(file_path)
kor_fs <- lapply(kor_fs, function(x){column_to_rownames(x, 'TICKER')})

# 주가 불러오기

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

# 벨류지표 불러오기

file_path <- paste0(
  getwd(),
  '/03_R을_이용한_퀀트_투자_포트폴리오_만들기/',
  'Chapter_07/files/KOR_value.csv'
  )

kor_value <- read.csv(
  file_path,
  fileEncoding = 'utf-8',
  stringsAsFactors = FALSE
  ) %>%
  mutate(TICKER = str_pad(TICKER, 6,
                          'left', 0)) %>%
  column_to_rownames('TICKER')

# quality factor 순위 정규화 후 합산

num_col <- ncol(kor_fs[[1]])
quality_roe <- (kor_fs$지배주주순이익 / kor_fs$자본)[num_col]
quality_gpa <- (kor_fs$매출총이익 / kor_fs$자산)[num_col]
quality_cfo <- (kor_fs$영업활동으로인한현금흐름 / kor_fs$자산)[num_col]

quality_profit <-
  cbind(quality_roe, quality_gpa, quality_cfo) %>%
  setNames(., c('ROE', 'GPA', 'CFO'))

factor_quality <- quality_profit %>%
  mutate_all(list(~min_rank(desc(.)))) %>% # quality factor는 높을 수록 좋다
  mutate_all(list(~scale(.))) %>%
  rowSums()

# value factor 순위 정규화 후 합산

factor_value <- kor_value %>%
  mutate_all(list(~min_rank(.))) %>% # value factor는 낮을 수록 좋다
  mutate_all(list(~scale(.))) %>%
  rowSums()

# momentum factor 순위 정규화 후 합산

library(PerformanceAnalytics)

ret_3m <- Return.calculate(kor_price) %>% xts::last(60) %>%
  sapply(., function(x) {prod(1 + x) - 1})
ret_6m <- Return.calculate(kor_price) %>% xts::last(120) %>%
  sapply(., function(x) {prod(1 + x) - 1})
ret_12m <- Return.calculate(kor_price) %>% xts::last(252) %>%
  sapply(., function(x) {prod(1 + x) - 1})
ret_bind <- cbind(ret_3m, ret_6m, ret_12m) %>% as.data.frame()

factor_mom <- ret_bind %>%
  mutate_all(list(~min_rank(desc(.)))) %>% # momentum factor는 높을 수록 좋다
  mutate_all(list(~scale(.))) %>%
  rowSums()

# quality, value, momentum factor 합산 점수를 재 정규화한 후 가중평균하여 합산

factor_qvm <-
  cbind(factor_quality, factor_value, factor_mom) %>%
  as.data.frame() %>%
  mutate_all(list(~scale(.))) %>%
  mutate(factor_quality = factor_quality * 0.33,
         factor_value = factor_value * 0.33,
         factor_mom = factor_mom * 0.33) %>%
  rowSums()

# 멀티팩터 합산 점수가 높은 30개 종목 선정

invest_qvm <- rank(factor_qvm) <= 30

kor_ticker[invest_qvm, ] %>%
  select('종목코드', '종목명') %>%
  cbind(round(quality_roe[invest_qvm, ], 2)) %>%
  cbind(round(kor_value$PBR[invest_qvm], 2)) %>%
  cbind(round(ret_12m[invest_qvm], 2)) %>%
  setNames(c('종목코드', '종목명', 'ROE', 'PBR', '12M'))

fig1 <- quality_profit[invest_qvm, ] %>%
  gather() %>%
  ggplot(aes(x = value)) +
  geom_histogram() +
  facet_wrap(. ~ key, scale = 'free', ncol = 1) +
  xlab(NULL)

fig2 <- kor_value[invest_qvm, ] %>%
  gather() %>%
  ggplot(aes(x = value)) +
  geom_histogram() +
  facet_wrap(. ~ key, scale = 'free', ncol = 1) +
  xlab(NULL)

fig3 <- ret_bind[invest_qvm, ] %>%
  gather() %>%
  ggplot(aes(x = value)) +
  geom_histogram() +
  facet_wrap(. ~ key, scale = 'free', ncol = 1) +
  xlab(NULL)

library(gridExtra)

grid.arrange(fig1, fig2, fig3, ncol = 3)
