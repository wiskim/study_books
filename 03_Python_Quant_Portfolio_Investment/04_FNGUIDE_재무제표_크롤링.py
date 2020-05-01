# %%
import requests
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
import os

path = os.getcwd() + '\\quant investment\\data\\'
kor_ticker = pd.read_csv(
    path + 'kor_ticker.csv',
    dtype={'종목코드' : 'str'}
)

i = 0 # 해당 종목 순서
n = len(kor_ticker['종목코드']) # 총 종목 갯수
fail_ticker = [] # 다운 실패한 종목 리스트

for ticker in kor_ticker['종목코드']:

    try:
        
        i += 1
        name = kor_ticker.loc[kor_ticker['종목코드'] == ticker, '종목명'].values[0]
        print("%d/%d %s 다운로드 시작" %(i, n, name))

        url = 'http://comp.fnguide.com/SVO2/ASP/SVD_Finance.asp'
        params = {
            'pGB': 1,
            'gicode': 'A' + ticker  
        }
        r = requests.get(url, params)
        soup = BeautifulSoup(r.content, 'html.parser')

        fs_list = ['divSonikY', 'divDaechaY', 'divCashY']
        fs_df = pd.DataFrame()

        for fs in fs_list:
            
            # 컬럼 데이터 추출
            soup_sub = soup.select('div#'+fs+' table thead tr th')
            fs_columns = [k.get_text().strip() for k in soup_sub]
            
            # 계정과목 데이터 추출
            soup_sub = soup.select('div#'+fs+' table tbody th')
            fs_coa = [k.get_text().strip() for k in soup_sub]

            # 값 데이터 추출
            soup_sub = soup.select('div#'+fs+' table tbody td')
            fs_data = [k.get_text().strip() for k in soup_sub]

            fs_data = np.array(fs_data)
            ncol = int(len(fs_columns) - 1) # 계정과목 데이터는 fs_coa에 들어 있으므로 컬럼 수에서 1 차감
            nrow = int(len(fs_data) / ncol)
            fs_data = np.resize(fs_data, (nrow, ncol))
            fs_data = pd.DataFrame(fs_data, columns=fs_columns[1:])
            fs_data.insert(0, fs_columns[0], fs_coa) # 계정과목 데이터를 별도로 붙임
            fs_data = fs_data.filter(regex='^((?!전년).)*$') # 손익계산서의 전년대비 컬럼 삭제

            fs_df = fs_df.append(fs_data, ignore_index=True)
        
        fs_df = fs_df.filter(regex='(^IFRS|12$)') # 연도말 자료만 남김
        fs_df.iloc[:, 0] = fs_df.iloc[:, 0].str.replace('계산에 참여한 계정 펼치기', '') # 계정과목명 클렌징

        fs_df.to_csv(
            path + '\\kor_fs\\' + ticker + '_fs.csv',
            index=False
        )
        print("%d/%d %s 다운로드 성공" %(i, n, name))

    except:
        print("%d/%d %s 다운로드 실패" %(i, n, name))
        fail_ticker.append(ticker)
        pass

print(fail_ticker)
