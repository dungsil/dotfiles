import { randomBytes } from "node:crypto";
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

// Pi session IDs are UUIDv7 values. Generate the same shape so consumers that
// read a timestamp from the ID see a sensible value.
function generateSessionId(): string {
  const bytes = new Uint8Array(randomBytes(16));
  const timestamp = BigInt(Date.now());
  for (let i = 5; i >= 0; i--) {
    bytes[i] = Number((timestamp >> BigInt((5 - i) * 8)) & 0xffn);
  }
  bytes[6] = (bytes[6] & 0x0f) | 0x70;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  const hex = Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

// An ephemeral run (for example a subagent child process started with
// --no-session) has no session file, so the id cannot be recovered from a file
// name. Such a run reuses the id inherited from its parent, which keeps its
// requests attributed to that session, and generates an id only when nothing
// was inherited.
function updateSessionHeader(pi: ExtensionAPI, ctx: unknown): void {
  const sessionId = readSessionId(ctx) ?? (process.env.PI_SESSION_ID || generateSessionId());

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
