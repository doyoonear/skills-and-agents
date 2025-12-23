# TypeScript 타입 안전성 가이드

## 목차
- [개요](#개요)
- [컴파일러 설정 (tsconfig.json)](#컴파일러-설정-tsconfigjson)
- [타입 에러 방지 코딩 패턴](#타입-에러-방지-코딩-패턴)
- [고급 타입 안전성 패턴](#고급-타입-안전성-패턴)
- [Utility Types 활용](#utility-types-활용)
- [커밋 전 타입 에러 체크](#커밋-전-타입-에러-체크)
- [실전 예시](#실전-예시)
- [레퍼런스](#레퍼런스)

---

## 개요

TypeScript의 가장 큰 강점은 **컴파일 타임에 타입 에러를 감지**하여 런타임 에러를 사전에 방지하는 것입니다. 이 가이드는 타입 안전성을 극대화하는 방법을 설명합니다.

### 핵심 원칙

#### 기본 원칙
1. **Strict Mode 활성화**: 가장 엄격한 타입 체크 적용
2. **`any` 금지**: `unknown`이나 명시적 타입 사용
3. **명시적 타입 선언**: 타입 추론에만 의존하지 않기
4. **커밋 전 타입 체크**: pre-commit hook으로 타입 에러 방지

#### 고급 원칙
5. **Branded Types**: 구조적으로 같아도 논리적으로 다른 타입 구분
6. **Assertion Functions**: Type Guards 대신 사용하여 코드 간결성 향상
7. **Exhaustiveness Checking**: never 타입으로 모든 케이스 처리 강제
8. **Template Literal Types**: 타입 안전한 문자열 패턴
9. **Generic Constraints**: extends, keyof, infer로 정확한 타입 추론

---

## 컴파일러 설정 (tsconfig.json)

### Strict Mode 활성화

**`"strict": true`는 모든 TypeScript 프로젝트의 기본값이어야 합니다.**

```json
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

### Strict Mode가 활성화하는 옵션들

`"strict": true`는 다음 옵션들을 자동으로 활성화합니다:

#### 1. **noImplicitAny**
암묵적 `any` 타입 금지

```typescript
// ❌ 에러 발생
function add(a, b) {
  // Parameter 'a' implicitly has an 'any' type
  return a + b;
}

// ✅ 명시적 타입 선언
function add(a: number, b: number): number {
  return a + b;
}
```

#### 2. **strictNullChecks**
`null`과 `undefined`를 명시적으로 처리

```typescript
// ❌ strictNullChecks 비활성화 시: 런타임 에러 가능
function getLength(str: string) {
  return str.length;
}
getLength(null); // 런타임 에러!

// ✅ strictNullChecks 활성화 시: 컴파일 에러
function getLength(str: string | null): number {
  if (str === null) {
    return 0;
  }
  return str.length;
}
```

#### 3. **strictPropertyInitialization**
클래스 프로퍼티 초기화 강제

```typescript
// ❌ 에러 발생
class User {
  name: string; // Property 'name' has no initializer
}

// ✅ 올바른 초기화
class User {
  name: string;

  constructor(name: string) {
    this.name = name;
  }
}

// ✅ 또는 초기값 제공
class User {
  name: string = '';
}

// ✅ 또는 optional로 선언
class User {
  name?: string;
}
```

#### 4. **noImplicitThis**
`this`의 타입을 명시적으로 선언

```typescript
// ❌ 에러 발생
const obj = {
  name: 'John',
  greet() {
    setTimeout(function () {
      console.log(this.name); // 'this' has an implicit 'any' type
    }, 1000);
  },
};

// ✅ 화살표 함수 사용
const obj = {
  name: 'John',
  greet() {
    setTimeout(() => {
      console.log(this.name); // 올바른 this 바인딩
    }, 1000);
  },
};
```

#### 5. **strictBindCallApply**
`bind`, `call`, `apply` 메서드의 타입 체크

```typescript
function greet(name: string, age: number) {
  console.log(`Hello ${name}, you are ${age} years old`);
}

// ❌ strictBindCallApply 활성화 시 에러
greet.call(undefined, 'John', '25'); // '25'는 string인데 number 기대

// ✅ 올바른 타입
greet.call(undefined, 'John', 25);
```

#### 6. **alwaysStrict**
모든 파일에 `"use strict"` 자동 추가

---

## 타입 에러 방지 코딩 패턴

### 1. `any` 대신 `unknown` 사용

**문제**: `any`는 모든 타입 체크를 우회합니다.

```typescript
// ❌ any 사용 - 타입 안전성 없음
function processData(data: any) {
  return data.toUpperCase(); // data가 string이 아니면 런타임 에러
}

processData(123); // 컴파일은 성공하지만 런타임 에러 발생
```

**해결**: `unknown`을 사용하고 타입 가드로 좁히기

```typescript
// ✅ unknown 사용 - 타입 안전
function processData(data: unknown): string {
  if (typeof data === 'string') {
    return data.toUpperCase(); // 타입 좁히기 후 안전하게 사용
  }
  throw new Error('Data must be a string');
}

processData(123); // ✅ 타입 에러는 아니지만 런타임에 명시적 에러
processData('hello'); // ✅ 'HELLO'
```

### 2. 명시적 타입 선언

**타입 추론에만 의존하지 말고 중요한 곳은 명시적으로 선언**

```typescript
// ⚠️ 타입 추론에만 의존
const users = [
  { id: 1, name: 'John' },
  { id: 2, name: 'Jane' },
];

// ✅ 명시적 타입 선언
interface User {
  id: number;
  name: string;
  email?: string; // 나중에 추가될 수 있는 필드
}

const users: User[] = [
  { id: 1, name: 'John' },
  { id: 2, name: 'Jane' },
];

// ✅ 함수 시그니처 명시
function getUser(id: number): User | undefined {
  return users.find((user) => user.id === id);
}
```

### 3. Non-null Assertion (`!`) 신중하게 사용

**`!`는 컴파일러에게 "이 값은 절대 null/undefined가 아니다"라고 강제하는 것입니다.**

```typescript
// ❌ 위험한 사용
function processUser(userId: number) {
  const user = getUser(userId)!; // 만약 undefined면 런타임 에러
  console.log(user.name);
}

// ✅ 안전한 접근
function processUser(userId: number) {
  const user = getUser(userId);
  if (!user) {
    throw new Error(`User ${userId} not found`);
  }
  console.log(user.name);
}

// ✅ Optional Chaining 사용
function getUserName(userId: number): string | undefined {
  const user = getUser(userId);
  return user?.name;
}
```

### 4. Type Guards 활용

**타입을 안전하게 좁히는 방법**

```typescript
// 기본 타입 가드
function processValue(value: string | number) {
  if (typeof value === 'string') {
    return value.toUpperCase(); // value는 string
  }
  return value.toFixed(2); // value는 number
}

// 커스텀 타입 가드
interface Dog {
  type: 'dog';
  bark(): void;
}

interface Cat {
  type: 'cat';
  meow(): void;
}

type Animal = Dog | Cat;

// ✅ 타입 가드 함수
function isDog(animal: Animal): animal is Dog {
  return animal.type === 'dog';
}

function handleAnimal(animal: Animal) {
  if (isDog(animal)) {
    animal.bark(); // TypeScript가 animal을 Dog로 인식
  } else {
    animal.meow(); // TypeScript가 animal을 Cat으로 인식
  }
}
```

### 5. Discriminated Unions (구별된 유니온)

**`type` 필드로 타입을 구별**

```typescript
// ✅ Discriminated Union 패턴
type ApiResponse<T> =
  | { status: 'success'; data: T }
  | { status: 'error'; error: string }
  | { status: 'loading' };

function handleResponse<T>(response: ApiResponse<T>) {
  switch (response.status) {
    case 'success':
      console.log(response.data); // ✅ data 접근 가능
      break;
    case 'error':
      console.error(response.error); // ✅ error 접근 가능
      break;
    case 'loading':
      console.log('Loading...'); // ✅ 추가 필드 없음
      break;
  }
}
```

### 6. `as const`로 리터럴 타입 유지

```typescript
// ⚠️ 넓은 타입 추론
const colors = ['red', 'blue', 'green'];
// colors: string[]

// ✅ as const로 정확한 리터럴 타입
const colors = ['red', 'blue', 'green'] as const;
// colors: readonly ['red', 'blue', 'green']

type Color = (typeof colors)[number];
// type Color = 'red' | 'blue' | 'green'
```

### 7. 함수 오버로딩

**같은 함수가 다른 타입의 인자를 받을 때**

```typescript
// ✅ 함수 오버로딩
function createElement(tag: 'div'): HTMLDivElement;
function createElement(tag: 'span'): HTMLSpanElement;
function createElement(tag: 'a'): HTMLAnchorElement;
function createElement(tag: string): HTMLElement {
  return document.createElement(tag);
}

const div = createElement('div'); // HTMLDivElement
const span = createElement('span'); // HTMLSpanElement
```

---

## 고급 타입 안전성 패턴

### 1. Branded Types (Nominal Typing)

**문제**: TypeScript는 구조적 타입 시스템이라 형태가 같으면 다른 타입도 호환됩니다.

```typescript
// ❌ 구조적 타입 시스템의 문제
type USD = number;
type EUR = number;

const usd: USD = 100;
const eur: EUR = usd; // ✅ 에러 없음! (문제 발생 가능)
```

**해결**: Branded Types로 논리적으로 다른 타입을 구분

```typescript
// ✅ Branded Type 패턴
type Brand<K, T> = K & { __brand: T };

type USD = Brand<number, 'USD'>;
type EUR = Brand<number, 'EUR'>;

// 생성 함수 (타입 가드)
function usd(amount: number): USD {
  return amount as USD;
}

function eur(amount: number): EUR {
  return amount as EUR;
}

const dollars = usd(100);
const euros = eur(100);

// ❌ 타입 에러 발생!
const mixedCurrency: USD = euros; // Type 'EUR' is not assignable to type 'USD'

// ✅ 명시적 변환 필요
function convertEurToUsd(amount: EUR, rate: number): USD {
  return usd(amount * rate);
}
```

**실용적인 사용 사례**

```typescript
// ✅ 사용자 ID 구분
type UserId = Brand<string, 'UserId'>;
type PostId = Brand<string, 'PostId'>;

function getUserById(id: UserId) { /* ... */ }
function getPostById(id: PostId) { /* ... */ }

const userId = 'user-123' as UserId;
const postId = 'post-456' as PostId;

getUserById(userId);   // ✅
getUserById(postId);   // ❌ 타입 에러

// ✅ 검증된 값 타입
type SanitizedString = Brand<string, 'Sanitized'>;
type Email = Brand<string, 'Email'>;

function sanitize(raw: string): SanitizedString {
  // XSS 방지 로직
  return raw.replace(/</g, '&lt;').replace(/>/g, '&gt;') as SanitizedString;
}

function validateEmail(email: string): Email {
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new Error('Invalid email');
  }
  return email as Email;
}

function renderHTML(html: SanitizedString) {
  // 안전하게 렌더링
  document.body.innerHTML = html;
}

const userInput = '<script>alert("XSS")</script>';
renderHTML(userInput); // ❌ 타입 에러
renderHTML(sanitize(userInput)); // ✅
```

---

### 2. Assertion Functions (타입 단언 함수)

**Type Guards vs Assertion Functions**

```typescript
// Type Guard - boolean 반환
function isString(value: unknown): value is string {
  return typeof value === 'string';
}

if (isString(data)) {
  data.toUpperCase(); // ✅ string으로 좁혀짐
}

// Assertion Function - throw 또는 return
function assertIsString(value: unknown): asserts value is string {
  if (typeof value !== 'string') {
    throw new TypeError('Value must be a string');
  }
}

assertIsString(data); // throw하거나 통과
data.toUpperCase(); // ✅ 이후 코드에서 string으로 간주
```

**실용적인 Assertion Functions**

```typescript
// ✅ null/undefined 체크
function assertDefined<T>(value: T | null | undefined): asserts value is T {
  if (value === null || value === undefined) {
    throw new Error('Value is null or undefined');
  }
}

const user = getUser(id);
assertDefined(user);
console.log(user.name); // ✅ user는 User 타입

// ✅ 조건 검증
function assertTrue(condition: boolean, message?: string): asserts condition {
  if (!condition) {
    throw new Error(message ?? 'Assertion failed');
  }
}

const age = getUserAge();
assertTrue(age >= 18, 'User must be 18 or older');
// 이후 코드에서 age >= 18이 보장됨

// ✅ 배열 타입 검증
function assertIsStringArray(value: unknown): asserts value is string[] {
  if (!Array.isArray(value) || !value.every((item) => typeof item === 'string')) {
    throw new TypeError('Value must be an array of strings');
  }
}

const data: unknown = JSON.parse(jsonString);
assertIsStringArray(data);
data.forEach((str) => console.log(str.toUpperCase())); // ✅
```

---

### 3. Exhaustiveness Checking (완전성 체크)

**`never` 타입으로 모든 케이스 처리 강제**

```typescript
type Status = 'pending' | 'approved' | 'rejected';

function handleStatus(status: Status) {
  switch (status) {
    case 'pending':
      return 'Waiting...';
    case 'approved':
      return 'Success!';
    case 'rejected':
      return 'Failed!';
    default:
      // ✅ 모든 케이스를 처리했으므로 도달 불가능
      const _exhaustive: never = status;
      return _exhaustive;
  }
}

// ⚠️ 새로운 status 추가
type Status = 'pending' | 'approved' | 'rejected' | 'cancelled';

// ❌ 컴파일 에러 발생!
// Type 'string' is not assignable to type 'never'
```

**Helper 함수 패턴**

```typescript
// ✅ assertNever 헬퍼
function assertNever(value: never): never {
  throw new Error(`Unexpected value: ${value}`);
}

type Shape =
  | { kind: 'circle'; radius: number }
  | { kind: 'square'; size: number }
  | { kind: 'rectangle'; width: number; height: number };

function getArea(shape: Shape): number {
  switch (shape.kind) {
    case 'circle':
      return Math.PI * shape.radius ** 2;
    case 'square':
      return shape.size ** 2;
    case 'rectangle':
      return shape.width * shape.height;
    default:
      return assertNever(shape); // 모든 케이스 처리 강제
  }
}
```

---

### 4. Advanced Type Narrowing (고급 타입 좁히기)

#### `in` 연산자로 프로퍼티 체크

```typescript
interface Dog {
  bark(): void;
}

interface Cat {
  meow(): void;
}

function handlePet(pet: Dog | Cat) {
  if ('bark' in pet) {
    pet.bark(); // ✅ Dog로 좁혀짐
  } else {
    pet.meow(); // ✅ Cat으로 좁혀짐
  }
}
```

#### `instanceof`로 클래스 체크

```typescript
class NetworkError extends Error {
  constructor(public statusCode: number) {
    super('Network error');
  }
}

class ValidationError extends Error {
  constructor(public field: string) {
    super('Validation error');
  }
}

function handleError(error: Error) {
  if (error instanceof NetworkError) {
    console.log(`Network error: ${error.statusCode}`); // ✅
  } else if (error instanceof ValidationError) {
    console.log(`Validation error in field: ${error.field}`); // ✅
  } else {
    console.log(`Unknown error: ${error.message}`);
  }
}
```

#### Truthiness Narrowing

```typescript
function printLength(str: string | null | undefined) {
  // ✅ Truthiness check로 null/undefined 제거
  if (str) {
    console.log(str.length); // str은 string
  }
}

// ⚠️ 주의: 빈 문자열, 0, false도 필터링됨
function processValue(value: string | number) {
  if (value) {
    // value는 string | number이지만 "", 0은 제외
  }
}
```

#### Equality Narrowing

```typescript
function handleValue(value: string | number, compare: string | number) {
  if (value === compare) {
    // value와 compare는 같은 타입으로 좁혀짐
    console.log(value.toUpperCase()); // ❌ 에러: number일 수도 있음
  }
}

// ✅ 리터럴과 비교
function handleStatus(status: 'success' | 'error' | null) {
  if (status !== null) {
    status; // 'success' | 'error'
  }
}
```

---

### 5. Template Literal Types (문자열 리터럴 타입)

**타입 레벨에서 문자열 조작**

```typescript
// ✅ 기본 패턴
type EventName = 'click' | 'focus' | 'blur';
type EventHandler = `on${Capitalize<EventName>}`;
// type EventHandler = 'onClick' | 'onFocus' | 'onBlur'

// ✅ 문자열 조합
type HttpMethod = 'GET' | 'POST';
type Endpoint = '/users' | '/posts';
type Route = `${HttpMethod} ${Endpoint}`;
// type Route = 'GET /users' | 'GET /posts' | 'POST /users' | 'POST /posts'

// ✅ 실용적인 예시: CSS 프로퍼티
type CSSUnit = 'px' | 'em' | 'rem' | '%';
type Size = `${number}${CSSUnit}`;

function setWidth(width: Size) {
  // width는 '10px', '2em', '100%' 등만 허용
}

setWidth('10px');   // ✅
setWidth('2em');    // ✅
setWidth('10');     // ❌ 타입 에러
setWidth('10pt');   // ❌ 타입 에러
```

**Built-in String Manipulation Types**

```typescript
type Original = 'hello_world';

type Upper = Uppercase<Original>;      // 'HELLO_WORLD'
type Lower = Lowercase<Original>;      // 'hello_world'
type Capi = Capitalize<Original>;      // 'Hello_world'
type Uncapi = Uncapitalize<Original>;  // 'hello_world'

// ✅ 실용적인 예시: API 엔드포인트
type ApiResource = 'user' | 'post' | 'comment';
type GetEndpoint = `GET /${ApiResource}s`;
type PostEndpoint = `POST /${ApiResource}s`;
type ApiEndpoint = GetEndpoint | PostEndpoint;

// ✅ 타입 안전한 이벤트 이름
type ObjectEvents<T> = {
  [K in keyof T as `on${Capitalize<string & K>}Changed`]: (value: T[K]) => void;
};

interface User {
  name: string;
  age: number;
}

type UserEvents = ObjectEvents<User>;
// {
//   onNameChanged: (value: string) => void;
//   onAgeChanged: (value: number) => void;
// }
```

---

### 6. Generic Constraints 심화

#### `extends`로 타입 제약

```typescript
// ✅ 기본 제약
function getLength<T extends { length: number }>(item: T): number {
  return item.length;
}

getLength('hello');      // ✅
getLength([1, 2, 3]);    // ✅
getLength({ length: 5 }); // ✅
getLength(123);          // ❌ number에는 length가 없음

// ✅ 여러 제약 조합
interface HasId {
  id: number;
}

interface HasName {
  name: string;
}

function findById<T extends HasId & HasName>(items: T[], id: number): T | undefined {
  return items.find((item) => item.id === id);
}
```

#### `keyof`로 객체 키 제약

```typescript
// ✅ 객체의 키만 허용
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user = { id: 1, name: 'John', age: 30 };

const name = getProperty(user, 'name');  // ✅ string
const age = getProperty(user, 'age');    // ✅ number
const invalid = getProperty(user, 'email'); // ❌ 타입 에러

// ✅ 업데이트 함수
function updateProperty<T, K extends keyof T>(
  obj: T,
  key: K,
  value: T[K]
): T {
  return { ...obj, [key]: value };
}

const updatedUser = updateProperty(user, 'age', 31); // ✅
const invalidUpdate = updateProperty(user, 'age', 'thirty'); // ❌ 타입 에러
```

#### `infer`로 타입 추출

```typescript
// ✅ 배열 요소 타입 추출
type ElementType<T> = T extends (infer U)[] ? U : never;

type StringArray = ElementType<string[]>;  // string
type NumberArray = ElementType<number[]>;  // number

// ✅ Promise 결과 타입 추출
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;

type Result = UnwrapPromise<Promise<string>>;  // string
type Result2 = UnwrapPromise<number>;          // number

// ✅ 함수 반환 타입 추출 (ReturnType 재구현)
type MyReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

function getUser() {
  return { id: 1, name: 'John' };
}

type User = MyReturnType<typeof getUser>;  // { id: number; name: string; }

// ✅ 복잡한 예시: 중첩 타입 추출
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object
    ? DeepReadonly<T[K]>
    : T[K];
};
```

---

### 7. Index Signatures vs Record

**Index Signature의 위험성**

```typescript
// ❌ 위험: 존재하지 않는 키도 허용
interface UserMap {
  [key: string]: User;
}

const users: UserMap = {
  john: { id: 1, name: 'John' },
};

const user = users['nonexistent']; // undefined이지만 타입은 User
console.log(user.name); // 런타임 에러!
```

**안전한 Index Signature**

```typescript
// ✅ undefined 명시
interface UserMap {
  [key: string]: User | undefined;
}

const user = users['nonexistent']; // User | undefined
if (user) {
  console.log(user.name); // ✅ 안전
}
```

**Record 사용 (리터럴 타입과 함께)**

```typescript
// ✅ Record with finite keys
type UserRole = 'admin' | 'user' | 'guest';
type Permissions = Record<UserRole, string[]>;

const permissions: Permissions = {
  admin: ['read', 'write', 'delete'],
  user: ['read', 'write'],
  guest: ['read'],
  // ✅ 모든 키를 제공해야 함
};

// ❌ 빠진 키가 있으면 에러
const incomplete: Permissions = {
  admin: ['read'],
  // 'user'와 'guest'가 없음
};
```

**언제 무엇을 사용할까?**

```typescript
// ✅ 유한한 키 집합 → Record
type ErrorMessages = Record<ErrorCode, string>;

// ✅ 동적인 키 + 안전성 필요 → Index Signature + undefined
interface Cache {
  [key: string]: CachedData | undefined;
}

// ✅ 동적인 키 + 복잡한 로직 → Map
const cache = new Map<string, CachedData>();
```

---

### 8. Const Assertions 심화

**`as const`의 효과**

```typescript
// ⚠️ 일반 객체
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
};
// config: { apiUrl: string; timeout: number; }

// ✅ as const
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
} as const;
// config: {
//   readonly apiUrl: 'https://api.example.com';
//   readonly timeout: 5000;
// }

config.timeout = 10000; // ❌ 에러: readonly
```

**실용적인 패턴**

```typescript
// ✅ 상수 배열
const STATUSES = ['pending', 'approved', 'rejected'] as const;
type Status = (typeof STATUSES)[number];
// type Status = 'pending' | 'approved' | 'rejected'

// ✅ 설정 객체
const ROUTES = {
  home: '/',
  about: '/about',
  contact: '/contact',
} as const;

type RouteKey = keyof typeof ROUTES;
type RoutePath = (typeof ROUTES)[RouteKey];

// ✅ Enum 대안
const Color = {
  Red: '#ff0000',
  Green: '#00ff00',
  Blue: '#0000ff',
} as const;

type ColorName = keyof typeof Color;
type ColorValue = (typeof Color)[ColorName];

function setColor(color: ColorValue) {
  // color는 '#ff0000' | '#00ff00' | '#0000ff'
}

// ✅ 함수 파라미터
function createUser(name: string, role: 'admin' | 'user') {
  return { name, role };
}

// ❌ 타입 에러
const role = 'admin';
createUser('John', role); // string은 'admin' | 'user'에 할당 불가

// ✅ as const로 해결
const role = 'admin' as const;
createUser('John', role); // ✅
```

---

## Utility Types 활용

TypeScript는 타입 변환을 안전하게 수행할 수 있는 내장 Utility Types를 제공합니다.

### 1. Partial\<T>

**모든 속성을 선택적(optional)으로 만듭니다.**

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  age: number;
}

// ✅ 일부 필드만 업데이트
function updateUser(id: number, updates: Partial<User>) {
  // updates는 { name?: string, email?: string, ... }
}

updateUser(1, { name: 'John' }); // ✅
updateUser(1, { email: 'john@example.com' }); // ✅
updateUser(1, {}); // ✅ 빈 객체도 가능
```

**⚠️ 주의사항**: 객체 생성 시 `Partial`을 사용하면 빈 객체도 허용됩니다!

```typescript
// ❌ 위험: 빈 객체도 허용
function createUser(user: Partial<User>): User {
  return { id: 0, name: '', email: '', age: 0, ...user };
}

createUser({}); // ✅ 타입 에러 없지만 의도와 다를 수 있음
```

### 2. Pick\<T, Keys>

**특정 속성만 선택합니다.**

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
}

// ✅ API 응답에는 password를 제외
type UserResponse = Pick<User, 'id' | 'name' | 'email'>;

// ✅ 프로필 페이지에는 id와 name만 필요
type UserPreview = Pick<User, 'id' | 'name'>;
```

### 3. Omit\<T, Keys>

**특정 속성을 제외합니다.**

```typescript
// ✅ 사용자 생성 시 id는 자동 생성
type CreateUserInput = Omit<User, 'id' | 'createdAt'>;

function createUser(input: CreateUserInput): User {
  return {
    ...input,
    id: Math.random(),
    createdAt: new Date(),
  };
}

createUser({
  name: 'John',
  email: 'john@example.com',
  password: 'secret',
});
```

**⚠️ 주의사항**: 필수 필드를 제거하면 타입 안전성이 떨어집니다!

```typescript
// ❌ 위험: id를 제거했는데 대체하지 않음
type UserWithoutId = Omit<User, 'id'>;

function processUser(user: UserWithoutId) {
  // user.id가 없는데 사용하려 하면 런타임 에러
}
```

### 4. Record\<Keys, Type>

**객체 타입을 간단하게 정의합니다.**

```typescript
// ✅ 권한 맵
type UserRole = 'admin' | 'user' | 'guest';
type Permissions = Record<UserRole, boolean>;

const permissions: Permissions = {
  admin: true,
  user: true,
  guest: false,
};

// ✅ 에러 메시지 맵
type ErrorCode = 'NOT_FOUND' | 'UNAUTHORIZED' | 'SERVER_ERROR';
type ErrorMessages = Record<ErrorCode, string>;

const messages: ErrorMessages = {
  NOT_FOUND: '리소스를 찾을 수 없습니다',
  UNAUTHORIZED: '권한이 없습니다',
  SERVER_ERROR: '서버 에러가 발생했습니다',
};
```

### 5. Required\<T>

**모든 선택적 속성을 필수로 만듭니다.**

```typescript
interface Config {
  apiUrl?: string;
  timeout?: number;
  retries?: number;
}

// ✅ 초기화 후에는 모든 값이 필수
type InitializedConfig = Required<Config>;

function initConfig(config: Config): InitializedConfig {
  return {
    apiUrl: config.apiUrl ?? 'http://localhost',
    timeout: config.timeout ?? 5000,
    retries: config.retries ?? 3,
  };
}
```

### 6. Readonly\<T>

**모든 속성을 읽기 전용으로 만듭니다.**

```typescript
interface User {
  id: number;
  name: string;
}

const user: Readonly<User> = {
  id: 1,
  name: 'John',
};

// ❌ 에러 발생
user.name = 'Jane'; // Cannot assign to 'name' because it is a read-only property
```

### 7. ReturnType\<T>

**함수의 반환 타입을 추출합니다.**

```typescript
function getUser() {
  return { id: 1, name: 'John', email: 'john@example.com' };
}

// ✅ 함수의 반환 타입을 자동으로 추출
type User = ReturnType<typeof getUser>;
// type User = { id: number; name: string; email: string; }
```

### 8. Parameters\<T>

**함수의 파라미터 타입을 튜플로 추출합니다.**

```typescript
function createUser(name: string, age: number, email: string) {
  return { name, age, email };
}

// ✅ 함수의 파라미터 타입을 추출
type CreateUserParams = Parameters<typeof createUser>;
// type CreateUserParams = [name: string, age: number, email: string]
```

---

## 커밋 전 타입 에러 체크

**타입 에러가 있는 코드를 커밋하지 않도록 pre-commit hook을 설정합니다.**

### 1. Husky + lint-staged 설치

```bash
# Husky 설치
pnpm add -D husky

# Husky 초기화
npx husky init

# lint-staged 설치
pnpm add -D lint-staged
```

### 2. package.json 설정

```json
{
  "scripts": {
    "prepare": "husky install",
    "type-check": "tsc --noEmit"
  },
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ]
  }
}
```

### 3. Pre-commit Hook 설정

#### 방법 1: 전체 프로젝트 타입 체크 (권장)

**lint-staged는 staged 파일만 체크하지만, TypeScript는 전체 프로젝트를 체크해야 합니다.**

```bash
# .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Lint와 Format (staged 파일만)
pnpm lint-staged

# 타입 체크 (전체 프로젝트)
pnpm type-check
```

**이유**: 한 파일의 타입 변경이 다른 파일에 영향을 미칠 수 있기 때문입니다.

```typescript
// user.ts (staged)
export interface User {
  id: number;
  name: string;
  // email 필드 제거
}

// profile.tsx (not staged)
function ProfilePage() {
  const user = getUser();
  return <div>{user.email}</div>; // 타입 에러!
}
```

#### 방법 2: tsc-files 사용 (선택적)

```bash
pnpm add -D tsc-files
```

```json
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write",
      "tsc-files --noEmit"
    ]
  }
}
```

**단점**: 파일 간 의존성을 완벽히 체크하지 못할 수 있습니다.

### 4. CI/CD에서도 타입 체크

**GitHub Actions 예시**

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  type-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: pnpm/action-setup@v2
        with:
          version: 8
      - uses: actions/setup-node@v3
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm type-check
      - run: pnpm lint
      - run: pnpm test
```

