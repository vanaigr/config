#!/usr/bin/env node

import { execSync, spawn } from "child_process";
import { readdirSync, statSync, writeFileSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";

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

interface CheckResult {
  folder: string;
  hasErrors: boolean;
  output: string;
}

function runTypeCheck(folder: string): Promise<CheckResult> {
  return new Promise((resolve) => {
    const child = spawn(
        "pnpm",
        ["exec", "tsc", "--noEmit"],
        { cwd: folder }
    );

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
      resolve({
        folder,
        hasErrors: code !== 0,
        output: output.trim(),
      });
    });
  });
}

async function main() {
  const repoRoot = findRepoRoot(process.cwd());
  console.log(`Repo root: ${repoRoot}`);

  const appsDir = join(repoRoot, "apps");
  const packagesDir = join(repoRoot, "packages");

  const apps = getDirectories(appsDir).map((name) => join(appsDir, name));
  const packages = getDirectories(packagesDir).map((name) => join(packagesDir, name));

  const allFolders = [...apps, ...packages].filter((folder) => existsSync(join(folder, "tsconfig.json")));

  const total = allFolders.length;
  console.log(`Found ${total} folders with tsconfig.json`);
  console.log("Running type checks in parallel...\n");

  let completed = 0;
  const results = await Promise.all(
    allFolders.map((folder) =>
      runTypeCheck(folder).then((result) => {
        completed++;
        const relativePath = folder.replace(repoRoot + "/", "");
        const status = result.hasErrors ? "❌" : "✅";
        process.stdout.write(`\r${completed}/${total} ${status} ${relativePath}`.padEnd(80));
        return result;
      })
    )
  );
  console.log("\n");

  // Generate markdown
  let markdown = `# TypeScript Type Check Results\n\n`;
  markdown += `**Repo root:** \`${repoRoot}\`\n\n`;
  markdown += `**Date:** ${new Date().toISOString()}\n\n`;
  markdown += `---\n\n`;

  for (const result of results) {
    const relativePath = result.folder.replace(repoRoot + "/", "");
    markdown += `## ${relativePath}\n\n`;

    if (result.hasErrors) {
      markdown += `**Status:** ❌ Type errors\n\n`;
      markdown += "```\n" + result.output + "\n```\n\n";
    } else {
      markdown += `**Status:** ✅ No type errors\n\n`;
    }
  }

  // Summary
  const errorCount = results.filter((r) => r.hasErrors).length;
  const successCount = results.filter((r) => !r.hasErrors).length;
  markdown += `---\n\n`;
  markdown += `## Summary\n\n`;
  markdown += `- ✅ Passed: ${successCount}\n`;
  markdown += `- ❌ Failed: ${errorCount}\n`;
  markdown += `- Total: ${results.length}\n`;

  const outputPath = join(homedir(), "checks.md");
  writeFileSync(outputPath, markdown);
  console.log(`Results written to ${outputPath}`);

  // Open in nvim
  execSync(`nvim ${outputPath}`, { stdio: "inherit" });
}

main().catch(console.error);
