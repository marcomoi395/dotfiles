---
name: nestjs-code-review
description: Reviews NestJS code against VTD Service Loyalty V3 architecture, coding rules, and production-readiness standards. Use when finishing a feature, reviewing a PR, or auditing code quality before merge.
---

# NestJS Code Review

- Mọi dữ liệu khi ghi vào Markdown phải là tiếng Việt có dấu.

## Overview

This skill provides a strict, evidence-based workflow to review NestJS features in VTD Service Loyalty V3. It ensures code is correct, secure, performant, maintainable, and aligned with project-specific layers, DTO/decorator conventions, and exception/response patterns.

## When to Use

- After implementing or refactoring a NestJS feature
- Before opening/merging a pull request
- When reviewing another engineer/agent contribution
- When debugging recurring defects caused by architecture drift
- Not for writing brand new features from scratch (use implementation/planning skills first)

## Core Process

1. Scope and baseline
- Identify changed modules/files and map to expected layers: `controllers/`, `services/`, `repositories/`, `entities/`, `dtos/`, `filters/`.
- Capture task/spec acceptance criteria and classify each changed endpoint: read/list/create/update/delete/import/export.

2. Architecture and file-structure review
- Validate separation of concerns: Controller -> Service -> Repository.
- Confirm VTD file naming conventions:
  - Controller: `{feature-name}.{scope}.controller.ts`
  - Service: `{feature-name}.{scope}.service.ts`
  - Repository: `{feature-name}.repository.ts`
  - Entity: `{feature-name}.entity.ts`
  - DTO: `{feature-name}.req.dto.ts`, `{feature-name}.res.dto.ts`
  - Filter: `{feature-name}.{scope}.filter.ts`
- Verify classes use PascalCase, methods use camelCase, directories use kebab-case.

3. Layer-by-layer deep review
- Run the 8 review axes below and collect concrete evidence (code references, command outputs, failed cases).
- Review public methods first, then private helper methods and shared utilities.

4. Risk ranking and remediation
- Classify findings by severity:
  - Critical: security hole, data corruption, broken authorization, transactional inconsistency.
  - High: wrong business logic, missing validation, non-paginated list, N+1 query.
  - Medium: maintainability debt, naming drift, missing JSDoc, duplicated logic.
  - Low: minor consistency/style issues.
- Propose minimal, concrete fixes that preserve existing behavior unless spec requires change.

5. Verification and merge decision
- Run verification checklist in this skill.
- Provide a clear decision: `approve`, `approve with minor fixes`, or `request changes`.

## Review Axes (VTD Service Loyalty V3)

### 1. Correctness and Behavior

- [ ] Code satisfies task/spec and endpoint contract
- [ ] Happy paths and error paths are both implemented
- [ ] Boundary cases handled (null, empty, invalid range, duplicate, not-found)
- [ ] Service returns raw domain data; response wrapping stays in controller
- [ ] Uses project exceptions instead of generic `Error`

### 2. Architecture and Layering

- [ ] Controller only handles HTTP/decorators/response mapping
- [ ] Service contains business logic and orchestration
- [ ] Repository contains data-access logic only
- [ ] Filter logic extracted to filter classes with `@QueryFilter({ order })`
- [ ] No circular dependencies and no layer bypassing

### 3. Type Safety and Naming

- [ ] No `any`; explicit types on parameters, variables, and return values
- [ ] DTO/entity/interface types are used instead of raw primitive blobs
- [ ] Names are explicit verbs/nouns (`getList`, `addUserToBlackList`, `applyDateRangeFilter`)
- [ ] No ambiguous abbreviations (except standard ones like API, DTO, ID)

### 4. DTO, Validation, and Mapping

- [ ] Request DTOs use custom validators (`@IsValidText`, `@IsValidNumber`, `@IsValidDate`, ...)
- [ ] Response DTOs extend `BaseMapperDto` when appropriate
- [ ] Uses `@AutoMapDecorator`, `@NestedDecorator`, `@NestedArrayDecorator` correctly
- [ ] Complex transform/transformSource logic is documented with JSDoc
- [ ] Pagination request DTOs inherit `PaginationReqDto` for list endpoints

### 5. Query, Filter, and Repository Patterns

- [ ] Repositories extend `BaseRepository<T>` and inject `DataSource`
- [ ] Uses shared methods (`applyAllFilters`, `findOneOrThrowExc`, etc.) instead of duplicating
- [ ] Query params are parameterized (no SQL injection from string concatenation)
- [ ] Date range filters use `datetime.util.ts` helper functions
- [ ] Filter method names start with `apply` and are single-purpose

