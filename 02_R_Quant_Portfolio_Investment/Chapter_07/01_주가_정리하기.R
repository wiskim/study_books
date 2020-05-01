library(tidyverse)
library(xts)
library(lubridate)
library(timetk)

file_path <- paste0(
  getwd(),
  "/03_R을_이용한_퀀트_투자_포트폴리오_만들기/"
)

kor_ticker <- read.csv(
  file = paste0(file_path,
                "Chapter_05/files/KOR_ticker.csv"),
  fileEncoding = "UTF-8",
  stringsAsFactors = FALSE
)

kor_ticker$"종목코드" <- str_pad(
  string = kor_ticker$"종목코드",
  width = 6,
  side = c("left"),
  pad = "0")

price_list = list()

for (i in 1:nrow(kor_ticker)) {
  
  code <- kor_ticker[i, "종목코드"]
  
  price_list[[code]] <- 
    read.csv(
      file = paste0(
        file_path, 
        "Chapter_06/files/KOR_price/",
        code,
        "_price.csv"
      ),
      fileEncoding = "UTF-8",
      stringsAsFactors = FALSE
    ) %>%
    select(DATE, CLOSE) %>%
    mutate(DATE = ymd(DATE)) %>% 
    tk_xts(date_var = DATE)
  
}

price_list <- do.call(cbind, price_list) %>% na.locf()
colnames(price_list) <- kor_ticker$종목코드

write.csv(as.data.frame(price_list),
          file = paste0(file_path,
                        'Chapter_07/files/',
                        'KOR_price.csv'),
          fileEncoding = 'utf-8',
          row.names = TRUE)
