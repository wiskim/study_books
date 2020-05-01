library(tidyverse)
library(Lahman)
library(MASS)
library(class)

df <- Batting %>% 
  filter(yearID > 1998 & yearID < 2012, AB > 250) %>% 
  mutate(X2BR = X2B / AB,
         lgID = ifelse(lgID == 'AL', 1, 0)) %>% 
  dplyr::select(yearID, X2BR, HBP, lgID) %>% 
  na.omit()

train <- df %>% 
  filter(yearID != 2011)
test <- df %>% 
  filter(yearID == 2011)
var_train <- train[, c("X2BR", "HBP")]
var_test <- test[, c("X2BR", "HBP")]
lg_train <- train[, 'lgID']
lg_test <- test[, 'lgID']

ldafit <- lda(lgID ~ X2BR + HBP, data = test)
ldapred <- predict(ldafit)
a <- table(ldapred$class, test$lgID)
a
(a[1, 1] + a[2, 2]) / sum(a)

qdafit <- qda(lgID ~ X2BR + HBP, data = test)
qdapred <- predict(qdafit)
b <- table(qdapred$class, test$lgID)
b
(b[1, 1] + b[2, 2]) / sum(b)

knnpred <- knn(train = var_train, test = var_test, cl = lg_train, k = 3) # class는 vector 여야함
c <- table(knnpred, lg_test)
c
(c[1, 1] + c[2, 2]) / sum(c)