### 6. Service Transactions and Side Effects

- [ ] Multi-entity write workflows use `@Transactional()` where atomicity is required
- [ ] Parallel independent I/O uses `Promise.all()` safely
- [ ] Methods are short and focused (target <20 lines where practical)
- [ ] Side effects (logging/audit/history) extracted to dedicated private methods
- [ ] Public service methods include JSDoc with intent, params, return, throws

### 7. Controller, Auth, and Response Contract

- [ ] Controllers define `version` and path with `Prefix` constants
- [ ] Admin routes include required authorization decorators:
  - `@UseAdminWithAuthorizeBySetupAdminMenuModuleAcl()`
  - `@AdminMenuModuleDecorator(...)`
  - `@ActionsOnAdminMenuModuleDecorator(...)`
- [ ] Uses `@AuthAdmin()` where admin context is required
- [ ] Returns `AppResponseDto` / `AppResponseDto.fromNestJsPagination(...)` consistently
- [ ] Swagger tag/decorator usage is present where applicable

### 8. Security and Performance

- [ ] Authorization is enforced for protected resources
- [ ] Sensitive data is not leaked in response DTOs
- [ ] Error messages are safe and user-friendly (prefer Vietnamese in business messages)
- [ ] List queries are paginated and bounded (`page`, `limit`)
- [ ] No N+1 query pattern; joins/batch operations are used where needed

## Specific Techniques and Patterns

### Entity Review Pattern

```typescript
@Entity({ name: 'wheel_lucky_block_user' })
export class WheelLuckyBlockUser extends BaseEntityV2 {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'phone_number' })
  phoneNumber: string;
}
```

Review expectations:
- Extends the proper base entity from `@src/common/entities`
- DB columns are snake_case, entity properties are camelCase
- Property types are explicit

### Filter Review Pattern

```typescript
export class WheelLuckyBlockUserAdminFilter {
  @QueryFilter({ order: 10 })
  applyPhoneNumberFilter(
    queryBuilder: SelectQueryBuilder<WheelLuckyBlockUser>,
    dto: GetWheelLuckyBlockUserListReqDto,
  ): void {
    if (!dto.phoneNumber?.trim()) return;
    queryBuilder.andWhere('wheelLuckyBlockUser.phoneNumber = :phoneNumber', {
      phoneNumber: dto.phoneNumber.trim(),
    });
  }
}
```

Review expectations:
- Filter methods are instance methods
- Each method has one concern
- Uses `@QueryFilter({ order })` for deterministic order

### Service Review Pattern

```typescript
@Transactional()
async addUserToBlackList(
  admin: AccountData,
  dto: AddUserToBlackListWheelLuckyReqDto,
): Promise<void> {
  const { phoneNumber, isActive } = dto;

  const [user, currentBlockRecord] = await Promise.all([
    this.userRepo.findOneBy({ phoneNumber }),
    this.wheelLuckyBlockUserRepo.findOneBy({ phoneNumber }),
  ]);

  if (!user) throw new BadRequestExc('So dien thoai khong ton tai.');
  if (isActive && currentBlockRecord) throw new BadRequestExc('So dien thoai nay da bi chan.');

  await Promise.all([
    this.updateBlockStatus(phoneNumber, isActive),
    this.logSingleAction(admin.email, phoneNumber, isActive),
  ]);
}
```

Review expectations:
- `@Transactional()` for multi-step writes
- Parallel independent queries/side effects use `Promise.all()`
- Business rule exceptions are specific and meaningful

### Controller Review Pattern

```typescript
@Get()
@UseAdminWithAuthorizeBySetupAdminMenuModuleAcl()
@AdminMenuModuleDecorator(EnumCodeAdminMenuModule.DANH_SACH_CHAN_KHACH_HANG)
@ActionsOnAdminMenuModuleDecorator(
  EnumCodeActionOnAdminMenuModule.FULL_ACCESS,
  EnumCodeActionOnAdminMenuModule.READ,
)
async getAll(@Query() dto: GetWheelLuckyBlockUserListReqDto): Promise<AppResponseDto> {
  const { items, meta } = await this.wheelLuckyBlockUserAdminService.getList(dto);
  const formattedItems = items.map((item) => new WheelLuckyBlockUserResDto(item));
  return AppResponseDto.fromNestJsPagination(formattedItems, meta);
}
```

