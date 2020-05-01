# %%
# DART API를 통해 고유번호 XML 다운로드

import requests, zipfile, os
from io import BytesIO

api_key = 'b557dbf9e8a26cf32e13a5612bb1405b0fc83aca'
url = 'https://opendart.fss.or.kr/api/corpCode.xml'
params = {
    'crtfc_key' : api_key
}
response = requests.get(url, params)
zip_file = zipfile.ZipFile(BytesIO(response.content))

path = os.path.join(
    os.getcwd(), 'quant investment\\data\\'
)

zip_file.extractall(path)

# %%
# 고유번호 XML을 파싱하여 DB에 저장

from bs4 import BeautifulSoup as bs
import pandas as pd
import sqlite3

with open(path + 'CORPCODE.xml', 'rt', encoding='utf-8') as f:
    xml = f.read()
    soup = bs(xml, 'lxml')

col_list = ['corp_code', 'corp_name', 'stock_code', 'modify_date']
data = {}
for col in col_list:
    data[col] = [k.get_text().strip() for k in soup.find_all(col)]

data = pd.DataFrame(data)
data = data[col_list]

con = sqlite3.connect(path + 'kor_stock.db')
data.to_sql(
    'dart_code', con,
    if_exists='replace',
    index=False,
    chunksize=1000,
    dtype={
        'corp_code' : 'TEXT',
        'corp_name' : 'TEXT',
        'stock_code' : 'TEXT',
        'modify_date' : 'TEXT',
    }
)
con.close()
