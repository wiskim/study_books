library(tidyverse)
library(corrplot)

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

num_col <- ncol(kor_fs[[1]])
quality_roe <- (kor_fs$지배주주순이익 / kor_fs$자본)[num_col]
quality_gpa <- (kor_fs$매출총이익 / kor_fs$자산)[num_col]
quality_cfo <- (kor_fs$영업활동으로인한현금흐름 / kor_fs$자산)[num_col]

quality_profit <-
  cbind(quality_roe, quality_gpa, quality_cfo) %>%
  setNames(., c('ROE', 'GPA', 'CFO'))

rank_quality <- quality_profit %>%
  mutate_all(list(~min_rank(desc(.))))

cor(rank_quality, use = 'complete.obs') %>%
  round(., 2) %>%
  corrplot(method = 'color', type = 'upper',
           addCoef.col = 'black', number.cex = 1,
           tl.cex = 0.6, tl.srt = 45, tl.col = 'black',
           col = 
             colorRampPalette(c('blue', 'white', 'red'))(200),
           mar = c(0, 0, 0.5, 0))

rank_sum <- rank_quality %>%
  rowSums()

invest_quality <- rank(rank_sum) <= 30

kor_ticker[invest_quality, ] %>%
  select(종목코드, 종목명) %>%
  cbind(round(quality_profit[invest_quality, ], 4))
