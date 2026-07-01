# RetryBackoff

Roblox Luau에서 사용할 수 있는 재시도 백오프 유틸리티입니다.

`pcall(action)`으로 작업을 실행하고, 실패하면 지정된 백오프 전략에 따라 `task.wait()` 후 다시 시도합니다. 모든 API는 `typeof(--[[ 설명 ]] function(...) ... end)` 타입 선언을 사용하므로, 다른 코드에서 `require()`로 불러왔을 때 함수 설명과 시그니처를 에디터 자동완성에서 확인하기 좋습니다.

## 파일

- `retryBackoff.fixed.luau`: 한국어 설명 주석 버전
- `retryBackoff.english.luau`: 영어 설명 주석 버전
- `README.md`: 간단 사용 설명
- `API.md`: 함수별 API 설명

## 설치

Roblox Studio 프로젝트의 ModuleScript에 `retryBackoff.fixed.luau` 또는 `retryBackoff.english.luau` 내용을 넣고 사용합니다.

```lua
local RetryBackoff = require(path.to.RetryBackoff)
```

## 기본 사용법

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

## 반환값

모든 함수는 `(boolean, ...any)`를 반환합니다.

- 성공하면 `true, ...actionResults`
- 실패하면 `false, errorMessage`
- `action`이 nil이면 `false, "action is nil"`

## maxRetries 동작

`maxRetries`는 최대 실행 횟수입니다. 예를 들어 `maxRetries = 3`이면 최초 실행을 포함해 최대 3번 `action`을 실행합니다.

`maxRetries`가 nil이거나 1보다 작으면 무한 재시도합니다.

## errorAction

`errorAction`은 실패할 때마다 호출되는 선택 콜백입니다.

```lua
function(attempt: number, result: any, cap: number?)
	print(attempt, result, cap)
end
```

`ConstantBackoff`는 cap 개념이 없기 때문에 `cap`으로 nil을 전달합니다.

## 선택 기준

- `ConstantBackoff`: 항상 같은 간격으로 재시도
- `LinearBackoff`: 점진적으로 대기시간 증가
- `ExponentialBackoff`: 빠르게 대기시간 증가
- `FullJitterBackoff`: 랜덤 분산이 가장 큼
- `AdditiveJitterBackoff`: 기본 지수 대기시간에 랜덤값 추가
- `EqualJitterBackoff`: 일부 고정, 일부 랜덤
- `ManagedJitterBackoff`: 최소 대기시간 보장
