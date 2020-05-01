# %%
import requests
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
from io import BytesIO
import re
import os
import sqlite3

# %% 거래소 request header 정보
user_agent = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.97 Safari/537.36'
session_id = 'AAF4DCA28DFE6282022C00EC6FFD466E.58tomcat1'
referer = 'http://marketdata.krx.co.kr/mdi'

# %% 최근 영업일 구하기
url = 'https://finance.naver.com/sise/sise_deposit.nhn'
response = requests.get(url)
soup = BeautifulSoup(response.content, 'html.parser')
biz_day = soup.find('span', {'class':'tah'}).text
biz_day = re.search('[0-9]+.[0-9]+.[0-9]+', biz_day).group()
biz_day = biz_day.replace('.', '')

# %% 산업별 현황 OTP 발급
otp_gen_url = 'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
otp_gen_params = {
    'name': 'fileDown',
    'filetype': 'xls',
    'url': 'MKD/03/0303/03030103/mkd03030103',
    'tp_cd': 'ALL',
    'date': biz_day,
    'lang': 'ko',
    'pagePath' : '/contents/MKD/03/0303/03030103/MKD03030103.jsp'
}
response = requests.get(
    otp_gen_url, otp_gen_params,
    headers = {
        'user-agent': user_agent,
        'referer': referer,
        'JSESSIONID': session_id
    },
)
otp = response.content

# %% 산업별 현황 데이터 다운로드
down_url = 'http://file.krx.co.kr/download.jspx'
down_data = {'code': otp}
response = requests.post(
    down_url, down_data,
    headers = {
        'user-agent': user_agent,
        'referer': referer
    }
)
down_sector = pd.read_excel(BytesIO(response.content))

# %% 개별종목 지표 OTP 발급
otp_gen_url = 'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
otp_gen_params = {
    'name' : 'fileDown',
    'filetype' : 'xls',
    'url' : 'MKD/13/1302/13020401/mkd13020401',
    'market_gubun' : 'ALL',
    'gubun' : '1',
    'schdate' : biz_day,
    'pagePath' : '/contents/MKD/13/1302/13020401/MKD13020401.jsp'
}
response = requests.get(
    otp_gen_url, otp_gen_params,
    headers = {
        'user-agent': user_agent,
        'referer': referer,
        'JSESSIONID': session_id
    }
)
otp = response.content

# %% 개별종목 지표 데이터 다운로드
down_url = 'http://file.krx.co.kr/download.jspx'
down_data = {'code': otp}
response = requests.post(
    down_url, down_data,
    headers = {
        'user-agent': user_agent,
        'referer': referer
    }
)
down_ind = pd.read_excel(BytesIO(response.content))

# %% 데이터 정리
kor_ticker = pd.merge(
    left = down_sector,
    right = down_ind,
    how = 'inner',
    on = '종목코드'
)
kor_ticker.drop(
    ['종목명_y', '현재가(종가)', '전일대비'],
    axis=1, inplace=True
)
kor_ticker.rename(
    columns = {'종목명_x':'종목명','시가총액(원)':'시가총액'},
    inplace = True
)

kor_ticker = kor_ticker.astype('str').replace(regex=r',', value='')
kor_ticker = kor_ticker.replace(to_replace='-', value=np.nan)
type_dic = {
    '시장구분' : 'object',
    '종목코드' : 'object',
    '종목명' : 'object',
    '산업분류' : 'object',
    '시가총액' : 'int64',
    '일자' : 'datetime64',
    '관리여부' : 'object',
    '종가' : 'int64',
    'EPS' : 'float64',
    'PER' : 'float64',
    'BPS' : 'float64',
    'PBR' : 'float64',
    '주당배당금' : 'float64',
    '배당수익률' : 'float64'
}
kor_ticker = kor_ticker.astype(type_dic)
kor_ticker['관리여부'] = kor_ticker['관리여부'].astype('str').str.replace('nan', '-')
kor_ticker = kor_ticker.loc[
    kor_ticker.종목코드.str.contains('0$') &
    ~kor_ticker.종목명.str.contains('스팩'), 
    :
]
kor_ticker = kor_ticker.sort_values(
    ['시가총액'],
    ascending = False
)
kor_ticker.reset_index(drop=True, inplace=True)

# %% 데이터 저장
path = os.path.join(
    os.getcwd(), 'data\\'
)

con = sqlite3.connect(path + 'kor_stock.db')
kor_ticker.to_sql(
    'kor_ticker', con,
    if_exists='replace',
    index=False,
    chunksize=1000,
    dtype={
        '시장구분' : 'TEXT',
        '종목코드' : 'TEXT',
        '종목명' : 'TEXT',
        '산업분류' : 'TEXT',
        '시가총액' : 'INTEGER',
        '일자' : 'TEXT',
        '관리여부' : 'TEXT',
        '종가' : 'INTEGER',
        'EPS' : 'REAL',
        'PER' : 'REAL',
        'BPS' : 'REAL',
        'PBR' : 'REAL',
        '주당배당금' : 'REAL',
        '배당수익률' : 'REAL'
    }
)
con.close()
