--[=[
[LICENSE]
------------------------------------------------------------------------------------------------
MIT License

Copyright (c) 2026 NoName-wks

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

-----------------------------------------------------------------------------------------------
--]=]

export type retryBackoffs = {
	ConstantBackoff: typeof(
	--[=[
		고정 간격 백오프
		maxRetries에 도달할 때까지 항상 동일한 waitTime 만큼 대기합니다.
		action이 실패하면 errorAction(attempt, result, cap)을 호출합니다.
		waitTime은 초 단위이며 기본값은 0입니다.
	]=]
		function(
			waitTime: number?,
			maxRetries: number?,
			action: (() -> ...any)?,
			errorAction: ((attempt: number, result: any, cap: number?) -> ())?
		): (boolean, ...any) end
	),

	LinearBackoff: typeof(
	--[=[
		선형 증가 백오프
		maxRetries에 도달할 때까지 attempt * base 만큼 대기합니다.
		cap이 있으면 대기 시간이 cap을 넘지 않습니다.
	]=]
		function(
			base: number?,
			cap: number?,
			maxRetries: number?,
			action: (() -> ...any)?,
			errorAction: ((attempt: number, result: any, cap: number?) -> ())?
		): (boolean, ...any) end
	),

	ExponentialBackoff: typeof(
	--[=[
		지수 백오프
		2 ^ attempt 만큼 대기합니다.
		cap이 있으면 대기 시간이 cap을 넘지 않습니다.
	]=]
		function(
			cap: number?,
			maxRetries: number?,
			action: (() -> ...any)?,
			errorAction: ((attempt: number, result: any, cap: number?) -> ())?
		): (boolean, ...any) end
	),

	FullJitterBackoff: typeof(
	--[=[
		Full Jitter 백오프
		0 ~ 2 ^ attempt * jitterPercent 범위에서 랜덤 대기합니다.
		jitterPercent는 0~100 값이며 기본값은 50입니다.
	]=]
		function(
			cap: number?,
			maxRetries: number?,
			jitterPercent: number?,
			action: (() -> ...any)?,
			errorAction: ((attempt: number, result: any, cap: number?) -> ())?
		): (boolean, ...any) end
	),

	AdditiveJitterBackoff: typeof(
	--[=[
		Additive Jitter 백오프
		2 ^ attempt 기본 대기시간에 랜덤 jitter를 추가합니다.
		jitterPercent는 0~100 값이며 기본값은 50입니다.
	]=]
		function(
			cap: number?,
			maxRetries: number?,
			jitterPercent: number?,
			action: (() -> ...any)?,
			errorAction: ((attempt: number, result: any, cap: number?) -> ())?
		): (boolean, ...any) end
	),

	EqualJitterBackoff: typeof(
	--[=[
		Equal Jitter 백오프
		대기시간 일부는 고정하고 나머지는 랜덤 jitter로 더합니다.
		jitterPercent는 0~100 값이며 기본값은 50입니다.
	]=]
		function(
			cap: number?,
			maxRetries: number?,
			jitterPercent: number?,
			action: (() -> ...any)?,
			errorAction: ((attempt: number, result: any, cap: number?) -> ())?
		): (boolean, ...any) end
	),

	ManagedJitterBackoff: typeof(
	--[=[
		Managed Jitter 백오프
		Full Jitter 기반으로 대기하되 minLimit 이상의 최소 대기시간을 보장합니다.
		jitterPercent는 0~100 값이며 기본값은 50입니다.
	]=]
		function(
			minLimit: number?,
			cap: number?,
			maxRetries: number?,
			jitterPercent: number?,
			action: (() -> ...any)?,
			errorAction: ((attempt: number, result: any, cap: number?) -> ())?
		): (boolean, ...any) end
	),
}

local retryBackoff = {}

local function getMaxAttempts(maxRetries: number?): number
		if maxRetries == nil then
		return math.huge
	else
		return math.max(maxRetries,1)
	end
end

local function getJitter(jitterPercent: number?): number
	return math.clamp(jitterPercent or 50, 0, 100) / 100
end

