---
name: nestjs-postman-generator
description: Generates production-ready Postman Collections from NestJS controllers by extracting routes, DTO validation rules, auth constraints, and representative success/error scenarios. Use when given a controller path and needing executable API test coverage instead of manual request drafting.
---

# NestJS Postman Generator

## Overview

This skill creates complete, executable Postman Collections from NestJS controller implementations. It converts controller/DTO/service behavior into structured request suites that validate both successful flows and high-value failure cases.

## When to Use

- When you receive a NestJS controller path and must generate a Postman collection quickly
- When teams need consistent API test scenarios across multiple modules
- When QA/UAT requires ready-to-run requests with realistic payloads
- When validating request DTO constraints and auth contracts from code
- Not for non-NestJS frameworks
- Not for Swagger/OpenAPI-only documentation tasks without executable test requests

## Core Process

1. Discover API surface from controller
- Read `@Controller()` to determine base path and version.
- Enumerate methods and decorators: `@Get`, `@Post`, `@Put`, `@Patch`, `@Delete`.
- Extract route fragments, path params, query usage, body DTOs, and auth decorators.
- Build operation inventory: one record per endpoint with method, route, input channels, and protection level.

2. Extract DTO constraints and data contracts
- Open all referenced request DTO files and capture validation decorators.
- Determine required vs optional fields and constraint ranges:
  - text length, number min/max, enum values, array size, date format, nested objects.
- Open response DTOs when needed to improve request naming and expected output context.
- Infer default pagination behavior from `PaginationReqDto` when list endpoints exist.

3. Infer business error scenarios from service/repository
- Scan service methods called by each controller route.
- Identify exception paths and map to status classes:
  - 400 (`BadRequestExc`), 401 (`UnauthorizedExc`), 403 (`ForbiddenExc`),
  - 404 (`NotFoundExc`), 409 (`ConflictExc`), 500 (`InternalServerErrorExc`).
- Prioritize representative error cases over combinatorial explosion.

4. Design test matrix per endpoint
- Create mandatory success scenarios:
  - default happy path,
  - boundary-valid input,
  - minimal required fields,
  - one realistic alternative dataset.
- Create mandatory error scenarios (when applicable):
  - 400 missing required field,
  - 400 invalid type/format/range,
  - 401 missing/invalid auth for protected routes,
  - 403 insufficient permission for protected admin actions,
  - 404 non-existent identifier,
  - 409 duplicate/conflict transition.

5. Generate collection structure and requests
- Use Postman v2.1 collection schema.
- Organize by endpoint into two folders:
  - `<Operation> - Success Cases`
  - `<Operation> - Error Cases`
- Fill each request completely:
  - method, URL, params/path vars, headers, auth placeholder, body payload, description.
- Use variables such as `{{base_url}}`, `{{admin_token}}`, `{{user_token}}`.

6. Validate and finalize output
- Save as `{controller-name}.postman_collection.json`.
- Validate JSON syntax and Postman importability.
- Cross-check endpoint coverage and scenario coverage against inventory.

## Specific Techniques and Patterns

### Controller Parsing Pattern

```typescript
@Controller({ version: '1', path: `${Prefix.ADMIN}/wheel-lucky-block-user` })
export class WheelLuckyBlockUserAdminController {
  @Get()
  async getAll(@Query() dto: GetWheelLuckyBlockUserListReqDto) {}

  @Post()
  async addUser(@Body() dto: AddUserToBlackListWheelLuckyReqDto) {}

  @Delete(':id')
  async remove(@Param('id', ParseIntPipe) id: number) {}
}
```

Generate operations:
- `GET /v1/admin/wheel-lucky-block-user`
- `POST /v1/admin/wheel-lucky-block-user`
- `DELETE /v1/admin/wheel-lucky-block-user/:id`

### DTO Constraint Extraction Pattern

```typescript
export class AddUserToBlackListWheelLuckyReqDto {
  @IsValidText()
  phoneNumber: string;

  @IsValidBoolean()
  isActive: boolean;
}
```

