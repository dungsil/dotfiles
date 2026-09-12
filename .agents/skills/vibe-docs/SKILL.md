---
name: vibe-docs
description: Writes and reviews clear Korean repository text for Agent Skill work. Use for Korean skill files, related documents, commit messages, issues, pull requests, reviews, and comments. Do not use for source code, code comments, logs, or quoted text.
---

# Vibe Docs

Keep the meaning of Korean text clear in Agent Skill work.

## Scope

- Skill files and related documents
- Commit messages
- Issue titles, bodies, and comments
- Pull request titles, bodies, reviews, and comments

Preserve repository templates and structural rules, such as title formats and commit prefixes. Apply the complete Korean rules below to the Korean wording. Within this scope, this section overrides the commit-message exclusion in item 2 under `Operating scope`.

This skill only governs writing and review. It does not grant authority to create commits, publish issues or pull requests, or send comments. The calling skill and the user's request control those side effects.

## Required application order

1. Read every rule in this file **before** drafting any Korean output.
2. Apply every rule from the first draft, including titles, bodies, lists, and comments.
3. After completing the final draft, review it against every rule again immediately before any save, commit, publish, or send action.
4. Pass only the reviewed final text to the real command.

If this skill is read after drafting has started, do not treat the existing text as compliant; review it again from the start against every rule. Reading it before drafting does not allow the final review to be skipped. When producing multiple issues or comments in one run, review every title and body separately. Do not replace the complete rules with a summary.

The text fails the review if any of these conditions apply:

- Unneeded English wording hides the meaning of normal Korean prose.
- A particle, predicate, or sentence ending is missing and breaks the meaning.
- A title or list awkwardly joins Korean and English nouns.
- Only some items in a multi-item output were reviewed.

Preserve code identifiers, commands, API names, file paths, quotations, and technical terms that must stay in their original form. Do not extend this exception to normal English wording.

## Protect established domain terms

Before drafting, check domain terms established by the user and by repository sources such as `CONTEXT.md`, relevant ADRs, and issue tracker documents. Treat these terms as project contracts, not wording choices.

- Keep the exact form, whether it is Korean, English, or mixed.
- Do not translate, transliterate, explain away, generalize, neutralize, or replace it with a synonym for smoother prose.
- Change it only when a source defines a new name or the user requests the change.
- If sources conflict, report the conflict instead of silently choosing a replacement.

This section overrides general vocabulary rules below. An established domain term does not fail the "unneeded English wording" check above.

## Complete Korean writing rules

Whenever a situation requires Korean, follow the instructions in this document. Doing so improves the efficiency of communication. These instructions explain in detail how to produce Korean sentences with clear meaning, relatively good readability, and a stable structure. Do not apply them to quotations, code, or code comments.

## Context and goal

- LLMs show several traits when using Korean. Some of these traits lower the quality of the result or make the user spend more effort on communication. Following this document improves those problems.

- In general, do not summarize these instructions. A summary removes the examples attached to each item, making the intended behavior harder to understand. It can also create pressure to follow only the few rules that remain in the summary. If a summary removes the purpose and intent but keeps only restrictions, the model may check the rules mechanically instead of meeting their goal.

## Operating scope

1. These instructions require clear Korean when Korean is used. They do not require foreign-language sentences or terms to be translated into or replaced with Korean.

2. Text that belongs to code, such as variable names, comments, commit messages, and log strings, must follow the project's existing conventions. Do not apply these instructions to that text. This item repeats the boundary to make it explicit.

3. For proper nouns and technical terms, prefer an established translation or transliteration when one exists. Otherwise, keep the source-language term so Korean readers can understand it more easily and correctly.

4. Do not imitate the tone or vocabulary of the user's message. Apply these instructions consistently regardless of how the user writes.

## Sentence level

1. Do not omit meaningful sentence parts. The reader must be able to understand the sentence fully. [`그러면 경고가 붙습니다.` → Revise it with enough context and information, such as `그러면 이미 작업 중인 파일에도 경고 표지가 추가됩니다.`] In particular, using the possessive particle `~의` more than necessary can make it easy to omit meaningful sentence parts. [`사본의 문구는 작업의 상황을` → `사본에 기재된 문구는 작업이 진행되는 상황을`]

2. This item is not mandatory for headings and lists. Do not end a sentence with a noun phrase, adverbial phrase, or connective ending. Finish it as a complete sentence with a predicate and a sentence-final ending.

## Phrase level

1. Do not omit particles or endings unless necessary. Use adverbs, auxiliary particles, pre-final endings, and auxiliary predicates where useful to make the meaning of a Korean sentence clear. [`이 결정은 이후 중요 정책이 갈리는 자리. 컨텍스트 압축 전 신중 반영한다.` → `이 결정은 이후 중요한 정책에 지속적으로 영향을 주기 때문에, 컨텍스트가 압축되기 전에 신중히 반영합니다.` → `지금 답변해주신 결정 사항은 이후 중요한 정책에도 지속적으로 영향을 미치기 때문에, 컨텍스트가 압축되기 전에 미리 신중하게 반영해 놓겠습니다.`]

2. Combine precise Sino-Korean vocabulary with natural syntax to convey rich and clear meaning. Use Sino-Korean terms that fit the context, then attach particles and endings so the relationships between terms remain explicit. [`쓴 비용을 구하는 토큰 카운트 함수에 문제가 생기면` lacks a sufficiently precise term for the context. `지출 비용 추론 용도의 토큰 카운트 함수의 오류 상황에서` omits particles and endings, which lowers readability and makes the relationships unclear. The target form is `지출한 비용을 추론하는 토큰 카운트 함수에 오류가 발생하면`.]

3. Using figurative words where ordinary words are expected lowers readability and can distort the meaning. Do not replace ordinary nouns or verbs with figurative wording unless it is necessary. Keep an expression when it is common in everyday writing and established as an idiom in the current field, and changing it to ordinary wording would sound less natural. [`분석의 흐름` → `분석의 방향성`; `코드로 박는 자리` → `코드에 명시하는 상황` or `코드에 명시하는 작업`; `요청을 받습니다` → `요청을 확인했습니다` or `요청대로 수행하겠습니다`]

4. Avoid the em dash (`—`) because it compresses the relationship between clauses too much. Replace it with a colon or conjunction that fits the context and format.

## Additional rule

- When a subagent prompt is written in Korean, check it against these instructions before calling the subagent tool. Apply the same instructions when passing a subagent's result to the user.
