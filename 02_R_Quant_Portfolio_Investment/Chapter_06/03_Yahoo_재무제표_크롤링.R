library(httr)
library(rvest)
library(jsonlite)
library(tidyr)
library(dplyr)
library(stringr)

options(scipen = 100)

ticker <- '005930.KS'

coa_list = c(
  'annualTotalRevenue',
  'annualGrossProfit',
  'annualOperatingIncome',
  'annualNetIncome',
  'annualEbitda')

url <- paste0('https://query1.finance.yahoo.com/',
              'ws/fundamentals-timeseries/v1/',
              'finance/timeseries/005930.KS?')

resp <- GET(url = url,
            query = list(
              lang = 'en-US',
              region = 'US',
              symbol = ticker,
              padTimeSeries = 'true',
              type = paste0(coa_list, collapse = '%2C'),
              merge = 'false',
              period1 = '493590046',
              period2 = '1569568965',
              corsDomain = 'finance.yahoo.com'))

raw_data <- resp %>%
  content(as = 'text', encoding = 'utf-8') %>%
  fromJSON()

result_data <- list()

for (i in 1:length(coa_list)) {
  
  temp_data <- raw_data$timeseries$result %>%
    .[[coa_list[i]]]
  temp_data <- Filter(Negate(is.null), temp_data)
  temp_data <- temp_data[[1]] %>% flatten()
  temp_data$CoA <- coa_list[i]
  result_data[[i]] <- temp_data
  
}

result_data <- do.call(rbind, result_data)
result_data <- result_data %>% 
  select(CoA, asOfDate, reportedValue.raw) %>% 
  spread(key = 'asOfDate', value = 'reportedValue.raw') %>%
  arrange(match(CoA, coa_list)) %>%
  mutate(CoA = str_replace_all(CoA, '^annual', ''))
