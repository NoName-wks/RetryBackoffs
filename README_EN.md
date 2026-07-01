# RetryBackoff

A retry backoff utility for Roblox Luau.

This module executes a task using `pcall(action)`, and if it fails, retries after `task.wait()` using a specified backoff strategy.
All APIs are defined using `typeof(--[[ description ]] function(...) ... end)` type annotations, so when required from other scripts, both function signatures and descriptions are visible in editor autocomplete.

> ⚠️ This document is a translated version of `README_KR.md`.
> There may be minor inaccuracies or differences from the original Korean documentation.

## Files

* `retryBackoff.fixed.luau`: Version with Korean comments
* `retryBackoff.english.luau`: Version with English comments
* `README.md`: Basic usage guide
* `API.md`: Detailed API documentation

## Installation

Paste the contents of either `retryBackoff.fixed.luau` or `retryBackoff.english.luau` into a ModuleScript in your Roblox Studio project.

```lua
local RetryBackoff = require(path.to.RetryBackoff)
```

## Basic Usage

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

## Return Values

All functions return `(boolean, ...any)`:

* On success: `true, ...actionResults`
* On failure: `false, errorMessage`
* If `action` is nil: `false, "action is nil"`

## maxRetries Behavior

`maxRetries` represents the maximum number of attempts, including the initial execution.

For example, if `maxRetries = 3`, the `action` will be executed up to 3 times.

If `maxRetries` is nil or less than 1, the retry will continue indefinitely.

## errorAction

`errorAction` is an optional callback executed on every failure.

```lua
function(attempt: number, result: any, cap: number?)
	print(attempt, result, cap)
end
```

For `ConstantBackoff`, `cap` is not applicable, so `nil` is passed.

## Strategy Guide

* `ConstantBackoff`: Retries at a fixed interval
* `LinearBackoff`: Gradually increases delay
* `ExponentialBackoff`: Rapidly increases delay
* `FullJitterBackoff`: Maximum randomness and distribution
* `AdditiveJitterBackoff`: Adds randomness on top of exponential delay
* `EqualJitterBackoff`: Mix of fixed and random delay
* `ManagedJitterBackoff`: Guarantees a minimum delay
