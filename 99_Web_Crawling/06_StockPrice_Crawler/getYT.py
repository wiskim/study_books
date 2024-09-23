# %%
import datetime
import requests
import json
import numpy as np
import pandas as pd

ticker = 'TLT'
dt1 = '2023-01-01'
dt2 = '2024-09-01'
dt1 = datetime.datetime.strptime(dt1, '%Y-%m-%d').timestamp()
dt2 = datetime.datetime.strptime(dt2, '%Y-%m-%d').timestamp()
url = 'https://query1.finance.yahoo.com/v8/finance/chart/'
url += ticker
params = {
    'period1' : int(dt1),
    'period2' : int(dt2),
    'interval' : '1d',
    'events' : 'history',
    'includeAdjustedClose' : 'true'
}
headers = {
    'USER-AGENT' : 'Mozilla/5.0'
}
res = requests.get(url, params, headers=headers)
decodedContent = res.content.decode('UTF-8')
js = json.loads(decodedContent)
date = js['chart']['result'][0]['timestamp']
high = js['chart']['result'][0]['indicators']['quote'][0]['high']
volume = js['chart']['result'][0]['indicators']['quote'][0]['volume']
close = js['chart']['result'][0]['indicators']['quote'][0]['close']
open = js['chart']['result'][0]['indicators']['quote'][0]['open']
low = js['chart']['result'][0]['indicators']['quote'][0]['low']
adjclose = js['chart']['result'][0]['indicators']['adjclose'][0]['adjclose']

ohlcDf = pd.DataFrame(list(zip(date, open, high, low, close, adjclose, volume)), columns=['Date', 'Open', 'High', 'Low', 'Close', 'AdjClose', 'Volume'])
ohlcDf.Date = pd.to_datetime(ohlcDf.Date, unit='s').dt.normalize()
ohlcDf.set_index('Date', inplace=True)

