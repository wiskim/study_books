library(tidyverse)
library(corrplot)

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
                          'left', 0)) 

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

rank_value <- kor_value %>%
  mutate_at(vars(PER, PBR, PCR, PSR),
            list(~ min_rank(.))) %>%
  mutate(rank_sum = PER + PBR + PCR + PSR) %>%
  rename_at(vars(PER, PBR, PCR, PSR),
            function(x){paste0(x, '_rank')})

result_df <-
  left_join(
    kor_value,
    kor_ticker %>% select(종목코드, 종목명),
    by = c('TICKER' = '종목코드')
    ) %>% 
  left_join(
    rank_value,
    by = 'TICKER'
    ) %>%
  select(종목명, TICKER, PER, PBR, PCR, PSR, rank_sum) %>% 
  mutate_at(vars(PER, PBR, PCR, PSR),
            function(x) {round(x, 4)}) %>%
  rename(NAME = 종목명)

cor(rank_value %>% 
      select(ends_with('_rank')) %>%
      rename_all(function(x) {str_remove_all(x, '_rank')}),
    use = 'complete.obs') %>%
  round(., 2) %>%
  corrplot(method = 'color', type = 'upper',
           addCoef.col = 'black', number.cex = 1,
           tl.cex = 0.6, tl.srt = 45, tl.col = 'black',
           col = colorRampPalette(
             c('blue', 'white', 'red'))(200),
           mar = c(0, 0, 0.5, 0))

invest_pbr <- result_df %>%
  arrange(PBR) %>%
  slice(1:30) %>%
  .[['NAME']] %>% 
  c()

invest_value <- result_df %>%
  arrange(rank_sum) %>%
  slice(1:30) %>%
  .[['NAME']] %>% 
  c()

intersect(invest_pbr, invest_value)
