# RetryBackoff API

> ⚠️ This document is a translated version of the original Korean API documentation.
> There may be minor inaccuracies or differences from the original version.

---

## Common Types

```lua
type Action = () -> ...any
type ErrorAction = (attempt: number, result: any, cap: number?) -> ()
```

All functions execute `action` using `pcall`.
If the call succeeds, the result is returned immediately.
If it fails, the system waits based on the backoff strategy and retries.

---

## ConstantBackoff

```lua
RetryBackoff.ConstantBackoff(
	waitTime: number?,
	maxRetries: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
```

Retries with a fixed delay between attempts.

* `waitTime`: Delay between retries in seconds. Default: `0`
* `maxRetries`: Maximum number of attempts. If nil or less than 1, retries indefinitely
* `action`: Function to execute
* `errorAction`: Callback executed on each failure

---

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

Waits `attempt * base` seconds before retrying.

* `base`: Linear scaling factor. Default: `1`
* `cap`: Maximum delay. Default: `math.huge`
* `maxRetries`: Maximum number of attempts
* `action`: Function to execute
* `errorAction`: Callback executed on failure

---

## ExponentialBackoff

```lua
RetryBackoff.ExponentialBackoff(
	cap: number?,
	maxRetries: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
```

Waits `2 ^ attempt` seconds before retrying.

* `cap`: Maximum delay. Default: `math.huge`
* `maxRetries`: Maximum number of attempts
* `action`: Function to execute
* `errorAction`: Callback executed on failure

---

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

Waits for a random duration between `0` and `2 ^ attempt * jitterPercent`.

* `cap`: Maximum delay. Default: `math.huge`
* `maxRetries`: Maximum number of attempts
* `jitterPercent`: Random range percentage (0–100). Default: `50`
* `action`: Function to execute
* `errorAction`: Callback executed on failure

---

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

Adds a random jitter value to the base exponential delay (`2 ^ attempt`).

* `cap`: Maximum delay. Default: `math.huge`
* `maxRetries`: Maximum number of attempts
* `jitterPercent`: Additional random percentage (0–100). Default: `50`
* `action`: Function to execute
* `errorAction`: Callback executed on failure

---

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

Splits the delay into a fixed portion and a random jitter portion.

* `cap`: Maximum delay. Default: `math.huge`
* `maxRetries`: Maximum number of attempts
* `jitterPercent`: Random ratio (0–100). Default: `50`
* `action`: Function to execute
* `errorAction`: Callback executed on failure

---

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

Uses Full Jitter but ensures the delay is never less than `minLimit`.

* `minLimit`: Minimum delay. Default: `0`
* `cap`: Maximum delay. Default: `math.huge`
* `maxRetries`: Maximum number of attempts
* `jitterPercent`: Random ratio (0–100). Default: `50`
* `action`: Function to execute
* `errorAction`: Callback executed on failure
