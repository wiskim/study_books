#%%
import os
import pandas as pd
import numpy as np
import sqlite3

path = os.getcwd() + '\\quant investment\\data\\'

kor_mcap = pd.read_csv(
    path + 'kor_mcap.csv',
    dtype={'ticker' : 'str'}
)

con = sqlite3.connect(path + 'kor_stock.db')
kor_fs = pd.read_sql(
    "SELECT * FROM kor_fs", con, index_col=None
)
con.close()

last_fy = '2018/12'
select_coa = [
    '당기순이익',
    '자본',
    '영업활동으로인한현금흐름',
    '매출액'
]

kor_value = kor_fs.loc[
    (kor_fs.date == last_fy) & (kor_fs.coa.isin(select_coa)), :
]
kor_value = kor_value.groupby(['ticker', 'coa'])['fs_value'].agg('sum')
kor_value = kor_value.unstack()
kor_value = pd.merge(
    kor_mcap, kor_value,
    on='ticker'
)

kor_value['per'] = (kor_value['market_cap'] / kor_value['당기순이익']).round(2)
kor_value['pbr'] = (kor_value['market_cap'] / kor_value['자본']).round(2)
kor_value['pcr'] = (kor_value['market_cap'] / kor_value['영업활동으로인한현금흐름']).round(2)
kor_value['psr'] = (kor_value['market_cap'] / kor_value['매출액']).round(2)

kor_value = kor_value[['ticker', 'per', 'pbr', 'pcr', 'psr']]

kor_value.set_index('ticker', drop=True, inplace=True)

kor_value = kor_value.apply(lambda x: np.where(x<=0, 0, x))
kor_value = kor_value.apply(lambda x: np.where(x == np.inf, np.nan, x))

kor_value.to_csv(path + 'kor_value.csv')
