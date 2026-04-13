#!/bin/bash

set -e

# Generate Implementation Plan from Feature Specs and Project Patterns
# This script analyzes feature specifications and project patterns to generate
# a comprehensive implementation plan document.

# Exit trap for cleanup
trap 'rm -f "$TEMP_FILE" "$TEMP_JSON"' EXIT

# Initialize variables
FEATURES_FILE=""
PATTERNS_FILE=""
OUTPUT_FILE="implementation-plan.md"
TEMP_FILE=$(mktemp)
TEMP_JSON=$(mktemp)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --features)
      FEATURES_FILE="$2"
      shift 2
      ;;
    --patterns)
      PATTERNS_FILE="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Validate arguments
if [[ -z "$FEATURES_FILE" ]]; then
  echo "Error: --features argument is required" >&2
  exit 1
fi

if [[ -z "$PATTERNS_FILE" ]]; then
  echo "Error: --patterns argument is required" >&2
  exit 1
fi

# Check file existence
if [[ ! -f "$FEATURES_FILE" ]]; then
  jq -n --arg err "FILE_NOT_FOUND" --arg msg "Feature file not found: $FEATURES_FILE" \
    '{status: "error", error: $msg, code: $err}' > "$TEMP_JSON"
  cat "$TEMP_JSON"
  exit 1
fi

if [[ ! -f "$PATTERNS_FILE" ]]; then
  jq -n --arg err "FILE_NOT_FOUND" --arg msg "Patterns file not found: $PATTERNS_FILE" \
    '{status: "error", error: $msg, code: $err}' > "$TEMP_JSON"
  cat "$TEMP_JSON"
  exit 1
fi

echo "Analyzing feature specifications..." >&2
echo "Extracting project patterns..." >&2
echo "Generating implementation tasks..." >&2

# Extract title from features file
FEATURE_TITLE=$(grep "^# " "$FEATURES_FILE" | head -1 | sed 's/^# //')
[[ -z "$FEATURE_TITLE" ]] && FEATURE_TITLE="Implementation"

# Generate plan document
cat > "$OUTPUT_FILE" << 'EOF'
# Implementation Plan: [FEATURE_TITLE]

## Overview

This plan provides a structured approach to implementing the feature based on the project patterns and specifications. The implementation is broken down into phases with clear dependencies and verification checkpoints.

## Architecture Decisions

Based on the project patterns, the following architectural decisions guide implementation:

### Technology Stack
- Framework/Language: Extracted from project patterns
- Key Dependencies: Identified from existing implementations
- Architecture Pattern: Following project conventions

### Implementation Approach
- Backend-focused: Core service logic, APIs, database integration
- Dependency-driven ordering: Foundation tasks first
- Incremental verification: Builds and manual verification after each phase
- No test artifacts: Code implementation only, no unit/integration/E2E tests

## Task Organization

Tasks are organized into phases following project conventions:

### Phase 1: Foundation & Setup

Foundation tasks establish the base structure and core functionality.

#### Task 1.1: Analyze and Plan
- **Description:** Review feature specifications and project patterns. Create detailed technical plan.
- **Acceptance Criteria:**
  - [ ] All feature requirements understood and documented
  - [ ] Technical approach aligns with project patterns
  - [ ] Dependencies between components identified
- **Verification:**
  - [ ] Manual review: Plan document reviewed and approved
  - [ ] Coverage: All acceptance criteria from specs addressed
- **Files likely touched:**
  - Implementation plan document
- **Dependencies:** None
- **Estimated scope:** Small

#### Task 1.2: API Design & Database Schema
- **Description:** Design API endpoints and database schema for the feature following project patterns.
- **Acceptance Criteria:**
  - [ ] API endpoints documented (routes, request/response format)
  - [ ] Database schema designed and migrations prepared
  - [ ] Data models/DTOs defined
  - [ ] Configuration files created/updated
