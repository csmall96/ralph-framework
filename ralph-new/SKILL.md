---
name: ralph-new
description: "Create a new Ralph variant for a specific domain or tech stack"
---

# Create Ralph Variant

Creates a new Ralph variant with all necessary files for autonomous task execution.

---

## What You'll Create

A new Ralph variant consists of:

```
.claude/skills/ralph-{name}/
├── SKILL.md      # PRD converter (how to translate input → prd.json)
├── config.yaml   # Execution settings (quality checks, context files)
├── prompt.md     # Agent instructions (what Claude does each iteration)
└── run.sh        # Launcher script

scripts/ralph-{name}/
├── prd.json      # (created when you run /ralph-{name})
├── progress.txt  # (created on first run)
└── archive/      # (created automatically)
```

---

## Questions to Ask

Gather this information from the user:

### 1. Variant Name
What should this variant be called? (kebab-case, e.g., `ralph-python`, `ralph-qa`, `ralph-docs`)

### 2. Description
What is this variant optimized for? One sentence.

### 3. Does This Variant Commit Code?
**This is critical for determining the agent's behavior.**

- **Yes (requires_git: true)**: The agent writes code, manages branches, runs quality checks, and commits changes. This is the default for development agents.
- **No (requires_git: false)**: The agent performs tasks (QA, research, monitoring, data gathering) but does NOT commit code. It only updates prd.json with results and progress.txt with logs.

Examples of `requires_git: false` variants:
- QA agents that test websites with Playwright
- Research agents that gather information
- Monitoring agents that check for conditions
- Audit agents that analyze and report

### 4. Quality Checks (only if requires_git: true)
What commands validate the work? For each:
- Command to run (e.g., `pytest`, `npm run build`, `mypy .`)
- Is it required (must pass) or optional (warning only)?

Common examples:
- Code: `npm run build`, `tsc`, `cargo check`, `go build`
- Tests: `npm test`, `pytest`, `go test ./...`
- Lint: `eslint .`, `ruff check .`, `golangci-lint run`

Skip this question if `requires_git: false`.

### 5. Context Files
What files should Claude read FIRST for project understanding?
- `README.md` (common)
- `CLAUDE.md` (if exists)
- `docs/ARCHITECTURE.md`
- `pyproject.toml`, `package.json`, etc.

For non-git variants, this might include:
- URL lists to audit
- Pricing rules or test criteria
- API documentation

### 6. Custom Instructions
Any domain-specific guidance? Examples:
- "Use Playwright MCP for browser testing"
- "Follow PEP 8 style"
- "Take screenshots as evidence and save to scripts/{variant}/evidence/"
- "Output findings in JSON format"

---

## Generation Process

Once you have the answers:

### Step 1: Create the skill directory
```bash
mkdir -p .claude/skills/ralph-{name}
```

### Step 2: Create config.yaml
Use the template from `.claude/skills/ralph-core/templates/config.template.yaml` and fill in:
- name
- description
- data_dir: `scripts/ralph-{name}`
- quality_checks (from user answers)
- context_files (from user answers)
- custom_instructions (from user answers)

### Step 3: Create SKILL.md
Use the template from `.claude/skills/ralph-core/templates/SKILL.template.md` and customize:
- Variant name and description
- What inputs this variant typically receives
- What acceptance criteria are always required
- Domain-specific story ordering guidance

### Step 4: Create prompt.md
Combine:
1. Read instructions for context_files from config
2. Core workflow (from `.claude/skills/ralph-core/CORE.md`)
3. Quality check commands from config
4. Custom instructions from config

### Step 5: Create run.sh
```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/../ralph-core/runner.sh" "$SCRIPT_DIR" "$@"
```

Make it executable: `chmod +x run.sh`

### Step 6: Create data directory
```bash
mkdir -p scripts/ralph-{name}
```

---

## Example: Creating ralph-python

**User input:**
- Name: `ralph-python`
- Description: "Python backend development"
- Commits code: **Yes** (`requires_git: true`)
- Quality checks: `pytest` (required), `mypy .` (required), `ruff check .` (optional)
- Context files: `README.md`, `pyproject.toml`
- Custom instructions: "Follow PEP 8. Use type hints everywhere."

**Generated config.yaml:**
```yaml
name: ralph-python
description: "Python backend development"
data_dir: scripts/ralph-python

# This variant writes and commits code
requires_git: true

quality_checks:
  - name: test
    command: pytest
    required: true
  - name: typecheck
    command: mypy .
    required: true
  - name: lint
    command: ruff check .
    required: false

context_files:
  - README.md
  - pyproject.toml

branch_prefix: ralph/
commit_format: "feat: {story_id} - {story_title}"

custom_instructions: |
  ## Python Guidelines
  - Follow PEP 8 style
  - Use type hints everywhere
  - Write docstrings for public functions
```

---

## Example: Creating ralph-qa-ecommerce

**User input:**
- Name: `ralph-qa-ecommerce`
- Description: "Browser-based ecommerce validation using Playwright"
- Commits code: **No** (`requires_git: false`)
- Quality checks: (skipped — not applicable)
- Context files: `docs/test-urls.md`, `docs/pricing-rules.md`
- Custom instructions: "Use Playwright MCP. Take screenshots as evidence."

**Generated config.yaml:**
```yaml
name: ralph-qa-ecommerce
description: "Browser-based ecommerce validation using Playwright"
data_dir: scripts/ralph-qa-ecommerce

# This variant does NOT commit code — it's a QA/testing agent
requires_git: false

# No quality checks needed (not writing code)
quality_checks: []

context_files:
  - docs/test-urls.md
  - docs/pricing-rules.md

custom_instructions: |
  ## QA Variant — Browser Testing Mode

  You are NOT writing code. You are executing browser tests.

  ### Tools Available
  Use the Playwright MCP tools:
  - `mcp__playwright__browser_navigate` — Go to URL
  - `mcp__playwright__browser_snapshot` — Get page state
  - `mcp__playwright__browser_click` — Click elements
  - `mcp__playwright__browser_take_screenshot` — Capture evidence

  ### Workflow
  1. Read test scenario from prd.json
  2. Execute browser actions
  3. Verify each acceptance criterion
  4. Take screenshot as evidence (save to scripts/ralph-qa-ecommerce/evidence/)
  5. Update prd.json: set passes: true/false and add notes with findings
  6. Append summary to progress.txt

  ### Output
  Your output is:
  - Updated prd.json with pass/fail status and notes
  - Screenshots in scripts/ralph-qa-ecommerce/evidence/
  - Progress log in progress.txt
```

---

## After Creation

Tell the user:

1. **To convert requirements to prd.json:**
   ```
   /ralph-{name} "your requirements here"
   ```

2. **To run the variant:**
   ```
   .claude/skills/ralph-{name}/run.sh 10
   ```

3. **Files created:**
   - `.claude/skills/ralph-{name}/` — Skill configuration
   - `scripts/ralph-{name}/` — Runtime data (created on first run)
