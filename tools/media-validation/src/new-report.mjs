import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadProfiles } from "./core.mjs";

function valueAfter(flag) {
  const index = process.argv.indexOf(flag);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

const platform = valueAfter("--platform");
const profileId = valueAfter("--profile") ?? "balanced";
const model = valueAfter("--model") ?? "TODO";
const osVersion = valueAfter("--os") ?? "TODO";

if (!platform || !["ios", "android"].includes(platform)) {
  throw new Error("Use --platform ios or --platform android");
}

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const toolDirectory = path.resolve(currentDirectory, "..");
const profiles = await loadProfiles(path.join(toolDirectory, "profiles.json"));
const profile = profiles.find((candidate) => candidate.id === profileId);
if (!profile) {
  throw new Error(`Unknown profile: ${profileId}`);
}

const reportId = `${platform}-minimum-${profileId}-${Date.now()}`;
const report = {
  schemaVersion: 1,
  reportId,
  profileId,
  device: {
    platform,
    tier: "minimum",
    model,
    osVersion,
    physicalMemoryMb: null,
  },
  quality: {
    photo: "original",
    video: "1080p-balanced",
  },
  workload: { ...profile.limits },
  operations: {
    importCompleted: false,
    encryptCompleted: false,
    reopenCompleted: false,
    feedCompleted: false,
    editCompleted: false,
    shareCompleted: false,
    backupCompleted: false,
    restoreCompleted: false,
    integrityMatched: false,
  },
  safety: {
    crashed: null,
    outOfMemory: null,
    plaintextTempFilesAfterRun: null,
    orphanFilesAfterCancel: null,
    lowStoragePreflightPassed: false,
    cancelCleanupPassed: false,
  },
  ux: {
    longTasksBackgrounded: false,
    progressVisible: false,
    cancelAvailable: false,
    inputResponsive: false,
    feedUsesThumbnails: false,
    storageEstimateShown: false,
    maxConcurrentOriginalDecryptions: null,
  },
  measurements: {
    importMs: null,
    encryptMs: null,
    backupMs: null,
    restoreMs: null,
    peakMemoryMb: null,
    outputBytes: null,
    batteryDeltaPercent: null,
    maxThermalState: null,
  },
  notes: [],
};

const reportsDirectory = path.join(toolDirectory, "reports");
await mkdir(reportsDirectory, { recursive: true });
const outputPath = path.join(reportsDirectory, `${reportId}.json`);
await writeFile(outputPath, `${JSON.stringify(report, null, 2)}\n`, "utf8");
console.log(outputPath);
