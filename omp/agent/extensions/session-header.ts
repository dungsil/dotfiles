import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

interface ProviderRegistration {
  headers?: Record<string, string>;
  baseUrl?: string;
  apiKey?: string;
  api?: string;
}

interface ExtensionAPIWithProvider extends ExtensionAPI {
  registerProvider?(name: string, config: ProviderRegistration): void;
}

function updateSessionHeader(pi: ExtensionAPI, ctx: unknown): void {
  const sessionManager = (
    ctx as { sessionManager?: { getSessionId?: () => unknown } } | null
  )?.sessionManager;
  const sessionId = sessionManager?.getSessionId?.();
  if (typeof sessionId !== "string" || !sessionId) {
    return;
  }

  process.env.OMP_SESSION_ID = sessionId;

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
  pi.on("session_switch", (_event, ctx) => updateSessionHeader(pi, ctx));
  pi.on("session_branch", (_event, ctx) => updateSessionHeader(pi, ctx));
  pi.on("session_tree", (_event, ctx) => updateSessionHeader(pi, ctx));
}
