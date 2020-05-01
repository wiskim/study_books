library(tidyverse)
library(ggrepel)
library(ggthemes)
library(showtext)

batting <- read_csv(file = "./01_메이저리그_야구_통계학/KBO Statistics/files/KBO_Batting_Stats.csv")
batting <- batting %>% 
  filter(연도 == 2018) %>% 
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

# 도수분포표 작성

fdt <- batting %>% 
  count(cut_width(x = AB, width = 50, boundary = 0, closed = "left")) %>% 
  mutate(prop = round(n/sum(n), digits = 2))

fdt <- rename(fdt,
              AB = colnames(fdt)[1],
              frequency = colnames(fdt)[2],
              proportion = colnames(fdt)[3])

print(fdt)

# 관심 선수 등록 

monitoringPlayers <- batting %>% 
  filter(team == "한화") %>% 
  select(player) %>% 
  pull()

batting2 <- batting %>%
  mutate(monitoring = ifelse(player %in% monitoringPlayers, 1, 0))

# 산포도 작성

## 나눔고딕 사용을 위한 설정
font_add_google("Noto Serif KR", "notoserifkr")
showtext_auto()
windows()

ggplot() +
  geom_point(data = filter(batting2, AB >= 50),
             mapping = aes(OBP, SLG),
             color = ifelse(filter(batting2, AB >= 50)$monitoring == 1, "#e5001f", "#014d64"),
             size = 2) +
  geom_smooth(data = filter(batting2, AB >= 50),
              mapping = aes(OBP, SLG),
              method = "lm",
              color = "#56B4E9",
              linetype = "dashed",
              se = F) + 
  geom_text_repel(data = filter(batting2, AB >= 50, monitoring == 1),
                  aes(OBP, SLG, label = player),
                  nudge_x = 0.05,
                  nudge_y = -0.15,
                  color = "#014d64",
                  family = "notoserifkr",
                  size = 3.5) +
  labs(title = "출루율과 장타율 상관관계 분석",
       subtitle = "2018정규시즌의 상관계수는 0.88",
       caption = "출처 : KB Report",
       x = "출루율(OBP)",
       y = "장타율(SLG)") +
  theme_economist(base_family = "notoserifkr", base_size = 11)
