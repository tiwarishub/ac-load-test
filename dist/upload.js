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
Object.defineProperty(exports, "__esModule", { value: true });
var dotenv_1 = require("dotenv");
var cacheHttpClient = __importStar(require("./cacheHttpClient"));
var utils = __importStar(require("./cacheUtils"));
var path = __importStar(require("path"));
var uuid_1 = require("uuid");
var fs = __importStar(require("fs"));
process.on("uncaughtException", function (e) { return logWarning(e.message); });
function logWarning(message) {
    var warningPrefix = "[warning]";
    console.log("" + warningPrefix + message);
}
function run() {
    return __awaiter(this, void 0, void 0, function () {
        var dotEnvPath, cachePaths, primaryKey, startTime, compressionMethod, cacheId, cache_file, archivePath, endTime, cacheVersion, error_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 4, , 5]);
                    dotEnvPath = path.resolve(__dirname, "../.env");
                    dotenv_1.config({ path: dotEnvPath });
                    cachePaths = ["caches"];
                    primaryKey = "aparna-ravindra-test-" + uuid_1.v4();
                    startTime = new Date().getTime();
                    console.log("Starting cache save for primary key=" + primaryKey + " at " + startTime);
                    return [4 /*yield*/, utils.getCompressionMethod()];
                case 1:
                    compressionMethod = _a.sent();
                    console.log('Reserving Cache');
                    return [4 /*yield*/, cacheHttpClient.reserveCache(primaryKey, cachePaths, {
                            compressionMethod: compressionMethod
                        })];
                case 2:
                    cacheId = _a.sent();
                    console.log("cacheId=" + cacheId);
                    if (cacheId === -1) {
                        console.log("Unable to reserve cache with key " + primaryKey + ", another job may be creating this cache.");
                        return [2 /*return*/];
                    }
                    cache_file = process.env['CACHE_FILE'] || 'caches_5GB.tgz';
                    archivePath = path.join(".", cache_file);
                    return [4 /*yield*/, cacheHttpClient.saveCache(cacheId, archivePath)];
                case 3:
                    _a.sent();
                    endTime = new Date().getTime();
                    console.log("Cache saved with key: " + primaryKey + " at time " + endTime);
                    console.log("Time taken for saving cache key =" + primaryKey + " = " + (endTime - startTime));
                    cacheVersion = cacheHttpClient.getCacheVersion(cachePaths, compressionMethod);
                    fs.appendFileSync("/tmp/saved_cache_result", primaryKey + "," + cacheVersion + "\n");
                    return [3 /*break*/, 5];
                case 4:
                    error_1 = _a.sent();
                    logWarning("an error occured");
                    console.log(error_1);
                    return [3 /*break*/, 5];
                case 5: return [2 /*return*/];
            }
        });
    });
}
run();
exports.default = run;
//# sourceMappingURL=upload.js.map