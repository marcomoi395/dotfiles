---
description: Chuyên gia hỗ trợ phát triển NestJS Microservice v3 (vtd-micro-v3).
mode: primary
model: github-copilot/claude-haiku-4.5
temperature: 0.2
permission:
  edit: allow
  bash:
    "*": allow
---

# Agent Guidelines - NestJS VTD Micro v3

> **Core Rules**: Refer to `/AGENTS.md` for universal TypeScript standards. This guide extends with NestJS-specific patterns for `vtd-micro-v3`.

## Project Info

- **Framework**: NestJS 9.2.1 with TypeScript 5.3.3
- **Architecture**: Controller → Service → Repository → Database
- **Package Manager**: Yarn
- **Timezone**: Vietnam (UTC+7)

## Service Layer (CRITICAL)

Services return **raw data only** (raw entities):

```typescript
// ❌ WRONG: Returns formatted response
async getItems(): Promise<AppResponseDto<ItemDto>> {
  return AppResponseDto.fromNestJsPagination(items, meta);
}

// ✅ CORRECT: Returns raw data
async getItems() {
  return { items, meta };
}
```

## DTOs & Validation

**Custom decorators** from `/common/decorators/`: `@IsValidText()`, `@IsValidNumber()`, `@IsValidDate()`, `@IsValidEnum()`, `@IsValidBoolean()`, `@IsValidUUID()`, `@IsValidUrl()`, `@IsValidObject()`, `@IsValidArray*`, `@AutoMapDecorator()`, `@NestedDecorator()`, `@AppResponse()` (Swagger)

**Pattern**:

```typescript
@Post('create')
@AppResponse(CreateItemResDto)
async create(@Body() dto: CreateItemReqDto) {
  const result = await this.service.create(dto);  // raw data
  return AppResponseDto.ok(result);  // wrap in controller
}
```

**Organization**: `dtos/req/[role]/`, `dtos/res/`, use `@ApiProperty()` for Swagger

## Error Handling

Use custom exceptions from `src/common/exceptions/custom-http.exception.ts`:

- `BadRequestExc` (400)
- `ConflictExc` (409)
- `NotFoundExc` (404)

```typescript
if (!item) {
  throw new NotFoundExc("Item not found");
}
```

## Query Filter Pattern

Use `@QueryFilter` decorator for list operations:

```typescript
// Constant: src/[feature]/constants/[feature]-query-alias.constant.ts
export const ITEM_QUERY_ALIAS = { ITEM: 'item' };

// Filter: src/[feature]/filters/[feature].admin.filter.ts
export class ItemAdminFilter {
  @QueryFilter({ order: 10 })
  applyNameFilter(queryBuilder: SelectQueryBuilder<Item>, dto: GetItemListAdminReqDto): void {
    if (dto.name?.trim()) {
      queryBuilder.andWhere(`${ITEM_QUERY_ALIAS.ITEM}.name ILIKE :name`, { name: `%${dto.name.trim()}%` });
    }
  }
}

// Service usage
async getList(dto: GetItemListAdminReqDto) {
  const qb = this.itemRepo.createQueryBuilder(ITEM_QUERY_ALIAS.ITEM).orderBy(`${ITEM_QUERY_ALIAS.ITEM}.createdAt`, 'DESC');
  await this.itemRepo.applyAllFilters(qb, dto, new ItemAdminFilter());
  return await paginate(qb, { limit: dto.limit, page: dto.page });
}
```

**Filter Best Practices**: Order (10, 20, 30...) controls sequence. Check parameter exists. Use `.trim()`. Use alias constants. One filter per concern.

## DateTime Utilities

**CRITICAL**: Use `/src/common/datetime.util.ts`, never `dayjs` directly.

Available: `getNowAtTimezone()`, `subtractDaysFromDate()`, `getStartOfDateInTimezone()`, `getEndOfDateInTimezone()`, `getStartOfMonthInTimezone()`, `compareDateWithDateInTimezone()`, `addDayToDate()`, `addMonthToDate()`, `addMinuteToDate()`, `formatToString()`, `parseStringToDate()`

Wrong: `const now = dayjs().tz(TIME_ZONE);` | Correct: `const now = getNowAtTimezone();`

## Repository Pattern

**Responsibilities**: Query building via filter classes, data fetching, basic entity retrieval, NO business logic.

**BaseRepository Methods**: `findOneOrThrowExc()`, `applyAllFilters()`

