import assert from "node:assert/strict";
import { mkdtemp, mkdir, copyFile, readFile, writeFile, rm } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { after, before, test } from "node:test";
import registerGuard from "../omp/agent/extensions/gg-guard.ts";

const repository = fileURLToPath(new URL("../", import.meta.url));
const originalProfile = process.env.USERPROFILE;
const originalHome = process.env.HOME;
let fixture;
let handler;

before(async () => {
  fixture = await mkdtemp(join(tmpdir(), "dotfiles-gg-guard-"));
  const hooks = join(fixture, ".agents", "hooks");
  await mkdir(hooks, { recursive: true });
  await copyFile(join(repository, "hooks", "gg-guard.ps1"), join(hooks, "gg-guard.ps1"));
  process.env.USERPROFILE = fixture;
  process.env.HOME = fixture;
  registerGuard({ on: (name, callback) => {
    assert.equal(name, "tool_call");
    handler = callback;
  } });
});

after(async () => {
  for (const [key, value] of [["USERPROFILE", originalProfile], ["HOME", originalHome]]) {
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
  // Delete only the exact mkdtemp fixture, never a configured home/workspace.
  assert.ok(resolve(fixture).startsWith(resolve(tmpdir()) + "\\") ||
    resolve(fixture).startsWith(resolve(tmpdir()) + "/"));
  assert.match(fixture.split(/[\\/]/).at(-1), /^dotfiles-gg-guard-/);
  await rm(fixture, { recursive: true });
});

function assertPassiveAdvice(result) {
  assert.deepEqual(Object.keys(result), ["additionalContext"]);
  assert.equal(typeof result.additionalContext, "string");
  assert.ok(result.additionalContext.trim());
}

test("OMP advises direct shell execution without blocking or changing input", async () => {
  const event = { toolName: "bash", input: { command: "git status" } };
  const original = structuredClone(event);
  const result = await handler(event);
  assertPassiveAdvice(result);
  assert.match(result.additionalContext, /\$gg.*SKILL\.md/);
  assert.match(result.additionalContext, /Do not repeat an already-completed operation/);
  assert.deepEqual(event, original);
});

test("OMP allows gg and literal documentation searches", async () => {
  for (const command of ["gg status", 'rg "git status" README.md']) {
    assert.equal(await handler({ toolName: "bash", input: { command } }), undefined);
  }
});

test("OMP checks eval process calls but leaves ordinary code and edits alone", async () => {
  assertPassiveAdvice(await handler({ toolName: "eval", input: { code: 'await exec("gh pr list")' } }));
  assert.equal(await handler({ toolName: "eval", input: { code: 'console.log("git status")' } }), undefined);
  assert.equal(await handler({ toolName: "write", input: { content: "git status" } }), undefined);
});

test("Codex's configured hook command emits only advice, not permission decisions", async () => {
  const config = JSON.parse(await readFile(join(repository, "codex", "hooks.json"), "utf8"));
  const registration = config.hooks.PreToolUse[0];
  assert.ok(new RegExp(registration.matcher).test("Bash"));
  // Substitute only the home lookup so the real registered command can run in
  // an isolated fixture without installing or trusting any user-level hooks.
  const command = registration.hooks[0].command.replace(
    "[Environment]::GetFolderPath('UserProfile')", `'${fixture.replaceAll("'", "''")}'`,
  );
  assert.notEqual(command, registration.hooks[0].command);
  for (const [candidate, advised] of [["tea issues list", true], ["gg status", false]]) {
    const result = spawnSync("pwsh", ["-NoProfile", "-NonInteractive", "-Command", command], {
      input: JSON.stringify({ hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: { command: candidate } }),
      encoding: "utf8", windowsHide: true, timeout: 10_000,
    });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stderr, "");
    const output = JSON.parse(result.stdout);
    if (advised) {
      assert.deepEqual(Object.keys(output), ["hookSpecificOutput"]);
      assert.deepEqual(Object.keys(output.hookSpecificOutput).sort(), ["additionalContext", "hookEventName"]);
      assert.equal(output.hookSpecificOutput.hookEventName, "PreToolUse");
      assert.match(output.hookSpecificOutput.additionalContext, /\$gg.*SKILL\.md/);
    } else {
      assert.deepEqual(output, {});
    }
  }
});

test("OMP inspection and serialization errors remain advisory", async () => {
  const invalidInput = await handler({ toolName: "bash", input: {} });
  assertPassiveAdvice(invalidInput);
  assert.match(invalidInput.additionalContext, /could not inspect/);
  const cyclic = { command: "git status" };
  cyclic.self = cyclic;
  const invalidSerialization = await handler({ toolName: "bash", input: cyclic });
  assertPassiveAdvice(invalidSerialization);
  assert.match(invalidSerialization.additionalContext, /could not inspect/);
});

test("OMP malformed and legacy blocking responses cannot block a tool call", async () => {
  const inspector = join(fixture, ".agents", "hooks", "gg-guard.ps1");
  try {
    for (const response of ["not-json", "null", '{"hookSpecificOutput":{"permissionDecision":"deny"}}']) {
      await writeFile(inspector, "[Console]::Out.WriteLine('" + response.replaceAll("'", "''") + "')\n");
      const result = await handler({ toolName: "bash", input: { command: "git status" } });
      assertPassiveAdvice(result);
      assert.match(result.additionalContext, /could not inspect/);
    }
  } finally {
    await copyFile(join(repository, "hooks", "gg-guard.ps1"), inspector);
  }
});

test("OMP spawn failures remain advisory", async () => {
  const originalPath = process.env.PATH;
  try {
    process.env.PATH = "";
    const result = await handler({ toolName: "bash", input: { command: "git status" } });
    assertPassiveAdvice(result);
    assert.match(result.additionalContext, /could not inspect/);
  } finally {
    if (originalPath === undefined) delete process.env.PATH;
    else process.env.PATH = originalPath;
  }
});

test("OMP does not block execution when its inspector is missing", async () => {
  await rm(join(fixture, ".agents", "hooks", "gg-guard.ps1"));
  const result = await handler({ toolName: "bash", input: { command: "gg status" } });
  assertPassiveAdvice(result);
  assert.match(result.additionalContext, /could not inspect/);
});
