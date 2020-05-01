library(tidyverse)
library(Lahman)

file_path = paste0(getwd(), '/01_메이저리그_야구_통계학/ML Statistics/Chapter05/files/')
google_trend <- read_csv(file = paste0(file_path, 'google_trend.csv'),
                         skip = 2)
colnames(google_trend) <- c('YM', 'NYY', 'PHI', 'LAD', 'SF', 'BOS')

google_trend$YEAR <- str_split_fixed(google_trend$YM, '-', 2)[, 1]
google_trend$MONTH <- str_split_fixed(google_trend$YM, '-', 2)[, 2]
google_trend <- google_trend %>% 
  filter(MONTH != 1 & MONTH != 2 & MONTH != 3 &
         MONTH != 10 & MONTH != 11 & MONTH != 12) %>% 
  gather(key = "teamID", value = "popularity", NYY, PHI, LAD, SF, BOS)

ggplot(data = google_trend, mapping = aes(x = teamID, y = popularity)) +
  geom_boxplot()

aov <- aov(popularity ~ teamID, google_trend)
summary(aov)

TukeyHSD(aov, "teamID")
