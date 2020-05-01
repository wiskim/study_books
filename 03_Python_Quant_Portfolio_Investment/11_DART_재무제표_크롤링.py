# %%
# kor_ticker에 dart_code의 corp_code(다트 회사고유번호) 매핑

import pandas as pd
import os
import sqlite3

path = os.path.join(
    os.getcwd(), 'data\\'
)
con = sqlite3.connect(path + 'kor_stock.db')
kor_ticker = pd.read_sql(
    "SELECT * FROM kor_ticker", con, index_col=None
)
dart_code = pd.read_sql(
    "SELECT * FROM dart_code", con, index_col=None
)

kor_ticker = pd.merge(
    left=kor_ticker,
    right=dart_code,
    left_on='종목코드',
    right_on='stock_code',
    how='left'
)

# 당월에 상장한 종목은 dart_code 자료에 stock_code가 누락되어 있어 종목명으로 매핑
new_listed_stock = [
    '제이앤티씨',
    '레몬',
    '켄코아에어로스페이스',
    '서남'
]
for stock in new_listed_stock:
    kor_ticker.loc[kor_ticker['종목명']==stock, 'corp_code'] = \
        dart_code.loc[dart_code['corp_name']==stock, 'corp_code'].values[0]

# %%
# DART OPEN API를 이용해 재무제표 크롤링

import requests
from bs4 import BeautifulSoup as bs

# %%
i = 0                                             # 해당 종목 순서
n = len(kor_ticker['corp_code'])                  # 총 종목 갯수
fail_ticker = []                                  # 다운 실패한 종목 리스트
kor_fs = pd.DataFrame()

for dart_code in kor_ticker['corp_code']:

    i += 1

    for year in [2014, 2015, 2016, 2017, 2018]:   # 대상기간

        try:
          
            name = kor_ticker.loc[kor_ticker['corp_code'] == dart_code, '종목명'].values[0]
            print("%d/%d %s %d년 다운로드 시작" %(i, n, name, year))

            api_key = 'b557dbf9e8a26cf32e13a5612bb1405b0fc83aca'
            url = 'https://opendart.fss.or.kr/api/fnlttSinglAcntAll.xml'
            params = {
                    'crtfc_key' : api_key,
                    'corp_code' : dart_code,
                    'bsns_year' : year,
                    'reprt_code' : 11011,         # 1분기보고서 : 11013, 반기보고서 : 11012, 3분기보고서 : 11014, 사업보고서 : 11011
                    'fs_div' : 'CFS'              # 연결재무제표 : CFS, 개별재무제표 : OFS
            }
            response = requests.get(url, params)
            soup = bs(response.content, 'lxml')
            col_list = [
                'rcept_no',                       # 접수번호
                'reprt_code',                     # 보고서코드
                'bsns_year',                      # 사업연도
                'corp_code',                      # 고유번호
                'sj_div',                         # 재무제표구분
                'sj_nm',                          # 재무제표명
                'account_id',                     # 계정ID
                'account_nm',                     # 계정명
                'thstrm_amount',                  # 당기금액
                'ord'                             # 계정과목 정렬순서
            ]
            data = {}
            for col in col_list:
                data[col] = [k.get_text().strip() for k in soup.find_all(col)]
            data = pd.DataFrame(data, columns = col_list)
            kor_fs = kor_fs.append(data, ignore_index=True)

            print("%d/%d %s %d년 다운로드 성공" %(i, n, name, year))

        except:

            print("%d/%d %s %d년 다운로드 실패" %(i, n, name, year))
            fail_ticker.append(name+'_'+year)
            pass

print(fail_ticker)

kor_fs[kor_fs.columns[:8]] =kor_fs[kor_fs.columns[:8]].apply(lambda x : x.astype('str'))
kor_fs[kor_fs.columns[8:]] =kor_fs[kor_fs.columns[8:]].apply(pd.to_numeric)
kor_fs.drop_duplicates(keep='first', inplace=True)

con = sqlite3.connect(path + 'kor_stock.db')
kor_fs.to_sql(
    'kor_fs', con,
    if_exists='replace',
    index=False,
    chunksize=1000,
    dtype={
        'rcept_no' : 'TEXT',     
        'reprt_code' : 'TEXT',   
        'bsns_year' : 'TEXT',    
        'corp_code' : 'TEXT',    
        'sj_div' : 'TEXT',       
        'sj_nm' : 'TEXT',        
        'account_id' : 'TEXT',   
        'account_nm' : 'TEXT',   
        'thstrm_amount' : 'INTEGER',
        'ord' : 'INTEGER'           
    }
)
con.close()
