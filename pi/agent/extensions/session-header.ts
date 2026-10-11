import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

interface ProviderRegistration {
  headers?: Record<string, string>;
  baseUrl?: string;
  apiKey?: string;
  api?: string;
}

interface ExtensionAPIWithProvider extends ExtensionAPI {
  registerProvider?(name: string, config: ProviderRegistration): void;
}

// Pi session files are named <timestamp>_<session-id>.jsonl and
// sessionManager exposes no getSessionId(), so the id is recovered from the
// file name.
function readSessionId(ctx: unknown): string | undefined {
  const sessionFile = (ctx as { sessionManager?: { getSessionFile?: () => unknown } } | null)
    ?.sessionManager
    ?.getSessionFile?.();
  if (typeof sessionFile !== "string" || !sessionFile) {
    return undefined;
  }

  const match = /^[0-9TZ:.-]+_(.+)\.jsonl$/.exec(basename(sessionFile));
  const sessionId = match?.[1];
  return sessionId ? sessionId : undefined;
}

function updateSessionHeader(pi: ExtensionAPI, ctx: unknown): void {
  const sessionId = readSessionId(ctx);
  if (!sessionId) {
    return;
  }

  process.env.PI_SESSION_ID = sessionId;

  const ext = pi as ExtensionAPIWithProvider;
  if (typeof ext.registerProvider === "function") {
    ext.registerProvider("tailscale", {
      headers: {
        "x-opencode-session": sessionId,
      },
    });
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => updateSessionHeader(pi, ctx));
  pi.on("session_tree", (_event, ctx) => updateSessionHeader(pi, ctx));
}
