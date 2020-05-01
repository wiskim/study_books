library(tidyverse)
library(httr)
library(rvest)
library(lubridate)
library(timetk)
library(xts)

file_path <- paste0(
  getwd(),
  "/03_R을_이용한_퀀트_투자_포트폴리오_만들기/")

kor_ticker <- read_csv(
  paste0(file_path, "Chapter_05/files/KOR_ticker.csv")
)

url <- "https://fchart.stock.naver.com/sise.nhn"

ohlc <- xts(NA, order.by = Sys.Date())

for (i in 1:nrow(kor_ticker)) {
  
  code <- kor_ticker[i, "종목코드"] %>% pull()
  name <- kor_ticker[i, "종목명"] %>% pull()

  print(name)
  
  tryCatch(
    {
      resp <- GET(
        url = url,
        query = list(
          symbol = code,
          timeframe = "day",
          count = 500,
          requestType = 0
        )
      )
      
      ohlc <- read_html(resp) %>%
        html_nodes(css = 'item') %>%
        html_attr('data') %>%
        read_delim(
          delim = "|",
          col_names = 
            c("DATE", "OPEN", "HIGH", "LOW", "CLOSE", "VOL")
        ) # 구분자(|)를 기준으로 데이터 분리
        
      ohlc$DATE <- ymd(ohlc$DATE) # 일자 정보 파싱
    },
    error = function(e) {
      warning(paste0("Error in Ticker: ", name))
    }
  )
  
  write.csv(
    ohlc,
    file = paste0(
      file_path,
      "Chapter_06/files/KOR_price/",
      code,
      "_price.csv"
    ),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  
  Sys.sleep(2)
  
}
