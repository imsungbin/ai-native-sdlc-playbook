# Intent: let other coding agents read the same instructions and skills
Author: imsungbin (repo owner). Status: accepted.

## Problem
CLAUDE.md and .claude/skills/ are read by Claude Code only. Other coding
agents (Codex, Cursor, Gemini CLI, Copilot and the like) look for AGENTS.md
at the repo root and for skills under .agents/skills/. A team running more
than one agent would keep two copies of the same instructions, which drift.

## Proposed outcome
The other agents find the same files at the paths they expect, with one
source of truth. No content is duplicated.

## Affected users and systems
Teams adopting this repo with a mixed set of coding agents; the
verification script, which must know about the new entries.

## Constraints
No new content on top of the article. CLAUDE.md and .claude/ stay the
source of truth, as the article places them. The change is recorded as an
author's call in the README.

## Open questions
Whether a root-level skills/ alias is worth adding as well. Not decided here.