Review expectations:
- Authorization decorators are complete
- Controller delegates logic to service
- Output is standardized by `AppResponseDto`

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Service trả luôn `AppResponseDto` cho nhanh." | Sai layering. Service phải trả raw data để dễ tái sử dụng và test. |
| "API nội bộ nên không cần validate DTO kỹ." | Nội bộ vẫn có dữ liệu bẩn. Thiếu validate dẫn đến lỗi runtime và lỗ hổng bảo mật. |
| "Query nhỏ nên viết nhanh bằng string concat." | String concat mở cửa SQL injection và khó bảo trì. Luôn dùng params binding. |
| "Chưa cần `@Transactional()`, dữ liệu ít thôi." | Multi-step write không transaction sẽ gây trạng thái nửa vời khi lỗi giữa chừng. |
| "Filter để luôn trong service cho đỡ nhiều file." | Dẫn đến service phình to, khó test. Dùng filter class + `@QueryFilter` để tách concern. |
| "Để `any` tạm, sau này sửa." | `any` che giấu lỗi type, làm review và refactor rủi ro cao. |
| "List này ít bản ghi, chưa cần pagination." | Tăng trưởng dữ liệu sẽ làm API chậm/timeout. Pagination là yêu cầu mặc định. |
| "Dùng dayjs trực tiếp cũng giống util thôi." | Dự án chuẩn hóa timezone qua `datetime.util.ts`; dùng trực tiếp gây lệch hành vi. |

## Red Flags

- Service trả `AppResponseDto` hoặc phụ thuộc HTTP concerns
- Controller chứa business logic, gọi query trực tiếp, hoặc xử lý rule phức tạp
- Repository chứa nghiệp vụ thay vì data-access
- DTO request bị bỏ qua (`@Body() body: any`) hoặc thiếu decorators validate
- Query không tham số hóa, lọc dữ liệu bằng concat string
- Endpoint list không dùng `PaginationReqDto`/paginate
- Dùng `dayjs()` trực tiếp thay vì util thời gian chung
- Thiếu decorators authorization cho endpoint admin
- Generic `Error` thay cho custom exceptions
- Phương thức dài, lồng nhiều tầng, khó đọc và khó test

## Verification

After the review, confirm all items below with evidence:

- [ ] Scope reviewed against changed files and feature requirements
- [ ] All critical/high findings include file path, violated rule, impact, and fix proposal
- [ ] Build/type checks executed successfully (`npm run build`, `npx tsc`)
- [ ] Lint/check script executed in read-only mode (no `--fix`, no prettier)
- [ ] Relevant tests executed and outcomes recorded
- [ ] Architecture constraints validated (Controller/Service/Repository/Filter separation)
- [ ] Security checks validated (auth, validation, query safety, sensitive fields)
- [ ] Performance checks validated (pagination, N+1, bounded queries)
- [ ] Merge decision provided (`approve` / `approve with minor fixes` / `request changes`)

Evidence format to provide in the final review report:
- Finding: `[severity] short title`
- Location: `path/to/file.ts:line`
- Why it matters: one sentence on risk/impact
- Suggested fix: one concrete action or patch direction

## Review Checklist (6 Axes)

### 1. CORRECTNESS

- [ ] Matches spec/task requirements  
- [ ] Edge cases handled (null, empty, boundaries)  
- [ ] Error paths handled  
- [ ] All tests pass  
- [ ] Service returns raw data (never AppResponseDto)  
- [ ] Custom exceptions used (not generic Error)

### 2. READABILITY & SIMPLICITY

- [ ] Names clear and follow conventions  
- [ ] Functions <20 lines, single responsibility  
- [ ] Control flow straightforward  
- [ ] No dead code, unused imports  
- [ ] Comments explain "why", not obvious "what"  
- [ ] No clever tricks, prefer explicit code  
- [ ] Classes <200 lines, <10 public methods  
- [ ] Constants extracted and named clearly

### 3. ARCHITECTURE

- [ ] Controller → Service → Repository separation  
- [ ] Services return raw data only  
- [ ] Controllers wrap with AppResponseDto.ok()  
- [ ] No circular dependencies  
- [ ] Code duplication eliminated  
- [ ] Filter classes isolated with @QueryFilter

### 4. SECURITY

