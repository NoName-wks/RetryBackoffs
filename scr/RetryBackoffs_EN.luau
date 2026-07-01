export type retryBackoffs = {
	ConstantBackoff: typeof(
	--[=[
		Constant interval backoff.
		Waits for the same waitTime until maxRetries is reached.
		Calls errorAction(attempt, result, cap) when action fails.
		waitTime is in seconds and defaults to 0.
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
		Linear backoff.
		Waits for attempt * base until maxRetries is reached.
		If cap is provided, the wait time will not exceed cap.
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
		Exponential backoff.
		Waits for 2 ^ attempt seconds.
		If cap is provided, the wait time will not exceed cap.
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
		Full jitter backoff.
		Waits for a random value from 0 to 2 ^ attempt * jitterPercent.
		jitterPercent is a value from 0 to 100 and defaults to 50.
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
		Additive jitter backoff.
		Adds random jitter to the base 2 ^ attempt wait time.
		jitterPercent is a value from 0 to 100 and defaults to 50.
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
		Equal jitter backoff.
		Keeps part of the wait time fixed and adds random jitter to the rest.
		jitterPercent is a value from 0 to 100 and defaults to 50.
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
		Managed jitter backoff.
		Uses full jitter while guaranteeing a minimum wait time.
		jitterPercent is a value from 0 to 100 and defaults to 50.
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
	return if maxRetries and maxRetries >= 1 then maxRetries else math.huge
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
