library(tidyverse)
library(Lahman)
library(arules)

df <- Batting %>% 
  filter(yearID > 2010) %>% 
  select(playerID, teamID)

df$teamID <- as.character(df$teamID)

move <- as(object = split(df$teamID, df$playerID), Class = 'transactions')
# value값이 먼저 오고, key값이 뒤에 와야함
itemFrequencyPlot(move, support = 0.0015, cex.names = 0.6)
pattern <- apriori(move, list(support = 0.0015, confidence = 0.5, minlen = 2))
summary(inspect(pattern))
