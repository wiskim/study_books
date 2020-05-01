library(httr)
library(rvest)
library(dplyr)
library(readr)
library(stringr)
library(jsonlite)



apiKey <- "b557dbf9e8a26cf32e13a5612bb1405b0fc83aca"
startDt <- "20180101" # 검색시작시점
rptNm1 <- "분기보고서 (2018.03)" # 공시보고서명1
rptNm2 <- "[기재정정]분기보고서 (2018.03)" # 공시보고서명2
crpData <- read.csv(file = "./01_DART_Crawler/files/crpData.csv",
                    colClasses = c("character", "character"),
                    encoding = "utf-8", 
                    stringsAsFactors = FALSE)
crpCdList <- crpData$crpCd # 대상기업 종목코드(상장사 : SIMS 종목코드, 비상장사 : DART 고유번호)



# 공시 접수번호 찾기 함수

findRcpNo = function(crpCd){
  url <- paste0("http://dart.fss.or.kr/api/search.json?auth=",
                apiKey,
                "&crp_cd=",
                crpCd,
                "&start_dt=",
                startDt,
                "&fin_rpt=Y&dsp_tp=A")
  resp <- GET(url)
  df <- resp %>% 
    content(as = "text") %>% 
    fromJSON() %>% 
    .$list
  if(rptNm1 %in% df$rpt_nm){
    rcpNo <- df %>% 
      filter(rpt_nm == rptNm1) %>% 
      select(rcp_no) %>% 
      .[[1]]
    return(rcpNo)
  }else if(rptNm2 %in% df$rpt_nm){
    rcpNo <- df %>% 
      filter(rpt_nm == rptNm2) %>% 
      select(rcp_no) %>% 
      .[[1]]
    return(rcpNo)
  }else{
    return(NA)
  }
}



# 공시 문서번호 찾기 함수

findDcmNo = function(rcpNo){
  url <- paste0("http://dart.fss.or.kr/dsaf001/main.do?rcpNo=", rcpNo)
  resp <- GET(url)
  text <- content(resp, as="text")
  dcmNo <- str_extract(text, "viewDoc(.*)") %>% 
    str_split(",") %>% 
    unlist() %>% 
    .[[2]] %>% 
    str_extract("\\d+")
  return(dcmNo)
}



# 별도재무상태표 찾기 함수

findBsInd = function(rcpNo, dcmNo){
  options(warn = -1)
  url <- paste0("http://dart.fss.or.kr/report/viewer.do?rcpNo=",
                rcpNo,
                "&dcmNo=",
                dcmNo,
                "&eleId=15&offset=297450&length=378975&dtd=dart3.xsd")
  resp <- GET(url)
  html <- read_html(url, encoding = "utf-8")
  for(j in 1:5){
    Sys.setlocale(category = "LC_ALL", locale = "C")
    BS <- html %>%
      html_nodes(css = "table") %>% 
      .[[j]] %>% 
      html_table(fill = TRUE)
    Sys.setlocale(category = "LC_ALL", locale = "KOREAN")
    BS[,1] <- str_remove_all(BS[,1], "\\s")
    if("부채총계" %in% BS[,1]){
      break
    }
  }
  Sys.setlocale(category = "LC_ALL", locale = "C")
  for(i in 2:ncol(BS)){
    BS[,i] <- str_remove_all(BS[,i], ",") %>% 
      as.numeric()
  }
  Sys.setlocale(category = "LC_ALL", locale = "KOREAN")
  colnames(BS) <- str_remove_all(colnames(BS), "\\s")
  if(colnames(BS)[2] == "주석"){BS <- BS[,-2]}
  colnames(BS)[1] <- "계정과목"
  return(BS)
}



# 연결재무상태표 찾기 함수

