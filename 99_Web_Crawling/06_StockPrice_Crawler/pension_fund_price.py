# %%
# 네이버에서 주가 정보 크롤링

import numpy as np
import pandas as pd
import requests
from bs4 import BeautifulSoup
import warnings
import os
import datetime
from tabulate import tabulate

name_list = [
    'TIGER 미국다우존스30',
    'KINDEX 미국S&P500',
    'TIGER 미국S&P500',
    'TIGER 미국나스닥100',
    'ARIRANG 신흥국MSCI(합성 H)',
    'TIGER 200',
    'KODEX 미디어&엔터테인먼트',
    'KODEX 헬스케어',
    'TIGER 부동산인프라고배당',
    'KOSEF 국고채10년',
    'KODEX 미국채10년선물',
    'KODEX 골드선물(H)'
]

ticker_list = [
    '245340', 
    '360200',
    '360750',
    '133690',
    '195980',
    '102110',
    '266360',
    '266420',
    '329200',
    '148070',
    '308620',
    '132030'
]

result_df = pd.DataFrame()

warnings.filterwarnings('ignore', category=UserWarning, module='bs4')

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

# %%
change_df = result_df.iloc[-2:, :]
change_df.index = pd.Series(change_df.index).apply(
    lambda x: datetime.datetime.strftime(x, '%Y-%m-%d')
)
change_df.index.name = None
change_df = change_df.apply(pd.to_numeric)
change_df = change_df.transpose()
change_df['Change'] = (change_df.iloc[:, 1] / change_df.iloc[:, 0] - 1) * 100
change_df['Change'] = np.round(change_df['Change'], 2)
print(tabulate(change_df, headers='keys', tablefmt='psql'))

result_df = result_df.reset_index()

#%%
# 구글스프레드시트 열기

import gspread
import gspread_dataframe as gd
from oauth2client.service_account import ServiceAccountCredentials

scope = [
    'https://spreadsheets.google.com/feeds',
    'https://www.googleapis.com/auth/drive'
]

path = os.path.dirname(__file__)
json = os.path.join(path, 'my-project-1550060360364-f758ca00dc50.json')
credentials = ServiceAccountCredentials.from_json_keyfile_name(json, scope)

gc = gspread.authorize(credentials)

spreadsheetUrl = 'https://docs.google.com/spreadsheets/d/1-rYC8_1fpnJIC7G1pr3fbLolGledGn3Cb_OzwEmaUWU'
doc = gc.open_by_url(spreadsheetUrl)

# periodPrice 시트에 result_df 업로드

worksheet = doc.worksheet('periodPrice')
gd.set_with_dataframe(worksheet,
                      result_df,
                      include_index = False)

# periodPortValue 시트에 row 업데이트
worksheet = doc.worksheet('periodPortValue')
sheet_id = worksheet._properties['sheetId']

last_row = len(list(filter(None, worksheet.col_values(1)))) + 1
last_col = worksheet.col_count
last_date = worksheet.cell(last_row, 1).value
last_date_index = result_df.loc[result_df.DATE == last_date].index[0]   # 250 거래일을 초과하여 업데이트할 경우 오류가 발생
total_date_no = len(result_df.index)
n = total_date_no - (last_date_index + 1)

if n > 0:
    body = {
        'requests': [
            {
                'copyPaste': {
                    'source': {
                        'sheetId': sheet_id,
                        'startRowIndex': int(last_row - 1),
                        'endRowIndex': last_row,
                        'startColumnIndex': 0,
                        'endColumnIndex': last_col
                    },
                    'destination': {
                        'sheetId': sheet_id,
                        'startRowIndex': last_row,
                        'endRowIndex': int(last_row + n),
                        'startColumnIndex': 0,
                        'endColumnIndex': last_col                    
                    },
                    'pasteType': 'PASTE_FORMULA'
                }
            }
        ]
    }
    res = doc.batch_update(body)

    update_range = 'A' + str(last_row + 1) + ':' + 'A' + str(last_row + n)
    date_list = result_df['DATE'][-n:].to_list()
    date_list = [[date.strftime('%Y-%m-%d %H:%M:%S.%f')] for date in date_list]
    worksheet.update(update_range, date_list, value_input_option='USER_ENTERED')

    body = {
        'requests': [
            {
                'copyPaste': {
                    'source': {
                        'sheetId': sheet_id,
                        'startRowIndex': int(last_row - 1),
                        'endRowIndex': last_row,
                        'startColumnIndex': 0,
                        'endColumnIndex': last_col
                    },
                    'destination': {
                        'sheetId': sheet_id,
                        'startRowIndex': last_row,
                        'endRowIndex': int(last_row + n),
                        'startColumnIndex': 0,
                        'endColumnIndex': last_col                    
                    },
                    'pasteType': 'PASTE_FORMAT'
                }
            }
        ]
    }
    res = doc.batch_update(body)

print("The Google Spreadsheet has been updated.")