- [ ] Input validated with custom DTOs/decorators  
- [ ] Authorization checks on protected endpoints  
- [ ] Database queries parameterized (no string concatenation)  
- [ ] No secrets in code  
- [ ] Sensitive fields excluded from responses  
- [ ] Error messages don't expose internals  
- [ ] User can only access their own resources

### 5. PERFORMANCE

- [ ] No N+1 query patterns  
- [ ] List endpoints paginated with limits  
- [ ] Database joins/includes used (not loops)  
- [ ] No unbounded data fetching  
- [ ] Query indexes leveraged  
- [ ] Query performance acceptable

### 6. NESTJS STANDARDS (vtd-micro-v3)

- [ ] Custom exceptions: BadRequestExc, ConflictExc, NotFoundExc  
- [ ] DateTime from datetime.util.ts (never dayjs directly)  
- [ ] Query alias constants defined (ITEM_QUERY_ALIAS)  
- [ ] Filter classes with @QueryFilter decorators  
- [ ] All types declared (no `any`)  
- [ ] @Transactional() for multi-step DB ops  
- [ ] JSDoc on all public methods  
- [ ] File structure: controllers/, services/, repositories/, dtos/req/[role]/, dtos/res/, entities/, constants/, filters/  
- [ ] Custom validators: @IsValidText(), @IsValidNumber(), @IsValidEnum()  
- [ ] DTOs organized by role

---

## Anti-Patterns (10 Issues)

| Issue                      | ❌ Wrong                                | ✅ Correct                                    |
| -------------------------- | -------------------------------------- | -------------------------------------------- |
| **Service wraps response** | `async get(): Promise<AppResponseDto>` | `async get(): Promise<{ data }>`             |
| **N+1 queries**            | Loop + find inside                     | Use `leftJoinAndSelect` or `applyAllFilters` |
| **Direct dayjs**           | `dayjs().tz(TZ)`                       | `getNowAtTimezone()` from util.ts            |
| **Generic errors**         | `throw new Error()`                    | `throw new NotFoundExc()`                    |
| **Hardcoded aliases**      | `'item.name'` scattered                | Define `ITEM_QUERY_ALIAS` constant           |
| **Missing DTOs**           | `@Body() body: any`                    | `@Body() dto: CreateReqDto`                  |
| **Filter in service**      | Complex if/where logic                 | Extract to `@QueryFilter` class              |
| **No pagination**          | `find()` returns all                   | `paginate(qb, { limit, page })`              |
| **Using `any` type**       | `function get(x: any): any`            | `function get(x: Id): ItemDto`               |
| **Long functions**         | 50+ lines mixed concerns               | Split into <20 line focused functions        |

---

## Implementation Patterns

### List Endpoint with Filters

```typescript
// Query alias constant (src/items/constants/item-query-alias.constant.ts)
export const ITEM_QUERY_ALIAS = { ITEM: 'item' } as const;

// Filter class (src/items/filters/item.filter.ts)
export class ItemFilter {
  @QueryFilter({ order: 10 })
  applyName(qb: SelectQueryBuilder<Item>, dto: ListReqDto) {
    if (dto.name?.trim()) {
      qb.andWhere(`${ITEM_QUERY_ALIAS.ITEM}.name ILIKE :name`, 
        { name: `%${dto.name.trim()}%` });
    }
  }
}

// Service (returns raw data)
async getList(dto: ListReqDto) {
  const qb = this.itemRepo.createQueryBuilder(ITEM_QUERY_ALIAS.ITEM);
  await this.itemRepo.applyAllFilters(qb, dto, new ItemFilter());
  return await paginate(qb, { limit: dto.limit, page: dto.page });
}

// Controller (wraps response)
@Get()
@AppResponse(ListResDto)
async getList(@Query() dto: ListReqDto) {
  const result = await this.service.getList(dto);
  return AppResponseDto.ok(result);
}
```

### Create Endpoint

```typescript
// DTO with custom validators
export class CreateReqDto {
  @IsValidText() name: string;
  @IsValidEnum(['low', 'high']) priority?: string;
}

// Service (raw entity)
async create(dto: CreateReqDto): Promise<Item> {
  const item = new Item();
  item.name = dto.name.trim();
  item.priority = dto.priority || 'low';
  return await this.itemRepo.save(item);
}

// Controller (wrap response)
@Post()
@AppResponse(CreateResDto)
async create(@Body() dto: CreateReqDto) {
  const result = await this.service.create(dto);
  return AppResponseDto.ok(result);
}
```

