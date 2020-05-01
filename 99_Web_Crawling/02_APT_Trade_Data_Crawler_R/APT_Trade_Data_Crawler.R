library(tidyverse)
library(httr)
library(rvest)
library(jsonlite)

open_data_url <- "http://openapi.molit.go.kr/OpenAPI_ToolInstallPackage/service/rest/RTMSOBJSvc/getRTMSDataSvcAptTradeDev"
open_data_key <- "5rME4JUT4tms4%2FKdTGkj6Cv25hq6hEGWJskV0nnvkBkjsJAkdEvu5%2FWRqWO4blqBrRFQHvps4cPJiCnbKkIjqQ%3D%3D"
result_df <- data.frame()

for(y in seq(2000, 2019)){
  for(m in seq(1, 12)){
    resp <- GET(url = paste0(open_data_url,
                             "?serviceKey=",
                             open_data_key,
                             "&LAWD_CD=11560", #영등포구
                             "&DEAL_YMD=",
                             paste0(y, sprintf("%02d", m)),
                             "&pageNo=1"))
    json <- resp %>% content(as = "text", encoding = "utf-8") %>% fromJSON()
    total_count <- json$response$body$totalCount
    if(total_count != 0){
      total_page <- ceiling(total_count / 10)
      for(p in seq(1, total_page)){
        resp <- GET(url = paste0(open_data_url,
                                 "?serviceKey=",
                                 open_data_key,
                                 "&LAWD_CD=11560",
                                 "&DEAL_YMD=",
                                 paste0(y, sprintf("%02d", m)),
                                 "&pageNo=",
                                 p))
        json <- resp %>% content(as = "text", encoding = "utf-8") %>% fromJSON()
        df <- json$response$body$items$item
        result_df <- rbind(result_df, df)
      }
    }else{
      next
    }
  }
}

result_df <- result_df %>% 
  mutate(거래금액 = parse_number(거래금액),
         법정동 = str_remove_all(법정동, "\\s")) %>% 
  filter(법정동 == "여의도동")