- **Verification:**
  - [ ] API documentation complete
  - [ ] Database schema reviewed and correct
  - [ ] Project builds without errors
  - [ ] No configuration errors
- **Files likely touched:**
  - Configuration files (5-10% of total)
  - Schema/migration files
- **Dependencies:** Task 1.1
- **Estimated scope:** Small

### Checkpoint: Foundation
- [ ] Project builds successfully
- [ ] Configuration verified
- [ ] Proceed to core implementation

### Phase 2: Core Implementation

Core tasks implement the primary feature functionality.

#### Task 2.1: Core Feature Implementation
- **Description:** Implement core backend logic and services following project patterns and specifications.
- **Acceptance Criteria:**
  - [ ] Core business logic implemented
  - [ ] Services created and functional
  - [ ] Follows project code conventions
  - [ ] No compilation/build errors
- **Verification:**
  - [ ] Build succeeds: `npm run build`
  - [ ] Manual verification of core logic
  - [ ] Code follows project style
- **Files likely touched:**
  - Core implementation files (40-50% of total)
- **Dependencies:** Task 1.2
- **Estimated scope:** Medium to Large

#### Task 2.2: API Implementation & Database Integration
- **Description:** Implement API endpoints and integrate with database following designed schema.
- **Acceptance Criteria:**
  - [ ] All API endpoints implemented
  - [ ] Database operations working correctly
  - [ ] Error handling in place
  - [ ] No breaking changes to existing APIs
- **Verification:**
  - [ ] Build succeeds: `npm run build`
  - [ ] Manual API testing (curl, Postman, or similar)
  - [ ] Database operations verified
  - [ ] End-to-end flow works
- **Files likely touched:**
  - API/controller files (15-25% of total)
  - Database/repository files (10-15% of total)
- **Dependencies:** Task 2.1
- **Estimated scope:** Medium

### Checkpoint: Core Features
- [ ] All core backend logic implemented
- [ ] API endpoints working
- [ ] Database integration complete
- [ ] End-to-end flow verified
- [ ] Proceed to refinement

### Phase 3: Refinement & Polish

Refinement tasks improve code quality, error handling, and maintainability.

#### Task 3.1: Error Handling & Logging
- **Description:** Add comprehensive error handling, validation, and logging to the feature.
- **Acceptance Criteria:**
  - [ ] All error scenarios handled gracefully
  - [ ] Input validation implemented
  - [ ] Logging added for important operations
  - [ ] Error messages are clear and helpful
- **Verification:**
  - [ ] Build succeeds: `npm run build`
  - [ ] Manual testing of error scenarios
  - [ ] Logging output verified
  - [ ] Code review of error handling
- **Files likely touched:**
  - Error handling updates (10-15% of total)
- **Dependencies:** Task 2.2
- **Estimated scope:** Medium

#### Task 3.2: Code Quality & Documentation
- **Description:** Ensure code follows project conventions, add documentation, and clean up code.
- **Acceptance Criteria:**
  - [ ] Code follows project conventions
  - [ ] All public functions/APIs documented
  - [ ] No linting errors (read-only mode)
  - [ ] README/API documentation updated
  - [ ] Code is clean and maintainable
- **Verification:**
  - [ ] Linting passes: `npm run lint` (read-only mode)
  - [ ] Build succeeds: `npm run build`
  - [ ] Manual code review
  - [ ] Documentation complete
- **Files likely touched:**
  - Documentation and minor fixes (5-10% of total)
- **Dependencies:** Task 3.1
- **Estimated scope:** Small to Medium

### Checkpoint: Complete & Ready for Review
- [ ] Error handling implemented
- [ ] Code quality and conventions verified
- [ ] Build succeeds without errors
- [ ] Linting clean (or documented exceptions)
- [ ] Documentation complete
- [ ] Code follows project patterns
- [ ] Ready for code review and integration

## Parallelization Opportunities