local function runWithBackoff(
	name: string,
	maxRetries: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?,
	cap: number?,
	getWaitTime: (attempt: number) -> number
): (boolean, ...any)
	if not action then
		warn("[" .. name .. "] action is nil")
		return false, "action is nil"
	end

	local maxAttempts = getMaxAttempts(maxRetries)
	local attempt = 0
	local results = table.pack(false, "retry was not attempted")

	while attempt < maxAttempts do
		results = table.pack(pcall(action))

		if results[1] then
			return true, table.unpack(results, 2, results.n)
		end

		attempt += 1
		local errorMessage = results[2]

		if errorAction then
			errorAction(attempt, errorMessage, cap)
		end

		if attempt >= maxAttempts then
			return false, errorMessage
		end

		task.wait(getWaitTime(attempt))
	end

	return false, results[2]
end

function retryBackoff.ConstantBackoff(
	waitTime: number?,
	maxRetries: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
	return runWithBackoff("ConstantBackoff", maxRetries, action, errorAction, nil, function()
		return waitTime or 0
	end)
end

function retryBackoff.LinearBackoff(
	base: number?,
	cap: number?,
	maxRetries: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
	local safeBase = base or 1
	local safeCap = cap or math.huge

	return runWithBackoff("LinearBackoff", maxRetries, action, errorAction, safeCap, function(attempt)
		return math.min(attempt * safeBase, safeCap)
	end)
end

function retryBackoff.ExponentialBackoff(
	cap: number?,
	maxRetries: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
	local safeCap = cap or math.huge

	return runWithBackoff("ExponentialBackoff", maxRetries, action, errorAction, safeCap, function(attempt)
		return math.min(2 ^ attempt, safeCap)
	end)
end

function retryBackoff.FullJitterBackoff(
	cap: number?,
	maxRetries: number?,
	jitterPercent: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
	local safeCap = cap or math.huge
	local jitter = getJitter(jitterPercent)

	return runWithBackoff("FullJitterBackoff", maxRetries, action, errorAction, safeCap, function(attempt)
		local baseWait = 2 ^ attempt
		local jitterCeiling = math.max(1, math.floor(baseWait * jitter))
		return math.min(math.random(0, jitterCeiling), safeCap)
	end)
end

function retryBackoff.AdditiveJitterBackoff(
	cap: number?,
	maxRetries: number?,
	jitterPercent: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
	local safeCap = cap or math.huge
	local jitter = getJitter(jitterPercent)

	return runWithBackoff("AdditiveJitterBackoff", maxRetries, action, errorAction, safeCap, function(attempt)
		local baseWait = 2 ^ attempt
		local jitterCeiling = math.max(1, math.floor(baseWait * jitter))
		return math.min(baseWait + math.random(0, jitterCeiling), safeCap)
	end)
end

function retryBackoff.EqualJitterBackoff(
	cap: number?,
	maxRetries: number?,
	jitterPercent: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
	local safeCap = cap or math.huge
	local jitter = getJitter(jitterPercent)

	return runWithBackoff("EqualJitterBackoff", maxRetries, action, errorAction, safeCap, function(attempt)
		local baseWait = 2 ^ attempt
		local fixedPart = baseWait * (1 - jitter)
		local randomCeiling = math.max(1, math.floor(baseWait * jitter))
		return math.min(fixedPart + math.random(0, randomCeiling), safeCap)
	end)
end

function retryBackoff.ManagedJitterBackoff(
	minLimit: number?,
	cap: number?,
	maxRetries: number?,
	jitterPercent: number?,
	action: (() -> ...any)?,
	errorAction: ((attempt: number, result: any, cap: number?) -> ())?
): (boolean, ...any)
	local safeMinLimit = minLimit or 0
	local safeCap = cap or math.huge
	local jitter = getJitter(jitterPercent)

	return runWithBackoff("ManagedJitterBackoff", maxRetries, action, errorAction, safeCap, function(attempt)
		local baseWait = 2 ^ attempt
		local jitterCeiling = math.max(1, math.floor(baseWait * jitter))
		local fullJitter = math.random(0, jitterCeiling)
		return math.min(math.max(safeMinLimit, fullJitter), safeCap)
	end)
end

return retryBackoff :: retryBackoffs
