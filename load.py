#!/usr/bin/python
from subprocess import call
import argparse
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

# Get args
parser = argparse.ArgumentParser()
parser.add_argument("download_cache_thread_rpm", help="GenerateArtifactDownloadV1 API requests per min", type=str)
parser.add_argument("jobs_per_min", help="Upload Jobs to run per minute", type=int)
parser.add_argument("time_to_run_in_minutes", help="Time to run in minutes", type=int)
args = parser.parse_args()

start_time = time.time()
interval_s = (1/args.jobs_per_min)*60
max_time = 60 * args.time_to_run_in_minutes 
download_cache_thread_rpm = float(args.download_cache_thread_rpm)
download_cache_thread = Thread(target=start_download_cache, args=(max_time, download_cache_thread_rpm))
download_cache_thread.start()

while (time.time() - start_time) < max_time:
    if (time.time() - start_time) < max_time:
            t = Thread(target=dispatch_job)
            t.start()
            time.sleep(interval_s)
    else:
        print("~Finished stagger load test! *high five* ~")
        break
        