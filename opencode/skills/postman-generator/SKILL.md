---
name: postman-generator
description: Generates production-ready Postman Collections (v2.1) from NestJS controllers by analyzing routes, DTO validation rules, service logic branches, and error handling to create diverse test scenarios covering success paths, validation errors, and business logic failures. Use when provided a NestJS controller file path and needing comprehensive API test coverage.
---

# Postman Generator for NestJS APIs

## Overview

This skill analyzes NestJS Controller, DTO, and Service files to automatically generate a complete Postman Collection (v2.1) with multiple test scenarios per endpoint. Instead of generic requests, it creates scenario-specific requests covering success paths, validation failures, and business logic errors, each with realistic mock data derived from DTO constraints.

## When to Use

- **Use when:** You have a NestJS controller file and want executable API test coverage without manual request drafting
- **Includes:** Route analysis, DTO constraint extraction, service logic tracing, mock data generation, and comprehensive request organization
- **Excludes:** GraphQL APIs, REST APIs in non-NestJS frameworks, frontend testing, integration test setup
- **Not for:** Code review, deployment, debugging existing Postman collections

## Before You Start: Pre-Analysis Phase

**Think before coding. Don't assume. Surface tradeoffs.**

Before analyzing the controller, clarify these points with the user:

1. **Scope Clarification:**
   - Does the collection need to include authentication/authorization test scenarios, or focus on happy path + validation errors only?
   - Should I test error handling (rate limits, timeouts, 500s), or just validation + business logic errors?
   - Are there sensitive endpoints that require specific mock data patterns?

2. **Purpose & Audience:**
   - Is this collection for manual testing, automation/CI, or documentation?
   - Do you need pre-request scripts to set up test data (users, resources) before requests run?
   - Should requests be independent or can they depend on each other (e.g., create → read → update)?

3. **Realism vs Simplicity:**
   - How detailed should mock data be? (e.g., valid UUIDs vs generic "id": 1)
   - Should I include edge cases (empty strings, null values, boundary values) or focus on typical happy path + one validation error per endpoint?

4. **If Updating an Existing Collection:**
   - Which endpoints changed? New routes only, or modifications to existing routes?
   - Should I preserve existing test scenarios or regenerate the entire collection?
   - Any custom test scripts or setup I should preserve?

**If unclear on any point, stop and ask. Don't assume defaults.**

## Simplicity First: Constraints

**Minimum collection that solves the problem. Nothing speculative.**

Adhere to these limits:

- **Scenarios per endpoint:** Target 3-5, absolute maximum 7. More scenarios create maintenance burden without proportional test value.
- **Service logic tracing:** Trace only the happy path + immediate error handling. Don't analyze nested service calls unless directly relevant to the endpoint's error response.
- **Mock data realism:** Use concrete values (emails, UUIDs, names), but don't over-engineer with database lookups or complex setup. If it takes more than 2 lines of code to generate mock data, simplify it.
- **Optional fields:** Don't create separate scenarios for every optional field combination. Test 1 success scenario with required fields only, then error scenarios as needed.
- **Features NOT to add:** Authentication bypass techniques, performance/load test scenarios, graphical documentation, or Postman environment setup scripts (unless explicitly requested).

**If you write 50 scenarios and could deliver 15 distinct ones, cut it down.**

## Surgical Analysis: What to Touch

**Only analyze what you must. Don't over-engineer for future changes.**

When examining service logic:

- **Extract error paths only if they directly affect HTTP response codes.** Skip internal logging, metrics collection, or side effects that don't change the response.
- **Don't refactor or "improve" the controller code you're analyzing.** Focus on understanding its current behavior, not fixing it.
- **If you notice unrelated bugs** (e.g., missing validation, logic errors), mention them—don't include them in the collection or fix them.
- **Stop tracing at the service boundary.** Don't analyze the repository layer, database queries, or ORM behavior unless the error response depends on it.

Every analyzed line should directly contribute to a test scenario.

## Goal-Driven Execution: Success Criteria

**Define what "done" means. Loop until verified.**

Before starting analysis, commit to these goals:

1. **Coverage Goal:** Every HTTP endpoint from controller → ≥1 success scenario + ≥1 error scenario. Verification: checklist in collection matches controller routes.
2. **Quality Goal:** All mock data is concrete and immediately executable. Verification: no `{{placeholder}}` values, no "update your API key" instructions.
3. **Distinctness Goal:** No two requests test the same thing. Verification: each error scenario targets a different error code or validation rule.
4. **Clarity Goal:** Anyone reading the collection can immediately understand what each request tests. Verification: request names and descriptions explain the scenario.

**Success criteria let you finish confidently. Weak criteria ("make it look good") extend indefinitely.**

## The Workflow

### Phase 1: Code Analysis & Discovery

**Step 1.1: Scan Controller File**
- Extract all HTTP endpoints: routes, HTTP methods (GET/POST/PUT/DELETE), decorators (@Query, @Param, @Body)
- Identify linked service methods
- Note authentication requirements (@UseGuards, @Public)

**Step 1.2: Trace Service Logic**
- Locate each service method referenced by the controller
- Parse conditional branches (if/else, switch, try/catch)
- Identify error scenarios: validation failures, business rule violations, not found errors, conflicts
- Map error codes and exception types to HTTP status codes (400, 401, 403, 404, 409, 500)

