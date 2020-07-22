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
    '?ceil_yn=0&dt=20200721&sec_cd=', i)
  data <- fromJSON(url)
  data <- data$list
  sec_tb[[i]] <- data
  Sys.sleep(1)
}

sec_tb <- do.call(bind_rows, sec_tb) %>% as_tibble()
sec_tb <- sec_tb %>% arrange(desc(MKT_VAL))

files_path <- paste0(
  '/02_R_Quant_Portfolio_Investment',
  '/Chapter_05',
  '/files/')

write.csv(
  sec_tb,
  file = paste0(getwd(), files_path, 'KOR_sector.csv'),
  row.names = FALSE,
  fileEncoding = 'UTF-8')