findBsCon = function(rcpNo, dcmNo){
  options(warn = -1)
  url <- paste0("http://dart.fss.or.kr/report/viewer.do?rcpNo=",
                rcpNo,
                "&dcmNo=",
                dcmNo,
                "&eleId=13&offset=297450&length=378975&dtd=dart3.xsd")
  resp <- GET(url)
  html <- read_html(url, encoding = "utf-8")
  for(j in 1:5){
    Sys.setlocale(category = "LC_ALL", locale = "C")
    BS <- html %>%
      html_nodes(css = "table") %>% 
      .[[j]] %>% 
      html_table(fill = TRUE)
    Sys.setlocale(category = "LC_ALL", locale = "KOREAN")
    BS[,1] <- str_remove_all(BS[,1], "\\s")
    if("부채총계" %in% BS[,1]){
      break
    }
  }
  Sys.setlocale(category = "LC_ALL", locale = "C")
  for(i in 2:ncol(BS)){
    BS[,i] <- str_remove_all(BS[,i], ",") %>% 
      as.numeric()
  }
  Sys.setlocale(category = "LC_ALL", locale = "KOREAN")
  colnames(BS) <- str_remove_all(colnames(BS), "\\s")
  if(colnames(BS)[2] == "주석"){BS <- BS[,-2]}
  colnames(BS)[1] <- "계정과목"
  return(BS)
}



# 대상기업들의 공시 접수번호를 찾아 리스트로 만듬

rcpNoList <- c()

for(i in 1:length(crpCdList)){
  if(nchar(crpCdList[i]) == 5){
    rcpNo <- findRcpNo(paste0(crpCdList[i], "0")) # SIMS 종목코드는 뒤에 0을 붙여야 DART에서 조회가능
  }else{
    rcpNo <- findRcpNo(crpCdList[i])
  }
  rcpNoList[i] <- rcpNo
  Sys.sleep(1)
}



# 대상기업들의 공시 문서번호를 찾아 리스트로 만듬

dcmNoList <- c()

for(i in 1:length(rcpNoList)){
  if(is.na(rcpNoList[i])){
    dcmNoList[i] = NA
  }else{
    dcmNo <- findDcmNo(rcpNoList[i])
    dcmNoList[i] = dcmNo
    Sys.sleep(1)
  }
}



# 대상기업들의 공시 접수번호/문서번호를 통해 BS를 다운받아 부채비율을 계산 후 리스트로 만듬

debtRatioListInd <- c()

for(i in 1:length(rcpNoList)){
  if(is.na(rcpNoList[i]) | is.na(dcmNoList[i])){
    debtRatioListInd[i] = NA
  }else{
    tryCatch(
      BS <- findBsInd(rcpNoList[i], dcmNoList[i]),
      error = function(e){BS <<- data.frame()}
    )
    tryCatch(
      debtRatio <- round((filter(BS, 계정과목 == "부채총계")[1,2] / filter(BS, 계정과목 == "자본총계")[1,2]), 2),
      error = function(e){debtRatio <<- NA}
    )
    tryCatch(
      debtRatioListInd[i] <- debtRatio,
      error = function(e){debtRatio <<- NA}
    )
    Sys.sleep(1)
  }
}

debtRatioListCon <- c()

for(i in 1:length(rcpNoList)){
  if(is.na(rcpNoList[i]) | is.na(dcmNoList[i])){
    debtRatioListCon[i] = NA
  }else{
    tryCatch(
      BS <- findBsCon(rcpNoList[i], dcmNoList[i]),
      error = function(e){BS  <<-  data.frame()}
    )
    tryCatch(
      debtRatio <- round((filter(BS, 계정과목 == "부채총계")[1,2] / filter(BS, 계정과목 == "자본총계")[1,2]), 2),
      error = function(e){debtRatio  <<-  NA}
    )
    tryCatch(
      debtRatioListCon[i] <- debtRatio,
      error = function(e){debtRatio  <<-  NA}
    )
    Sys.sleep(1)
  }
}



# 최종결과물을 저장함

resultData <- cbind(crpData, debtRatioListInd, debtRatioListCon)
write.csv(x = resultData, file = "./01_DART_Crawler/files/resultData.csv", row.names = FALSE)
