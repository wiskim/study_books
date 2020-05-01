library(tidyverse)
library(Lahman)

team <- as_tibble(Teams) %>% 
  filter(yearID > 1990) %>% 
  mutate(attendAvg = attendance / G,
         category = paste(lgID, divID, sep = " ")) %>% 
  select(category, attendAvg)

# 지부별 "연평균 관중수"의  평균와 표준편차를 적용한 정규분포 확률밀도함수 데이터를 생성

categorySeq <- team %>% 
  distinct(category) %>% 
  arrange(category) %>% 
  pull()

normal <- tibble()

for(i in 1:length(categorySeq)){
  attendAvgSubset <- team %>% 
    filter(category == categorySeq[i]) %>% 
    arrange(attendAvg) %>% 
    select(attendAvg) %>% 
    pull()
  density <- dnorm(x = attendAvgSubset, 
                   mean = mean(attendAvgSubset), 
                   sd = sd(attendAvgSubset))
  df <- tibble(category = categorySeq[i],
               attendAvg = attendAvgSubset,
               density = density)
  normal <- bind_rows(normal, df)
}

# 패널별로 각각의 정규분포를 그릴수 있음

breaks <-  seq(0, 30000, 1000)

ggplot() + 
  geom_histogram(data = team, mapping = aes(x = attendAvg, y = ..density..), breaks = breaks) +
  geom_line(data = normal, mapping = aes(x = attendAvg, y = density), color = 'blue', size = 1) + 
  facet_wrap(~ category, nrow = 2)
