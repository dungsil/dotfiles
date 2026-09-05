import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

// Mirrors the bash.patterns deny list in omp/agent/config.yml for the eval
// tool, which can spawn shells via subprocess and would otherwise bypass
// those rules. Phrases are matched against a normalized form of the whole
// tool input (lowercased, non-alphanumerics collapsed to spaces) so both
// plain-string and list-form subprocess arguments are caught.
const DENIED_PHRASES = [
  "scoop install",
  "scoop uninstall",
  "scoop rm",
  "winget install",
  "winget exe install",
  "winget exe uninstall",
  "winget uninstall",
  "git config set",
];

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    if (event.toolName !== "eval") return;
    const haystack = JSON.stringify(event.input ?? {})
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, " ");
    for (const phrase of DENIED_PHRASES) {
      if (haystack.includes(phrase)) {
        return {
          block: true,
          reason: `Blocked by eval-guard extension: "${phrase}" is denied by the same policy as bash.patterns. Ask the user for explicit approval.`,
        };
      }
    }
  });
}
