# 메이저리그 팀들을 2루타, 3루타, 방어율, 평균실점을 기준으로 그룹핑

library(tidyverse)
library(Lahman)

team <- Teams %>% 
  filter(yearID == 2015) %>% 
  select(teamID, X2B, X3B, ERA, RA)

rownames(team) <- team$teamID
team <- team[, -1]
team <- scale(team)

library(factoextra)

p1 <- fviz_nbclust(team, kmeans, method = 'gap_stat') # 몇개의 그룹으로 나누는 것이 군집 간 구분이 가장 분명한지 확인

residual <- kmeans(team, 3, nstart = 25) # 3개의 그룹으로 나누어서 sum of squares by cluster를 보여줌
residual

p2 <- fviz_cluster(residual, data = team) # cluster plot

library(FactoMineR)
library(gridExtra)

pca.res <- PCA(team, graph = FALSE) # cluster plot의 각 dim별 요인분석
p3 <- fviz_contrib(pca.res, choice = 'var', axes = 1, top = 4)
p4 <- fviz_contrib(pca.res, choice = 'var', axes = 2, top = 4)
grid.arrange(p1, p2, p3, p4, ncol=2)
