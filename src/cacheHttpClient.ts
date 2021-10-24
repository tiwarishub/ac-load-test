import {HttpClient} from '@actions/http-client'
import {BearerCredentialHandler} from '@actions/http-client/auth'
import {IRequestOptions, ITypedResponse} from '@actions/http-client/interfaces'
import * as crypto from 'crypto'
import {CompressionMethod, DefaultRetryDelay, DefaultRetryAttempts} from './constants'
import * as utils from './cacheUtils'
import * as fs from 'fs'
import {
    InternalCacheOptions,
    CommitCacheRequest,
    ReserveCacheRequest,
    ReserveCacheResponse
  } from './contracts'

import {
isSuccessStatusCode,
retryHttpClientResponse,
retryTypedResponse
} from './requestUtils'

const versionSalt = '1.0'

function getCacheApiUrl(resource: string): string {
  // Ideally we just use ACTIONS_CACHE_URL
  const baseUrl: string = process.env['ACTIONS_CACHE_URL'] || ''
  if (!baseUrl) {
    throw new Error('Cache Service Url not found, unable to get CacheApiUrl.')
  }

  const url = `${baseUrl}_apis/artifactcache/${resource}`
  console.log(`Resource Url: ${url}`)
  return url
}

function createAcceptHeader(type: string, apiVersion: string): string {
  return `${type};api-version=${apiVersion}`
}

function getRequestOptions(): IRequestOptions {
  const requestOptions: IRequestOptions = {
    headers: {
      Accept: createAcceptHeader('application/json', '6.0-preview.1')
    }
  }

  return requestOptions
}

function createHttpClient(): HttpClient {
  const token = process.env.ACTIONS_RUNTIME_TOKEN || ''
  if (!token) {
    throw new Error('ACTIONS_RUNTIME_TOKEN not found, unable to creat HttpClient .')
  }
  const bearerCredentialHandler = new BearerCredentialHandler(token)

  return new HttpClient(
    'actions/cache',
    [bearerCredentialHandler],
    getRequestOptions()
  )
}

export function getCacheVersion(
  paths: string[],
  compressionMethod?: CompressionMethod
): string {
  const components = paths.concat(
    !compressionMethod || compressionMethod === CompressionMethod.Gzip
      ? []
      : [compressionMethod]
  )

  // Add salt to cache version to support breaking changes in cache entry
  components.push(versionSalt)

  return crypto
    .createHash('sha256')
    .update(components.join('|'))
    .digest('hex')
}
// Reserve Cache
export async function reserveCache(
  key: string,
  paths: string[],
  options?: InternalCacheOptions
): Promise<number> {
  const httpClient = createHttpClient()
  const version = getCacheVersion(paths, options?.compressionMethod)

  const reserveCacheRequest: ReserveCacheRequest = {
    key,
    version
  }
  console.log("key="+key+", version="+version)
  const response = await retryTypedResponse('reserveCache', async () =>
    httpClient.postJson<ReserveCacheResponse>(
      getCacheApiUrl('caches'),
      reserveCacheRequest
    )
  )
  return response?.result?.cacheId ?? -1
}

function getContentRange(start: number, end: number): string {
  // Format: `bytes start-end/filesize
  // start and end are inclusive
  // filesize can be *
  // For a 200 byte chunk starting at byte 0:
  // Content-Range: bytes 0-199/*
  return `bytes ${start}-${end}/*`
}

async function uploadChunk(
  httpClient: HttpClient,
  resourceUrl: string,
  openStream: () => NodeJS.ReadableStream,
  start: number,
  end: number
): Promise<void> {
  console.log(
    `Uploading chunk of size ${end -
      start +
      1} bytes at offset ${start} with content range: ${getContentRange(
      start,
      end
    )}`
  )
  const additionalHeaders = {
    'Content-Type': 'application/octet-stream',
    'Content-Range': getContentRange(start, end)
  }

  const uploadChunkResponse = await retryHttpClientResponse(
    `uploadChunk (start: ${start}, end: ${end})`,
    async () =>
      httpClient.sendStream(
        'PATCH',
        resourceUrl,
        openStream(),
        additionalHeaders
      )
  )

  if (!isSuccessStatusCode(uploadChunkResponse.message.statusCode)) {
    throw new Error(
      `Cache service responded with ${uploadChunkResponse.message.statusCode} during upload chunk.`
    )
  }
}

async function uploadFile(
  httpClient: HttpClient,
  cacheId: number,
  archivePath: string,
): Promise<void> {
  // Upload Chunks
  console.log("archivePath="+archivePath)
  const fileSize = utils.getArchiveFileSizeInBytes(archivePath)
  const resourceUrl = getCacheApiUrl(`caches/${cacheId.toString()}`)
  const fd = fs.openSync(archivePath, 'r')
  console.log("fileSize="+fileSize)
  
  const concurrency = 4
  const maxChunkSize = 32 * 1024 * 1024

  const parallelUploads = [...new Array(concurrency).keys()]
  console.log('Awaiting all uploads')
  let offset = 0

  try {
    await Promise.all(
      parallelUploads.map(async () => {
        while (offset < fileSize) {
          const chunkSize = Math.min(fileSize - offset, maxChunkSize)
          const start = offset
          const end = offset + chunkSize - 1
          offset += maxChunkSize

          await uploadChunk(
            httpClient,
            resourceUrl,
            () =>
              fs
                .createReadStream(archivePath, {
                  fd,
                  start,
                  end,
                  autoClose: false
                })
                .on('error', error => {
                  throw new Error(
                    `Cache upload failed because file read failed with ${error.message}`
                  )
                }),
            start,
            end
          )
        }
      })
    )
  } finally {
    fs.closeSync(fd)
  }
  return
}

async function commitCache(
  httpClient: HttpClient,
  cacheId: number,
  filesize: number
): Promise<ITypedResponse<null>> {
  const commitCacheRequest: CommitCacheRequest = {size: filesize}
  return await retryTypedResponse('commitCache', async () =>
    httpClient.postJson<null>(
      getCacheApiUrl(`caches/${cacheId.toString()}`),
      commitCacheRequest
    )
  )
}

export async function saveCache(
  cacheId: number,
  archivePath: string,
): Promise<void> {
  const httpClient = createHttpClient()

  console.log('Upload cache')
  await uploadFile(httpClient, cacheId, archivePath)

  // Commit Cache
  console.log('Commiting cache')
  const cacheSize = utils.getArchiveFileSizeInBytes(archivePath)
  console.log(
    `Cache Size: ~${Math.round(cacheSize / (1024 * 1024))} MB (${cacheSize} B)`
  )

  const commitCacheResponse = await commitCache(httpClient, cacheId, cacheSize)
  if (!isSuccessStatusCode(commitCacheResponse.statusCode)) {
    throw new Error(
      `Cache service responded with ${commitCacheResponse.statusCode} during commit cache.`
    )
  }

  console.log('Cache saved successfully')
}