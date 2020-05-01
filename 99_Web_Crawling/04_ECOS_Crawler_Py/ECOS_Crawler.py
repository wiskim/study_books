#%%
import pandas as pd
import urllib.request as req
import json
from datetime import datetime
from dateutil.relativedelta import relativedelta
import matplotlib.pyplot as plt

#%%
pd.options.display.float_format = '{:.4f}'.format

_api_key = '8UZQEG5IXJSEFP9N0C48'

#%%
class Ecos_Item:

    def __init__(self, item_name):
        url = str('http://ecos.bok.or.kr/api/StatisticItemList/'
                  + _api_key
                  + '/json/kr/1/50/901Y001/')
        res = req.urlopen(url)
        js = res.read().decode('utf-8')
        dic = json.loads(js)
        df = pd.DataFrame(dic['StatisticItemList']['row'])
        df = df.loc[df['ITEM_NAME'] == item_name]
        self.item_code = df['ITEM_CODE'].iloc[0]

    def get_data(self, start='', end='', cycle='MM', num='60'):
        if start == '':
            start = (datetime.today() - relativedelta(months=60)).strftime('%Y%m')
        if end == '':
            end = datetime.today().strftime('%Y%m')
        url = str('http://ecos.bok.or.kr/api/StatisticSearch/'
                  + _api_key
                  + '/json/kr/1/'
                  + num
                  + '/901Y001/'
                  + cycle + '/'
                  + start + '/'
                  + end + '/'
                  + self.item_code
                  + '/?/?/')
        res = req.urlopen(url)
        js = res.read().decode('utf-8')
        dic = json.loads(js)
        df = pd.DataFrame(dic['StatisticSearch']['row'])
        df = df[['TIME', 'DATA_VALUE']]
        df = df.loc[df['DATA_VALUE'] != '']
        df['DATA_VALUE'] = df['DATA_VALUE'].astype('float')
        if cycle == 'YY':
            df['TIME'] = df['TIME'].apply(lambda x: pd.Period(x, absfreq='A'))
        elif cycle == 'QQ':
            df['TIME'] = df['TIME'].apply(lambda x: pd.Period(str(x[:4] + '-' + x[-1]), freq='Q'))
        elif cycle == 'MM':
            df['TIME'] = df['TIME'].apply(lambda x: pd.Period(str(x[:4] + '-' + x[-2:]), freq='M'))
        elif cycle == 'DD':
            df['TIME'] = df['TIME'].apply(lambda x: datetime.strptime(str(x), '%Y%m%d'))
        df.index = df['TIME']
        df = df[['DATA_VALUE']]
        return df

    def get_chart(self, start='', end='', cycle='MM', num='60'):
        if start == '':
            start = (datetime.today()-relativedelta(months=60)).strftime('%Y%m')
        if end == '':
            end = datetime.today().strftime('%Y%m')
        url = str('http://ecos.bok.or.kr/api/StatisticSearch/'
                  + _api_key
                  + '/json/kr/1/'
                  + num
                  + '/901Y001/'
                  + cycle + '/'
                  + start + '/'
                  + end + '/'
                  + self.item_code
                  + '/?/?/')
        res = req.urlopen(url)
        js = res.read().decode('utf-8')
        dic = json.loads(js)
        df = pd.DataFrame(dic['StatisticSearch']['row'])
        df = df[['TIME', 'DATA_VALUE']]
        df = df.loc[df['DATA_VALUE'] != '']
        df['DATA_VALUE'] = df['DATA_VALUE'].astype('float')
        if cycle == 'YY':
            df['TIME'] = df['TIME'].apply(lambda x: pd.Period(x, freq='A'))
        elif cycle == 'QQ':
            df['TIME'] = df['TIME'].apply(lambda x: pd.Period(str(x[:4] + '-' + x[-1]), freq='Q'))
        elif cycle == 'MM':
            df['TIME'] = df['TIME'].apply(lambda x: pd.Period(str(x[:4] + '-' + x[-2:]), freq='M'))
        elif cycle == 'DD':
            df['TIME'] = df['TIME'].apply(lambda x: datetime.strptime(str(x), '%Y%m%d'))
        df.index = df['TIME']
        df.index = df.index.to_datetime()
        df = df[['DATA_VALUE']]
        plt.plot(df)
        plt.show()


def listing_item():
    url = str('http://ecos.bok.or.kr/api/StatisticItemList/'
              + _api_key
              + '/json/kr/1/50/901Y001/')
    res = req.urlopen(url)
    js = res.read().decode('utf-8')
    dic = json.loads(js)
    df = pd.DataFrame(dic['StatisticItemList']['row'])
    df = df[['ITEM_NAME']]
    return df
