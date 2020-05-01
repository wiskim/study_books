#%%
import requests
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np

# %%
def get_round_value(year, mon, day):
    year = str(year)
    mon = str(mon).rjust(2, '0')
    day = str(day).rjust(2, '0')
    url = 'https://okbfex.kbstar.com/quics'
    params = {
    'chgCompId' : 'b028286',
    'baseCompId' : 'b028286',
    'page' : 'C015690',
    'cc' : 'b028286:b028286'
    }
    data = {
        '조회년월일':year+mon+day,
        '등록회차' : '1',
        'selDate' : year+mon+day,
        'strFocusBtn' : '조회',
        'year1' : year,
        'mon1' : mon,
        'day1' : day,
        'se_inqueryRound' : '1'
    }
    response = requests.post(url, params=params, data=data)
    soup = BeautifulSoup(response.content, 'html.parser')
    round_value = soup.find('option')['value']
    return round_value

# %%
def get_exchange_rate(year, mon, day, round_value):
    year = str(year)
    mon = str(mon).rjust(2, '0')
    day = str(day).rjust(2, '0')
    url = 'https://okbfex.kbstar.com/quics'
    params = {
    'chgCompId' : 'b028286',
    'baseCompId' : 'b028286',
    'page' : 'C015690',
    'cc' : 'b028286:b028286'
    }
    data = {
        '조회년월일':year+mon+day,
        '등록회차' : round_value,
        'selDate' : year+mon+day,
        'strFocusBtn' : '조회',
        'year1' : year,
        'mon1' : mon,
        'day1' : day,
        'se_inqueryRound' : round_value
    }
    response = requests.post(url, params=params, data=data)
    soup = BeautifulSoup(response.content, 'html.parser')
    try:
        aud = soup.select('#AllDsp1 > tr:nth-child(7) > td:nth-child(2)')[0].get_text()
        chf = soup.select('#AllDsp1 > tr:nth-child(5) > td:nth-child(2)')[0].get_text()
        cny = soup.select('#AllDsp1 > tr:nth-child(10) > td:nth-child(2)')[0].get_text()
        eur = soup.select('#AllDsp1 > tr:nth-child(3) > td:nth-child(2)')[0].get_text()
        hkd = soup.select('#AllDsp1 > tr:nth-child(9) > td:nth-child(2)')[0].get_text()
        jpy = soup.select('#AllDsp1 > tr:nth-child(2) > td:nth-child(2)')[0].get_text()
        usd = soup.select('#AllDsp1 > tr:nth-child(1) > td:nth-child(2)')[0].get_text()        
    except:
        aud = np.nan
        chf = np.nan
        cny = np.nan
        eur = np.nan
        hkd = np.nan
        jpy = np.nan
        usd = np.nan
    result_dic = {
        'date' : year+mon+day,
        'AUD' : aud,
        'CHF' : chf,
        'CNY' : cny,
        'EUR' : eur,
        'HKD' : hkd,
        'JPY' : jpy,
        'USD' : usd
    }
    return result_dic

#%%
result_list = []
year = 2020
for mon in range(1, 4):
    for day in range(1, 32):
        round_value = get_round_value(year, mon, day)
        result_dic = get_exchange_rate(year, mon, day, round_value)
        result_list.append(result_dic)
        print(str(year)+str(mon).rjust(2, '0')+str(day).rjust(2, '0')+' 완료')
result_df = pd.DataFrame(result_list)
result_df.to_csv(r'c:\Users\ksfc\Downloads\kb_exchange_rate.csv', index=False)
