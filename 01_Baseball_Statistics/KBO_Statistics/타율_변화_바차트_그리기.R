library(tidyverse)
library(ggthemes)
library(showtext)

batting <- read_csv(file = "./01_메이저리그_야구_통계학/KBO Statistics/files/KBO_Batting_Stats.csv")

batting <- batting %>% 
  mutate(팀명 = as.factor(팀명)) %>% 
  rename(year = 연도,
         player = 선수명,
         team = 팀명,
         G = 경기,
         PA = 타석,
         AB = 타수,
         H = 안타,
         HR = 홈런,
         R = 득점,
         RBI = 타점,
         BB = 볼넷,
         SO = 삼진,
         SB = 도루,
         AVG = 타율,
         OBP = 출루율,
         SLG = 장타율)

batting %>% 
  filter(year == 2017 | year == 2018) %>% 
  group_by(team, year) %>% 
  summarise(AVG = sum(H) / sum(AB)) %>% 
  spread(key = year, value = AVG) %>% 
  mutate(gap = `2018` - `2017`) %>% 
  arrange(desc(gap)) %>% 
  gather(key = year, value = AVG, -team, -gap) -> plotDf

font_add_google("Noto Serif KR", "notoserifkr")
showtext_auto()
windows()

ggplot(plotDf, aes(x = team, y = AVG, fill = as.factor(year))) + 
  geom_bar(stat = "identity", position = "dodge", width = 0.7) + 
  scale_x_discrete(limits = plotDf$team[1:10]) + 
  coord_cartesian(ylim = c(0.25, 0.32)) + 
  labs(title = "KBO 팀타율 변화", 
       subtitle = "2017년 대비 2018년 팀타율 변동",
       x = "", 
       y = "", 
       fill = "",
       caption = "출처 : KB Report") +
  theme_economist(base_family = "notoserifkr", base_size = 11) +
  scale_fill_economist()