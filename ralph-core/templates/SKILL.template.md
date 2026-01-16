---
name: ralph-{variant}
description: "Convert requirements to prd.json for {description}"
---

# Ralph {Variant} — PRD Converter

Converts requirements into prd.json format for autonomous execution.

---

## The Job

Take input (requirements doc, feature description, test cases, etc.) and convert it to `{data_dir}/prd.json`.

---

## Output Format

```json
{
  "project": "{project_name}",
  "branchName": "{branch_prefix}{feature-name-kebab-case}",
  "description": "{Feature description}",
  "userStories": [
    {
      "id": "US-001",
      "title": "{Story title}",
      "description": "As a {user}, I want {feature} so that {benefit}",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "{quality_criterion}"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Story Size: The Number One Rule

**Each story must be completable in ONE iteration (one context window).**

If a story is too big, the agent runs out of context before finishing and produces broken work.

### Right-sized stories:
- Single focused change
- Clear start and end point
- Verifiable completion criteria

### Too big (split these):
- Multiple unrelated changes
- "Build the entire X"
- Anything requiring multiple commits

**Rule of thumb:** If you can't describe the change in 2-3 sentences, it's too big.

---

## Story Ordering: Dependencies First

Stories execute in priority order. Earlier stories must not depend on later ones.

Think about what needs to exist before other things can be built.

---

## Acceptance Criteria: Must Be Verifiable

Each criterion must be something that can be CHECKED, not something vague.

### Good criteria (verifiable):
- Specific observable outcomes
- Exact values or behaviors
- Clear pass/fail conditions

### Bad criteria (vague):
- "Works correctly"
- "Good UX"
- "Handles edge cases"

### Always include as final criterion:
```
"{quality_criterion}"
```

---

## Conversion Rules

1. Each logical unit of work becomes one JSON entry
2. IDs: Sequential (US-001, US-002, etc.)
3. Priority: Based on dependency order, then document order
4. All stories: `passes: false` and empty `notes`
5. branchName: Derive from feature name, kebab-case, prefixed with `{branch_prefix}`

---

## {Variant}-Specific Notes

{Add domain-specific guidance here:}
- What inputs this variant typically receives
- What acceptance criteria are always required
- What the typical story ordering looks like
- Any special considerations for this domain

---

## Checklist Before Saving

Before writing prd.json, verify:

- [ ] Each story is completable in one iteration
- [ ] Stories are ordered by dependency
- [ ] Every story has verifiable acceptance criteria
- [ ] No story depends on a later story
- [ ] Branch name follows the prefix convention
