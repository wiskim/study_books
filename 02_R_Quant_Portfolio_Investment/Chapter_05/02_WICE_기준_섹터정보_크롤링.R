library(tidyverse)
library(httr)
library(jsonlite)

sec_code_list <-
  c('G25', 'G35', 'G50', 'G40', 'G10',
    'G20', 'G55', 'G30', 'G15', 'G45')

sec_tb <- list()

for (i in sec_code_list) {
  url <- paste0(
    'http://www.wiseindex.com/Index/GetIndexComponets',
    '?ceil_yn=0&dt=20190911&sec_cd=', i)
  resp <- GET(url)
  sec_tb[[i]] <- resp %>% content(as = 'text') %>% fromJSON() %>% .$list
  Sys.sleep(1)
}

sec_tb <- do.call(bind_rows, sec_tb) %>% as_tibble()
sec_tb <- sec_tb %>% arrange(desc(MKT_VAL))

files_path <- paste0(
  '/03_R을_이용한_퀀트_투자_포트폴리오_만들기',
  '/Chapter_05',
  '/files/')
write.csv(
  sec_tb,
  file = paste0(getwd(), files_path, 'KOR_sector.csv'),
  row.names = FALSE,
  fileEncoding = 'UTF-8')
