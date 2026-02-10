#!/usr/bin/env node

import { execSync, spawn } from "child_process";
import { readdirSync, statSync, writeFileSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";

const tasks = new Set<Promise<unknown>>()

// Find repo root by looking for .git directory
function findRepoRoot(startDir: string): string {
  let dir = startDir;
  while (dir !== "/") {
    if (existsSync(join(dir, ".git"))) {
      return dir;
    }
    dir = join(dir, "..");
  }
  throw new Error("Could not find repo root");
}

// Get all directories in a folder
function getDirectories(basePath: string): string[] {
  if (!existsSync(basePath)) return [];
  return readdirSync(basePath).filter((name) => {
    const fullPath = join(basePath, name);
    return statSync(fullPath).isDirectory();
  });
}

type CheckType = "type" | "lint" | "format";

type CheckStatus = "passed" | "failed" | "skipped";

interface CheckResult {
  folder: string;
  checkType: CheckType;
  status: CheckStatus;
  output: string;
}

// ESLint exit code 2 = fatal error (config not found, crash, etc.)
// ESLint exit code 1 = lint errors found
// ESLint exit code 0 = success
const ESLINT_FATAL_EXIT_CODE = 2;

// Patterns that indicate eslint config is missing (fatal, should skip)
const ESLINT_CONFIG_NOT_FOUND_PATTERNS = [
  /could not find config file/i,
  /no eslint configuration found/i,
  /eslint couldn't find a configuration file/i,
  /error: no configuration file found/i,
];

function isEslintConfigMissing(output: string, exitCode: number | null): boolean {
    if(/Command "eslint" not found/i.test(output)) return true

    if (exitCode === ESLINT_FATAL_EXIT_CODE) {
        return ESLINT_CONFIG_NOT_FOUND_PATTERNS.some((pattern) => pattern.test(output));
    }

    return false
}

async function runCheck(folder: string, checkType: CheckType): Promise<CheckResult> {
    while(tasks.size >= 10) {
        await Promise.race(tasks)
    }

  const task = new Promise((resolve) => {
    const args = checkType === "type"
      ? ["exec", "tsc", "--noEmit"]
      : checkType === "format"
      ? ["exec", "prettier", "--check", "."]
      : ["exec", "eslint", "."];

    const child = spawn("pnpm", args, { cwd: folder });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    child.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    child.on("close", (code) => {
      const output = stdout + stderr;

      let status: CheckStatus;
      if (code === 0) {
        status = "passed";
      } else if (checkType === "lint" && isEslintConfigMissing(output, code)) {
        status = "skipped";
      } else {
        status = "failed";
      }

      resolve({
        folder,
        checkType,
        status,
        output: output.trim(),
      });
    });
  }).finally(() => {
        tasks.delete(task)
    });

    tasks.add(task)

    return await task
}

function parseArgs(): CheckType[] {
  const args = process.argv.slice(2);
  if (args.length === 0) return ["type"];

  const checksSet = new Set<CheckType>()
  for (const arg of args) {
    if (arg === "type" || arg === "lint" || arg === "format") {
      checksSet.add(arg);
    } else {
      console.error(`Unknown argument: ${arg}`);
      console.error("Usage: checks.mts [type] [lint] [format]");
      process.exit(1);
    }
  }

  const checks = [];
  if(checksSet.has('type')) checks.push('type');
  if(checksSet.has('lint')) checks.push('lint');
  if(checksSet.has('format')) checks.push('format');

  return checks;
}

async function main() {
  const checkTypes = parseArgs();
  const repoRoot = findRepoRoot(process.cwd());
  console.log(`Repo root: ${repoRoot}`);
  console.log(`Running: ${checkTypes.join(", ")}`);

  const appsDir = join(repoRoot, "apps");
  const packagesDir = join(repoRoot, "packages");

  const apps = getDirectories(appsDir).map((name) => join(appsDir, name));
  const packages = getDirectories(packagesDir).map((name) => join(packagesDir, name));

  const allFolders = [...apps, ...packages].filter((folder) => existsSync(join(folder, "tsconfig.json")));

  const checkTasks: { folder: string; checkType: CheckType }[] = [];
  for (const folder of allFolders) {
    for (const checkType of checkTypes) {
      checkTasks.push({ folder, checkType });
    }
  }

  const total = checkTasks.length;
  console.log(`Found ${allFolders.length} folders, ${total} checks to run`);
  console.log("Running checks...\n");

  let completed = 0;
  const results = await Promise.all(
    checkTasks.map(({ folder, checkType }) =>
      runCheck(folder, checkType).then((result) => {
        completed++;
        const relativePath = folder.replace(repoRoot + "/", "");
        const icon = result.status === "passed" ? "✅" : result.status === "skipped" ? "⏭️" : "❌";
        process.stdout.write(`\r${completed}/${total} ${icon} [${checkType}] ${relativePath}`.padEnd(80));
        return result;
      })
    )
  );
  console.log("\n");

  // Generate markdown
  const checkLabel = checkTypes.join(" + ");
  let markdown = `# Check Results (${checkLabel})\n\n`;
  markdown += `**Repo root:** \`${repoRoot}\`\n\n`;
  markdown += `**Date:** ${new Date().toISOString()}\n\n`;
  markdown += `---\n\n`;

  // Group results by folder
  const byFolder = new Map<string, CheckResult[]>();
  for (const result of results) {
    const existing = byFolder.get(result.folder) || [];
    existing.push(result);
    byFolder.set(result.folder, existing);
  }

  for (const [folder, folderResults] of byFolder) {
    const relativePath = folder.replace(repoRoot + "/", "");
    markdown += `### ${relativePath}\n\n`;

    for (const result of folderResults) {
      const label = result.checkType === "type" ? "Type Check" : result.checkType === "format" ? "Format" : "Lint";
      if (result.status === "passed") {
        markdown += `#### ${label}: ✅ Passed\n\n`;
      } else if (result.status === "skipped") {
        markdown += `#### ${label}: ⏭️ Skipped (no config)\n\n`;
      } else {
        markdown += `#### ${label}: ❌ Errors\n\n`;
        markdown += "```\n" + result.output + "\n```\n\n";
      }
    }
  }

  // Summary
  const errorCount = results.filter((r) => r.status === 'failed').length;
  const successCount = results.filter((r) => r.status === 'passed').length;
  const skipCount = results.filter((r) => r.status === 'skipped').length;
  markdown += `---\n\n`;
  markdown += `### Summary\n\n`;
  markdown += `- ✅ Passed : ${successCount}\n`;
  markdown += `- ⏭️ Skipped: ${skipCount}\n`;
  markdown += `- ❌ Failed : ${errorCount}\n`;
  markdown += `- Total: ${results.length}\n`;

  const outputPath = join(homedir(), "checks.md");
  writeFileSync(outputPath, markdown);
  console.log(`Results written to ${outputPath}`);

  // Open in nvim
  execSync(`nvim ${outputPath}`, { stdio: "inherit" });
}

main().catch(console.error);
