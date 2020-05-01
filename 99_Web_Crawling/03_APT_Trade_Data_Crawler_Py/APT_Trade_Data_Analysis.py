#%%
import os
import sys
import datetime
import numpy as np
import pandas as pd
from plotnine import *
from mizani.breaks import date_breaks
from mizani.formatters import date_format, comma_format

#%%
file_path = os.path.join(os.getcwd(), '03_APT_Trade_Data_Crawler_Py\\file\\')
module_path = os.path.join(os.getcwd(), '03_APT_Trade_Data_Crawler_Py\\')
sys.path.append(module_path)
from APT_Trade_Data_Crawler import *

#%%
# 실거래가 데이터 업데이트
# 기존 데이터에 추가 다운로드 받은 자료를 업데이트하여 apt_trade_data(누적).csv로 저장
# 추가 다운로드 받은 자료 중 기존 데이터에 없던 거래를 apt_trade_data(신규).csv로 저장

last_df = pd.read_csv(file_path + 'apt_trade_data(누적).csv', encoding='euc-kr', dtype='str')
gu_code_data = pd.read_csv(file_path + 'gu_code_data.csv', encoding='euc-kr')
gu_code = gu_code_data['코드']
result_df = pd.DataFrame()
for gu in gu_code:
    df = getAptTradeData(gu, 201901, 201907)    # 추가로 다운로드 받을 기간 설정
    result_df = result_df.append(df, ignore_index=True)
result_df = pd.concat([last_df, result_df], ignore_index=True)
result_df.drop_duplicates(keep='first', inplace=True)
result_df.to_csv(file_path + 'apt_trade_data(누적).csv', index=False, encoding='euc-kr')
update_df = pd.concat([last_df, result_df], ignore_index=True)
update_df.drop_duplicates(keep=False, inplace=True)
update_df.to_csv(file_path + 'apt_trade_data(신규).csv', index=False, encoding='euc-kr')

#%%
# 구별로 월간 거래금액 총액 흐름을 분석하기 위한 데이터 정리

result_df = pd.read_csv(file_path + 'apt_trade_data(누적).csv', encoding='euc-kr', dtype='str')
result_df['거래금액'] = result_df['거래금액'].str.replace('[\s,]', '', regex=True)
result_df['거래금액'] = pd.to_numeric(result_df['거래금액'])
result_df['도로명시군구코드'] = pd.to_numeric(result_df['도로명시군구코드'], downcast='integer')
result_df = pd.merge(left=result_df, 
                     right=gu_code_data, 
                     left_on='도로명시군구코드', 
                     right_on='코드').drop('코드', axis=1)
result_df['년월'] = result_df['년'] + result_df['월']
result_df['년월'] = result_df['년월'].map(lambda x : datetime.datetime.strptime(x, '%Y%m'))

chart_df = result_df.groupby(['년월', '구'])['거래금액'].agg('sum')
chart_df = chart_df.reset_index()
chart_df['거래금액'] = chart_df['거래금액'] * 0.0001
chart_df = chart_df.query('년월 != "2019-07-01"')   # 19년 6월 실거래가 아직 일부만 반영되어 제외

#%%
# 그래프 그리기

(ggplot(data=chart_df, mapping=aes(x = '년월', y = '거래금액', color='구'))
 + geom_line()
 + scale_x_datetime(breaks=date_breaks('6 months'), labels=date_format('%Y%m'))
 + scale_y_continuous(breaks=list(range(0, 20000, 2500)),labels = comma_format())
 + labs(x='기간', y='거래금액 (단위:억원)', color='')
 + theme(text=element_text(family='Malgun Gothic'))
)

#%%
# 피벗 돌려서 파일로 저장하기

trade_vol_df = chart_df.pivot(index='년월', columns='구', values='거래금액')
trade_vol_df.to_csv(file_path + 'apt_trade_vol_data.csv', encoding='euc-kr')
