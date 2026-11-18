--!strict
-- Brainrot Bazaar Server Entry Point

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServerScript = script
local Config = require(ServerScript:WaitForChild("Config"))
local PlayerService = require(ServerScript:WaitForChild("PlayerService"))
local BaseService = require(ServerScript:WaitForChild("BaseService"))
local BrainrotService = require(ServerScript:WaitForChild("BrainrotService"))
local EventService = require(ServerScript:WaitForChild("EventService"))

print("[Brainrot Bazaar] Initializing Server Systems...")

-- Initialize Services in order
PlayerService.Init()
BaseService.Init()
BrainrotService.Init()
EventService.Init()

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local buyRemote = remotesFolder:WaitForChild("BuyBrainrot") :: RemoteEvent
local lockRemote = remotesFolder:WaitForChild("LockBase") :: RemoteEvent
local stealRemote = remotesFolder:WaitForChild("StealBrainrot") :: RemoteEvent
local rebirthRemote = remotesFolder:WaitForChild("Rebirth") :: RemoteEvent
local syncRemote = remotesFolder:WaitForChild("GameStateSync") :: RemoteEvent
local notifyRemote = remotesFolder:WaitForChild("Notify") :: RemoteEvent

-- Remote Event Handlers
buyRemote.OnServerEvent:Connect(function(player: Player, itemId: any)
	if typeof(itemId) == "string" then
		local success, message = BrainrotService.BuyBrainrotById(player, itemId)
		notifyRemote:FireClient(player, message, not success)
	end
end)

lockRemote.OnServerEvent:Connect(function(player: Player)
	local success, message = BaseService.RequestLockBase(player)
	notifyRemote:FireClient(player, message, not success)
end)

stealRemote.OnServerEvent:Connect(function(player: Player, targetBaseId: any, slotIndex: any)
	if typeof(targetBaseId) == "string" and typeof(slotIndex) == "number" then
		local success, message = BaseService.StealBrainrot(player, targetBaseId, slotIndex)
		notifyRemote:FireClient(player, message, not success)
	end
end)

rebirthRemote.OnServerEvent:Connect(function(player: Player)
	local canRebirth, cost = PlayerService.CanAffordRebirth(player)
	if not canRebirth then
		notifyRemote:FireClient(player, string.format("Need $%d coins to rebirth!", cost), true)
		return
	end

	BaseService.ClearBaseSlots(player)
	local success = PlayerService.Rebirth(player)
	if success then
		BrainrotService.RecalculatePlayerIncome(player)
		notifyRemote:FireClient(player, "🌟 REBIRTH SUCCESSFUL! +25% Income Multiplier Activated!", false)
	else
		notifyRemote:FireClient(player, "Rebirth failed.", true)
	end
end)

-- Periodic GameStateSync to all clients
task.spawn(function()
	while true do
		task.wait(0.5)

		local leaderboard = PlayerService.GetLeaderboard()
		local stormStatus = EventService.GetStormStatus()

		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerService.Get(player)
			local plot = BaseService.GetPlayerBase(player)

			if data then
				local slotsSummary = {}
				local isLocked = false
				local lockRemaining = 0
				local inCooldown = false
				local cooldownRemaining = 0

				if plot then
					isLocked = BaseService.IsBaseLocked(plot)
					lockRemaining = BaseService.GetLockTimeRemaining(plot)
					inCooldown, cooldownRemaining = BaseService.IsBaseInCooldown(plot)
					BaseService.UpdateBaseVisuals(plot)

					for idx = 1, Config.Economy.SlotCount do
						local slot = plot.Slots[idx]
						if slot then
							table.insert(slotsSummary, {
								SlotIndex = idx,
								CharacterId = slot.CharacterId,
								Name = slot.Name,
								Rarity = slot.Rarity,
								Mutation = slot.Mutation,
								Income = slot.Income,
							})
						end
					end
				end

				syncRemote:FireClient(player, {
					Coins = data.Coins,
					Rebirths = data.Rebirths,
					Income = data.IncomePerSec,
					BaseId = plot and plot.Id or nil,
					BaseLocked = isLocked,
					LockRemaining = lockRemaining,
					InCooldown = inCooldown,
					CooldownRemaining = cooldownRemaining,
					Slots = slotsSummary,
					Leaderboard = leaderboard,
					Storm = stormStatus,
				})
			end
		end
	end
end)

print("[Brainrot Bazaar] Server initialization complete! Conveyor running, bases active.")
