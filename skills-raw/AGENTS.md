# Skill Sources

This directory contains the canonical Korean source files for skills. 
Translate each skill into English and place the translated output under `.agents/skills/<skill-name>/` at the repository root.

## Create Skills
Generate the canonical Korean source for an [Agent Skill](https://agentskills.io/home) under `skills-raw/<skill-name>/` from project documentation. Then translate it into `.agents/skills/<skill-name>/`.

Strictly follow the [skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

- Focus on agent capabilities and practical usage patterns.
- Ignore user-facing guides, introductions, getting-started guides, installation guides, and similar content.
- Ignore content that LLM agents are likely to know from their training data.
- Keep the skill as concise as possible and avoid creating unnecessary reference files.

## Translation Guidelines

- Treat the Korean source as canonical. Preserve its meaning, requirements, ordering, and level of detail without adding or omitting behavior.
- Preserve the directory structure, filenames, frontmatter keys, skill `name`, code blocks, commands, identifiers, paths, URLs, syntax examples, and management markers. Translate frontmatter descriptions and explanatory prose unless a rule below requires preserving the original language.
- If the frontmatter contains `disable-model-invocation: true`, preserve its `description` exactly as written instead of translating it because the skill is intended for manual user invocation.
- Translate Markdown headings, instructions, examples, and text-based assets into clear, natural English. Copy non-text assets unchanged.
- Preserve intentional language requirements. For example, if a source rule requires a commit subject to be written in Korean, the English translation must retain that requirement rather than translating it into an English-only policy.
- Keep relative links valid in the translated directory. Translate every text file belonging to the skill so that the output does not contain stale or unintentionally mixed-language content.

## Verification

After creating or translating a skill, verify the applicable source and translated output. Confirm that the frontmatter is valid, every referenced asset exists, relative links resolve, and every text file ends with a trailing newline. For the translated output, also confirm that no unintended Korean prose remains, excluding a `description` preserved for a skill with `disable-model-invocation: true`.
