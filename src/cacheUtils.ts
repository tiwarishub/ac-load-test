import * as fs from 'fs'
import * as exec from '@actions/exec'
import * as util from 'util'
import {CacheFilename, CompressionMethod} from './constants'


export function getArchiveFileSizeInBytes(filePath: string): number {
  return fs.statSync(filePath).size
}


export async function unlinkFile(filePath: fs.PathLike): Promise<void> {
  return util.promisify(fs.unlink)(filePath)
}

async function getVersion(app: string): Promise<string> {
  console.log(`Checking ${app} --version`)
  let versionOutput = ''
  try {
    await exec.exec(`${app} --version`, [], {
      ignoreReturnCode: true,
      silent: true,
      listeners: {
        stdout: (data: Buffer): string => (versionOutput += data.toString()),
        stderr: (data: Buffer): string => (versionOutput += data.toString())
      }
    })
  } catch (err) {
    console.log(err)
  }

  versionOutput = versionOutput.trim()
  console.log(versionOutput)
  return versionOutput
}

// Use zstandard if possible to maximize cache performance
export async function getCompressionMethod(): Promise<CompressionMethod> {
  return CompressionMethod.Gzip
}

export function getCacheFileName(compressionMethod: CompressionMethod): string {
  return compressionMethod === CompressionMethod.Gzip
    ? CacheFilename.Gzip
    : CacheFilename.Zstd
}

export async function isGnuTarInstalled(): Promise<boolean> {
  const versionOutput = await getVersion('tar')
  return versionOutput.toLowerCase().includes('gnu tar')
}

export function assertDefined<T>(name: string, value?: T): T {
  if (value === undefined) {
    throw Error(`Expected ${name} but value was undefiend`)
  }

  return value
}