# %%
import pandas as pd
from pandas.core.frame import DataFrame
import requests
from bs4 import BeautifulSoup
import re
import time
# %%
# 전체 테마리스트 크롤링
themeNm = []
themeCd = []

url = 'https://finance.naver.com/sise/theme.nhn'

for i in range(6):
    params = {'page':str(i)}
    response = requests.get(url, params)
    soup = BeautifulSoup(response.text, 'lxml')
    pageThemeNm = [i.get_text() for i in soup.find_all('a', {'href':re.compile(r'^/sise/sise_group_detail')})]
    pageThemeCd = [i['href'] for i in soup.find_all('a', {'href':re.compile(r'^/sise/sise_group_detail')})]
    themeNm += pageThemeNm
    themeCd += pageThemeCd
    time.sleep(0.5)

themeDf = pd.DataFrame(list(zip(themeCd, themeNm)), columns='themeCd, themeNm'.split(', '))
themeDf['themeCd'] = themeDf.themeCd.str.extract(r'(\d+)').astype('int')
themeDf = themeDf.sort_values('themeCd', ignore_index=True)
# %%
# 각 테마별 종목 크롤링
themeStockDf = pd.DataFrame(columns='themeCd, themeNm, stockCd, stockNm, stockInfo'.split(', '))

url = 'https://finance.naver.com/sise/sise_group_detail.nhn'

for i in range(len(themeDf['themeCd'])):
    params = {'type':'theme', 'no':themeDf['themeCd'][i]}
    response = requests.get(url, params)
    soup = BeautifulSoup(response.text, 'lxml')
    stockCd = [i['href'] for i in soup.find_all('a', {'href':re.compile('^/item/main.nhn\?code')})]
    stockNm = [i.get_text() for i in soup.find_all('a', {'href':re.compile('^/item/main.nhn\?code')})]
    stockInfo = [i.get_text() for i in soup.find_all('p', {'class':'info_txt'})]
    del stockInfo[0]
    pageThemeStockDf = pd.DataFrame(list(zip(stockCd, stockNm, stockInfo)), columns='stockCd, stockNm, stockInfo'.split(', '))
    pageThemeStockDf['themeCd'] = themeDf['themeCd'][i]
    pageThemeStockDf['themeNm'] = themeDf['themeNm'][i]
    themeStockDf = themeStockDf.append(pageThemeStockDf, ignore_index=True)
    time.sleep(0.5)

themeStockDf['stockCd'] = themeStockDf.stockCd.str.extract(r'(\d+)')
themeStockDf['stockCd'] = themeStockDf.stockCd.str.rjust(7, 'A')

# %%
themeStockDf.to_csv('naver_theme_stock_info.csv', index=False)
