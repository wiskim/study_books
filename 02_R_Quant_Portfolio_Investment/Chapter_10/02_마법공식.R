library(tidyverse)

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
  'Chapter_07/files/KOR_fs.Rds'
  )

kor_fs <- readRDS(file_path)
kor_fs <- lapply(kor_fs, function(x){column_to_rownames(x, 'TICKER')})

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

num_col <- ncol(kor_fs[[1]])

# Earning Yield (EBIT / EV) 계산

magic_ebit <- (kor_fs$지배주주순이익 + 
                 kor_fs$법인세비용 + 
                 kor_fs$이자비용)[num_col]

magic_cap <- kor_value$PER * kor_fs$지배주주순이익[num_col]

magic_debt <- kor_fs$부채[num_col]

magic_excess_cash_1 <- kor_fs$유동부채 - kor_fs$유동자산 +
  kor_fs$현금및현금성자산
magic_excess_cash_1[magic_excess_cash_1 < 0] <- 0
magic_excess_cash_2 <- (kor_fs$현금및현금성자산 -
                          magic_excess_cash_1)[num_col]

magic_ev <- magic_cap + magic_debt - magic_excess_cash_2

magic_ey <- magic_ebit / magic_ev

# Return on Capital (EBIT / IC) 계산

magic_ic <- ((kor_fs$유동자산 - kor_fs$유동부채) +
               (kor_fs$비유동자산 - kor_fs$감가상각비))[num_col]

magic_roc <- magic_ebit / magic_ic

# Earning Yield 순위 + Return on Capital 순위가 높은 종목 필터링

invest_magic <- rank(rank(-magic_ey) + rank(-magic_roc)) <= 30

kor_ticker[invest_magic, ] %>%
  select(종목코드, 종목명) %>%
  mutate(이익수익률 = round(magic_ey[invest_magic, ], 4),
              투하자본수익률 = round(magic_roc[invest_magic, ], 4))
