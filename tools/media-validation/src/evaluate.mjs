import path from "node:path";
import { fileURLToPath } from "node:url";
import { evaluateProfiles, loadProfiles, loadReports } from "./core.mjs";

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const toolDirectory = path.resolve(currentDirectory, "..");
const reportsDirectory = path.resolve(process.argv[2] ?? path.join(toolDirectory, "reports"));

const profiles = await loadProfiles(path.join(toolDirectory, "profiles.json"));
const reports = await loadReports(reportsDirectory);
const result = evaluateProfiles(profiles, reports);

console.log(JSON.stringify(result, null, 2));
process.exitCode = result.recommendedProfileId ? 0 : 2;
