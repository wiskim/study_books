#%%
import os
import time
import datetime
import urllib.request
from bs4 import BeautifulSoup
import numpy as np
import pandas as pd
from plotnine import *

#%%
service_key = '5rME4JUT4tms4%2FKdTGkj6Cv25hq6hEGWJskV0nnvkBkjsJAkdEvu5%2FWRqWO4blqBrRFQHvps4cPJiCnbKkIjqQ%3D%3D'
file_path = os.path.join(os.getcwd(), '03_APT_Trade_Data_Crawler_Py\\file\\')
gu_code_data = pd.read_csv(file_path + 'gu_code_data.csv', encoding='euc-kr')
gu_code = gu_code_data['코드']

#%%
def getRequestUrl(url):
    req = urllib.request.Request(url)
    try:
        response = urllib.request.urlopen(req)
        if response.getcode() == 200:
            print("[%s] Url Request Success" % datetime.datetime.now())
            soup = BeautifulSoup(response, 'xml')
            return soup
    except Exception as e:
        print(e)
        print("[%s] Error for URL : %s" % (datetime.datetime.now(), url))
        return None

def getAptTradeData(gu_code, from_ym, to_ym):
    deal_ym_list = pd.date_range(datetime.datetime.strptime(str(from_ym), '%Y%m'),
                                 datetime.datetime.strptime(str(to_ym), '%Y%m'),
                                 freq='MS').strftime('%Y%m').tolist()                                 
    columns = ['거래금액',
               '건축년도',
               '년',
               '도로명',
               '도로명건물본번호코드',
               '도로명건물부번호코드',
               '도로명시군구코드',
               '도로명일련번호코드',
               '도로명지상지하코드',
               '도로명코드',
               '법정동',
               '법정동본번코드',
               '법정동부번코드',
               '법정동시군구코드',
               '법정동읍면동코드',
               '법정동지번코드',
               '아파트',
               '월',
               '일',
               '일련번호',
               '전용면적',
               '지번',
               '지역코드',
               '층']    
    result_df = pd.DataFrame(columns=columns)
    for deal_ym in deal_ym_list:
        page = 1
        while True:
            end_point = 'http://openapi.molit.go.kr/OpenAPI_ToolInstallPackage/service/rest/RTMSOBJSvc/getRTMSDataSvcAptTradeDev'
            query1 = '?serviceKey=' + service_key
            query1 += '&LAWD_CD=' + str(gu_code)
            query1 += '&DEAL_YMD=' + deal_ym
            query2 = '&pageNo=' + str(page)
            url = end_point + query1 + query2
            soup = getRequestUrl(url)
            if soup != None:
                total_page = round(int(soup.find('totalCount').get_text()) / 10)                  
                for item in soup.find_all('item'):
                    dic = {}
                    for line in item:
                        dic[line.name] = line.get_text()
                    result_df = result_df.append(dic, ignore_index=True)
                page += 1
            else:
                continue
            if page > total_page:
                break
    return result_df
    
def main():
    result_df = pd.DataFrame()
    for gu in gu_code:
        df = getAptTradeData(gu, 201701, 201905)
        result_df = result_df.append(df, ignore_index=True)
        result_df.to_csv(file_path + 'apt_trade_data.csv', index = False, encoding = 'euc-kr')

#%%
if __name__ == '__main__':
    main()
