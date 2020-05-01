#%%
import requests
from bs4 import BeautifulSoup
import pandas as pd
import os

path = os.getcwd() + '\\quant investment\\data\\'
kor_ticker = pd.read_csv(
    path + 'kor_ticker.csv',
    dtype={'종목코드' : 'str'}
)

i = 0 # 해당 종목 순서
n = len(kor_ticker['종목코드']) # 총 종목 갯수

mcap_list = []
for ticker in kor_ticker['종목코드']:

    try:
        i += 1
        name = kor_ticker.loc[kor_ticker['종목코드'] == ticker, '종목명'].values[0]
        print("%d/%d %s 다운로드 시작" %(i, n, name))

        url = 'http://comp.fnguide.com/SVO2/ASP/SVD_Main.asp'
        params = {
            'pGB': 1,
            'gicode': 'A' + ticker            
        }

        r = requests.get(url, params)
        soup = BeautifulSoup(r.content, 'html.parser')

        mcap = soup.select(
            '#svdMainGrid1 > table > tbody > tr:nth-child(5) > td:nth-child(2)'
        )
        mcap = mcap[0].get_text().strip()
        mcap_list.append(mcap)

        print("%d/%d %s 다운로드 성공" %(i, n, name))
    
    except:
        print("%d/%d %s 다운로드 실패" %(i, n, name))
        mcap_list.append(None)
        pass

kor_mcap = pd.DataFrame(
    {
        'ticker': kor_ticker['종목코드'],
        'market_cap': mcap_list
    }
)
kor_mcap['market_cap'] = pd.to_numeric(
    kor_mcap['market_cap'].astype('str').str.replace(',', ''),
    errors='coerce'
)
kor_mcap = kor_mcap[['ticker', 'market_cap']]
kor_mcap.to_csv(
    path + 'kor_mcap.csv',
    index=False
)
