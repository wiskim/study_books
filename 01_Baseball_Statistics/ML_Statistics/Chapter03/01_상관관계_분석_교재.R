library(Lahman)
library(plyr)

a <- subset(Batting, yearID>2014)
a$teamID <- as.numeric(as.factor(a$teamID))

b <- function(a){
  return(data.frame(
    team = ifelse(mean(a$teamID)==a$teamID, 0, 1),
    a$playerID,
    a$lgID,
    a$SF,
    a$SH,
    a$H,
    a$yearID,
    a$teamID,
    a$RBI,
    a$AB
  ))
}

d <- ddply(a, .(playerID), b)

d$lag_team <- as.numeric(sapply(1:nrow(d), function(x){
  d$a.teamID[x-1]
}))
d$lag_RBI <- as.numeric(sapply(1:nrow(d), function(x){
  d$a.RBI[x-1]
}))
d$lag_AB <- as.numeric(sapply(1:nrow(d), function(x){
  d$a.AB[x-1]
}))
d$lag_SF <- as.numeric(sapply(1:nrow(d), function(x){
  d$a.SF[x-1]
}))
d$lag_SH <- as.numeric(sapply(1:nrow(d), function(x){
  d$a.SH[x-1]
}))
d$lag_H <- as.numeric(sapply(1:nrow(d), function(x){
  d$a.H[x-1]
}))
d$lag_playerID <- as.character(sapply(1:nrow(d), function(x){
  d$playerID[x-1]
}))
d$lag_team <- ifelse(d$playerID == d$lag_playerID, d$lag_team, "NA")
d$lag_avg <- d$lag_H / d$lag_AB
d$sac <- d$lag_SF + d$lag_SH

d <- subset(d, a.AB>400 & lag_AB>400)

d$change_rbi <- d$a.RBI / d$lag_RBI

d <- subset(d, !((lag_team =="NA") | (a.teamID == lag_team)))

d$lg_col <- ifelse(d$a.lgID == "NL", "gray", "black")
d$lg_shape <- ifelse(d$a.lgID == "NL", 2, 15)

print(cor(d$lag_avg, d$change_rbi))

plot(d$lag_avg, d$change_rbi, 
     main="Pridictor of RBI", 
     xlab="Batting Average of Prior Year", 
     ylab="Change in RBI",
     las=1,
     cex.axis=0.8,
     pch=19,
     col=d$lg_col)
text(x=0.3, y=1.6, label="r=-0.49")
abline(lm(change_rbi~lag_avg,d))
legend(x=0.29, y=1.4, c("National", "American"), col=c("gray", "black"), pch=c(19,19))
