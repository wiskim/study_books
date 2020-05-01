library(ggplot2)
library(ggmap)

# 구글 API KEY를 입력
register_google("AIzaSyDHG66GSDqpAAyNLZLt45oRQUwtLc3CX4Y")

# 구장 위치정보 불러오기
a <- read.csv("./01_메이저리그_야구_통계학/ML Statistics/Chapter03/files/stadium_location.csv")

# 구글맵 가져오기
b <- get_map("Oklahoma City", zoom = 4, maptype = "roadmap")

# 구글맵 위에 구장 위치 표시하기
ggmap(b) + 
  geom_point(data = a, aes(longitude, latitude), size = 2, color = "blue") +
  geom_text(data = a, aes(longitude, latitude - 1, label = id), size = 3, color = "blue")
