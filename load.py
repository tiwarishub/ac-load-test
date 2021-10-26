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

def distpatch_download_cache():
    try:
        call(["node", "dist/download_cache.js"]) 
    except Exception as e:
        log_err("distpatch_download_cache Failed")
        log_err(e)

def start_download_cache(max_time, rpm):
    start_time = time.time()
    interval_s = (1/rpm)*60
    while (time.time() - start_time) < max_time:
        if (time.time() - start_time) < max_time:
                t = Thread(target=distpatch_download_cache)
                t.start()
                time.sleep(interval_s)
        else:
            print("~Finished stagger load test! *high five* ~")
            break

start_time = time.time()
jobs_per_min = 2
interval_s = (1/jobs_per_min)*60
max_time = 120 
download_cache_thread = Thread(target=start_download_cache, args=(max_time, 300))
download_cache_thread.start()

while (time.time() - start_time) < max_time:
    if (time.time() - start_time) < max_time:
            t = Thread(target=dispatch_job)
            t.start()
            time.sleep(interval_s)
    else:
        print("~Finished stagger load test! *high five* ~")
        break
        