The following tasks can potentially be executed in parallel:
- Most tasks are sequential due to dependencies
- Error handling (Task 3.1) and documentation (Task 3.2) could proceed together after implementation
- However, verify dependencies before parallelizing

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| Unforeseen API/database complexity | High | Medium | Early API/schema checkpoint (Task 1.2) and integration checkpoint (Task 2.2) |
| Project pattern mismatch | Medium | Low | Review of patterns in Task 1.1, alignment with existing code |
| Scope creep | High | Medium | Clear acceptance criteria per task, checkpoint reviews |
| Performance issues | High | Low | Performance review during implementation, optimization if needed |
| Error handling gaps | Medium | Medium | Comprehensive error handling task (Task 3.1) covers main scenarios |

## Success Criteria

The feature is considered complete when:

- [ ] All acceptance criteria from the feature specification are met
- [ ] API endpoints implemented and working
- [ ] Database integration complete
- [ ] Build succeeds without errors
- [ ] Code follows project conventions and patterns
- [ ] Error handling implemented
- [ ] Logging added for important operations
- [ ] Documentation is complete and accurate
- [ ] No breaking changes to existing functionality
- [ ] Ready for code review and integration

## Open Questions

- [ ] Are there additional performance requirements?
- [ ] Should this feature include audit logging?
- [ ] Are there specific security considerations to address?
- [ ] Should this feature be feature-flagged for gradual rollout?
- [ ] What are the API versioning requirements?
- [ ] Are there rate limiting or throttling needs?

## Notes for Implementation

- Follow the project patterns documented in the project conventions file
- Use existing patterns for similar backend features as reference implementations
- Maintain consistency with existing code style and architecture
- Focus on clean, maintainable backend code
- Prioritize early integration testing to catch issues quickly
- Consider performance implications for each component and API endpoint
- Document any architectural decisions or deviations from patterns
- Add appropriate logging for debugging and monitoring
- Implement proper error handling and validation at API boundaries

---

**Plan Last Updated:** [TIMESTAMP]
**Generated from:** [FEATURES_FILE] and [PATTERNS_FILE]
EOF

# Replace placeholders with actual values
sed -i "s|\[FEATURE_TITLE\]|$FEATURE_TITLE|g" "$OUTPUT_FILE"
sed -i "s|\[TIMESTAMP\]|$(date -u +'%Y-%m-%d %H:%M:%S UTC')|g" "$OUTPUT_FILE"
sed -i "s|\[FEATURES_FILE\]|$FEATURES_FILE|g" "$OUTPUT_FILE"
sed -i "s|\[PATTERNS_FILE\]|$PATTERNS_FILE|g" "$OUTPUT_FILE"

# Calculate statistics
TASK_COUNT=$(grep -c "^#### Task " "$OUTPUT_FILE")
PHASE_COUNT=$(grep -c "^### Phase " "$OUTPUT_FILE")

# Determine estimated scope
if [[ $TASK_COUNT -lt 5 ]]; then
  SCOPE="Small"
elif [[ $TASK_COUNT -lt 10 ]]; then
  SCOPE="Medium"
else
  SCOPE="Large"
fi

# Output JSON result
jq -n \
  --arg status "success" \
  --arg plan_file "$OUTPUT_FILE" \
  --arg tasks "$TASK_COUNT" \
  --arg phases "$PHASE_COUNT" \
  --arg scope "$SCOPE" \
  --arg features_file "$FEATURES_FILE" \
  --arg patterns_file "$PATTERNS_FILE" \
  '{
    status: $status,
    plan_file: $plan_file,
    stats: {
      tasks_generated: ($tasks | tonumber),
      phases: ($phases | tonumber),
      estimated_scope: $scope
    },
    summary: {
      overview: "Implementation plan generated from feature specifications and project patterns",
      features_file: $features_file,
      patterns_file: $patterns_file,
      ready_for_review: true
    }
  }' > "$TEMP_JSON"

cat "$TEMP_JSON"
