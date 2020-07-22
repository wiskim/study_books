library(httr)
library(rvest)
library(tidyverse)

# KRX [20004] 산업분류 크롤링

url <- "https://finance.naver.com/sise/sise_deposit.nhn"
today <- str_replace_all(Sys.Date(), "-", "")
biz_date <-
  GET(url) %>%
  read_html(encoding = "euc-kr") %>%
  html_node(
    xpath =
      paste0(
        "/html/body/div[3]/div[1]/div[2]/div[1]",
        "/div[2]/div[1]/div/ul[2]/li/span"
      )
  ) %>%
  html_text() %>%
  str_extract("[0-9.]+") %>%
  str_replace_all("\\.", "")

gen_otp_url <-
  "http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx"
gen_otp_query <-
  list(
    name = "fileDown",
    filetype = "csv",
    url = "MKD/03/0303/03030103/mkd03030103",
    tp_cd = "ALL",
    date = biz_date,
    lang = "ko",
    pagePath = "/contents/MKD/03/0303/03030103/mkd03030103.jsp"
  )
otp <-
  POST(gen_otp_url, query = gen_otp_query) %>%
  read_html() %>%
  html_text()

down_url <- "http://file.krx.co.kr/download.jspx"
down_sector <-
  POST(
    down_url,
    query = list(code = otp),
    add_headers(referer = gen_otp_url)
  ) %>%
  read_html() %>%
  html_text() %>%
  read_csv()

# KRX [30009] PER/PBR/배당수익(개별종목) 크롤링

gen_otp_url <-
  "http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx"
gen_otp_query <-
  list(
    name = "fileDown",
    filetype = "csv",
    url = "MKD/13/1302/13020401/mkd13020401",
    market_gubun = "ALL",
    gubun = "1",
    schdate = today,
    fromdate = biz_date,
    todate = biz_date,
    pagePath = "/contents/MKD/13/1302/13020401/MKD13020401.jsp"
  )
otp <-
  GET(gen_otp_url, query = gen_otp_query) %>%
  read_html() %>%
  html_text()

down_url <- "http://file.krx.co.kr/download.jspx"
down_ind <-
  POST(
    down_url,
    query = list(code = otp),
    add_headers(referer = gen_otp_url)
  ) %>%
  read_html() %>%
  html_text() %>%
  read_csv()

KOR_ticker <-
  inner_join(down_sector, down_ind, by = "종목코드") %>%
  select(-종목명.y) %>%
  rename(종목명 = 종목명.x) %>%
  arrange(desc(`시가총액(원)`)) %>%
  filter(
    str_detect(종목코드, "0$") & !str_detect(종목명, "스팩")
  )

files_path <- 
  paste0(
    "/02_R_Quant_Portfolio_Investment",
    "/Chapter_05",
    "/files/"
  )
write.csv(
  KOR_ticker,
  file = paste0(getwd(), files_path, "KOR_ticker.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
