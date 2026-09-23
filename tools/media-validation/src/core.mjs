import { readFile, readdir } from "node:fs/promises";
import path from "node:path";

const REQUIRED_OPERATIONS = [
  "importCompleted",
  "encryptCompleted",
  "reopenCompleted",
  "feedCompleted",
  "editCompleted",
  "shareCompleted",
  "backupCompleted",
  "restoreCompleted",
  "integrityMatched",
];

const REQUIRED_SAFETY_CHECKS = [
  "lowStoragePreflightPassed",
  "cancelCleanupPassed",
];

const REQUIRED_UX_CHECKS = [
  "longTasksBackgrounded",
  "progressVisible",
  "cancelAvailable",
  "inputResponsive",
  "feedUsesThumbnails",
  "storageEstimateShown",
];

export async function readJson(filePath) {
  return JSON.parse(await readFile(filePath, "utf8"));
}

export async function loadProfiles(filePath) {
  const profiles = await readJson(filePath);
  if (!Array.isArray(profiles) || profiles.length === 0) {
    throw new Error("profiles.json must contain at least one profile");
  }

  return profiles.toSorted((a, b) => a.rank - b.rank);
}

export async function loadReports(directoryPath) {
  const entries = await readdir(directoryPath, { withFileTypes: true });
  const reportPaths = entries
    .filter((entry) => entry.isFile() && entry.name.endsWith(".json"))
    .map((entry) => path.join(directoryPath, entry.name));

  return Promise.all(reportPaths.map(readJson));
}

export function evaluateReport(report, profile) {
  const errors = [];
  const warnings = [];

  if (report.schemaVersion !== 1) {
    errors.push("schemaVersion must be 1");
  }

  if (!report.device?.platform || !["ios", "android"].includes(report.device.platform)) {
    errors.push("device.platform must be ios or android");
  }

  if (report.device?.tier !== "minimum") {
    warnings.push("This report does not represent a minimum-tier device");
  }

  if (report.profileId !== profile.id) {
    errors.push(`profileId must be ${profile.id}`);
  }

  const workload = report.workload ?? {};
  for (const [metric, expected] of Object.entries(profile.limits)) {
    const actual = workload[metric];
    if (!Number.isFinite(actual)) {
      errors.push(`workload.${metric} must be a number`);
    } else if (actual < expected) {
      errors.push(`workload.${metric} must exercise at least ${expected}; received ${actual}`);
    }
  }

  for (const operation of REQUIRED_OPERATIONS) {
    if (report.operations?.[operation] !== true) {
      errors.push(`operations.${operation} must be true`);
    }
  }

  if (report.safety?.crashed !== false) {
    errors.push("safety.crashed must be false");
  }
  if (report.safety?.outOfMemory !== false) {
    errors.push("safety.outOfMemory must be false");
  }
  if (report.safety?.plaintextTempFilesAfterRun !== 0) {
    errors.push("safety.plaintextTempFilesAfterRun must be 0");
  }
  if (report.safety?.orphanFilesAfterCancel !== 0) {
    errors.push("safety.orphanFilesAfterCancel must be 0");
  }

  for (const check of REQUIRED_SAFETY_CHECKS) {
    if (report.safety?.[check] !== true) {
      errors.push(`safety.${check} must be true`);
    }
  }

  for (const check of REQUIRED_UX_CHECKS) {
    if (report.ux?.[check] !== true) {
      errors.push(`ux.${check} must be true`);
    }
  }

  const concurrentDecryptions = report.ux?.maxConcurrentOriginalDecryptions;
  if (!Number.isInteger(concurrentDecryptions) || concurrentDecryptions > 1) {
    errors.push("ux.maxConcurrentOriginalDecryptions must be an integer no greater than 1");
  }

  if (!Number.isFinite(report.measurements?.peakMemoryMb)) {
    warnings.push("measurements.peakMemoryMb is missing");
  }
  if (!Number.isFinite(report.measurements?.outputBytes)) {
    warnings.push("measurements.outputBytes is missing");
  }

  return {
    reportId: report.reportId ?? "unknown",
    platform: report.device?.platform ?? "unknown",
    tier: report.device?.tier ?? "unknown",
    profileId: profile.id,
    passed: errors.length === 0,
    errors,
    warnings,
    measurements: report.measurements ?? {},
  };
}

export function evaluateProfiles(profiles, reports) {
  const evaluations = [];
  const requiredPlatforms = ["ios", "android"];

  for (const profile of profiles) {
    const profileReports = reports.filter((report) => report.profileId === profile.id);
    const reportEvaluations = profileReports.map((report) => evaluateReport(report, profile));
    const missingPlatforms = requiredPlatforms.filter(
      (platform) => !profileReports.some(
        (report) => report.device?.platform === platform && report.device?.tier === "minimum",
      ),
    );
    const minimumDeviceEvaluations = reportEvaluations.filter(
      (evaluation) => evaluation.tier === "minimum",
    );

    evaluations.push({
      profileId: profile.id,
      label: profile.label,
      rank: profile.rank,
      passed:
        missingPlatforms.length === 0 &&
        minimumDeviceEvaluations.length >= requiredPlatforms.length &&
        minimumDeviceEvaluations.every((evaluation) => evaluation.passed),
      missingPlatforms,
      reports: reportEvaluations,
    });
  }

  const recommended = evaluations
    .filter((evaluation) => evaluation.passed)
    .toSorted((a, b) => b.rank - a.rank)[0] ?? null;

  return {
    recommendedProfileId: recommended?.profileId ?? null,
    evaluations,
  };
}
