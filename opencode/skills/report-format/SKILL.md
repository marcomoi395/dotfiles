---
name: report-format
description: Standardizes leader reports into the *_FIXED.md format for review and zero-trust reports while preserving original content.
---

# Report Leader Formatting -> FIXED

## Overview

This skill converts leader reports into a consistent *_FIXED.md format using a standard table per finding without altering original content.

## When to Use

- Use when you receive exactly two leader report files (review + zero-trust) and need to normalize formatting.
- Use when the content must remain unchanged and only presentation should be standardized.
- Do not use when you need to edit findings or add new analysis.
- Do not use for reports outside the leader review/zero-trust formats.

## Core Process

1. Confirm the input scope → verify there are exactly two leader report files (review + zero-trust).
2. If there are not exactly two files → stop and request the missing or corrected scope.
3. State assumptions explicitly → list any inferred structure or naming that must hold before proceeding.
4. Normalize output file names → add the `_FIXED` suffix before `.md`, preserving the original name even if it contains punctuation errors.
5. Preserve the top-level structure → do not change titles, links, descriptions, or major sections.
6. For each finding, convert it into a subsection with the standard 4-column table.
7. Leave **Trạng thái** and **Lý do** completely blank.

### Decision Flow

```
Start
  |
  v
Exactly two leader report files?
  |-- No  --> Stop, request missing/corrected scope
  |-- Yes --> Continue formatting
```

## Specific Techniques

### File naming rules

- `REPORT-pr-2226.md` → `REPORT-pr-2226_FIXED.md`
- `REPORT_ZERO_TRUST_2226.md` → `REPORT_ZERO_TRUST_2226_FIXED..md` (preserve if the original name has a double-dot)

### Standard table for each finding

```markdown
#### <Index>. <Finding title>

| Item           | Chi tiết |
| -------------- | -------- |
| **Files**      | `<file_path_1>`, `<file_path_2>` |
| **Trạng thái** |  |
| **Lý do**      |  |

- <keep original explanatory bullet>
- <keep original explanatory bullet>
```

### Template for REPORT-pr-xxxxx_FIXED.md

- Preserve the structure: title, PR link, Base/Head, Scope, Findings, Suggested Fix Order, Notes.
- In Findings, each finding must use the standard table.

### Template for REPORT_ZERO_TRUST_xxxxx_FIXED.md

- Preserve the structure: CRITICAL, SUSPICIOUS, VULNERABILITIES, REMEDIATION PLAN, Verification checklist.
- For each item in CRITICAL/SUSPICIOUS/VULNERABILITIES, add the standard table.
- Do not change the checklist content.

## Common Rationalizations

| Rationalization                                 | Principle Violated  | Reality                                                                         |
| ----------------------------------------------- | ------------------- | ------------------------------------------------------------------------------- |
| "I only need to fix a few items"                | Simplicity First    | All findings must be standardized to keep the report consistent and reviewable. |
| "I can fill Status/Reason based on assumptions" | Think Before Coding | These fields must remain blank to avoid speculative content.                    |
| "I can shorten content to make it cleaner"      | Surgical Changes    | The original leader content must be preserved without reinterpretation.         |

## Red Flags

- Editing the original finding content instead of only reformatting it.
- Filling any value in **Trạng thái** or **Lý do**.
- Changing top-level structure beyond the requested scope.
- Proceeding without stating assumptions or resolving ambiguous input structure.
- Modifying files outside the two leader reports.

## Verification

- [ ] Exactly two output files exist with `_FIXED` before `.md` (evidence: output filenames).
- [ ] Each report preserves its top-level structure (evidence: section titles match the original).
- [ ] Every finding has the 4-column table: **Files, **Trạng thái**, **Lý do** (evidence: table headers present).
- [ ] **Trạng thái** and **Lý do** are blank (evidence: empty cells in all tables).
- [ ] Explanatory bullets match the original content (evidence: bullet text is unchanged).
