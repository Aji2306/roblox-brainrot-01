--!strict
-- Dynamic 3D Brainrot Conveyor Spawning, Models, Buying & Passive Income Service

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Config"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))
local PlayerService = require(ServerScriptService:WaitForChild("Server"):WaitForChild("PlayerService"))
local BaseService = require(ServerScriptService:WaitForChild("Server"):WaitForChild("BaseService"))

local BrainrotService = {}

export type ConveyorItem = {
	Id: string,
	CharacterDef: any,
	MutationDef: any,
	Price: number,
	BaseIncome: number,
	Model: Model,
	SpawnTime: number,
	IsBought: boolean,
}

local activeConveyorItems: { [string]: ConveyorItem } = {}
local conveyorFolder: Folder
local nextItemId = 1

function BrainrotService.Init()
	conveyorFolder = Instance.new("Folder")
	conveyorFolder.Name = "ActiveBrainrots"
	conveyorFolder.Parent = Workspace

	-- Spawner loop
	task.spawn(function()
		while true do
			task.wait(Config.Conveyor.SpawnInterval)
			BrainrotService.CheckSpawnConveyor()
		end
	end)

	-- Conveyor movement loop
	RunService.Heartbeat:Connect(function(dt)
		BrainrotService.UpdateConveyorMovement(dt)
	end)

	-- Passive Income loop (every 1 second)
	task.spawn(function()
		while true do
			task.wait(Config.IncomeTickRate or 1.0)
			BrainrotService.ProcessPassiveIncome()
		end
	end)
end

function BrainrotService.GetRandomCharacter(): any
	local totalWeight = 0
	for _, char in ipairs(Config.Characters) do
		local rarity = Config.Rarities[char.Rarity]
		local weight = rarity and rarity.DropWeight or 10
		totalWeight += weight
	end

	local roll = math.random() * totalWeight
	local current = 0
	for _, char in ipairs(Config.Characters) do
		local rarity = Config.Rarities[char.Rarity]
		local weight = rarity and rarity.DropWeight or 10
		current += weight
		if roll <= current then
			return char
		end
	end
	return Config.Characters[1]
end

function BrainrotService.GetRandomMutation(): any
	local totalWeight = 0
	for _, mut in pairs(Config.Mutations) do
		totalWeight += mut.Weight
	end

	local roll = math.random() * totalWeight
	local current = 0
	for _, mut in pairs(Config.Mutations) do
		current += mut.Weight
		if roll <= current then
			return mut
		end
	end
	return Config.Mutations.Normal
end

