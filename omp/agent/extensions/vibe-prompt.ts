import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const VIBE_MESSAGE_TYPE = "vibe-additional-guidelines";

const VIBE_PROMPT = `
## Additional Vibe Mode Instructions

1. Your role is to plan and implement what the user requests, then create a Pull Request so the user can review the changes. You must not publish releases, create tags, or merge Pull Requests.

2. Do not interpret mechanically generated prompts such as \`"Continue task now"\` as explicit approval from the user. Distinguish them from approval written directly by the user. For actions requiring approval, rely only on the user's directly expressed intent.

3. New test files are opt-in. Do not create unit, integration, end-to-end, or spec files, or new test-only helpers or fixtures, unless the user explicitly requests their creation or approves them first. A request to implement, fix, test, or verify something does not by itself authorize new test files. Assume no by default; ask only when creating them has a concrete benefit, not as a routine step.

4. Prefer running existing tests and direct browser or runtime checks without adding test files. Where test changes are in scope, exercise observable behavior rather than asserting source-code strings, implementation shapes, or that tests exist.

5. Do not add \`Co-authored-by:\` trailers to commit messages. Tools and AI assistants are not code contributors or co-authors.
`.trim();

export default function (pi: ExtensionAPI) {
  let hasInjectedInSession = false;

  pi.on("session_start", (_event, ctx) => {
    hasInjectedInSession = ctx.sessionManager.getBranch().some(
      (entry) =>
        entry.type === "message" &&
        "customType" in entry.message &&
        entry.message.customType === VIBE_MESSAGE_TYPE,
    );
  });

  pi.on("before_agent_start", async () => {
    const isVibeMode = pi.getActiveTools().includes("vibe_spawn");
    if (!isVibeMode || hasInjectedInSession) {
      return;
    }

    hasInjectedInSession = true;

    return {
      message: {
        customType: VIBE_MESSAGE_TYPE,
        content: VIBE_PROMPT,
        display: false,
      },
    };
  });

  pi.on("context", async (event) => {
    if (pi.getActiveTools().includes("vibe_spawn")) {
      return;
    }

    return {
      messages: event.messages.filter(
        (message) =>
          (message as { customType?: string }).customType !== VIBE_MESSAGE_TYPE,
      ),
    };
  });
}
