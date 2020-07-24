# %%
import os
import datetime
import pandas as pd
import FinanceDataReader as fdr

today = datetime.datetime.now().strftime('%Y-%m-%d')

nameList = [
    '원달러환율'
    'iShares 20+ Year Treasury Bond ETF', 
    'iShares 7-10 Year Treasury Bond ETF',
    'Vanguard Total World Stock ETF',
    'iShares Gold Trust',
    'Invesco DB Commodity Tracking'
]

tickerList = [
    'USD/KRW',
    'TLT', 
    'IEF',
    'VT',
    'IAU',
    'DBC'
]

resultDf = pd.DataFrame()

for i in range(0, len(tickerList)):
    priceList = fdr.DataReader(
        tickerList[i], '2020-01-01', today
    )
    priceList = priceList['Close']
    resultDf[tickerList[i]] = priceList

print(resultDf.iloc[-1,:])

# %%
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

spreadsheetUrl = 'https://docs.google.com/spreadsheets/d/1m5ztJoiMNptV5NFB1fauCVx4F6RB3ecHRG3fNolDp_U/'
doc = gc.open_by_url(spreadsheetUrl)
worksheet = doc.worksheet('periodPrice')

gd.set_with_dataframe(worksheet,
                      resultDf,
                      include_index = True)

print('copied to GoogleSpreadSheet')
