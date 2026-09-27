import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

function inspectionWarning() {
  return {
    additionalContext: "gg-guard could not inspect this tool call. This advisory hook does not block execution or change normal permission checks. Check the gg-guard installation when convenient.",
  };
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    if (!["bash", "eval", "python"].includes(event.toolName)) return;
    // OMP blocks rejected tool_call handlers, so unexpected adapter failures
    // must resolve to passive context as well.
    return await new Promise<{ additionalContext: string } | undefined>((resolve) => {
      const payload = JSON.stringify({ tool_name: event.toolName, tool_input: event.input });
      const child = spawn("pwsh", [
        "-NoLogo", "-NoProfile", "-NonInteractive", "-File",
        join(homedir(), ".agents", "hooks", "gg-guard.ps1"),
      ], { windowsHide: true, timeout: 10_000 });
      let stdout = "";
      const failed = () => resolve(inspectionWarning());
      child.stdout.setEncoding("utf8").on("data", (data) => { stdout += data; });
      // Drain diagnostics without injecting raw process output as instructions.
      child.stderr.resume();
      child.on("error", failed);
      child.stdin.on("error", failed);
      child.on("close", (code) => {
        if (code !== 0) { failed(); return; }
        try {
          const result = JSON.parse(stdout);
          const advice = result.hookSpecificOutput?.additionalContext;
          if (typeof advice === "string" && advice.trim()) {
            resolve({ additionalContext: advice });
          } else if (Object.keys(result).length === 0) {
            resolve(undefined);
          } else {
            failed();
          }
        } catch { failed(); }
      });
      child.stdin.end(payload);
    }).catch(inspectionWarning);
  });
}