**Step 1.3: Extract DTO Constraints**
- Read request DTO files for validation decorators: @IsEmail, @MinLength, @IsEnum, @IsUUID, etc.
- Parse response DTOs to understand expected response shape
- Document required vs optional fields

### Phase 2: Scenario Definition

**Step 2.1: Identify Test Scenarios**

For each endpoint, define:
- **1 Success scenario**: Valid data, happy path execution
- **N Error scenarios**: Validation errors (bad email, too short, missing required field), business logic failures (duplicate, not found, unauthorized), edge cases

Minimum scenarios per endpoint: 2 (success + 1 error)  
Target scenarios per endpoint: 3-5 (diverse error types)

**Step 2.2: Mock Data Generation**

For each scenario, create specific mock data:
- Use realistic values: actual email formats, valid UUIDs, proper name lengths
- Violate constraints intentionally for error scenarios: `email: "invalid"`, `password: "abc"`, missing required fields
- Reference existing database data patterns from code if visible

### Phase 3: Postman Collection Construction

**Step 3.1: Folder Structure**
```
Collection
├── [GET] /api/endpoint1
│   ├── [Success] Fetch all items
│   ├── [Error] Invalid query parameter
│   └── [Error] Unauthorized access
├── [POST] /api/endpoint2
│   ├── [Success] Create new item
│   ├── [Error] Validation - Email already exists
│   ├── [Error] Validation - Password too short
│   └── [Error] Duplicate record
```

**Step 3.2: Request Configuration**

For each request:
- **Name:** `[Status] Description` where Status ∈ {Success, Error}, Description explains the scenario
- **Method & URL:** Exact endpoint path
- **Headers:** Content-Type, Authorization if needed
- **Params/Query:** Proper types and formats
- **Body:** Mock JSON data specific to scenario
- **Tests:** Post-request script validating response code, structure (optional enhancement)

**Step 3.3: Avoid Redundancy**

- No duplicate requests with identical data and expected outcome
- Each request must represent a unique test case (different input, different business logic branch, different error)
- No placeholder values like `{{placeholder}}` for mock data — use actual realistic values
- Collection variables may be used for sensitive data (API keys, base URLs)

## Core Workflow Steps

1. **Read the Controller file** — Extract HTTP routes, methods, parameter types, and service method names
2. **Locate corresponding DTOs** — Find request and response DTO files referenced in controller
3. **Trace service methods** — Follow the service logic, identify success and error branches
4. **Parse validation rules** — Extract constraints from DTO decorators
5. **Design test scenarios** — For each endpoint, design success + error test cases
6. **Generate mock data** — Create realistic test data that violates constraints for error scenarios
7. **Build Postman collection structure** — Create folder hierarchy and requests with proper HTTP setup
8. **Format and export** — Output Postman v2.1 JSON collection
9. **Verify** — Ensure no redundant requests, all scenarios are distinct, realistic mock data used

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I can just run the same request with different data" | Without analyzing service logic, you'll miss error branches. Each endpoint needs scenarios covering success, validation errors, and business logic failures. |
| "Generic mock data like 'string', 'number' is fine" | Real test coverage requires realistic data that triggers actual validations. `email: "invalid"` won't validate like `email: "test@example"`. |
| "I'll create requests for success paths only" | This misses half the test coverage. Error scenarios (404, 409, validation failures) require different data patterns and reveal logic bugs. |
| "Postman v2.0 is close enough" | v2.1 adds critical features like request/variable scoping and better auth handling. Use the specified version. |
| "I'll use placeholder variables for all mock data" | Concrete values in requests are self-documenting and immediately executable. Placeholders add setup friction and reduce usability. |
| "I can generate this without analyzing DTOs" | DTO validation rules directly determine test data. Without them, error scenarios are guesswork, not systematic coverage. |

## Red Flags

- ❌ Requests with identical request bodies but different expected outcomes (indicates missing scenario differentiation)
- ❌ Mock data using placeholder strings (`string`, `number`, `{{var}}`) instead of realistic values
- ❌ Only success-path requests, no error scenarios per endpoint
- ❌ Collection structure is flat or unclear which endpoint each request targets
- ❌ Error requests with valid data (defeats the purpose of testing validation)
- ❌ Missing request metadata (unclear names, no description of what error is being tested)
- ❌ Service method referenced in controller but not traced to understand error paths

## Verification

After generating the Postman collection, confirm:

- [ ] **Route Extraction:** All HTTP endpoints from controller are present as folders in collection
- [ ] **Scenario Coverage:** Each endpoint has ≥2 requests (success + ≥1 error scenario)
- [ ] **No Redundancy:** No two requests have identical data and expected HTTP status code
- [ ] **Mock Data Quality:** All test data is concrete values (email: "john.doe@example.com", password: "SecurePass123"), not placeholders
- [ ] **Error Scenarios:** Error requests deliberately use invalid data matching DTO constraints (too short, wrong format, missing fields)
- [ ] **Naming:** Requests are clearly named: "[Success] Create User with valid data" or "[Error] Create User - Email already exists"
- [ ] **Collection Structure:** Organized by endpoint in folders, with clear hierarchical relationship
- [ ] **Request Completeness:** Each request has method, URL, headers (if needed), body (if needed), and parameters
- [ ] **Postman Version:** Collection exported as v2.1 JSON format
- [ ] **Executability:** Requests can be run directly in Postman without modification to mock data
