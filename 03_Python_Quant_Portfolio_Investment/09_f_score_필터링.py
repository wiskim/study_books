#%%
import os
import pandas as pd
import numpy as np
import sqlite3

path = os.getcwd() + '\\quant investment\\data\\'

con = sqlite3.connect(path + 'kor_stock.db')
kor_fs = pd.read_sql(
    "SELECT * FROM kor_fs", con, index_col=None
)
con.close()

select_fy = [
    '2017/12',
    '2018/12'
]
select_coa = [
    '당기순이익',
    '자산',
    '영업활동으로인한현금흐름',
    '장기차입금',
    '유동자산',
    '유동부채',
    '유상증자',
    '매출총이익',
    '매출액'
]

kor_fscore = kor_fs.loc[
    (kor_fs.date.isin(select_fy)) & (kor_fs.coa.isin(select_coa)), :
]
kor_fscore = kor_fscore.pivot_table(
    index=['ticker', 'date'], 
    columns='coa', 
    values='fs_value'
)

# 수익성
kor_fscore['roa'] = kor_fscore['당기순이익'] / kor_fscore['자산']
kor_fscore['cfo'] = kor_fscore['영업활동으로인한현금흐름'] / kor_fscore['자산']
kor_fscore['accrual'] = kor_fscore['cfo'] - kor_fscore['roa']

# 재무성과
kor_fscore['lev'] = kor_fscore['장기차입금'] / kor_fscore['자산']
kor_fscore['liq'] = kor_fscore['유동자산'] / kor_fscore['유동부채']
kor_fscore['offer'] = kor_fscore['유상증자']

# 운영효율성
kor_fscore['margin'] = kor_fscore['매출총이익'] / kor_fscore['매출액']
kor_fscore['turn'] = kor_fscore['매출액'] / kor_fscore['자산']

kor_fscore = kor_fscore[
    ['roa', 'cfo', 'accrual', 'lev', 'liq', 'offer', 'margin', 'turn']
]

kor_fscore = kor_fscore.unstack()

kor_fscore['f_1'] = np.where(
    kor_fscore.loc[:, ('roa', '2018/12')] > 0, 1, 0
)
kor_fscore['f_2'] = np.where(
    kor_fscore.loc[:, ('cfo', '2018/12')] > 0, 1, 0
)
kor_fscore['f_3'] = np.where(
    kor_fscore.loc[:, ('roa', '2018/12')] 
    - kor_fscore.loc[:, ('roa', '2017/12')] > 0, 1, 0
)
kor_fscore['f_4'] = np.where(
    kor_fscore.loc[:, ('accrual', '2018/12')] > 0, 1, 0
)
kor_fscore['f_5'] = np.where(
    kor_fscore.loc[:, ('lev', '2018/12')] 
    - kor_fscore.loc[:, ('lev', '2017/12')] <= 0, 1, 0
)
kor_fscore['f_6'] = np.where(
    kor_fscore.loc[:, ('liq', '2018/12')] 
    - kor_fscore.loc[:, ('liq', '2017/12')] > 0, 1, 0
)
kor_fscore['f_7'] = np.where(
    (
        (kor_fscore.loc[:, ('offer', '2018/12')].isna()) | 
        (kor_fscore.loc[:, ('offer', '2018/12')] <= 0)
    ), 
    1, 0
)
kor_fscore['f_8'] = np.where(
    kor_fscore.loc[:, ('margin', '2018/12')] 
    - kor_fscore.loc[:, ('margin', '2017/12')] > 0, 1, 0
)
kor_fscore['f_9'] = np.where(
    kor_fscore.loc[:, ('turn', '2018/12')] 
    - kor_fscore.loc[:, ('turn', '2017/12')] > 0, 1, 0
)
kor_fscore['f_score'] = kor_fscore.loc[:, 'f_1':'f_9'].sum(axis=1)

kor_fscore_filter = kor_fscore.reset_index()
kor_fscore_filter = kor_fscore_filter.melt(id_vars='ticker')
kor_fscore_filter = kor_fscore_filter.loc[
    kor_fscore_filter.coa == 'f_score', 
    ['ticker', 'value']
]
kor_fscore_filter.rename(columns={'value': 'f_score'}, inplace=True)
kor_fscore_filter.sort_values('f_score', ascending=False, inplace=True)
kor_fscore_filter = kor_fscore_filter.reset_index(drop=True)


kor_ticker = pd.read_csv(
    path + 'kor_ticker.csv',
    dtype={'종목코드' : 'str'}
)

kor_fscore_filter = pd.merge(
    kor_fscore_filter,
    kor_ticker[['종목코드', '종목명']],
    left_on='ticker',
    right_on='종목코드'
)

kor_fscore_filter = kor_fscore_filter[['종목코드', '종목명', 'f_score']]
