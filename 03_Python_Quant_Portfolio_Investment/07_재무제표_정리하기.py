# %%
import os
import pandas as pd
import sqlite3

# %%
path = os.getcwd() + '\\quant investment\\data\\'
kor_ticker = pd.read_csv(
    path + 'kor_ticker.csv',
    dtype={'종목코드' : 'str'}
)

# %%
fs_df = pd.DataFrame()
for ticker in kor_ticker.종목코드:
    select_fs = pd.read_csv(
        path + '\\kor_fs\\' + ticker + '_fs.csv'
    )
    select_fs.rename(
        columns={select_fs.columns[0]: 'coa'},
        inplace=True
    )
    select_fs = select_fs.melt(
        id_vars='coa',
        value_vars=select_fs.columns[1:],
        var_name='date',
        value_name='fs_value'
    )
    select_fs['ticker'] = ticker
    select_fs = select_fs[['ticker', 'date', 'coa', 'fs_value']]
    fs_df = fs_df.append(select_fs, ignore_index=True)

# %%
fs_df.fs_value = pd.to_numeric(
    fs_df.fs_value.astype('str').str.replace(',', ''),
    errors='coerce'
)
con = sqlite3.connect(path + 'kor_stock.db')
fs_df.to_sql(
    'kor_fs', con,
    if_exists='replace',
    index=False,
    chunksize=1000,
    dtype={
        'ticker': 'text',
        'date': 'text',
        'coa': 'text',
        'fs_value': 'int'
    }
)
con.close()