Generate tests:
- Success: valid phone, valid boolean
- Error 400: missing `phoneNumber`
- Error 400: `phoneNumber` invalid format/empty
- Error 400: `isActive` not boolean

### Pagination Scenario Pattern

For endpoints using `PaginationReqDto`:
- Success: `page=1&limit=20`
- Success boundary: `page=2&limit=100` (if max 100)
- Error 400: `page=0`
- Error 400: `limit=101` (if max 100)

### Path Parameter Scenario Pattern

For `:id` routes:
- Success: existing numeric ID (e.g., `1`)
- Error 400: invalid type (e.g., `abc` when `ParseIntPipe` is used)
- Error 404: non-existent ID (e.g., `99999`)

### Auth and Permission Scenario Pattern

If route includes auth/ACL decorators:
- Add one 401 case: missing token
- Add one 401 case: malformed token
- Add one 403 case: valid token without required permission

### Request Naming Pattern

Use concise, stable naming:
- `SUCCESS - Default list`
- `SUCCESS - Boundary limit`
- `ERROR 400 - Missing phoneNumber`
- `ERROR 401 - Missing bearer token`
- `ERROR 403 - No READ permission`
- `ERROR 404 - ID not found`
- `ERROR 409 - Duplicate resource`

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Chỉ cần happy path là đủ cho Postman." | Thiếu error cases làm bộ test mất giá trị thực tế; cần ít nhất các nhóm lỗi đại diện. |
| "DTO nhìn đơn giản, không cần đọc file DTO." | Decorator ẩn nhiều ràng buộc (min/max/required/enum). Bỏ qua sẽ tạo payload sai. |
| "Test tất cả tổ hợp lỗi cho chắc." | Gây bùng nổ số lượng request. Chỉ tạo tập lỗi canonical có tính đại diện cao. |
| "Không cần 401/403 vì môi trường dev thường bypass auth." | Auth contract vẫn là một phần của API behavior và phải được kiểm thử. |
| "Enum thì phải generate cho mọi giá trị." | Với Postman collection, 1 valid + 1 invalid là đủ hiệu quả và dễ bảo trì. |
| "Không cần đọc service, cứ dựa controller là đủ." | Nhiều lỗi 404/409 nằm ở service/business rules, không thể suy ra đầy đủ chỉ từ controller. |

## Red Flags

- Không đủ coverage endpoint (thiếu method so với controller)
- Chỉ có success, không có error folders
- Payload không phản ánh constraints thực tế từ DTO
- Dùng giá trị path/query không thực tế hoặc mâu thuẫn (ví dụ 404 dùng ID hiện hữu)
- Thiếu test 401/403 cho endpoint có auth/ACL decorators
- Request name mơ hồ, không nói rõ mục tiêu test
- JSON không import được vào Postman
- Collection dùng URL hardcode thay vì biến môi trường

## Verification

After generation, confirm with evidence:

- [ ] Collection JSON valid and imports successfully into Postman
- [ ] Every controller route is represented in the collection
- [ ] Each route has both success and error scenario folders
- [ ] Success scenarios include default + boundary/minimal variants where applicable
- [ ] Error scenarios include representative 400/401/403/404/409 cases where applicable
- [ ] DTO constraints are reflected accurately in payload/query/path tests
- [ ] Protected endpoints include at least one 401 and one 403 case
- [ ] List endpoints include pagination boundary tests when paginated
- [ ] Path param endpoints include invalid-type and not-found tests
- [ ] All requests are executable without manual payload rewriting
- [ ] Base variables are set (`{{base_url}}` minimum)
- [ ] Output filename follows `{controller-name}.postman_collection.json`

Evidence to report:
- Controller analyzed: `path/to/controller.ts`
- DTO files analyzed: list of paths
- Endpoint count: `<controller_methods>` vs `<generated_operation_groups>`
- Output file: `path/to/<controller-name>.postman_collection.json`