---

## 실전 예시

### 예시 1: API 응답 타입 안전하게 처리

```typescript
// ❌ 위험한 방법
async function fetchUser(id: number) {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json(); // any 타입
  return data;
}

// ✅ 안전한 방법
interface User {
  id: number;
  name: string;
  email: string;
}

interface ApiResponse<T> {
  data: T;
  error?: string;
}

async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`);

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  const json: unknown = await response.json();

  // 런타임 검증
  if (!isUser(json)) {
    throw new Error('Invalid user data');
  }

  return json;
}

// 타입 가드
function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'name' in data &&
    'email' in data &&
    typeof (data as User).id === 'number' &&
    typeof (data as User).name === 'string' &&
    typeof (data as User).email === 'string'
  );
}
```

### 예시 2: Zod로 런타임 검증과 타입 추론 동시에

```bash
pnpm add zod
```

```typescript
import { z } from 'zod';

// ✅ Zod 스키마 정의
const UserSchema = z.object({
  id: z.number(),
  name: z.string(),
  email: z.string().email(),
  age: z.number().min(0).optional(),
});

// ✅ 타입 자동 추론
type User = z.infer<typeof UserSchema>;

async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const json = await response.json();

  // ✅ 런타임 검증 + 타입 안전
  return UserSchema.parse(json);
}

