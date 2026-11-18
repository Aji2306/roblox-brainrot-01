--!strict
-- Base Plots, Slot Management, Base Defense & Stealing Service

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Config"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local BaseService = {}

export type BrainrotSlot = {
	SlotIndex: number,
	CharacterId: string,
	Name: string,
	Rarity: string,
	Mutation: string,
	BaseIncome: number,
	MutationMultiplier: number,
	Income: number,
	VisualModel: Model?,
}

export type BasePlot = {
	Id: string,
	Model: Model,
	Owner: Player?,
	LockEndTime: number,
	CooldownEndTime: number,
	Forcefield: Part?,
	LockButton: Part?,
	SignPart: Part?,
	ClaimPad: Part?,
	Slots: { BrainrotSlot? },
}

local bases: { [string]: BasePlot } = {}
local playerBaseMap: { [Player]: BasePlot } = {}

function BaseService.Init()
	for i = 1, Config.Economy.BaseCount do
		local baseId = "BasePlot" .. i
		local baseModel = Workspace:FindFirstChild(baseId) :: Model?
		if baseModel then
			local forcefield = baseModel:FindFirstChild("Forcefield") :: Part?
			local lockButton = baseModel:FindFirstChild("LockButton") :: Part?
			local signPart = baseModel:FindFirstChild("GateSign") :: Part?
			local claimPad = baseModel:FindFirstChild("ClaimPad") :: Part?

			local plot: BasePlot = {
				Id = baseId,
				Model = baseModel,
				Owner = nil,
				LockEndTime = 0,
				CooldownEndTime = 0,
				Forcefield = forcefield,
				LockButton = lockButton,
				SignPart = signPart,
				ClaimPad = claimPad,
				Slots = table.create(Config.Economy.SlotCount),
			}
			bases[baseId] = plot
			BaseService.UpdateBaseVisuals(plot)

			-- Setup ClaimPad Proximity / Touched
			if claimPad then
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Claim Base"
				prompt.ObjectText = "Plot #" .. i
				prompt.MaxActivationDistance = 10
				prompt.RequiresLineOfSight = false
				prompt.Triggered:Connect(function(player)
					BaseService.TryClaimBase(player, plot)
				end)
				prompt.Parent = claimPad
			end

			-- Setup LockButton Proximity
			if lockButton then
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Lock Base ($100)"
				prompt.ObjectText = "Security Console"
				prompt.MaxActivationDistance = 10
				prompt.RequiresLineOfSight = false
				prompt.Triggered:Connect(function(player)
					if plot.Owner == player then
						BaseService.RequestLockBase(player)
					end
				end)
				prompt.Parent = lockButton
			end
		end
	end

	-- Auto assign base on join if available
	Players.PlayerAdded:Connect(function(player)
		task.wait(0.5)
		BaseService.AutoAssignBase(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		BaseService.ReleaseBase(player)
	end)
end

function BaseService.AutoAssignBase(player: Player)
	if playerBaseMap[player] then
		return
	end

	for i = 1, Config.Economy.BaseCount do
		local baseId = "BasePlot" .. i
		local plot = bases[baseId]
		if plot and plot.Owner == nil then
			BaseService.AssignBase(player, plot)
			break
		end
	end
end

function BaseService.TryClaimBase(player: Player, plot: BasePlot)
	if plot.Owner == player then
		return
	end
	if plot.Owner ~= nil then
		return
	end
	-- If player already has a base, release the old one
	if playerBaseMap[player] then
		BaseService.ReleaseBase(player)
	end
	BaseService.AssignBase(player, plot)
end

function BaseService.AssignBase(player: Player, plot: BasePlot)
	plot.Owner = player
	plot.LockEndTime = 0
	plot.CooldownEndTime = 0
	playerBaseMap[player] = plot
	BaseService.UpdateBaseVisuals(plot)
end

function BaseService.ReleaseBase(player: Player)
	local plot = playerBaseMap[player]
	if not plot then
		return
	end

	-- Clear visual models in slots
	for idx = 1, Config.Economy.SlotCount do
		local slot = plot.Slots[idx]
		if slot and slot.VisualModel then
			slot.VisualModel:Destroy()
		end
		plot.Slots[idx] = nil
	end

	plot.Owner = nil
	plot.LockEndTime = 0
	plot.CooldownEndTime = 0
	playerBaseMap[player] = nil
	BaseService.UpdateBaseVisuals(plot)
end

function BaseService.GetPlayerBase(player: Player): BasePlot?
	return playerBaseMap[player]
end

function BaseService.GetBaseById(baseId: string): BasePlot?
	return bases[baseId]
end

function BaseService.GetAllBases(): { [string]: BasePlot }
	return bases
end

function BaseService.IsBaseLocked(plot: BasePlot): boolean
	return os.clock() < plot.LockEndTime
end

function BaseService.IsBaseInCooldown(plot: BasePlot): (boolean, number)
	local now = os.clock()
	if now < plot.LockEndTime then
		return false, 0
	end
	if now < plot.CooldownEndTime then
		return true, math.ceil(plot.CooldownEndTime - now)
	end
	return false, 0
end

function BaseService.GetLockTimeRemaining(plot: BasePlot): number
	local now = os.clock()
	if now < plot.LockEndTime then
		return math.ceil(plot.LockEndTime - now)
	end
	return 0
end

function BaseService.RequestLockBase(player: Player): (boolean, string)
	local plot = playerBaseMap[player]
	if not plot then
		return false, "You do not own a base plot!"
	end

	local now = os.clock()
	if now < plot.LockEndTime then
		return false, "Base is already locked for another " .. math.ceil(plot.LockEndTime - now) .. "s!"
	end

	if now < plot.CooldownEndTime then
		return false, "Base lock is on cooldown for another " .. math.ceil(plot.CooldownEndTime - now) .. "s!"
	end

	local PlayerService = require(game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("PlayerService"))
	local success = PlayerService.SpendCoins(player, Config.Economy.BaseLockCost)
	if not success then
		return false, "Not enough coins! Base lock costs $" .. Config.Economy.BaseLockCost
	end

	plot.LockEndTime = now + Config.Economy.BaseLockDuration
	plot.CooldownEndTime = plot.LockEndTime + Config.Economy.BaseLockCooldown
	BaseService.UpdateBaseVisuals(plot)

	return true, "Base locked for 60 seconds! No one can steal your brainrots!"
end

function BaseService.UpdateBaseVisuals(plot: BasePlot)
	local now = os.clock()
	local isLocked = now < plot.LockEndTime

	if plot.Forcefield then
		if isLocked then
			plot.Forcefield.Transparency = 0.35
			plot.Forcefield.Color = Color3.fromRGB(0, 220, 255)
			plot.Forcefield.Material = Enum.Material.Neon
			plot.Forcefield.CanCollide = true
		else
			plot.Forcefield.Transparency = 0.88
			plot.Forcefield.Color = Color3.fromRGB(0, 180, 230)
			plot.Forcefield.Material = Enum.Material.SmoothPlastic
			plot.Forcefield.CanCollide = false
		end
	end

	if plot.LockButton then
		if isLocked then
			plot.LockButton.Color = Color3.fromRGB(255, 50, 50)
		elseif now < plot.CooldownEndTime then
			plot.LockButton.Color = Color3.fromRGB(255, 180, 0)
		else
			plot.LockButton.Color = Color3.fromRGB(50, 255, 100)
		end
	end
end

function BaseService.GetFirstEmptySlot(plot: BasePlot): number?
	for idx = 1, Config.Economy.SlotCount do
		if plot.Slots[idx] == nil then
			return idx
		end
	end
	return nil
end

function BaseService.GetSlotPad(plot: BasePlot, slotIndex: number): Part?
	local slotsFolder = plot.Model:FindFirstChild("Slots") :: Folder?
	if not slotsFolder then
		return nil
	end
	local slotModel = slotsFolder:FindFirstChild("Slot" .. slotIndex) :: Model?
	if not slotModel then
		return nil
	end
	return (slotModel:FindFirstChild("DisplayPad") or slotModel:FindFirstChild("Pad")) :: Part?
end

function BaseService.StealBrainrot(thief: Player, targetBaseId: string, slotIndex: number): (boolean, string)
	local targetPlot = bases[targetBaseId]
	if not targetPlot then
		return false, "Target base not found."
	end

	if targetPlot.Owner == thief then
		return false, "You cannot steal from your own base!"
	end

	if BaseService.IsBaseLocked(targetPlot) then
		return false, "Target base is LOCKED with a defense forcefield!"
	end

	local targetSlot = targetPlot.Slots[slotIndex]
	if not targetSlot then
		return false, "This pedestal is empty!"
	end

	local thiefPlot = playerBaseMap[thief]
	if not thiefPlot then
		return false, "You must own a base to steal brainrots!"
	end

	local emptySlotIndex = BaseService.GetFirstEmptySlot(thiefPlot)
	if not emptySlotIndex then
		return false, "Your base is full (8/8 brainrots)! Free a slot first."
	end

	-- Distance validation
	local character = thief.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local slotPad = BaseService.GetSlotPad(targetPlot, slotIndex)
	if rootPart and slotPad then
		local dist = (rootPart.Position - slotPad.Position).Magnitude
		if dist > Config.Economy.StealMaxDistance + 6 then
			return false, "Too far away to steal!"
		end
	end

	-- Execute Steal
	local stolenName = targetSlot.Name
	local stolenCharId = targetSlot.CharacterId
	local stolenRarity = targetSlot.Rarity
	local stolenMutation = targetSlot.Mutation
	local stolenBaseIncome = targetSlot.BaseIncome
	local stolenMutationMultiplier = targetSlot.MutationMultiplier
	local stolenIncome = targetSlot.Income

	-- Remove from victim
	if targetSlot.VisualModel then
		targetSlot.VisualModel:Destroy()
	end
	targetPlot.Slots[slotIndex] = nil

	-- Add to thief
	local newSlot: BrainrotSlot = {
		SlotIndex = emptySlotIndex,
		CharacterId = stolenCharId,
		Name = stolenName,
		Rarity = stolenRarity,
		Mutation = stolenMutation,
		BaseIncome = stolenBaseIncome,
		MutationMultiplier = stolenMutationMultiplier,
		Income = stolenIncome,
		VisualModel = nil,
	}
	thiefPlot.Slots[emptySlotIndex] = newSlot

	-- Recreate visual on thief pad
	local BrainrotService = require(game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("BrainrotService"))
	BrainrotService.CreateSlotVisual(thiefPlot, emptySlotIndex, newSlot)

	-- Recalculate income for both
	if targetPlot.Owner then
		BrainrotService.RecalculatePlayerIncome(targetPlot.Owner)
	end
	BrainrotService.RecalculatePlayerIncome(thief)

	return true, "Successfully stole " .. stolenName .. "!"
end

function BaseService.ClearBaseSlots(player: Player)
	local plot = playerBaseMap[player]
	if not plot then
		return
	end

	for idx = 1, Config.Economy.SlotCount do
		local slot = plot.Slots[idx]
		if slot and slot.VisualModel then
			slot.VisualModel:Destroy()
		end
		plot.Slots[idx] = nil
	end
end

function BaseService.IsPositionInsideBase(pos: Vector3, plot: BasePlot): boolean
	local floor = plot.Model:FindFirstChild("Floor") :: Part?
	if not floor then
		return false
	end
	local floorPos = floor.Position
	local halfX = floor.Size.X / 2
	local halfZ = floor.Size.Z / 2
	return math.abs(pos.X - floorPos.X) <= halfX and math.abs(pos.Z - floorPos.Z) <= halfZ
end

function BaseService.IsPositionInsideAnyClaimedBase(pos: Vector3): boolean
	for _, plot in pairs(bases) do
		if plot.Owner ~= nil and BaseService.IsPositionInsideBase(pos, plot) then
			return true
		end
	end
	return false
end

return BaseService
