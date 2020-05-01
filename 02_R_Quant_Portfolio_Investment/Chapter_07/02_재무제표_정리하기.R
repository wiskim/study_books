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

data_fs <- list()

for(i in 1:nrow(kor_ticker)) {
  
  name <-  kor_ticker[i, '종목코드']
  data_fs[[i]] <-
    read.csv(file = paste0(file_path,
                           'Chapter_06/files/',
                           'KOR_fs/',
                           name, '_fs.csv'),
             fileEncoding = 'utf-8',
             stringsAsFactors = FALSE)
}

fs_item <- data_fs[[1]]$CoA

fs_list <- list()

for (i in 1:length(fs_item)) {
  
  select_fs <- lapply(data_fs, function(x) {
    
    if (fs_item[i] %in% x[['CoA']]) {
      
      x[x[['CoA']] == fs_item[i], ][1, ]
      
    } else {
      
      data.frame(NA)
      
    }
    
  })
  
  select_fs <- bind_rows(select_fs) %>% 
    mutate(TICKER = kor_ticker$종목코드) %>% 
    select(-one_of(c('NA.', 'CoA'))) %>%
    select(TICKER, sort(everything()))
  
  fs_list[[fs_item[i]]] <- select_fs
  
}

saveRDS(fs_list,
        paste0(file_path,
               'Chapter_07/files/',
               'KOR_fs.Rds'))