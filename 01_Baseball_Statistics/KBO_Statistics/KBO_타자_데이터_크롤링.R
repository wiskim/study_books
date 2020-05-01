library(tidyverse)
library(httr)
library(rvest)

url <- "http://www.kbreport.com/leader/list/ajax"

Batting <- tibble()

Sys.setlocale(category = "LC_ALL", locale = "C")

for(i in 2012:2019){
  for(j in 1:10){
    resp <- POST(url = url,
                 body = list(
                   year_from = i,
                   year_to = i,
                   rows = 100,
                   gameType = "R",
                   page = j
                 ),
                 encode = "form")
    html <- read_html(resp, encoding = "utf-8")
    tbl_df <- html %>% 
      html_node(css = "table") %>% 
      html_table() %>% 
      as_tibble()
    for(k in 4:ncol(tbl_df)){
      tbl_df[[k]] <- na_if(tbl_df[[k]], "-")
      tbl_df[[k]] <- as.numeric(tbl_df[[k]])
    }
    if(nrow(tbl_df) != 0){
      tbl_df["연도"] = i
      Batting <- bind_rows(Batting, tbl_df)
    }else{
      next
    }
  }
}

Sys.setlocale(category = "LC_ALL", locale = "KOREAN")

Batting <- Batting[, -1]
Batting <- Batting %>% 
  mutate(팀명 = replace(팀명, 팀명 == "kt", "KT")) %>%
  mutate(팀명 = as.factor(팀명))
Batting <- Batting[c(ncol(Batting), 1:ncol(Batting)-1)]

write.csv(Batting, file = "./01_메이저리그_야구_통계학/KBO Statistics/files/KBO_Batting_Stats.csv", fileEncoding = "utf-8", row.names = FALSE)
