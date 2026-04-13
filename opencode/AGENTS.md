# Agent Guidelines - Core Rules

This document provides universal coding standards and development guidelines for all agents. Framework-specific rules are in respective agent files.

## Universal Code Style & Conventions

### Imports & Organization

- Order: built-ins → third-party → internal absolute imports → relative imports
- Use single quotes for strings
- No unused imports

### TypeScript Standards

- **Always declare the type of each variable and function** (parameters and return value)
- **Avoid using `any`** - create necessary types instead
- **Never use raw primitive types** - encapsulate data in composite types (DTOs, Entities)

```typescript
// ❌ WRONG
function getData(id: any): any {
  return data[id];
}

// ✅ CORRECT
function getData(id: number): UserDto {
  return data[id];
}
```

### File Naming Conventions

- **Classes**: PascalCase (e.g., `EventCanMarkService`)
- **Methods/Functions**: camelCase (e.g., `getListEventCanMark()`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `ACCOUNT_SERVICE_NAME`)
- **Interfaces/Types**: PascalCase (e.g., `UserDto`)
- **Database entities**: PascalCase (e.g., `EventCanMark`)
- **File/directory names**: Use kebab-case
- **Function naming**: Start with verb (get, create, update, delete, is, has, can, etc.)
- **Boolean variables**: Use verbs like `isLoading`, `hasError`, `canDelete`
- **Avoid abbreviations**: Use complete words except for standard ones (API, URL, ID, DTO)

### Function Guidelines

**Write short functions with a single purpose**:

- Less than 20 instructions per function
- Single responsibility principle
- One level of abstraction

```typescript
// ❌ WRONG: Function doing too much
async createAndNotifyUser(name: string, email: string) {
  const user = new User();
  user.name = name;
  user.email = email;
  await user.save();
  await sendEmail(email, user.name);
  return user;
}

// ✅ CORRECT: Separated concerns
async createUser(createUserDto: CreateUserDto): Promise<User> {
  return await this.userRepository.save(createUserDto);
}

async notifyNewUser(user: User): Promise<void> {
  await this.emailService.send(user.email, user.name);
}
```

**Avoid nesting blocks - Use early returns**:

```typescript
// ❌ WRONG: Deep nesting
function processData(data: Data[]): void {
  if (data) {
    if (data.valid) {
      if (data.length > 0) {
        // Process...
      }
    }
  }
}

// ✅ CORRECT
function processData(data: Data[]): void {
  if (!data) return;
  if (!data.valid) return;
  if (data.length === 0) return;
  // Process...
}
```

**Use default parameters and RO-RO pattern**:

```typescript
// ❌ WRONG: Too many parameters
function createUser(name: string, email: string, age: number, role: string) {}

// ✅ CORRECT: RO-RO pattern (Receive Object - Return Object)
function createUser(createUserDto: CreateUserDto): UserDto {}
```

### Documentation with JSDoc

```typescript
/**
 * Creates a new user record
 * @param createDto - DTO containing user data
 * @returns Promise<User> - Created user entity
 * @throws NotFoundExc - When user data is invalid
 */
async create(createDto: CreateUserDto): Promise<User> {
  // Implementation
}
```

### Data and Immutability

```typescript
// ❌ WRONG: Mutable constant
const config = { apiUrl: 'https://api.example.com', timeout: 5000 };

// ✅ CORRECT: Immutable constant
const CONFIG = {
  API_URL: 'https://api.example.com',
  TIMEOUT: 5000,
} as const;
```

### Class Design - SOLID Principles

- Less than 200 lines per class
- Less than 10 public methods per class
- Less than 10 properties per class
- Prefer composition over inheritance
- One export per file

```typescript
// ❌ WRONG: Class doing too much
export class UserManager {
  // 50+ methods handling users, emails, notifications, etc.
}

// ✅ CORRECT: Separated concerns
export class UserService {
  async create(dto: CreateUserDto): Promise<User> {}
  async findById(id: number): Promise<User> {}
}

export class UserEmailService {
  async sendWelcome(user: User): Promise<void> {}
}
```

## Testing Conventions

**Follow Arrange-Act-Assert (AAA) convention**:

```typescript
describe('UserService.create', () => {
  it('should create user with valid data', () => {
    // Arrange
    const inputDto = { name: 'John', email: 'john@example.com' };
    const expectedUser = { id: 1, ...inputDto };

    // Act
    const actualUser = userService.create(inputDto);

    // Assert
    expect(actualUser).toEqual(expectedUser);
  });
});
```

**Test naming conventions**:

- Use clear variable names: `inputX`, `mockX`, `actualX`, `expectedX`
- Follow: `describe('ClassName.methodName', () => {})`
- Use: `it('should [behavior] when [condition]', () => {})`

## Error Handling Best Practices

- Use exceptions to handle errors you don't expect
- If you catch an exception:
  - Fix an expected problem, OR
  - Add context, OR
  - Use a global handler instead
- Always provide meaningful error messages

## Linting & Code Formatting

- **⚠️ CRITICAL**: **NEVER run `eslint fix`, `npm run lint -- --fix`, or any prettier formatting commands** - they will modify many unintended files and cause uncontrolled changes
- Only use ESLint in read-only mode: `npm run lint` or manual file editing for specific violations
- Fix linting issues manually in the files you're actively working on
- Do NOT use prettier or any automatic code formatters
- Do NOT commit changes automatically after code modifications

## Common Issues & Solutions

| Issue                     | Cause                         | Solution                                  |
| ------------------------- | ----------------------------- | ----------------------------------------- |
| **Type errors**           | Forgot to declare types       | Always declare parameter and return types |
| **Using `any` type**      | Type safety ignored           | Create proper types for all values        |
| **Unused imports**        | Importing but not using       | Linter catches this - trust it            |
| **Large functions**       | Function doing too much       | Break into < 20 line functions            |
| **Missing documentation** | No JSDoc comments             | Always document public classes/methods    |
| **Deep nesting**          | Multiple nested if/else       | Use early returns and extract functions   |
| **Too many parameters**   | Function signature overloaded | Use RO-RO pattern with objects            |
| **Mutable data**          | Changing constants            | Use `as const` and `readonly` keywords    |

## Quick Reference - Writing Functions

1. Single purpose (< 20 lines)
2. Start name with verb (get, create, is, has, etc.)
3. Declare all parameter and return types
4. Use early returns to avoid nesting
5. Use default parameters instead of null checks
6. Use RO-RO pattern for multiple parameters
7. Add JSDoc comments explaining functionality
8. Use higher-order functions (map, filter, reduce) instead of loops