-- Builds a rich 3D character Model with stylized parts & accessories
function BrainrotService.BuildCharacterModel(charDef: any, mutDef: any): Model
	local model = Instance.new("Model")
	model.Name = charDef.Name

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 2)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Anchored = false
	rootPart.Parent = model
	model.PrimaryPart = rootPart

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = charDef.WalkSpeed or 10
	humanoid.DisplayName = string.format("[%s] %s", mutDef.Name, charDef.Name)
	humanoid.Parent = model

	local primaryColor = mutDef.Color or charDef.PrimaryColor
	local secondaryColor = mutDef.Color or charDef.SecondaryColor
	local material = mutDef.Material or Enum.Material.SmoothPlastic

	-- Helper to create and weld a part
	local function createPart(name: string, size: Vector3, offset: Vector3, color: Color3, partMat: Enum.Material, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = partMat
		p.CanCollide = false
		p.Anchored = false
		if shape then
			p.Shape = shape
		end
		p.CFrame = rootPart.CFrame * CFrame.new(offset)
		p.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rootPart
		weld.Part1 = p
		weld.Parent = p
		return p
	end

	-- Core Torso
	local torso = createPart("Torso", Vector3.new(2, 2.4, 1.4), Vector3.new(0, 0, 0), primaryColor, material)

	-- Head
	local head = createPart("Head", Vector3.new(1.6, 1.6, 1.6), Vector3.new(0, 1.8, 0), primaryColor, material)

	-- Stylized accessories based on ModelStyle
	if charDef.ModelStyle == "Canine" then
		-- Sir Barksalot: Top hat + ears + snout
		createPart("Snout", Vector3.new(1.0, 0.8, 1.0), Vector3.new(0, 1.6, 0.9), secondaryColor, material)
		createPart("EarL", Vector3.new(0.4, 0.9, 0.4), Vector3.new(-0.7, 2.4, 0), secondaryColor, material)
		createPart("EarR", Vector3.new(0.4, 0.9, 0.4), Vector3.new(0.7, 2.4, 0), secondaryColor, material)
		-- Top Hat
		createPart("HatBrim", Vector3.new(2.4, 0.2, 2.4), Vector3.new(0, 2.7, 0), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic)
		createPart("HatCrown", Vector3.new(1.6, 1.8, 1.6), Vector3.new(0, 3.6, 0), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic)
		createPart("HatRibbon", Vector3.new(1.7, 0.3, 1.7), Vector3.new(0, 2.9, 0), Color3.fromRGB(220, 30, 40), Enum.Material.Neon)
	elseif charDef.ModelStyle == "Croissant" then
		-- Captain Croissant: Flaky curve pastry + golden butter sword
		createPart("WingL", Vector3.new(1.2, 1.8, 1.0), Vector3.new(-1.4, 0.4, -0.3), secondaryColor, material)
		createPart("WingR", Vector3.new(1.2, 1.8, 1.0), Vector3.new(1.4, 0.4, -0.3), secondaryColor, material)
		-- Butter sword
		createPart("SwordBlade", Vector3.new(0.3, 2.8, 0.6), Vector3.new(1.6, 0.6, 0.8), Color3.fromRGB(255, 230, 80), Enum.Material.Neon)
		createPart("SwordHilt", Vector3.new(0.5, 0.4, 1.0), Vector3.new(1.6, -0.8, 0.8), Color3.fromRGB(150, 100, 40), Enum.Material.Metal)
	elseif charDef.ModelStyle == "Bird" then
		-- Professor Pigeon: Beak + spectacles + briefcase
		createPart("Beak", Vector3.new(0.6, 0.5, 0.8), Vector3.new(0, 1.6, 0.9), Color3.fromRGB(240, 120, 20), Enum.Material.SmoothPlastic)
		createPart("Glasses", Vector3.new(1.4, 0.4, 0.2), Vector3.new(0, 1.9, 0.85), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
		createPart("Briefcase", Vector3.new(1.2, 1.0, 0.5), Vector3.new(-1.4, -0.4, 0.4), Color3.fromRGB(100, 60, 30), Enum.Material.SmoothPlastic)
	elseif charDef.ModelStyle == "Pickle" then
		-- DJ Pickle: Tall pickle + headphones + pixel sunglasses
		torso.Size = Vector3.new(2, 3.6, 2)
		head.Size = Vector3.new(1.8, 1.2, 1.8)
		head.CFrame = rootPart.CFrame * CFrame.new(0, 2.2, 0)
		createPart("HeadphonesArc", Vector3.new(2.4, 0.4, 0.4), Vector3.new(0, 2.9, 0), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
		createPart("HeadphoneL", Vector3.new(0.5, 0.8, 0.8), Vector3.new(-1.1, 2.2, 0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon)
		createPart("HeadphoneR", Vector3.new(0.5, 0.8, 0.8), Vector3.new(1.1, 2.2, 0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon)
		createPart("Shades", Vector3.new(1.6, 0.5, 0.3), Vector3.new(0, 2.2, 0.95), Color3.fromRGB(10, 10, 10), Enum.Material.Neon)
	elseif charDef.ModelStyle == "Banana" then
		-- Baron von Banana: Monocle + Bowtie
		createPart("BowtieL", Vector3.new(0.6, 0.5, 0.3), Vector3.new(-0.4, 1.0, 0.8), Color3.fromRGB(220, 20, 30), Enum.Material.Neon)
		createPart("BowtieR", Vector3.new(0.6, 0.5, 0.3), Vector3.new(0.4, 1.0, 0.8), Color3.fromRGB(220, 20, 30), Enum.Material.Neon)
		createPart("Monocle", Vector3.new(0.6, 0.6, 0.2), Vector3.new(0.4, 1.9, 0.85), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
	elseif charDef.ModelStyle == "Toaster" then
		-- Grandma's Flying Toaster: Chrome cube + toast slices + top rotor
		torso.Size = Vector3.new(2.6, 2.2, 2.0)
		head.Transparency = 1
		createPart("Toast1", Vector3.new(0.4, 1.4, 1.2), Vector3.new(-0.5, 1.4, 0), Color3.fromRGB(190, 130, 60), Enum.Material.SmoothPlastic)
		createPart("Toast2", Vector3.new(0.4, 1.4, 1.2), Vector3.new(0.5, 1.4, 0), Color3.fromRGB(190, 130, 60), Enum.Material.SmoothPlastic)
		createPart("RotorShaft", Vector3.new(0.3, 1.2, 0.3), Vector3.new(0, 2.0, 0), Color3.fromRGB(50, 50, 50), Enum.Material.Metal)
		createPart("RotorBlade", Vector3.new(3.6, 0.2, 0.6), Vector3.new(0, 2.6, 0), Color3.fromRGB(220, 220, 220), Enum.Material.Metal)
	elseif charDef.ModelStyle == "Sandwich" then
		-- The Infinite Sandwich: Layered cosmic BLT + neon aura
		torso.Transparency = 1
		head.Transparency = 1
		createPart("BreadBottom", Vector3.new(2.8, 0.5, 2.8), Vector3.new(0, -0.6, 0), Color3.fromRGB(220, 175, 110), Enum.Material.WoodPlanks)
		createPart("Greens", Vector3.new(3.0, 0.3, 3.0), Vector3.new(0, -0.2, 0), Color3.fromRGB(40, 210, 50), Enum.Material.Neon)
		createPart("Tomato", Vector3.new(2.6, 0.4, 2.6), Vector3.new(0, 0.1, 0), Color3.fromRGB(230, 40, 40), Enum.Material.SmoothPlastic)
		createPart("Cheese", Vector3.new(2.9, 0.3, 2.9), Vector3.new(0, 0.4, 0), Color3.fromRGB(255, 200, 20), Enum.Material.Neon)
		createPart("BreadTop", Vector3.new(2.8, 0.6, 2.8), Vector3.new(0, 0.8, 0), Color3.fromRGB(220, 175, 110), Enum.Material.WoodPlanks)
		local aura = Instance.new("PointLight")
		aura.Color = Color3.fromRGB(0, 255, 180)
		aura.Brightness = 2.0
		aura.Range = 12
		aura.Parent = rootPart
	elseif charDef.ModelStyle == "Monarch" then
		-- Emperor of the Lost Socks: Royal crown + cape + spinning vortex ring
		createPart("CrownBase", Vector3.new(2.0, 0.4, 2.0), Vector3.new(0, 2.7, 0), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
		createPart("CrownSpire1", Vector3.new(0.4, 0.9, 0.4), Vector3.new(-0.7, 3.2, 0), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
		createPart("CrownSpire2", Vector3.new(0.4, 1.2, 0.4), Vector3.new(0, 3.4, 0), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
		createPart("CrownSpire3", Vector3.new(0.4, 0.9, 0.4), Vector3.new(0.7, 3.2, 0), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
		createPart("SockCape", Vector3.new(2.2, 2.6, 0.4), Vector3.new(0, 0.2, -0.9), Color3.fromRGB(255, 80, 160), Enum.Material.Fabric)
		local vortex = createPart("VortexRing", Vector3.new(4.2, 0.3, 4.2), Vector3.new(0, 0.8, 0), Color3.fromRGB(180, 50, 255), Enum.Material.Neon)
	end

	-- Mutation particle/light styling
	if mutDef.Name == "Golden" or mutDef.Name == "Diamond" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = mutDef.Color or Color3.fromRGB(255, 255, 255)
		sparkles.Parent = rootPart
	elseif mutDef.Name == "Rainbow" then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 100, 220)
		light.Brightness = 3.0
		light.Range = 14
		light.Parent = rootPart
	end

	return model
end

function BrainrotService.CheckSpawnConveyor()
	local activeCount = 0
	for _, item in pairs(activeConveyorItems) do
		if not item.IsBought then
			activeCount += 1
		end
	end

	if activeCount >= Config.Conveyor.MaxActive then
		return
	end

	local charDef = BrainrotService.GetRandomCharacter()
	local mutDef = BrainrotService.GetRandomMutation()
	local price = charDef.Price
	local baseIncome = charDef.BaseIncome

	local model = BrainrotService.BuildCharacterModel(charDef, mutDef)
	local itemId = "Brainrot_" .. nextItemId
	nextItemId += 1

	local spawnCFrame = CFrame.new(Config.Conveyor.StartX, Config.Conveyor.Y, Config.Conveyor.Z)
	model:PivotTo(spawnCFrame)
	model.Parent = conveyorFolder

	local conveyorItem: ConveyorItem = {
		Id = itemId,
		CharacterDef = charDef,
		MutationDef = mutDef,
		Price = price,
		BaseIncome = baseIncome,
		Model = model,
		SpawnTime = os.clock(),
		IsBought = false,
	}
	activeConveyorItems[itemId] = conveyorItem

	-- Setup ProximityPrompt for Buying
	local prompt = Instance.new("ProximityPrompt")
	local mutPrefix = mutDef.Name ~= "Normal" and ("[" .. mutDef.Name .. "] ") or ""
	prompt.ActionText = "Buy (E)"
	prompt.ObjectText = string.format("%s%s - $%s", mutPrefix, charDef.Name, Util.formatNumber(price))
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player)
		BrainrotService.PlayerBuyBrainrot(player, conveyorItem)
	end)
	prompt.Parent = model.PrimaryPart

	-- Also setup ClickDetector
	local clicker = Instance.new("ClickDetector")
	clicker.MaxActivationDistance = 24
	clicker.MouseClick:Connect(function(player)
		BrainrotService.PlayerBuyBrainrot(player, conveyorItem)
	end)
	clicker.Parent = model.PrimaryPart
end

function BrainrotService.UpdateConveyorMovement(dt: number)
	local now = os.clock()
	local targetX = Config.Conveyor.EndX

	for itemId, item in pairs(activeConveyorItems) do
		if item.IsBought or not item.Model.Parent or not item.Model.PrimaryPart then
			activeConveyorItems[itemId] = nil
			continue
		end

		local root = item.Model.PrimaryPart
		local currentPos = root.Position
		local speed = item.CharacterDef.WalkSpeed or 10

		local newX = currentPos.X + (speed * dt)
		if newX >= targetX then
			-- Reached end without purchase, despawn cleanly
			item.Model:Destroy()
			activeConveyorItems[itemId] = nil
		else
			root.CFrame = CFrame.new(newX, Config.Conveyor.Y, Config.Conveyor.Z)
		end
	end
end

function BrainrotService.PlayerBuyBrainrot(player: Player, item: ConveyorItem): (boolean, string)
	if item.IsBought then
		return false, "This brainrot has already been bought!"
	end

	local plot = BaseService.GetPlayerBase(player)
	if not plot then
		return false, "You must claim a base plot first!"
	end

	local emptySlotIndex = BaseService.GetFirstEmptySlot(plot)
	if not emptySlotIndex then
		return false, "Your base is full (8/8 slots)! Clear or rebirth first."
	end

	-- Check funds
	local success = PlayerService.SpendCoins(player, item.Price)
	if not success then
		return false, "Not enough coins! Costs $" .. Util.formatNumber(item.Price)
	end

	-- Mark as bought and cleanup from conveyor
	item.IsBought = true
	activeConveyorItems[item.Id] = nil
	if item.Model and item.Model.Parent then
		item.Model:Destroy()
	end

	-- Add to base slot
	local playerData = PlayerService.Get(player)
	local rebirths = playerData and playerData.Rebirths or 0
	local effectiveIncome = Util.calculateIncome(item.BaseIncome, item.MutationDef.Multiplier, rebirths)

	local newSlot: BaseService.BrainrotSlot = {
		SlotIndex = emptySlotIndex,
		CharacterId = item.CharacterDef.Id,
		Name = item.CharacterDef.Name,
		Rarity = item.CharacterDef.Rarity,
		Mutation = item.MutationDef.Name,
		BaseIncome = item.BaseIncome,
		MutationMultiplier = item.MutationDef.Multiplier,
		Income = effectiveIncome,
		VisualModel = nil,
	}
	plot.Slots[emptySlotIndex] = newSlot

	-- Create visual model on base slot
	BrainrotService.CreateSlotVisual(plot, emptySlotIndex, newSlot)
	BrainrotService.RecalculatePlayerIncome(player)

	return true, "Purchased " .. item.CharacterDef.Name .. "!"
end

function BrainrotService.BuyBrainrotById(player: Player, itemId: string): (boolean, string)
	local item = activeConveyorItems[itemId]
	if not item then
		return false, "This brainrot has moved on or was already purchased!"
	end
	return BrainrotService.PlayerBuyBrainrot(player, item)
end

function BrainrotService.CreateSlotVisual(plot: BaseService.BasePlot, slotIndex: number, slotData: BaseService.BrainrotSlot)
	local charDef = Util.getCharacterById(slotData.CharacterId) or Config.Characters[1]
	local mutDef = Config.Mutations[slotData.Mutation] or Config.Mutations.Normal

	local model = BrainrotService.BuildCharacterModel(charDef, mutDef)
	model.Name = "SlotCharacter_" .. slotIndex

	local pad = BaseService.GetSlotPad(plot, slotIndex)
	if pad then
		local padPos = pad.Position
		model:PivotTo(CFrame.new(padPos + Vector3.new(0, 1.8, 0)))
	end

	-- Anchor all parts in base slot
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	-- Floating BillboardGui with stats
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StatsDisplay"
	billboard.Size = UDim2.fromOffset(160, 60)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	local mutPrefix = slotData.Mutation ~= "Normal" and ("[" .. slotData.Mutation .. "] ") or ""
	nameLabel.Text = mutPrefix .. slotData.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextScaled = true
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rarityLabel.Text = slotData.Rarity
	rarityLabel.TextColor3 = Util.getRarityColor(slotData.Rarity)
	rarityLabel.TextStrokeTransparency = 0.2
	rarityLabel.TextScaled = true
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.Parent = billboard

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Size = UDim2.new(1, 0, 0.3, 0)
	incomeLabel.Position = UDim2.new(0, 0, 0.7, 0)
	incomeLabel.Text = string.format("+$%s/s", Util.formatNumber(slotData.Income))
	incomeLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
	incomeLabel.TextStrokeTransparency = 0.2
	incomeLabel.TextScaled = true
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Font = Enum.Font.SourceSansBold
	incomeLabel.Parent = billboard

	billboard.Parent = model.PrimaryPart

	-- Setup Steal ProximityPrompt for enemy players
	local stealPrompt = Instance.new("ProximityPrompt")
	stealPrompt.ActionText = "Steal (Hold E)"
	stealPrompt.ObjectText = slotData.Name
	stealPrompt.HoldDuration = Config.Economy.StealHoldDuration
	stealPrompt.MaxActivationDistance = Config.Economy.StealMaxDistance
	stealPrompt.RequiresLineOfSight = false
	stealPrompt.Triggered:Connect(function(thief)
		if plot.Owner ~= thief then
			BaseService.StealBrainrot(thief, plot.Id, slotIndex)
		end
	end)
	stealPrompt.Parent = model.PrimaryPart

	model.Parent = plot.Model
	slotData.VisualModel = model
end

function BrainrotService.RecalculatePlayerIncome(player: Player)
	local plot = BaseService.GetPlayerBase(player)
	if not plot then
		PlayerService.SetIncome(player, 0)
		return
	end

	local playerData = PlayerService.Get(player)
	local rebirths = playerData and playerData.Rebirths or 0

	local totalIncome = 0
	for _, slot in ipairs(plot.Slots) do
		if slot then
			slot.Income = Util.calculateIncome(slot.BaseIncome, slot.MutationMultiplier, rebirths)
			totalIncome += slot.Income

			-- Update floating billboard if present
			if slot.VisualModel and slot.VisualModel.PrimaryPart then
				local statsGui = slot.VisualModel.PrimaryPart:FindFirstChild("StatsDisplay") :: BillboardGui?
				if statsGui then
					for _, child in ipairs(statsGui:GetChildren()) do
						if child:IsA("TextLabel") and string.sub(child.Text, 1, 2) == "+$" then
							child.Text = string.format("+$%s/s", Util.formatNumber(slot.Income))
						end
					end
				end
			end
		end
	end

	PlayerService.SetIncome(player, totalIncome)
end

function BrainrotService.ProcessPassiveIncome()
	for _, player in ipairs(Players:GetPlayers()) do
		local plot = BaseService.GetPlayerBase(player)
		if plot then
			local income = 0
			for _, slot in ipairs(plot.Slots) do
				if slot then
					income += slot.Income
				end
			end
			if income > 0 then
				PlayerService.AddCoins(player, income)
			end
		end
	end
end

function BrainrotService.GetConveyorSnapshot(): { any }
	local list = {}
	for _, item in pairs(activeConveyorItems) do
		if not item.IsBought and item.Model and item.Model.PrimaryPart then
			table.insert(list, {
				Id = item.Id,
				Name = item.CharacterDef.Name,
				Rarity = item.CharacterDef.Rarity,
				Mutation = item.MutationDef.Name,
				Price = item.Price,
				BaseIncome = item.BaseIncome,
				Position = item.Model.PrimaryPart.Position,
			})
		end
	end
	return list
end

return BrainrotService
