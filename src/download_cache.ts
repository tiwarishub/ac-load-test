import * as fs from 'fs'
import * as cacheHttpClient from "./cacheHttpClient"
import { config } from "dotenv"
import * as path from 'path'

process.on("uncaughtException", e => logWarning(e.message));

function logWarning(message: string): void {
    const warningPrefix = "[warning]";
    console.log(`${warningPrefix}${message}`);
}

function getRandomLine(filename : string): string | null{
    if(!fs.existsSync(filename)) {
        console.log("File not found");
        return null
      }
    var array = fs.readFileSync(filename, 'utf8').toString().split('\n');
    if(array.length <= 0)
    {
        return null
    }
    var line = array[Math.floor(Math.random()*array.length)]
    return line
  }

async function download_cache(): Promise<void> {
    try {
        const dotEnvPath = path.resolve(__dirname, "../.env");
        config({ path: dotEnvPath });

        const seed_key = process.env.SEED_PRIMARY_KEY || 'randomkey'
        const seed_version = process.env.SEED_VERSION || 'randomversion'

        var saved_cache_result_sample = getRandomLine("/tmp/saved_cache_result")
        var key = seed_key
        var version = seed_version
        if(saved_cache_result_sample) {
            console.log(saved_cache_result_sample)
        }
        else {
            console.log("no data found in saved_cache_result_sample")
        }
        if(saved_cache_result_sample && saved_cache_result_sample.split(",").length == 2) {
            key = saved_cache_result_sample.split(",")[0]
            version = saved_cache_result_sample.split(",")[1]
        }
        cacheHttpClient.getCacheEntry(key, version)
    }
    catch (error) {
        logWarning("an error occured");
        console.log(error)
    }
}

download_cache();

export default download_cache;