# 네이버에서 주가 정보 크롤링

import pandas as pd
import requests
from bs4 import BeautifulSoup
import os

name_list = [
    'TIGER 미국다우존스30', 
    'TIGER 미국나스닥100',
    'ARIRANG 신흥국MSCI(합성 H)',
    'TIGER 200',
    'TIGER 부동산인프라고배당',
    'KOSEF 국고채10년',
    'KODEX 미국채10년선물',
    'KODEX 골드선물(H)'
]

ticker_list = [
    '245340', 
    '133690',
    '195980',
    '102110',
    '329200',
    '148070',
    '308620',
    '132030'
]

result_df = pd.DataFrame()

for i in range(len(ticker_list)):
    
    url = 'https://fchart.stock.naver.com/sise.nhn'
    params = {
        'symbol': ticker_list[i],
        'timeframe' : 'day',
        'count': 250,
        'requestType': 0
    }
    response = requests.get(url, params)
    soup = BeautifulSoup(response.text, 'lxml')
    
    item_list = soup.find_all('item')
    ohlc_list = []
    for item in item_list:
        ohlc_list.append(item.attrs['data'].split('|'))
    
    ohlc_df = pd.DataFrame(
        ohlc_list,
        columns=['DATE', 'START', 'HIGH', 'LOW', 'CLOSE', 'VOL']
    )
    ohlc_df = ohlc_df[['DATE', 'CLOSE']]
    ohlc_df.rename(columns = {'CLOSE' : name_list[i]}, inplace=True)
    ohlc_df['DATE'] = pd.to_datetime(ohlc_df['DATE'])
    ohlc_df.set_index('DATE', inplace = True)
    result_df = pd.concat([result_df, ohlc_df], axis=1, sort=True)

print(result_df.tail())

# 구글스프레드시트로 붙이기

import gspread
import gspread_dataframe as gd
from oauth2client.service_account import ServiceAccountCredentials

scope = [
    'https://spreadsheets.google.com/feeds',
    'https://www.googleapis.com/auth/drive'
]

path = os.path.dirname(__file__)
json = os.path.join(path, 'my-project-1550060360364-dd05317fea55.json')
credentials = ServiceAccountCredentials.from_json_keyfile_name(json, scope)

gc = gspread.authorize(credentials)

spreadsheetUrl = 'https://docs.google.com/spreadsheets/d/1-rYC8_1fpnJIC7G1pr3fbLolGledGn3Cb_OzwEmaUWU'
doc = gc.open_by_url(spreadsheetUrl)
worksheet = doc.worksheet('periodPrice')

gd.set_with_dataframe(worksheet,
                      result_df,
                      include_index = True)

print("copied to GoogleSpreadSheet")
