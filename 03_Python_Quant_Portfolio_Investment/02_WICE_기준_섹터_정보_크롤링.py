# %%
import requests
import pandas as pd
import os

# %%
sector_code = ['G25', 'G35', 'G50', 'G40', 'G10', 'G20', 'G55', 'G30', 'G15', 'G45']
data_sector = pd.DataFrame()

for code in sector_code:
    url = 'http://www.wiseindex.com/Index/GetIndexComponets'
    params = {
    'ceil_yn': 0,
    'dt': '20191118',
    'sec_cd': code
    }
    response = requests.get(url, params)
    data = pd.DataFrame(response.json()['list'])
    data_sector = data_sector.append(data, ignore_index=True)

# %%
path = os.path.join(
    os.getcwd(), 
    'quant investment\\data\\'
)
data_sector.to_csv(path + 'kor_sector.csv', index=False)