```typescript
@Injectable()
export class ItemRepository extends BaseRepository<Item> {
  constructor(dataSource: DataSource) {
    super(Item, dataSource);
  }

  /**
   * Find item by id
   * @param id - Item id
   * @returns Promise<Item | null>
   */
  async findItemById(id: number): Promise<Item | null> {
    return await this.findOne({ where: { id } });
  }
}
```

## File Structure

```
vtd-service-*/src/
├── [feature]/
│   ├── controllers/
│   ├── services/
│   ├── repositories/
│   ├── dtos/req/[role]/
│   ├── dtos/res/
│   ├── entities/
│   ├── enums/
│   ├── constants/
│   ├── filters/
│   └── [feature].module.ts
├── common/
│   ├── config/
│   ├── dtos/
│   ├── exceptions/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   ├── middlewares/
│   ├── decorators/
│   └── utils/
├── proto/
├── external/
└── main.ts
```

## Common Utilities (Don't Reinvent!)

**Response**: `AppResponseDto.ok(data)` in controllers only

**Pagination**: `paginate(queryBuilder, { limit, page })`

**Validation**: Use custom decorators (not raw `@IsString()`, `@IsEmail()`)

**Logging**: `new Logger(MyService.name)` then `this.logger.log()` or `.error()`

## Commands Reference

**Root**: `yarn install`, `bash ./scripts/lint.sh` (read-only mode, do NOT run format script)

**Service**: `cd vtd-service-[name]-v3 && npm run build|dev|start:prod|lint`

**⚠️ CRITICAL - ESLint & Formatting**: 

- **NEVER run** `npm run lint -- --fix`, `eslint fix`, `prettier --write`, or any auto-formatting commands
- **ONLY use** read-only mode: `npm run lint`
- **FIX MANUALLY** in specific files instead of using automated formatters
- **NEVER commit** changes automatically after code modifications - this must be done explicitly by the user

## NestJS Patterns

- **DI**: `@Injectable()` with typed constructor parameters
- **Modules**: `imports: []` for dependencies, `providers: []` for services; use `ClientsModule.registerAsync()` for gRPC
- **Controllers**: Use role-based suffixes (admin, user)
- **Transactions**: Use `@Transactional()` for multi-step DB ops

## Implementation Checklist

**Planning**: Read existing feature. Check `/common/` utilities. Verify DTOs/Entities/Repos don't exist. Check filter classes. Review error codes.

**Implementation**: Create Request DTO. Create Response DTO. Create/Update Entity. Create/Update Repository. Create/Update Filter. Implement Service (raw data). Implement Controller (wrap AppResponseDto). Update Module. Add JSDoc. No `any` types. Single responsibility. Define constants.

**Quality**: Lint. Build. No type errors. No unused imports. Proper error handling.

## Quick Scenarios

### List items with filters

1. Create filter class with `@QueryFilter()` decorators
2. Create query alias constant
3. Create request/response DTOs
4. Use `applyAllFilters()` in service
5. Return paginated result with `paginate()`
6. Wrap with `AppResponseDto.ok()` in controller

### Create/update item

1. Create request DTO with validation decorators
2. Create response DTO
3. Implement in service (return raw entity)
4. Call service from controller
5. Wrap result with `AppResponseDto.ok()`

### Work with dates

1. Import from `datetime.util.ts`
2. Never use `dayjs` directly
3. Use: `getNowAtTimezone()`, `getStartOfDateInTimezone()`, etc.

### Custom error handling

1. Use: `BadRequestExc`, `ConflictExc`, `NotFoundExc`
2. Import from `common/exceptions/custom-http.exception.ts`
3. Example: `throw new NotFoundExc('Item not found')`

### Complex database operation

1. Create repository method with clear naming
2. Use TypeORM query builder
3. Apply filters using filter classes
4. Use `@Transactional()` for multi-step ops

## Common Issues (See `/AGENTS.md` for universal issues)

| Issue                    | Cause                                       | Solution                                         |
| ------------------------ | ------------------------------------------- | ------------------------------------------------ |
| **Import cycles**        | Services importing modules that import them | Move shared logic to utils, check module imports |
| **Missing DTOs**         | Endpoint without request/response DTOs      | Always create DTOs for controller endpoints      |
| **Service returns DTO**  | Service wraps data in DTO                   | Services ONLY return raw data                    |
| **Direct dayjs usage**   | Using dayjs in service                      | Use `datetime.util.ts` utilities                 |
| **Hardcoded strings**    | Using raw column/alias names                | Use query alias constants                        |
| **Missing transactions** | Multiple DB operations not atomic           | Use `@Transactional()` decorator                 |
