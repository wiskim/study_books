library(tidyverse)
library(rvest)
library(httr)

file_path <-
  paste0(getwd(),
         '/03_R을_이용한_퀀트_투자_포트폴리오_만들기/')

kor_ticker <-
  read.csv(file = paste0(file_path, 
                         'Chapter_05/files/',
                         'KOR_ticker.csv'),
           fileEncoding = 'UTF-8',
           stringsAsFactors = FALSE)

kor_ticker$종목코드 <- 
  str_pad(string = kor_ticker$종목코드,
          width = 6,
          side = c('left'),
          pad = '0')

for (i in 1:nrow(kor_ticker)) {
  
  name <- kor_ticker$종목명[i]
  code <- kor_ticker$종목코드[i]
  print(paste0(name, '_', code))
  
  data_fs <- c()
  data_value <- c()
  
  tryCatch(
    {
      
      Sys.setlocale('LC_ALL', 'English')
      
      url <- paste0('http://comp.fnguide.com/SVO2/ASP/',
                    'SVD_Finance.asp?pGB=1&gicode=A',
                    code)
      
      data <- GET(url) %>% 
        read_html() %>% 
        html_table()
      
      Sys.setlocale('LC_ALL', 'Korean')
      
      data_IS <- data[[1]] %>% select(-contains('전년'))
      data_BS <- data[[3]]
      data_CF <- data[[5]]
      
      data_fs <- rbind(data_IS, data_BS, data_CF)
      data_fs <- data_fs %>%
        rename(CoA = 1) %>% 
        filter(!duplicated(CoA)) %>%
        select(CoA, ends_with('12')) %>%
        mutate(CoA = str_replace_all(
          CoA,'계산에 참여한 계정 펼치기', '')) %>%
        mutate_at(vars(ends_with('12')), 
                  function(x) {
                    as.numeric(str_replace_all(x, '\\,', ''))
                  })

      value_type <- c('지배주주순이익',
                      '자본',
                      '영업활동으로인한현금흐름',
                      '매출액')
      
      value_index <- data_fs[match(value_type, data_fs$CoA),
                             ncol(data_fs)]
      
      url <- paste0('http://comp.fnguide.com/SVO2/ASP/',
                    'SVD_main.asp?pGB=1&gicode=A',
                    code)
      
      data <- GET(url)
      
      price <- read_html(data) %>% 
        html_node(xpath = '//*[@id="svdMainChartTxt11"]') %>% 
        html_text() %>% 
        parse_number()
      
      share <- read_html(data) %>%
        html_node(xpath = paste0('//*[@id="svdMainGrid1"]',
                                 '/table/tbody/tr[7]/td[1]')) %>% 
        html_text() %>%
        str_split_fixed('/', 2) %>% 
        .[1, 1] %>% 
        parse_number()
    
      data_value <- price / (value_index * 100000000 / share)
      data_value[data_value < 0] <-  NA
      data_value <- as.data.frame(as.list(data_value))
      colnames(data_value) <- c('PER', 'PBR', 'PCR', 'PSR')
      
    },
    error = function(e) {
      data_fs <<- NA
      data_value <<- NA
      warning(paste0("Error in Ticker: ", name))
    }
  )
  
  write.csv(x = data_fs,
            file = paste0(file_path,
                          'Chapter_06/files/KOR_fs/',
                          code, '_fs.csv'),
            fileEncoding = 'UTF-8',
            row.names = FALSE)
  
  write.csv(x = data_value,
            file = paste0(file_path,
                          'Chapter_06/files/KOR_value/',
                          code, '_value.csv'),
            fileEncoding = 'UTF-8',
            row.names = FALSE)
  
  Sys.sleep(0.5)
  
}
