--!strict
-- Player Data & Leaderstats Service

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Config"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local PlayerService = {}

export type PlayerData = {
	Coins: number,
	Rebirths: number,
	TotalEarned: number,
	IncomePerSec: number,
	ClaimedBaseId: string?,
}

local playerDataMap: { [Player]: PlayerData } = {}

function PlayerService.Init()
	Players.PlayerAdded:Connect(function(player)
		PlayerService.OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerService.OnPlayerRemoving(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		PlayerService.OnPlayerAdded(player)
	end
end

function PlayerService.OnPlayerAdded(player: Player)
	local data: PlayerData = {
		Coins = Config.Economy.StarterCoins,
		Rebirths = 0,
		TotalEarned = Config.Economy.StarterCoins,
		IncomePerSec = 0,
		ClaimedBaseId = nil,
	}
	playerDataMap[player] = data

	-- Create Roblox standard leaderstats folder for default player list
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coinsVal = Instance.new("NumberValue")
	coinsVal.Name = "Coins"
	coinsVal.Value = data.Coins
	coinsVal.Parent = leaderstats

	local rebirthsVal = Instance.new("IntValue")
	rebirthsVal.Name = "Rebirths"
	rebirthsVal.Value = data.Rebirths
	rebirthsVal.Parent = leaderstats

	local incomeVal = Instance.new("IntValue")
	incomeVal.Name = "Income/s"
	incomeVal.Value = data.IncomePerSec
	incomeVal.Parent = leaderstats

	leaderstats.Parent = player
end

function PlayerService.OnPlayerRemoving(player: Player)
	playerDataMap[player] = nil
end

function PlayerService.Get(player: Player): PlayerData?
	return playerDataMap[player]
end

function PlayerService.AddCoins(player: Player, amount: number)
	local data = playerDataMap[player]
	if not data or amount <= 0 then
		return
	end

	data.Coins += amount
	data.TotalEarned += amount

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsVal = leaderstats:FindFirstChild("Coins") :: NumberValue?
		if coinsVal then
			coinsVal.Value = data.Coins
		end
	end
end

function PlayerService.SpendCoins(player: Player, amount: number): boolean
	local data = playerDataMap[player]
	if not data or amount < 0 or data.Coins < amount then
		return false
	end

	data.Coins -= amount

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsVal = leaderstats:FindFirstChild("Coins") :: NumberValue?
		if coinsVal then
			coinsVal.Value = data.Coins
		end
	end
	return true
end

function PlayerService.DeductCoinsPercent(player: Player, percent: number): number
	local data = playerDataMap[player]
	if not data or data.Coins <= 0 then
		return 0
	end

	local loss = math.floor(data.Coins * percent)
	if loss < 5 and data.Coins >= 5 then
		loss = 5
	end
	loss = math.min(loss, data.Coins)
	data.Coins -= loss

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsVal = leaderstats:FindFirstChild("Coins") :: NumberValue?
		if coinsVal then
			coinsVal.Value = data.Coins
		end
	end
	return loss
end

function PlayerService.SetIncome(player: Player, income: number)
	local data = playerDataMap[player]
	if not data then
		return
	end
	data.IncomePerSec = income

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local incomeVal = leaderstats:FindFirstChild("Income/s") :: IntValue?
		if incomeVal then
			incomeVal.Value = income
		end
	end
end

function PlayerService.CanAffordRebirth(player: Player): (boolean, number)
	local data = playerDataMap[player]
	if not data then
		return false, 0
	end

	local cost = Util.calculateRebirthCost(data.Rebirths)
	return data.Coins >= cost, cost
end

function PlayerService.Rebirth(player: Player): boolean
	local canRebirth, cost = PlayerService.CanAffordRebirth(player)
	if not canRebirth then
		return false
	end

	local data = playerDataMap[player]
	if not data then
		return false
	end

	data.Coins = Config.Economy.StarterCoins
	data.Rebirths += 1
	data.IncomePerSec = 0

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsVal = leaderstats:FindFirstChild("Coins") :: NumberValue?
		if coinsVal then
			coinsVal.Value = data.Coins
		end
		local rebirthsVal = leaderstats:FindFirstChild("Rebirths") :: IntValue?
		if rebirthsVal then
			rebirthsVal.Value = data.Rebirths
		end
		local incomeVal = leaderstats:FindFirstChild("Income/s") :: IntValue?
		if incomeVal then
			incomeVal.Value = 0
		end
	end

	return true
end

function PlayerService.GetLeaderboard(): { { Name: string, Coins: number, Rebirths: number, Income: number } }
	local list = {}
	for player, data in pairs(playerDataMap) do
		table.insert(list, {
			Name = player.DisplayName or player.Name,
			Coins = math.floor(data.Coins),
			Rebirths = data.Rebirths,
			Income = data.IncomePerSec,
		})
	end

	table.sort(list, function(a, b)
		if a.Rebirths == b.Rebirths then
			return a.Coins > b.Coins
		end
		return a.Rebirths > b.Rebirths
	end)

	return list
end

return PlayerService
