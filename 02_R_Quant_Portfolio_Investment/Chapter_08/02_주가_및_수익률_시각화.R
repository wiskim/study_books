library(quantmod)

getSymbols('SPY')
prices <- Cl(SPY)

plot(prices, main = 'Price')

library(ggplot2)

SPY %>% 
  ggplot(aes(x = Index, y = SPY.Close)) +
  geom_line()

library(plotly)

p <- SPY %>% 
  ggplot(aes(x = Index, y = SPY.Close)) +
  geom_line()

ggplotly(p)

prices %>% 
  fortify.zoo() %>% 
  plot_ly(x = ~Index, y =  ~SPY.Close) %>% 
  add_lines()

library(PerformanceAnalytics)

ret_yearly <- prices %>% 
  Return.calculate() %>% 
  apply.yearly(., Return.cumulative) %>% 
  round(4) %>% 
  fortify.zoo() %>% 
  mutate(Index = as.numeric(substring(Index, 1, 4)))

ggplot(ret_yearly, aes(x = Index, y = SPY.Close)) +
  geom_bar(stat = 'identity') +
  scale_x_continuous(breaks = ret_yearly$Index, expand = c(0.01, 0.01)) +
  geom_text(aes(label = paste(round(SPY.Close * 100, 2), '%'),
                vjust = ifelse(SPY.Close >= 0, -0.5, 1.5)),
            position = position_dodge(width = 1),
            size = 3)