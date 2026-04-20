---
name: feature-plan-generation
description: Generates detailed implementation plans from feature specifications and project patterns, producing phased task roadmaps, dependencies, risks, and verification checkpoints before coding. Use when feature requirements and architecture/rule documents are available and an execution-ready backend plan is needed.
---

# Feature Plan Generation

- Mọi dữ liệu khi ghi vào Markdown phải là tiếng Việt có dấu.

## Overview

This skill turns feature specs and project patterns into an actionable backend implementation plan before coding starts. It reduces rework by converting requirements into phased tasks, explicit dependencies, risks, and verification gates.

## When to Use

- When feature requirements are already documented in markdown
- When project architecture/rules/pattern documents are available
- When you need a detailed implementation roadmap before coding
- When multiple modules/teams need a shared execution sequence
- When you want to surface risks and open questions early
- Not for frontend UI planning as primary scope
- Not when specs are still ambiguous or missing core acceptance criteria

## Core Process

1. Validate inputs and planning scope
- Confirm feature spec path and project pattern path are readable markdown files.
- Confirm scope is backend-first (API, service, repository, data model, integration, operational concerns).
- Identify expected output path; default to `implementation-plan.md` if not specified.

2. Extract requirement model from feature spec
- Parse and normalize:
  - business goals,
  - user flows / actor actions,
  - acceptance criteria,
  - non-functional requirements,
  - constraints and exclusions.
- Mark unclear requirements as open questions; do not silently assume critical behavior.

3. Extract implementation constraints from project patterns
- Capture stack and architecture conventions:
  - module/layer patterns,
  - naming conventions,
  - DTO/validation standards,
  - error handling style,
  - transaction and data-access patterns,
  - performance/security baselines.
- Convert conventions into plan-level rules so each task maps back to project standards.

4. Build phased execution roadmap
- Break work into incremental phases with clear objectives.
- Decompose each phase into concrete tasks (verb-first, implementation-ready).
- Define task dependencies and critical path.
- Include checkpoints/gates between phases before moving forward.

5. Add risk, decision, and verification layers
- For each phase, identify key risks and mitigation actions.
- Capture architecture decisions and tradeoffs explicitly.
- Define verification activities per phase:
  - build/type checks,
  - integration behavior checks,
  - regression-sensitive areas,
  - rollout/operational validation if applicable.

6. Generate and present final plan document
- Write final plan file in markdown.
- Ensure plan contains summary, phases, tasks, dependencies, risks, and open questions.
- Present concise execution summary to user with next step recommendation.

## Specific Techniques and Patterns

### Input Command Pattern

```bash
bash /mnt/skills/user/feature-plan-generation/scripts/generate-plan.sh \
  --features <feature-specs.md> \
  --patterns <project-patterns.md> \
  --output <output-plan.md>
```

Arguments:
- `--features` required: feature specification markdown
- `--patterns` required: project rules/pattern markdown
- `--output` optional: output plan path (default `implementation-plan.md`)

### Recommended Plan Structure Pattern

Use this structure for generated plan documents:

```markdown
# Implementation Plan: <Feature Name>

## 1. Summary
- Objective
- Scope in / scope out
- Assumptions

## 2. Architecture and Constraints
- Existing project patterns to follow
- Data model and module boundaries
- API and integration constraints

## 3. Phase Roadmap
### Phase 1 - Foundation
- Tasks
- Deliverables
- Risks
- Exit criteria

### Phase 2 - Core Implementation
- Tasks
- Deliverables
- Risks
- Exit criteria

### Phase 3 - Hardening and Readiness
- Tasks
- Deliverables
- Risks
- Exit criteria

## 4. Dependency Graph
- Task dependencies
- Critical path

## 5. Verification Strategy
- Build/type checks
- Functional checks
- Error-path checks
- Performance/security considerations

## 6. Open Questions
- Unresolved requirements and owner
```

### Task Quality Pattern

A good task is:
- Specific and action-oriented (`Create`, `Implement`, `Refactor`, `Validate`)
- Scoped to one concern
- Mapped to a target module/layer
- Linked to acceptance criteria or risk mitigation
- Verifiable via concrete outcome

Bad task examples:
- `Handle backend logic`
- `Do API`

Good task examples:
- `Create request DTO for blacklist import with phone validation constraints`
- `Implement service method to upsert blacklist records with transactional guard`
- `Add repository query for paginated admin listing with date-range filters`

### Risk and Mitigation Pattern

Represent risks as:
- `Risk`: concise statement of failure mode
- `Impact`: business/technical consequence
- `Mitigation`: explicit prevention or fallback action
- `Owner`: who resolves/decides

Example:
- Risk: Inconsistent writes when import partially fails
- Impact: Data corruption and support overhead
- Mitigation: Wrap batch write and audit logging in transaction boundary
- Owner: Backend implementer + reviewer

### Output Summary Pattern

When presenting generated plan results, include:
- Total phases and tasks
- Estimated scope (`Small`/`Medium`/`Large`)
- Core focus areas (API/data/service/integration)
- Top risks and mitigations
- Path to generated plan file

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Có thể code trước rồi plan sau." | Thiếu plan làm tăng rework, bỏ sót dependencies và checkpoint quan trọng. |
| "Spec đủ rõ, không cần đối chiếu patterns dự án." | Không map với conventions hiện có sẽ gây lệch kiến trúc và tăng thời gian review/sửa. |
| "Task càng tổng quát càng linh hoạt." | Task mơ hồ khiến execution khó đoán, khó estimate và khó verify. |
| "Không cần ghi rủi ro, xử lý khi phát sinh." | Rủi ro backend thường tốn kém khi phát hiện muộn (data, transaction, auth, performance). |
| "Open questions có thể bỏ qua tạm." | Câu hỏi chưa chốt là nguồn gây sai behavior; phải nêu rõ để quyết định trước khi code. |
| "Chỉ cần danh sách task, không cần phase gate." | Không có gate/checkpoint làm khó kiểm soát chất lượng và tiến độ. |

## Red Flags

- Plan không liên kết rõ với acceptance criteria từ spec
- Task không chỉ ra module/layer đích hoặc không có outcome đo được
- Không có dependency map hoặc critical path
- Bỏ qua constraints từ project pattern docs
- Không có rủi ro/mitigation cho các điểm nhạy cảm (data, transaction, auth)
- Thiếu verification strategy theo phase
- Plan chỉ mô tả "what" mà thiếu "how" thực thi
- Không nêu open questions dù specs có điểm mơ hồ

## Verification

After generating the plan, confirm with evidence:

- [ ] Feature and pattern files were parsed successfully
- [ ] Plan scope and assumptions are explicit
- [ ] All major requirements are mapped to concrete tasks
- [ ] Tasks are grouped into phases with clear objectives and exit criteria
- [ ] Task dependencies and critical path are documented
- [ ] Risks and mitigations are present for each phase
- [ ] Verification/checkpoint strategy is present for each phase
- [ ] Open questions are listed with decision owner/next action
- [ ] Output file exists and is readable markdown
- [ ] User-facing summary includes phases, task count, scope estimate, top risks, and output path

Evidence to provide:
- Input files used: `path/to/features.md`, `path/to/patterns.md`
- Output file generated: `path/to/implementation-plan.md`
- Stats: `<tasks_generated>`, `<phases>`, `<estimated_scope>`
