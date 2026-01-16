# Ralph Framework

A portable framework for creating autonomous AI agents that execute tasks iteratively using Claude Code.

## What is Ralph?

Ralph breaks large tasks into small, context-window-sized chunks and executes them one at a time. Each iteration:

1. Reads a task list (prd.json)
2. Picks the next incomplete task
3. Completes it
4. Records learnings for future iterations
5. Repeats until done

Think of it like a shift worker at a factory — each shift (iteration) a fresh worker shows up, checks the job board, completes one task, writes notes for the next shift, and clocks out.

## Installation

Copy the framework into your project's `.claude/skills/` directory:

```bash
# Clone this repo
git clone https://github.com/YOUR_USERNAME/ralph-framework.git

# Copy to your project
cp -r ralph-framework/ralph-core YOUR_PROJECT/.claude/skills/
cp -r ralph-framework/ralph-new YOUR_PROJECT/.claude/skills/
```

Or add as a git submodule:

```bash
cd YOUR_PROJECT/.claude/skills
git submodule add https://github.com/YOUR_USERNAME/ralph-framework.git
ln -s ralph-framework/ralph-core ralph-core
ln -s ralph-framework/ralph-new ralph-new
```

## Usage

### 1. Create a variant for your project

```
/ralph-new
```

Answer the questions:
- **Name**: e.g., `ralph-python`, `ralph-frontend`, `ralph-qa`
- **Quality checks**: Commands that validate work (e.g., `pytest`, `npm run build`)
- **Context files**: Files Claude should read first (e.g., `README.md`, `CLAUDE.md`)
- **Custom instructions**: Domain-specific guidance

This creates `.claude/skills/ralph-{name}/` with all necessary files.

### 2. Convert requirements to prd.json

```
/ralph-{name} "your requirements here"
```

You can pass:
- A PRD markdown file
- Bullet points
- A feature description
- Test cases (for QA variants)

### 3. Run the agent

```bash
.claude/skills/ralph-{name}/run.sh 10
```

The number is max iterations. Ralph will stop early if all tasks complete.

## File Structure

```
.claude/skills/
├── ralph-core/                 # The engine (don't modify)
│   ├── runner.sh               # Loop that spawns Claude iterations
│   ├── CORE.md                 # Shared agent instructions
│   └── templates/              # Templates for new variants
│       ├── config.template.yaml
│       └── SKILL.template.md
│
├── ralph-new/                  # Variant generator
│   └── SKILL.md
│
└── ralph-{variant}/            # Your project-specific variant
    ├── SKILL.md                # How to convert input → prd.json
    ├── config.yaml             # Quality checks, context files
    ├── prompt.md               # Agent instructions
    └── run.sh                  # Launches runner.sh

scripts/ralph-{variant}/        # Runtime data
├── prd.json                    # Task list (created by skill)
├── progress.txt                # Learnings from iterations
└── archive/                    # Previous runs
```

## Core Concepts

| File | Purpose | Analogy |
|------|---------|---------|
| **SKILL.md** | Translates messy input into structured tasks | Waiter training manual |
| **config.yaml** | Settings for execution (commands, context) | Kitchen house rules |
| **prd.json** | The actual tasks to complete | Kitchen tickets |

## Example Variants

### Python Backend
```yaml
quality_checks:
  - name: test
    command: pytest
    required: true
  - name: typecheck
    command: mypy .
    required: true
```

### QA Testing (Playwright)
```yaml
quality_checks: []  # No code to validate

custom_instructions: |
  Use Playwright MCP for browser testing.
  Take screenshots as evidence.
  Don't commit code — only update prd.json with results.
```

### Documentation
```yaml
quality_checks:
  - name: links
    command: npx markdown-link-check docs/**/*.md
    required: true
```

## Requirements

- Claude Code CLI (`claude` command available)
- `jq` for JSON parsing
- Bash shell

## License

MIT
