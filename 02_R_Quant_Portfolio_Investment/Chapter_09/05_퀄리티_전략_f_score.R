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

roa <- kor_fs$지배주주순이익 / kor_fs$자산 
cfo <- kor_fs$영업활동으로인한현금흐름 / kor_fs$자산
accurual <- cfo - roa
lev <- kor_fs$장기차입금 / kor_fs$자산
liq <- kor_fs$유동자산 / kor_fs$유동부채
offer <- kor_fs$유상증자
margin <- kor_fs$매출총이익 / kor_fs$매출액
turn <- kor_fs$매출액 / kor_fs$자산

num_col <- ncol(kor_fs[[1]])

f_1 <- as.integer(roa[, num_col] > 0)
f_2 <- as.integer(cfo[, num_col] > 0)
f_3 <- as.integer(roa[, num_col] - roa[, (num_col - 1)] > 0)
f_4 <- as.integer(accurual[, num_col] > 0)
f_5 <- as.integer(lev[, num_col] - lev[, (num_col - 1)] <= 0)
f_6 <- as.integer(liq[, num_col] - liq[, (num_col - 1)] > 0)
f_7 <- as.integer(is.na(offer[, num_col]) |
                    offer[, num_col] <= 0)
f_8 <- as.integer(margin[, num_col] -
                    margin[, (num_col - 1)] > 0)
f_9 <- as.integer(turn[, num_col] - turn[, (num_col - 1)] > 0)

f_table <- cbind(f_1, f_2, f_3, f_4, f_5, f_6, f_7, f_8, f_9) %>% 
  as.data.frame()

f_table <- f_table %>%
  mutate(f_score = rowSums(f_table),
         ticker = row.names(kor_fs[[1]])) %>%
  left_join(kor_ticker %>% select(종목코드, 종목명),
            by = c('ticker' = '종목코드')) %>%
  select(ticker, 종목명, f_score) %>%
  rename(name = 종목명) %>%
  arrange(desc(f_score))

f_dist <- f_table$f_score %>%
  as.factor() %>%
  table() %>%
  prop.table() %>%
  as.data.frame() %>%
  mutate(Freq = round(Freq, 3))

f_table %>% filter(f_score == 9) %>% print()

ggplot(f_dist,
       aes(x = `.`, y = `Freq`,
           label = paste0(`Freq` * 100, '%'))) +
  geom_bar(stat = 'identity') +
  geom_text(vjust = -0.5, size = 3) +
  labs(x = 'F-Score', y = '') +
  theme_classic()