// ✅ 에러 처리
try {
  const user = await fetchUser(1);
  console.log(user.name);
} catch (error) {
  if (error instanceof z.ZodError) {
    console.error('Validation error:', error.errors);
  }
}
```

### 예시 3: Generic 함수로 재사용성 높이기

```typescript
// ✅ Generic 함수
async function fetchApi<T>(
  url: string,
  schema: z.ZodSchema<T>
): Promise<T> {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  const json = await response.json();
  return schema.parse(json);
}

// 사용
const user = await fetchApi('/api/users/1', UserSchema);
const posts = await fetchApi('/api/posts', z.array(PostSchema));
```

---

## 레퍼런스

### 공식 문서
- **[TypeScript Handbook - Basic Types](https://www.typescriptlang.org/docs/handbook/basic-types.html)**
  TypeScript 공식 문서 - 기본 타입

- **[TypeScript TSConfig Reference](https://www.typescriptlang.org/tsconfig)**
  컴파일러 옵션 전체 레퍼런스

- **[TypeScript Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html)**
  공식 Utility Types 문서

### Best Practices
- **[TypeScript Best Practices in 2025 (DEV Community)](https://dev.to/mitu_mariam/typescript-best-practices-in-2025-57hb)**
  2025년 TypeScript best practices

- **[Understanding TypeScript's Strict Option (Better Stack)](https://betterstack.com/community/guides/scaling-nodejs/typescript-strict-option/)**
  Strict mode 상세 가이드

- **[Mastering TypeScript Utility Types (DEV Community)](https://dev.to/ebereplenty/mastering-typescript-utility-types-partial-pick-omit-record-more-2ga2)**
  Utility Types 심화 가이드

### Pre-commit Hooks
- **[Run TypeScript type check in pre-commit hook (DEV Community)](https://dev.to/samueldjones/run-a-typescript-type-check-in-your-pre-commit-hook-using-lint-staged-husky-30id)**
  Husky + lint-staged 설정 가이드

- **[Prevent Bad Commits with Husky (Better Stack)](https://betterstack.com/community/guides/scaling-nodejs/husky-and-lint-staged/)**
  Husky와 lint-staged 종합 가이드

### 고급 타입 패턴
- **[Nominal Typing in TypeScript (Michal Zalecki)](https://michalzalecki.com/nominal-typing-in-typescript/)**
  Branded Types 구현 패턴 4가지 비교

- **[Branded Types (Learning TypeScript)](https://www.learningtypescript.com/articles/branded-types)**
  Branded Types 사용 사례 및 라이브러리

- **[Type Guards and Assertion Functions (2ality)](https://2ality.com/2020/06/type-guards-assertion-functions-typescript.html)**
  타입 가드와 assertion functions 상세 가이드

- **[TypeScript Narrowing (공식 문서)](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)**
  Type narrowing 기법 전체

- **[Exhaustiveness Checking with never (Sling Academy)](https://www.slingacademy.com/article/exhaustiveness-checking-with-never-type-in-typescript/)**
  never 타입으로 완전성 체크

- **[Generic Constraints with extends/keyof/infer (Medium 2025)](https://medium.com/@it.works/tackle-complex-typescript-constraints-with-ease-extends-keyof-infer-and-conditional-magic-cbe69cac218a)**
  제네릭 제약 고급 패턴

---

## 요약

### 핵심 체크리스트

✅ **tsconfig.json**
- [ ] `"strict": true` 설정
- [ ] `"noImplicitAny": true` 확인
- [ ] `"strictNullChecks": true` 확인

✅ **기본 코딩 패턴**
- [ ] `any` 대신 `unknown` 사용
- [ ] 중요한 함수에 명시적 타입 선언
- [ ] `!` (non-null assertion) 최소화
- [ ] Type Guards 활용
- [ ] Discriminated Unions 패턴 사용

✅ **고급 타입 패턴**
- [ ] Branded Types로 논리적 타입 구분
- [ ] Assertion Functions로 타입 좁히기
- [ ] Exhaustiveness Checking (never + default case)
- [ ] Template Literal Types로 타입 안전한 문자열
- [ ] Generic Constraints (extends, keyof, infer)
- [ ] Index Signature에 undefined 명시
- [ ] `as const`로 리터럴 타입 유지

✅ **Utility Types**
- [ ] `Partial<T>` - 업데이트 함수
- [ ] `Pick<T, Keys>` - API 응답 타입
- [ ] `Omit<T, Keys>` - 생성 입력 타입
- [ ] `Record<K, V>` - 맵 타입

✅ **Pre-commit Hooks**
- [ ] Husky 설치 및 설정
- [ ] `pnpm type-check` 스크립트 추가
- [ ] pre-commit hook에 타입 체크 추가
- [ ] CI/CD에도 타입 체크 포함

### 타입 에러 발생 시 대응

1. **에러 메시지 정확히 읽기**: TypeScript 에러는 매우 정확합니다
2. **타입 추론 확인**: IDE에서 hover하여 실제 타입 확인
3. **`any` 사용 금지**: 임시방편으로 `any`를 쓰지 않기
4. **근본 원인 해결**: 타입 단언(`as`)으로 에러만 숨기지 않기

### 다음 단계

#### 기본 설정 (필수)
1. 기존 프로젝트에 `"strict": true` 적용
2. `any` 사용 지점 찾아서 `unknown`이나 명시적 타입으로 변경
3. Husky + lint-staged 설정으로 pre-commit type check 적용
4. Zod나 io-ts 같은 런타임 검증 라이브러리 도입 검토

#### 고급 패턴 적용 (권장)
5. Branded Types로 ID 타입 구분 (UserId, PostId 등)
6. Assertion Functions로 null 체크 간소화
7. switch 문에 Exhaustiveness Checking 적용
8. API 엔드포인트에 Template Literal Types 적용
9. Generic 함수에 적절한 제약 추가 (extends, keyof)
10. Index Signature 대신 Record 또는 Map 사용 검토
