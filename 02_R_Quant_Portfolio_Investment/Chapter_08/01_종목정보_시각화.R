library(stringr)
library(dplyr)
library(ggplot2)

file_path <-
  paste0(getwd(),
         '/03_R을_이용한_퀀트_투자_포트폴리오_만들기/',
         'Chapter_05/files/')

kor_ticker <-
  read.csv(file = paste0(file_path,
                         'KOR_ticker.csv'),
           fileEncoding = 'utf-8',
           stringsAsFactors = FALSE)

kor_sector <-
  read.csv(file = paste0(file_path,
                         'KOR_sector.csv'),
           fileEncoding = 'utf-8',
           stringsAsFactors = FALSE)

kor_ticker$종목코드 <-
  str_pad(kor_ticker$종목코드, 6, 'left', 0)

kor_sector$CMP_CD <-
  str_pad(kor_sector$CMP_CD, 6, 'left', 0)

data_market <-
  left_join(kor_ticker, kor_sector,
            by = c('종목코드' = 'CMP_CD',
                   '종목명' = 'CMP_KOR'))

data_market <- data_market %>% 
  rename(`시가총액` = `시가총액.원.`) %>% 
  mutate_at(vars(EPS, PER, BPS, PBR),
            function(x) {
              as.numeric(str_replace_all(x, ',', ''))
            }) %>% 
  mutate(ROE = PBR / PER,
         ROE = round(ROE, 4),
         size = ifelse(
           시가총액 >= median(시가총액, na.rm = TRUE),
            'big', 'small'))

ggplot(data = data_market, aes(x = ROE, y = PBR,
                               color = 시장구분,
                               shape = 시장구분)) +
  geom_point() +
  geom_smooth(method= 'lm') +
  coord_cartesian(xlim = c(0, 0.3), ylim = c(0, 3))

ggplot(data = data_market, aes(x = PBR)) + 
  geom_histogram(aes(y = ..density..),
                 binwidth = 0.1,
                 alpha = 0.3) +
  coord_cartesian(xlim = c(0, 10)) +
  geom_density(color = 'red') +
  geom_vline(aes(xintercept = median(PBR, na.rm = TRUE)),
             color = 'blue') +
  geom_text(aes(x = median(PBR, na.rm = TRUE),
                y = 0.05,
                label = median(PBR, na.rm = TRUE)),
            hjust = -0.5)

ggplot(data = data_market %>% filter(!is.na(SEC_NM_KOR)),
       aes(x = SEC_NM_KOR, y = PBR)) +
  geom_boxplot() +
  coord_flip()

data_market %>%
  filter(!is.na(SEC_NM_KOR)) %>%
  group_by(SEC_NM_KOR) %>%
  summarise(ROE_sector = median(ROE, na.rm = TRUE),
            PBR_sector = median(PBR, na.rm = TRUE)) %>%
  ggplot(aes(x = ROE_sector, y = PBR_sector,
             color = SEC_NM_KOR, label = SEC_NM_KOR)) +
  geom_text(color = 'black', vjust = 1.5, size = 3) +
  geom_point() +
  theme(legend.position = 'bottom',
        legend.title = element_blank())

data_market %>%
  filter(!is.na(SEC_NM_KOR)) %>%
  group_by(SEC_NM_KOR) %>%
  summarise(n = n()) %>%
  ggplot(aes(x = reorder(SEC_NM_KOR, n), y = n, label = n)) +
  geom_bar(stat = 'identity') +
  geom_text(color = 'black', size = 4, hjust = -0.3) +
  xlab(NULL) +
  ylab(NULL) +
  coord_flip() +
  scale_y_continuous(c(0, 0, 0.1, 0)) +
  theme_classic()