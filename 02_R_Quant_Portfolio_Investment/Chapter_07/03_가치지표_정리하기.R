library(stringr)
library(magrittr)
library(dplyr)

file_path <- 
  paste0(getwd(),
         "/03_R을_이용한_퀀트_투자_포트폴리오_만들기/")

kor_ticker <-
  read.csv(file = paste0(file_path,
                         'Chapter_05/files/',
                         'KOR_ticker.csv'),
           fileEncoding = 'utf-8',
           stringsAsFactors = FALSE)

kor_ticker$종목코드 <-
  str_pad(string = kor_ticker$종목코드,
          width = 6,
          side = 'left',
          pad = '0')

data_value <- list()

for (i in 1:nrow(kor_ticker)) {
  
  name <- kor_ticker$종목코드[i]
  
  data_value[[i]] <-
    read.csv(paste0(file_path,
                    'Chapter_06/files/',
                    'KOR_value/',
                    name, '_value.csv'))
}

data_value <- bind_rows(data_value)
data_value <- data_value %>%
  mutate(TICKER = kor_ticker$종목코드) %>% 
  mutate_all(function(x) {
    replace(x, is.infinite(x), NA)}) %>% 
  select(TICKER, PER, PBR, PCR, PSR)

write.csv(data_value,
          file = paste0(file_path,
                        'Chapter_07/files/',
                        'KOR_value.csv'),
          fileEncoding = 'utf-8',
          row.names = FALSE)
