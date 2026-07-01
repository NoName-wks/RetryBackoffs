# RetryBackoff

---

## 🇰🇷 한국어 (README_KR.md)

Roblox Luau에서 사용할 수 있는 재시도 백오프 유틸리티입니다.

`pcall(action)`으로 작업을 실행하고, 실패하면 지정된 백오프 전략에 따라 `task.wait()` 후 다시 시도합니다. 모든 API는 `typeof(--[[ 설명 ]] function(...) ... end)` 타입 선언을 사용하므로, 다른 코드에서 `require()`로 불러왔을 때 함수 설명과 시그니처를 에디터 자동완성에서 확인하기 좋습니다.

### 파일

* `retryBackoff.fixed.luau`: 한국어 설명 주석 버전
* `retryBackoff.english.luau`: 영어 설명 주석 버전
* `README.md`: 간단 사용 설명
* `API.md`: 함수별 API 설명

### 설치

Roblox Studio 프로젝트의 ModuleScript에 `retryBackoff.fixed.luau` 또는 `retryBackoff.english.luau` 내용을 넣고 사용합니다.

```lua
local RetryBackoff = require(path.to.RetryBackoff)
```

### 기본 사용법

```lua
local RetryBackoff = require(path.to.RetryBackoff)

local success, result = RetryBackoff.ExponentialBackoff(
	10,
	5,
	function()
		return HttpService:GetAsync("https://example.com")
	end,
	function(attempt, err, cap)
		warn("request failed", attempt, err, cap)
	end
)

if success then
	print(result)
else
	warn("all retries failed", result)
end
```

### 반환값

모든 함수는 `(boolean, ...any)`를 반환합니다.

* 성공하면 `true, ...actionResults`
* 실패하면 `false, errorMessage`
* `action`이 nil이면 `false, "action is nil"`

### maxRetries 동작

`maxRetries`는 최대 실행 횟수입니다. 최초 실행을 포함합니다.

* 예: `maxRetries = 3` → 최대 3번 실행
* `nil` 또는 1 미만 → 무한 재시도

### errorAction

실패할 때마다 호출되는 선택 콜백입니다.

```lua
function(attempt: number, result: any, cap: number?)
	print(attempt, result, cap)
end
```

`ConstantBackoff`는 cap이 없으므로 `nil`이 전달됩니다.

### 선택 기준

* `ConstantBackoff`: 항상 같은 간격
* `LinearBackoff`: 점진 증가
* `ExponentialBackoff`: 빠른 증가
* `FullJitterBackoff`: 최대 랜덤 분산
* `AdditiveJitterBackoff`: 기본 + 랜덤
* `EqualJitterBackoff`: 고정 + 랜덤 혼합
* `ManagedJitterBackoff`: 최소 대기시간 보장

---

## 🇺🇸 English (Translated)

> ⚠️ This section is a translated version of `README_KR.md`.
> There may be minor inaccuracies compared to the original Korean documentation.

A retry backoff utility for Roblox Luau.

This module executes a task using `pcall(action)`, and if it fails, retries after `task.wait()` using a specified backoff strategy.
All APIs use `typeof(--[[ description ]] function(...) ... end)` type annotations, making function signatures and descriptions visible in editor autocomplete when required.

### Files

* `retryBackoff.fixed.luau`: Korean comments
* `retryBackoff.english.luau`: English comments
* `README.md`: Basic usage guide
* `API.md`: Detailed API documentation

### Installation

Paste either `retryBackoff.fixed.luau` or `retryBackoff.english.luau` into a ModuleScript.

```lua
local RetryBackoff = require(path.to.RetryBackoff)
```

### Basic Usage

```lua
local RetryBackoff = require(path.to.RetryBackoff)

local success, result = RetryBackoff.ExponentialBackoff(
	10,
	5,
	function()
		return HttpService:GetAsync("https://example.com")
	end,
	function(attempt, err, cap)
		warn("request failed", attempt, err, cap)
	end
)

if success then
	print(result)
else
	warn("all retries failed", result)
end
```

### Return Values

All functions return `(boolean, ...any)`:

* On success: `true, ...actionResults`
* On failure: `false, errorMessage`
* If `action` is nil: `false, "action is nil"`

### maxRetries Behavior

`maxRetries` defines the maximum number of attempts, including the initial execution.

* Example: `maxRetries = 3` → up to 3 attempts
* `nil` or less than 1 → infinite retry

### errorAction

Optional callback executed on each failure.

```lua
function(attempt: number, result: any, cap: number?)
	print(attempt, result, cap)
end
```

For `ConstantBackoff`, `cap` is not used, so `nil` is passed.

### Strategy Guide

* `ConstantBackoff`: Fixed interval
* `LinearBackoff`: Gradual increase
* `ExponentialBackoff`: Rapid increase
* `FullJitterBackoff`: Maximum randomness
* `AdditiveJitterBackoff`: Base + random
* `EqualJitterBackoff`: Fixed + random mix
* `ManagedJitterBackoff`: Minimum delay guaranteed
