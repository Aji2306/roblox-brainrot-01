--!strict
-- Shared Utilities for Brainrot Bazaar

local Config = require(script.Parent.Config)

local Util = {}

function Util.formatNumber(n: number): string
	local num = math.floor(n + 0.5)
	if num < 1000 then
		return tostring(num)
	elseif num < 1000000 then
		return string.format("%.1fK", num / 1000)
	elseif num < 1000000000 then
		return string.format("%.2fM", num / 1000000)
	else
		return string.format("%.2fB", num / 1000000000)
	end
end

function Util.formatCoins(n: number): string
	return "$" .. Util.formatNumber(n)
end

function Util.formatTime(seconds: number): string
	local sec = math.max(0, math.floor(seconds))
	local mins = math.floor(sec / 60)
	local remainingSec = sec % 60
	if mins > 0 then
		return string.format("%d:%02d", mins, remainingSec)
	else
		return string.format("%ds", remainingSec)
	end
end

function Util.getRarityColor(rarityName: string): Color3
	local rarity = Config.Rarities[rarityName]
	if rarity then
		return rarity.Color
	end
	return Color3.fromRGB(200, 200, 200)
end

function Util.getCharacterById(id: string): any
	for _, char in ipairs(Config.Characters) do
		if char.Id == id then
			return char
		end
	end
	return nil
end

function Util.calculateRebirthCost(rebirths: number): number
	local base = Config.Economy.RebirthBaseCost
	local scale = Config.Economy.RebirthCostScale
	return math.floor(base * (scale ^ rebirths))
end

function Util.calculateIncome(baseIncome: number, mutationMultiplier: number, rebirths: number): number
	local rebirthBonus = 1 + (rebirths * Config.Economy.RebirthIncomeMultiplier)
	return math.floor(baseIncome * mutationMultiplier * rebirthBonus)
end

function Util.deepCopy<T>(orig: T): T
	local origType = type(orig)
	local copy
	if origType == "table" then
		copy = {}
		for origKey, origValue in pairs(orig :: any) do
			copy[Util.deepCopy(origKey)] = Util.deepCopy(origValue)
		end
	else
		copy = orig
	end
	return copy :: T
end

return Util
