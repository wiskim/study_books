import pandas as pd
import os
import requests
from bs4 import BeautifulSoup
import time

path = os.getcwd() + '\\quant investment\\data\\'
kor_ticker = pd.read_csv(
    path + 'kor_ticker.csv',
    dtype={'종목코드' : 'str'}
)

i = 0
n = len(kor_ticker['종목코드'])
fail_ticker = []

for ticker in kor_ticker['종목코드']:

    try:
        i += 1
        name = kor_ticker.loc[kor_ticker['종목코드'] == ticker, '종목명'].values[0]
        print("%d/%d %s 다운로드 시작" %(i, n, name))
        url = 'https://fchart.stock.naver.com/sise.nhn'
        params = {
        'symbol': ticker,
        'timeframe' : 'day',
        'count': 500,
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
            columns=['date', 'start', 'high', 'low', 'close', 'vol']
        )
        ohlc_df['date'] = pd.to_datetime(ohlc_df['date'])
        ohlc_df.to_csv(
            path + '\\kor_price\\' + ticker + '_price.csv',
            index=False
        )
        print("%d/%d %s 다운로드 성공" %(i, n, name))
        time.sleep(0.01)

    except:
        print("%d/%d %s 다운로드 실패" %(i, n, name))
        fail_ticker.append(ticker)
        pass

print(fail_ticker)
