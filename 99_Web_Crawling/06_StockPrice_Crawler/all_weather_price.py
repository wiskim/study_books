# %%
import os
import datetime
import numpy as np
import pandas as pd
import FinanceDataReader as fdr
from tabulate import tabulate

today = datetime.datetime.now().strftime('%Y-%m-%d')

nameList = [
    '원달러환율'
    'iShares 20+ Year Treasury Bond ETF', 
    'iShares 7-10 Year Treasury Bond ETF',
    'Vanguard Total World Stock ETF',
    'iShares Gold Trust',
    'Invesco DB Commodity Tracking',
    'PIMCO 15Y US TIPS ETF'
]

tickerList = [
    'USD/KRW',
    'TLT', 
    'IEF',
    'VT',
    'IAU',
    'DBC',
    'LTPZ'
]

resultDf = pd.DataFrame()

for i in range(0, len(tickerList)):
    priceList = fdr.DataReader(
        tickerList[i], '2021-01-01', today
    )
    priceList = priceList['Close']
    resultDf[tickerList[i]] = priceList

# %%
resultDf = resultDf.dropna()

changeDf = resultDf.iloc[-2:, :]
changeDf.index = pd.Series(changeDf.index).apply(
    lambda x: datetime.datetime.strftime(x, '%Y-%m-%d')
)
changeDf.index.name = None
changeDf = changeDf.apply(pd.to_numeric)
changeDf = changeDf.transpose()
changeDf['Change'] = (changeDf.iloc[:, 0] / changeDf.iloc[:, 1] - 1) * 100
changeDf['Change'] = np.round(changeDf['Change'], 2)
print(tabulate(changeDf, headers='keys', tablefmt='psql'))

resultDf.reset_index(inplace=True)
resultDf.rename(columns={'index':'DATE'}, inplace=True)

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
                      include_index = False)

print('copied to GoogleSpreadSheet')
