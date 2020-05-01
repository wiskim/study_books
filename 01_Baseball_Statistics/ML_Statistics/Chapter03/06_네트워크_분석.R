library(tidyverse)
library(Lahman)
library(igraph)
library(showtext)

pitcher <- as_tibble(Pitching) %>% 
  filter(yearID > 2014, G > 35) %>% 
  select(playerID, yearID, teamID) %>% 
  mutate(teamyear = paste0(teamID, yearID))

manager <- as_tibble(Managers) %>% 
  filter(yearID > 2014) %>% 
  select(playerID, yearID, teamID) %>% 
  mutate(teamyear = paste0(teamID, yearID))

couple <- inner_join(pitcher, manager, by = "teamyear") %>% 
  select(playerID.x, playerID.y)

mlbNetwork <- graph.data.frame(couple, directed = F)

mapping <- tibble(vertexName = V(mlbNetwork)$name) %>% 
  left_join(manager, by = c("vertexName" = "playerID")) %>% 
  select(-teamyear) %>% 
  group_by(vertexName) %>% 
  spread(key = yearID, value = teamID) %>%
  mutate(label = ifelse(!is.na(`2015`) | !is.na(`2016`),
                        paste0(vertexName, 
                               "\n", 
                               `2015`, 
                               "-", 
                               `2016`), 
                        NA)) %>% 
  select(vertexName, label)
  
mappingReorder <- tibble(vertexName = V(mlbNetwork)$name) %>% 
  left_join(mapping, by = "vertexName")

V(mlbNetwork)$label <- mappingReorder$label

V(mlbNetwork)$size <- ifelse(V(mlbNetwork)$name %in% manager$playerID, 
                             4, 2)

V(mlbNetwork)$color <- ifelse(V(mlbNetwork)$name %in% manager$playerID, 
                              "orange", "gray")

font_add_google("Nanum Gothic", "nanumgothic")
showtext_auto()
windows()

plot(mlbNetwork,
     vertex.label.cex = 0.7, 
     vertex.label.dist = 1, 
     vertex.label.degree = pi/2, 
     vertex.label.color = "black", 
     vertex.label.family = "nanumgothic", 
     vertex.label.font = 2)
