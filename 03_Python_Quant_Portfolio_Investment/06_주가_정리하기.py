# %%
import os
import pandas as pd

# %%
path = os.getcwd() + '\\quant investment\\data\\'
kor_ticker = pd.read_csv(
    path + 'kor_ticker.csv',
    dtype={'종목코드' : 'str'}
)

# %%
price_df = pd.DataFrame()
for ticker in kor_ticker.종목코드:
    select_price = pd.read_csv(
        path + '\\kor_price\\' + ticker + '_price.csv'
    )
    select_price = select_price[['date', 'close']]
    select_price.rename(columns={'close': ticker}, inplace=True)
    select_price.set_index('date', drop=True, inplace=True)
    price_df = pd.concat([price_df, select_price], axis=1, sort=True)

# %%
price_df = price_df.iloc[1:-1, :]
price_df.to_csv(
    path + 'kor_price.csv'
)