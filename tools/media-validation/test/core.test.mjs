import assert from "node:assert/strict";
import test from "node:test";
import { evaluateProfiles, evaluateReport } from "../src/core.mjs";

const balancedProfile = {
  id: "balanced",
  label: "균형",
  rank: 2,
  limits: {
    totalMedia: 10,
    videos: 3,
    longestVideoSeconds: 30,
    totalVideoSeconds: 60,
    totalInputBytes: 314572800,
  },
};

function passingReport(platform) {
  return {
    schemaVersion: 1,
    reportId: `${platform}-balanced`,
    profileId: "balanced",
    device: { platform, tier: "minimum" },
    workload: { ...balancedProfile.limits },
    operations: {
      importCompleted: true,
      encryptCompleted: true,
      reopenCompleted: true,
      feedCompleted: true,
      editCompleted: true,
      shareCompleted: true,
      backupCompleted: true,
      restoreCompleted: true,
      integrityMatched: true,
    },
    safety: {
      crashed: false,
      outOfMemory: false,
      plaintextTempFilesAfterRun: 0,
      orphanFilesAfterCancel: 0,
      lowStoragePreflightPassed: true,
      cancelCleanupPassed: true,
    },
    ux: {
      longTasksBackgrounded: true,
      progressVisible: true,
      cancelAvailable: true,
      inputResponsive: true,
      feedUsesThumbnails: true,
      storageEstimateShown: true,
      maxConcurrentOriginalDecryptions: 1,
    },
    measurements: { peakMemoryMb: 512, outputBytes: 200000000 },
  };
}

test("a complete report passes", () => {
  const result = evaluateReport(passingReport("android"), balancedProfile);
  assert.equal(result.passed, true);
  assert.deepEqual(result.errors, []);
});

test("plaintext leftovers fail a report", () => {
  const report = passingReport("android");
  report.safety.plaintextTempFilesAfterRun = 1;
  const result = evaluateReport(report, balancedProfile);
  assert.equal(result.passed, false);
  assert.match(result.errors.join("\n"), /plaintextTempFilesAfterRun/);
});

test("both minimum platforms are required for a recommendation", () => {
  const missingIos = evaluateProfiles([balancedProfile], [passingReport("android")]);
  assert.equal(missingIos.recommendedProfileId, null);
  assert.deepEqual(missingIos.evaluations[0].missingPlatforms, ["ios"]);

  const complete = evaluateProfiles(
    [balancedProfile],
    [passingReport("android"), passingReport("ios")],
  );
  assert.equal(complete.recommendedProfileId, "balanced");
});
