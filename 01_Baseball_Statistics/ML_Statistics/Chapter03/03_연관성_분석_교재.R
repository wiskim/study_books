library(Lahman)
library(data.table)
library(arules)

a <- subset(Batting, yearID > 2010, select = c(playerID, teamID))
a$teamID <- factor(a$teamID)
a$teamID <- as.character(a$teamID)

move <- dcast(setDT(x = a)[, idx := 1:.N, by = playerID],
              playerID ~ idx, value.var = c("teamID"))
move[is.na(move)] <- ""
move[, 1] <- NULL
write.csv(move, file = "./01_메이저리그_야구_통계학/ML Statistics/Chapter03/files/move.csv")

move <- read.transactions("./01_메이저리그_야구_통계학/ML Statistics/Chapter03/files/move.csv", sep = ",")
# csv 파일을 dataframe 으로 업로드할 때 read.csv() 함수를 사용하는 것처럼, 
# transaction 데이터를 연관규칙분석을 위해 sparse format의 itemMatrix로 
# 업로드하기 위해서는 read.transactions("dataset.csv") 함수를 사용

summary(move)
itemFrequencyPlot(move, support = 0.01, cex.names = 0.6)
pattern <- apriori(move, list(support = 0.0015, confidence = 0.5, minlen = 2))
summary(inspect(pattern))
# A -> B 거래 해석
# support(지지도) = P(A and B) = P(A) * P(B|A) = P(B) * P(A|B)
# confidence(신뢰도) = P(A and B) / P(A) = P(B|A)
# lift(향상도) = P(A and B) / P(A) * P(B) = P(B|A) / P(B) = P(A|B) / P(A)