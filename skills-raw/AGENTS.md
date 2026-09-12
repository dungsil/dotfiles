# Skill Sources

This directory contains the canonical Korean source files for locally maintained skills.
`install.ps1` copies each skill unchanged into the ignored `.agents/skills/<skill-name>/` installation directory. Do not translate the source for installation.

Review and edit locally maintained skills here. `.agents/skills/` contains generated copies and external skills restored from `skills-lock.json`; do not edit or commit those files as sources.

## Create Skills
Generate the canonical Korean source for an [Agent Skill](https://agentskills.io/home) under `skills-raw/<skill-name>/` from project documentation. Keep the skill and its assets together in that directory.

Strictly follow the [skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

- Focus on agent capabilities and practical usage patterns.
- Omit generic introductions and user-facing walkthroughs, but retain installation, authentication, and environment prerequisites needed to perform the skill's task.
- Ignore content that LLM agents are likely to know from their training data.
- Keep the description short: state what the skill does and the concrete conditions for using it. Put workflow steps and tool-selection details in the body instead of the description, and avoid broad keyword lists that could trigger unrelated tasks.
- Keep `SKILL.md` concise. For multiple workflows, keep shared guidance and routing in `SKILL.md` and place workflow-specific details in supporting files that are read only when relevant. Do not split a short, focused skill merely to create reference files.

## Source Guidelines

- Write descriptions and explanatory prose in Korean. Preserve code, commands, identifiers, paths, URLs, frontmatter keys, and management markers in their required form.
- Preserve intentional language requirements in instructions, examples, and templates.
- Keep asset references relative to the skill directory so that the source and installed copies both work.
- When text fragments will be merged into a single document, reference sections using the final document's heading anchors instead of links to source asset files.
- Use `pwsh ./install.ps1 -SkillsOnly` from the repository root to refresh installed copies after source changes. External skill selection is managed separately in `skills-lock.json`.

## Verification

After creating or editing a skill, confirm that the frontmatter is valid, every referenced asset exists, relative links resolve, and every text file ends with a trailing newline. When verifying installation, confirm that local skill files match their Korean sources without translation.
