import { config } from "dotenv"
import * as cacheHttpClient from "./cacheHttpClient"
import * as utils from "./cacheUtils"
import * as path from 'path'
import { v4 as uuidv4 } from 'uuid';

process.on("uncaughtException", e => logWarning(e.message));

function logWarning(message: string): void {
    const warningPrefix = "[warning]";
    console.log(`${warningPrefix}${message}`);
}

async function run(): Promise<void> {
    try {
        const dotEnvPath = path.resolve(__dirname, "../.env");
        config({ path: dotEnvPath });
        const cachePaths = ["caches"]
        const primaryKey = "aparna-ravindra-test-"+uuidv4()
        const startTime = new Date().getTime()
        console.log("Starting cache save for primary key="+ primaryKey+ " at "+ startTime)
        const compressionMethod = await utils.getCompressionMethod()

        console.log('Reserving Cache')
        const cacheId = await cacheHttpClient.reserveCache(primaryKey, cachePaths, {
            compressionMethod
        })
        console.log("cacheId="+cacheId)
        if (cacheId === -1) {
            console.log(
              `Unable to reserve cache with key ${primaryKey}, another job may be creating this cache.`
            )
            return
        }
        const archivePath = path.join(
            ".",
            "caches.tgz"
          )
        await cacheHttpClient.saveCache(cacheId, archivePath)
        const endTime = new Date().getTime()
        console.log(`Cache saved with key: ${primaryKey} at time ` + endTime );
        console.log("Time taken for saving cache key =" + primaryKey + " = "+ (endTime - startTime))
        
        
    } catch (error) {
        logWarning("an error occured");
        console.log(error)
    }
}
run();

export default run;