-- FormatNumber
-- ModuleScript à placer dans ReplicatedStorage/utils/
-- Usage : local FormatNumber = require(game.ReplicatedStorage.utils.FormatNumber)

local FormatNumber = {}

local suffixes = {
    { limit = 1e21, suffix = "Se" },
    { limit = 1e18, suffix = "Qn" },
    { limit = 1e15, suffix = "Qa" },
    { limit = 1e12, suffix = "T"  },
    { limit = 1e9,  suffix = "B"  },
    { limit = 1e6,  suffix = "M"  },
    { limit = 1e3,  suffix = "K"  },
}

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function trimZeros(s: string): string
	return s:gsub("%.?0+$", "")
end

local function formatValue(value: number): string
	if value >= 100 then
		return tostring(math.floor(value))
	elseif value >= 10 then
		return trimZeros(string.format("%.1f", value))
	else
		return trimZeros(string.format("%.2f", value))
	end
end

-- ─── format(n) ────────────────────────────────────────────────────────────────
-- Ex : 1234 → "1.23K" | 1500000 → "1.5M" | 42 → "42"
function FormatNumber.format(n: number): string
	if n == nil or n ~= n then return "0" end

	local negative = n < 0
	n = math.abs(n)

	if n >= 1e3 then
		for _, entry in ipairs(suffixes) do
			if n >= entry.limit then
				local val = n / entry.limit
				return (negative and "-" or "") .. formatValue(val) .. entry.suffix
			end
		end
		-- Entre 1 000 et 999 999
		local val = n / 1e3
		return (negative and "-" or "") .. formatValue(val) .. "K"
	end

	return (negative and "-" or "") .. tostring(math.floor(n))
end

-- ─── formatWithSign(n) ────────────────────────────────────────────────────────
function FormatNumber.formatWithSign(n: number): string
	if n == nil or n ~= n then return "+0" end
	if n >= 0 then
		return "+" .. FormatNumber.format(n)
	else
		return "-" .. FormatNumber.format(math.abs(n))
	end
end

-- ─── formatPercent(n) ─────────────────────────────────────────────────────────
-- Ex : 0.183 → "+18.3%" | -0.05 → "-5.0%"
function FormatNumber.formatPercent(n: number): string
	if n == nil or n ~= n then return "0%" end
	local pct = n * 100
	local sign = pct >= 0 and "+" or ""
	return string.format("%s%.1f%%", sign, pct)
end

-- ─── formatRate(n) ────────────────────────────────────────────────────────────
-- Ex : 450 → "+450/s" | 1234 → "+1.23K/s"
function FormatNumber.formatRate(n: number): string
	if n == nil or n ~= n then return "+0/s" end
	return "+" .. FormatNumber.format(n) .. "/s"
end

return FormatNumber