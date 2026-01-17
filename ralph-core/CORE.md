# Ralph Core Agent Instructions

You are an autonomous agent executing tasks from a PRD (Product Requirements Document).

---

## The Loop

Each iteration, you:
1. Read the PRD to find work
2. Read the progress log for learnings from previous iterations
3. Pick one task and complete it
4. **[If requires_git: true]** Run quality checks and commit
5. Update prd.json and progress.txt
6. Signal completion or exit for next iteration

---

## Task Selection

1. Read `prd.json` in your data directory
2. Find the **highest priority** user story where `passes: false`
3. Work on that ONE story only
4. Do not start multiple stories in one iteration

---

## Git Operations (Only when requires_git: true)

> **Skip this section if your variant has `requires_git: false`**

### Branch Management

1. Check the `branchName` field in prd.json
2. Verify you're on that branch
3. If not, check it out or create it from main

### Quality Checks

Before committing, run all quality checks specified for your variant.

- ALL checks must pass before committing
- Do NOT commit broken code
- If a check fails, fix the issue before proceeding

### Committing Work

When a story is complete and quality checks pass:

1. Stage all relevant changes
2. Commit with the format specified in your variant config
3. Update prd.json: set `passes: true` for the completed story
4. Append progress report to progress.txt

---

## Non-Git Operations (Only when requires_git: false)

> **Skip this section if your variant has `requires_git: true`**

When a story is complete:

1. Update prd.json: set `passes: true` for the completed story
2. Add any `notes` to the story (findings, results, evidence paths)
3. Append progress report to progress.txt

You do NOT manage branches or commit code. Your output is the updated prd.json and progress.txt.

---

## Progress Report Format

APPEND to progress.txt (never replace, always append):

```
## [Date/Time] - [Story ID]
- What was implemented
- Files changed
- **Learnings for future iterations:**
  - Patterns discovered (e.g., "this codebase uses X for Y")
  - Gotchas encountered (e.g., "don't forget to update Z when changing W")
  - Useful context (e.g., "component X handles Y")
---
```

The learnings section is critical — it helps future iterations avoid repeating mistakes.

---

## Codebase Patterns

If you discover a **reusable pattern**, add it to the `## Codebase Patterns` section at the TOP of progress.txt (create it if it doesn't exist):

```
## Codebase Patterns
- Pattern 1: Description
- Pattern 2: Description
```

Only add patterns that are **general and reusable**, not story-specific details.

---

## AGENTS.md Files

Before committing, check if any edited directories have AGENTS.md files. If you discovered something future developers/agents should know:

- Add it to the relevant AGENTS.md
- Examples: API patterns, gotchas, dependencies between files, testing approaches

Do NOT add: story-specific details, debugging notes, information already in progress.txt.

---

## Stop Condition

After completing a user story, check if ALL stories have `passes: true`.

**If ALL stories are complete:**
```
<promise>COMPLETE</promise>
```

**If stories remain with `passes: false`:**
End your response normally. The runner will spawn the next iteration.

---

## Rules

- Work on ONE story per iteration
- Do NOT commit broken code
- Keep changes focused and minimal
- Follow existing code patterns in the codebase
- Read the Codebase Patterns section in progress.txt FIRST
