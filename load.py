#!/usr/bin/python
from subprocess import call

import sys
import time
from datetime import datetime, timezone
from threading import Thread

def log_err(s):
    print(str(datetime.now(tz=timezone.utc)), s, file=sys.stderr)
    
def dispatch_job():
    try:
        print("Current Time =", datetime.now().strftime("%H:%M:%S"))
        call(["node", "dist/index.js"]) 
    except Exception as e:
        log_err("Dispatched Job Failed")
        log_err(e)

start_time = time.time()
jobs_per_min = 2
interval_s = (1/jobs_per_min)*60
max_time = 120 
while (time.time() - start_time) < max_time:
    for x in range(0, 2):
        if (time.time() - start_time) < max_time:
            t = Thread(target=dispatch_job)
            t.start()
            time.sleep(interval_s)
        else:
            print("~Finished stagger load test! *high five* ~")
            break