### DateTime Operations

```typescript
// ❌ Wrong: dayjs directly
const now = dayjs().tz(TIME_ZONE);

// ✅ Correct: use util.ts
const now = getNowAtTimezone();
const startOfDay = getStartOfDateInTimezone();
const endOfDay = getEndOfDateInTimezone();
```

### Error Handling

```typescript
// ❌ Wrong
if (!item) throw new Error('not found');

// ✅ Correct
if (!item) throw new NotFoundExc('Item not found');
if (exists) throw new ConflictExc('Already exists');
if (!valid) throw new BadRequestExc('Invalid input');
```

### Multi-Step DB Operations

```typescript
@Transactional()
async createItemWithTags(dto: CreateItemWithTagsDto): Promise<Item> {
  const item = await this.itemRepo.save(dto);
  for (const tagId of dto.tagIds) {
    await this.itemTagRepo.save({ itemId: item.id, tagId });
  }
  return item;
}
```

---

## File Structure

```
[feature]/
├── controllers/       → HTTP endpoints, wrap responses
├── services/         → Business logic, return raw data
├── repositories/     → Extend BaseRepository
├── dtos/
│   ├── req/[role]/  → CreateAdminReqDto, ListAdminReqDto
│   └── res/         → CreateResDto, ItemResDto
├── entities/        → Database entities
├── constants/       → ITEM_QUERY_ALIAS
├── filters/         → ItemFilter with @QueryFilter
└── [feature].module.ts
```

---

## Red Flags (Fail Review)

- ❌ Service returns AppResponseDto  
- ❌ N+1 query patterns  
- ❌ List endpoints without pagination  
- ❌ Direct dayjs() usage  
- ❌ Generic Error thrown  
- ❌ Functions >20 lines with multiple concerns  
- ❌ Missing DTOs: `@Body() body: any`  
- ❌ Using `any` type  
- ❌ No JSDoc on public methods  
- ❌ Hardcoded strings/numbers  
- ❌ String concatenation in queries (SQL injection)  
- ❌ No authorization checks  
- ❌ Sensitive fields in responses  
- ❌ No error handling for edge cases

---

## Pre-Merge Verification

### Build & Quality

- [ ] `npm run build` succeeds
- [ ] `bash ./scripts/lint.sh` passes (read-only mode - do NOT use --fix)
- [ ] `npx tsc` has no errors
- [ ] No unused imports (fix manually, never use eslint --fix)
- [ ] All tests pass
- [ ] **CRITICAL**: Do NOT run prettier or eslint auto-format commands
- [ ] **CRITICAL**: Do NOT commit changes automatically

### Functionality

- [ ] Matches spec/requirements
- [ ] Edge cases tested
- [ ] Error paths tested
- [ ] Manual testing done

### Code Quality

- [ ] No dead code
- [ ] All types declared
- [ ] JSDoc on public methods
- [ ] Naming conventions followed

### Architecture

- [ ] Controllers wrap responses
- [ ] Services return raw data only
- [ ] Repositories have no business logic
- [ ] File structure followed
- [ ] No circular dependencies

### Security

- [ ] Input validated with DTOs
- [ ] Authorization checks present
- [ ] Queries parameterized
- [ ] No secrets in code
- [ ] Sensitive fields filtered
- [ ] Error messages safe

### Performance

- [ ] No N+1 queries
- [ ] List endpoints paginated
- [ ] Database indexes leveraged
- [ ] No unbounded operations
- [ ] Query performance acceptable

### NestJS Standards

- [ ] Custom exceptions used
- [ ] datetime.util.ts for dates (not dayjs)
- [ ] Filter classes with @QueryFilter
- [ ] Query alias constants
- [ ] @Transactional() for multi-step ops
- [ ] Custom validators on DTOs

---

## Common Questions

**Q: Service returns raw data, but how does client know response structure?**  
A: Response DTO defines structure. Controller documents with `@AppResponse(DtoClass)`.

**Q: Should I use @Transactional() for single DB operations?**  
A: Only for multi-step ops that need atomicity. Single ops don't need it.

**Q: Can I put business logic in repositories?**  
A: No. Repositories only fetch/persist data. Business logic goes in services.

**Q: What if I need to return computed/filtered fields?**  
A: Do it in service or use a response DTO with mapping, not in controller.

**Q: Should I always paginate list endpoints?**  
A: Yes. Always use pagination with configurable limits for security and performance.
