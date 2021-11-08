"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __read = (this && this.__read) || function (o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
};
var __spread = (this && this.__spread) || function () {
    for (var ar = [], i = 0; i < arguments.length; i++) ar = ar.concat(__read(arguments[i]));
    return ar;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.saveCache = exports.getCacheEntry = exports.reserveCache = exports.getCacheVersion = void 0;
var http_client_1 = require("@actions/http-client");
var auth_1 = require("@actions/http-client/auth");
var crypto = __importStar(require("crypto"));
var constants_1 = require("./constants");
var utils = __importStar(require("./cacheUtils"));
var fs = __importStar(require("fs"));
var requestUtils_1 = require("./requestUtils");
var versionSalt = '1.0';
function getCacheApiUrl(resource) {
    // Ideally we just use ACTIONS_CACHE_URL
    var baseUrl = process.env['ACTIONS_CACHE_URL'] || '';
    if (!baseUrl) {
        throw new Error('Cache Service Url not found, unable to get CacheApiUrl.');
    }
    var url = baseUrl + "_apis/artifactcache/" + resource;
    console.log("Resource Url: " + url);
    return url;
}
function createAcceptHeader(type, apiVersion) {
    return type + ";api-version=" + apiVersion;
}
function getRequestOptions() {
    var requestOptions = {
        headers: {
            Accept: createAcceptHeader('application/json', '6.0-preview.1')
        }
    };
    return requestOptions;
}
function createHttpClient() {
    var token = process.env.ACTIONS_RUNTIME_TOKEN || '';
    if (!token) {
        throw new Error('ACTIONS_RUNTIME_TOKEN not found, unable to creat HttpClient .');
    }
    var bearerCredentialHandler = new auth_1.BearerCredentialHandler(token);
    var userAgent = process.env['USER_AGENT'] || 'actions/cache';
    return new http_client_1.HttpClient(userAgent, [bearerCredentialHandler], getRequestOptions());
}
function getCacheVersion(paths, compressionMethod) {
    var components = paths.concat(!compressionMethod || compressionMethod === constants_1.CompressionMethod.Gzip
        ? []
        : [compressionMethod]);
    // Add salt to cache version to support breaking changes in cache entry
    components.push(versionSalt);
    return crypto
        .createHash('sha256')
        .update(components.join('|'))
        .digest('hex');
}
exports.getCacheVersion = getCacheVersion;
// Reserve Cache
function reserveCache(key, paths, options) {
    var _a, _b;
    return __awaiter(this, void 0, void 0, function () {
        var httpClient, version, reserveCacheRequest, response;
        var _this = this;
        return __generator(this, function (_c) {
            switch (_c.label) {
                case 0:
                    httpClient = createHttpClient();
                    version = getCacheVersion(paths, options === null || options === void 0 ? void 0 : options.compressionMethod);
                    reserveCacheRequest = {
                        key: key,
                        version: version
                    };
                    console.log("key=" + key + ", version=" + version);
                    return [4 /*yield*/, requestUtils_1.retryTypedResponse('reserveCache', function () { return __awaiter(_this, void 0, void 0, function () {
                            return __generator(this, function (_a) {
                                return [2 /*return*/, httpClient.postJson(getCacheApiUrl('caches'), reserveCacheRequest)];
                            });
                        }); })];
                case 1:
                    response = _c.sent();
                    return [2 /*return*/, (_b = (_a = response === null || response === void 0 ? void 0 : response.result) === null || _a === void 0 ? void 0 : _a.cacheId) !== null && _b !== void 0 ? _b : -1];
            }
        });
    });
}
exports.reserveCache = reserveCache;
function getContentRange(start, end) {
    // Format: `bytes start-end/filesize
    // start and end are inclusive
    // filesize can be *
    // For a 200 byte chunk starting at byte 0:
    // Content-Range: bytes 0-199/*
    return "bytes " + start + "-" + end + "/*";
}
function uploadChunk(httpClient, resourceUrl, openStream, start, end) {
    return __awaiter(this, void 0, void 0, function () {
        var additionalHeaders, uploadChunkResponse;
        var _this = this;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    additionalHeaders = {
                        'Content-Type': 'application/octet-stream',
                        'Content-Range': getContentRange(start, end)
                    };
                    return [4 /*yield*/, requestUtils_1.retryHttpClientResponse("uploadChunk (start: " + start + ", end: " + end + ")", function () { return __awaiter(_this, void 0, void 0, function () {
                            return __generator(this, function (_a) {
                                return [2 /*return*/, httpClient.sendStream('PATCH', resourceUrl, openStream(), additionalHeaders)];
                            });
                        }); })];
                case 1:
                    uploadChunkResponse = _a.sent();
                    if (!requestUtils_1.isSuccessStatusCode(uploadChunkResponse.message.statusCode)) {
                        throw new Error("Cache service responded with " + uploadChunkResponse.message.statusCode + " during upload chunk.");
                    }
                    return [2 /*return*/];
            }
        });
    });
}
function uploadFile(httpClient, cacheId, archivePath) {
    return __awaiter(this, void 0, void 0, function () {
        var fileSize, resourceUrl, fd, concurrency, maxChunkSize, parallelUploads, offset;
        var _this = this;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    // Upload Chunks
                    console.log("archivePath=" + archivePath);
                    fileSize = utils.getArchiveFileSizeInBytes(archivePath);
                    resourceUrl = getCacheApiUrl("caches/" + cacheId.toString());
                    fd = fs.openSync(archivePath, 'r');
                    console.log("fileSize=" + fileSize);
                    concurrency = 4;
                    maxChunkSize = 32 * 1024 * 1024;
                    parallelUploads = __spread(new Array(concurrency).keys());
                    console.log('Awaiting all uploads');
                    offset = 0;
                    _a.label = 1;
                case 1:
                    _a.trys.push([1, , 3, 4]);
                    return [4 /*yield*/, Promise.all(parallelUploads.map(function () { return __awaiter(_this, void 0, void 0, function () {
                            var _loop_1;
                            return __generator(this, function (_a) {
                                switch (_a.label) {
                                    case 0:
                                        _loop_1 = function () {
                                            var chunkSize, start, end;
                                            return __generator(this, function (_a) {
                                                switch (_a.label) {
                                                    case 0:
                                                        chunkSize = Math.min(fileSize - offset, maxChunkSize);
                                                        start = offset;
                                                        end = offset + chunkSize - 1;
                                                        offset += maxChunkSize;
                                                        return [4 /*yield*/, uploadChunk(httpClient, resourceUrl, function () {
                                                                return fs
                                                                    .createReadStream(archivePath, {
                                                                    fd: fd,
                                                                    start: start,
                                                                    end: end,
                                                                    autoClose: false
                                                                })
                                                                    .on('error', function (error) {
                                                                    throw new Error("Cache upload failed because file read failed with " + error.message);
                                                                });
                                                            }, start, end)];
                                                    case 1:
                                                        _a.sent();
                                                        return [2 /*return*/];
                                                }
                                            });
                                        };
                                        _a.label = 1;
                                    case 1:
                                        if (!(offset < fileSize)) return [3 /*break*/, 3];
                                        return [5 /*yield**/, _loop_1()];
                                    case 2:
                                        _a.sent();
                                        return [3 /*break*/, 1];
                                    case 3: return [2 /*return*/];
                                }
                            });
                        }); }))];
                case 2:
                    _a.sent();
                    return [3 /*break*/, 4];
                case 3:
                    fs.closeSync(fd);
                    return [7 /*endfinally*/];
                case 4: return [2 /*return*/];
            }
        });
    });
}
function commitCache(httpClient, cacheId, filesize) {
    return __awaiter(this, void 0, void 0, function () {
        var commitCacheRequest;
        var _this = this;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    commitCacheRequest = { size: filesize };
                    return [4 /*yield*/, requestUtils_1.retryTypedResponse('commitCache', function () { return __awaiter(_this, void 0, void 0, function () {
                            return __generator(this, function (_a) {
                                return [2 /*return*/, httpClient.postJson(getCacheApiUrl("caches/" + cacheId.toString()), commitCacheRequest)];
                            });
                        }); })];
                case 1: return [2 /*return*/, _a.sent()];
            }
        });
    });
}
function getCacheEntry(primaryKey, version) {
    return __awaiter(this, void 0, void 0, function () {
        var resource, httpClient, response;
        var _this = this;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    resource = "cache?keys=" + encodeURIComponent(primaryKey) + "&version=" + version;
                    httpClient = createHttpClient();
                    return [4 /*yield*/, requestUtils_1.retryTypedResponse('getCacheEntry', function () { return __awaiter(_this, void 0, void 0, function () { return __generator(this, function (_a) {
                            return [2 /*return*/, httpClient.getJson(getCacheApiUrl(resource))];
                        }); }); })];
                case 1:
                    response = _a.sent();
                    if (!requestUtils_1.isSuccessStatusCode(response.statusCode)) {
                        throw new Error("Cache service responded with " + response.statusCode + " during getCacheEntry for <" + primaryKey + " " + version + ">");
                    }
                    else {
                        console.log(response.statusCode);
                    }
                    return [2 /*return*/];
            }
        });
    });
}
exports.getCacheEntry = getCacheEntry;
function saveCache(cacheId, archivePath) {
    return __awaiter(this, void 0, void 0, function () {
        var httpClient, cacheSize, commitCacheResponse;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    httpClient = createHttpClient();
                    console.log('Upload cache');
                    return [4 /*yield*/, uploadFile(httpClient, cacheId, archivePath)
                        // Commit Cache
                    ];
                case 1:
                    _a.sent();
                    // Commit Cache
                    console.log('Commiting cache');
                    cacheSize = utils.getArchiveFileSizeInBytes(archivePath);
                    console.log("Cache Size: ~" + Math.round(cacheSize / (1024 * 1024)) + " MB (" + cacheSize + " B)");
                    return [4 /*yield*/, commitCache(httpClient, cacheId, cacheSize)];
                case 2:
                    commitCacheResponse = _a.sent();
                    if (!requestUtils_1.isSuccessStatusCode(commitCacheResponse.statusCode)) {
                        throw new Error("Cache service responded with " + commitCacheResponse.statusCode + " during commit cache.");
                    }
                    console.log('Cache saved successfully');
                    return [2 /*return*/];
            }
        });
    });
}
exports.saveCache = saveCache;
//# sourceMappingURL=cacheHttpClient.js.map