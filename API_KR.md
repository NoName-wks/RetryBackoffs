# RetryBackoff API

## 공통 타입

```lua
type Action = () -> ...any
type ErrorAction = (attempt: number, result: any, cap: number?) -> ()
```

모든 함수는 `pcall(action)`을 사용합니다. `action`이 성공하면 즉시 반환하고, 실패하면 백오프 대기 후 다시 시도합니다.

## ConstantBackoff

```lua
RetryBackoff.ConstantBackoff(
	waitTime: number?,
	maxRetries: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
```

항상 같은 시간만큼 기다린 뒤 재시도합니다.

- `waitTime`: 재시도 사이 대기 시간. 초 단위. 기본값 `0`
- `maxRetries`: 최대 실행 횟수. nil 또는 1 미만이면 무한 재시도
- `action`: 실행할 함수
- `errorAction`: 실패할 때마다 호출되는 콜백

## LinearBackoff

```lua
RetryBackoff.LinearBackoff(
	base: number?,
	cap: number?,
	maxRetries: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
```

`attempt * base` 만큼 기다립니다.

- `base`: 선형 증가 기준값. 기본값 `1`
- `cap`: 최대 대기 시간. 기본값 `math.huge`
- `maxRetries`: 최대 실행 횟수
- `action`: 실행할 함수
- `errorAction`: 실패 콜백

## ExponentialBackoff

```lua
RetryBackoff.ExponentialBackoff(
	cap: number?,
	maxRetries: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
```

`2 ^ attempt` 만큼 기다립니다.

- `cap`: 최대 대기 시간. 기본값 `math.huge`
- `maxRetries`: 최대 실행 횟수
- `action`: 실행할 함수
- `errorAction`: 실패 콜백

## FullJitterBackoff

```lua
RetryBackoff.FullJitterBackoff(
	cap: number?,
	maxRetries: number?,
	jitterPercent: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
```

`0`부터 `2 ^ attempt * jitterPercent` 사이의 랜덤 시간만큼 기다립니다.

- `cap`: 최대 대기 시간. 기본값 `math.huge`
- `maxRetries`: 최대 실행 횟수
- `jitterPercent`: 랜덤 범위 비율. 0~100. 기본값 `50`
- `action`: 실행할 함수
- `errorAction`: 실패 콜백

## AdditiveJitterBackoff

```lua
RetryBackoff.AdditiveJitterBackoff(
	cap: number?,
	maxRetries: number?,
	jitterPercent: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
```

`2 ^ attempt`에 랜덤 jitter 값을 더해서 기다립니다.

- `cap`: 최대 대기 시간. 기본값 `math.huge`
- `maxRetries`: 최대 실행 횟수
- `jitterPercent`: 랜덤 추가 비율. 0~100. 기본값 `50`
- `action`: 실행할 함수
- `errorAction`: 실패 콜백

## EqualJitterBackoff

```lua
RetryBackoff.EqualJitterBackoff(
	cap: number?,
	maxRetries: number?,
	jitterPercent: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
```

대기시간 일부를 고정하고 나머지를 랜덤 jitter로 더합니다.

- `cap`: 최대 대기 시간. 기본값 `math.huge`
- `maxRetries`: 최대 실행 횟수
- `jitterPercent`: 랜덤 비율. 0~100. 기본값 `50`
- `action`: 실행할 함수
- `errorAction`: 실패 콜백

## ManagedJitterBackoff

```lua
RetryBackoff.ManagedJitterBackoff(
	minLimit: number?,
	cap: number?,
	maxRetries: number?,
	jitterPercent: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
```

Full Jitter 기반으로 기다리되 `minLimit`보다 짧게 기다리지 않습니다.

- `minLimit`: 최소 대기 시간. 기본값 `0`
- `cap`: 최대 대기 시간. 기본값 `math.huge`
- `maxRetries`: 최대 실행 횟수
- `jitterPercent`: 랜덤 비율. 0~100. 기본값 `50`
- `action`: 실행할 함수
- `errorAction`: 실패 콜백
