library(tidyverse)
library(Lahman)

df <- Teams %>% 
  filter(yearID > 1900 & yearID < 2016) %>% 
  mutate(AVG = H / AB,
         X3R = X3B / AB,
         RR = R / RA) %>% 
  select(yearID, DivWin, ERA, AVG, X3R, RR) %>% 
  na.omit()

train <- df %>% 
  filter(yearID <= 1995)

test <- df %>% 
  filter(yearID > 1995)

library(nnet)

train$ID_a <- class.ind(train$DivWin)
test$ID_b <- class.ind(test$DivWin)
fitnn <- nnet(formula = ID_a ~ ERA + AVG + X3R + RR, data = train, size = 3, softmax = TRUE)

summary(fitnn)

result_df <- table(data.frame(predited = predict(fitnn, test)[,2] > 0.5, 
                              actual = test$ID_b[,2] > 0.5))
result_df
(result_df[1,1] + result_df[2,2]) / sum(result_df)

library(neuralnet)

df <- df %>% 
  mutate(win = DivWin == "Y",
         not_win = DivWin == "N")

net <- neuralnet(formula = win + not_win ~ ERA + AVG + X3R + RR, data = df, hidden = 3, stepmax = 1e6)
net$result.matrix
