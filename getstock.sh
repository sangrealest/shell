#!/usr/bin/python

import requests
import time
import re
import sys

colors = {
    'grey': '1;30',
    'red': '0;31',
    'green': '0;32',
    'yellow': '1;33',
}


def parse_stock_data(stock_str):
    if not stock_str:
        return None
    sdata = stock_str.split(',') 
    sname = ['name', 'open', 'close_yesterday', 'now', 'high', 'low', 'buy', 'sell', 'amount', 'volumn',
             'buy1-amount', 'buy1-price', 'buy2-amount', 'buy2-price', 'buy3-amount', 'buy3-price',
             'buy4-amount', 'buy4-price', 'buy5-amount', 'buy5-price',
             'sell1-amount', 'sell1-price', 'sell2-amount', 'sell2-price', 'sell3-amount', 'sell3-price',
             'sell4-amount', 'sell4-price', 'sell5-amount', 'sell5-price',
             'date', 'time']
    return dict(zip(sname, sdata))


def get_stock(stockid):
    if isinstance(stockid, list):
        stockid = ','.join(stockid)     #put the stockid string connected with ','
    url = 'http://hq.sinajs.cn/list=' + stockid
    r = requests.get(url)
    if r.status_code != 200:
        return []
    results = []
    for s in r.text.split('\n'):
        s = s.strip()       #delete the \n \t \r ' ' in s string
        if not s:
            continue
        content = s.split('"')
        sre = re.match(r'^var +hq_str_(\w+)=$', content[0].strip())
        sid = sre.group(1)
        sval = parse_stock_data(content[1].strip())
        results.append((sid, sval))
    return results


'''

Output examples:
var hq_str_sz002407="DFD,75.89,75.70,76.30,77.07,74.51,76.30,76.35,6979435,527858897.52,4500,76.30,300,76.11,21200,76.10,600,76.05,1850,76.02,1,76.35,2400,76.36,1400,76.37,100,76.38,1800,76.39,2015-12-22,10:22:46,00";
var hq_str_sz300085="YZJ,64.990,64.160,68.030,69.000,64.990,68.040,68.080,13712701,922183925.360,600,68.040,1500,67.950,2000,67.940,15338,67.930,7200,67.900,1500,68.080,10394,68.100,18300,68.150,4300,68.180,3100,68.190,2015-12-22,10:22:46,00";

'''

def print_stock(stock_data, color=True):
    for sid, sval in stock_data:
        if sval is None:
            val_str = sid
            color_code = colors['grey']
        else:
            change = float(sval['now']) - float(sval['close_yesterday'])
            percent = 100 * change / float(sval['close_yesterday'])
            val_str = '%s %-8s %7.2f %6.3f%% %-8s %-8s  %-8s %s %s' %(sid,
                sval['now'], change, percent,
                sval['open'], sval['high'], sval['low'],
                sval['time'], sval['name'])
            if change > 0:
                color_code = colors['red']
            elif change < 0:
                color_code = colors['green']
            else:
                color_code = colors['yellow']
        if color:
            print('\033[%sm %s \033[0m' %(color_code, val_str))
        else:
            print(val_str)
    print('')

if __name__ == "__main__":

    while True:
        try:
            if len(sys.argv) == 1:
                sys.exit('No any stock,example:stock_check sz002407 sh600804 !')
            r = get_stock(sys.argv[1:])
            print_stock(r)
        finally:
            pass
        time.sleep(3)
