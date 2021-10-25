#!/usr/bin/python
from subprocess import call

import sys
import time
from datetime import datetime, timezone
from threading import Thread

def log_err(s):
    print(str(datetime.now(tz=timezone.utc)), s, file=sys.stderr)
    
def current_milli_time():
    return round(time.time() * 1000)

def dispatch_job():
    try:
        print("Current Time =", datetime.now().strftime("%H:%M:%S"))
        call(["node", "dist/upload.js"]) 
    except Exception as e:
        log_err("Dispatched Job Failed")
        log_err(e)

def dispatch_download_cache(max_time, rpm):
    start_time = current_milli_time()
    distance_between_calls_ms = 60000/rpm
    try:
        while (current_milli_time() - start_time) < max_time * 1000:
            c_start_time = current_milli_time()
            call(["node", "dist/download_cache.js"]) 
            if distance_between_calls_ms - (current_milli_time() - c_start_time) > 0:
                print("sleeping for seconds:"+ (distance_between_calls_ms - (current_milli_time() - c_start_time) ) / 1000)
                time.sleep((distance_between_calls_ms - (current_milli_time() - c_start_time) ) / 1000)
            
    except Exception as e:
        log_err("Dispatched dispatch_download_cache Job Failed")
        log_err(e)

start_time = time.time()
jobs_per_min = 2
interval_s = (1/jobs_per_min)*60
max_time = 120 
download_cache_thread = Thread(target=dispatch_download_cache, args=(max_time, 150))
download_cache_thread.start()

while (time.time() - start_time) < max_time:
    for x in range(0, 2):
        if (time.time() - start_time) < max_time:
            t = Thread(target=dispatch_job)
            t.start()
            time.sleep(interval_s)
        else:
            print("~Finished stagger load test! *high five* ~")
            break