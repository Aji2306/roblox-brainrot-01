--!strict
-- Brainrot Bazaar Client: ScreenGui HUD, ContextActionService Controls & Interactive State

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local buyRemote = remotesFolder:WaitForChild("BuyBrainrot") :: RemoteEvent
local lockRemote = remotesFolder:WaitForChild("LockBase") :: RemoteEvent
local stealRemote = remotesFolder:WaitForChild("StealBrainrot") :: RemoteEvent
local rebirthRemote = remotesFolder:WaitForChild("Rebirth") :: RemoteEvent
local syncRemote = remotesFolder:WaitForChild("GameStateSync") :: RemoteEvent
local notifyRemote = remotesFolder:WaitForChild("Notify") :: RemoteEvent

-- Local Game State
local currentCoins = 150
local currentRebirths = 0
local currentIncome = 0
local baseId: string? = nil
local isBaseLocked = false
local lockTimeRemaining = 0
local inCooldown = false
local cooldownRemaining = 0
local ownedSlots: { any } = {}
local leaderboardData: { any } = {}
local stormState = "Calm"
local stormTimeRemaining = 0

-- UI Construction
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotBazaarHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false

local function createCorner(radius: number, parent: Instance): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(thickness: number, color: Color3, parent: Instance): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = color
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

-- 1. Top Center Storm Warning Banner
local stormBanner = Instance.new("Frame")
stormBanner.Name = "StormBanner"
stormBanner.AnchorPoint = Vector2.new(0.5, 0)
stormBanner.Position = UDim2.new(0.5, 0, 0, 8)
stormBanner.Size = UDim2.fromOffset(480, 46)
stormBanner.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
stormBanner.BackgroundTransparency = 0.15
createCorner(10, stormBanner)
local stormStroke = createStroke(2, Color3.fromRGB(0, 220, 255), stormBanner)

local stormLabel = Instance.new("TextLabel")
stormLabel.Name = "Label"
stormLabel.Size = UDim2.fromScale(1, 1)
stormLabel.BackgroundTransparency = 1
stormLabel.Font = Enum.Font.FredokaOne
stormLabel.TextSize = 20
stormLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
stormLabel.Text = "☀️ BAZAAR IS PEACEFUL"
stormLabel.Parent = stormBanner
stormBanner.Parent = screenGui

-- 2. Top-Right Currency & Stats HUD (Keeps Top-Left completely clear)
local statsContainer = Instance.new("Frame")
statsContainer.Name = "StatsContainer"
statsContainer.AnchorPoint = Vector2.new(1, 0)
statsContainer.Position = UDim2.new(1, -16, 0, 10)
statsContainer.Size = UDim2.fromOffset(340, 68)
statsContainer.BackgroundColor3 = Color3.fromRGB(25, 27, 36)
statsContainer.BackgroundTransparency = 0.2
createCorner(12, statsContainer)
createStroke(2, Color3.fromRGB(80, 85, 105), statsContainer)

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Position = UDim2.new(0, 14, 0, 8)
coinsLabel.Size = UDim2.new(0.55, 0, 0.45, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Font = Enum.Font.FredokaOne
coinsLabel.TextSize = 22
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.Text = "💰 $150"
coinsLabel.Parent = statsContainer

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Position = UDim2.new(0.58, 0, 0, 8)
incomeLabel.Size = UDim2.new(0.4, 0, 0.45, 0)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Font = Enum.Font.SourceSansBold
incomeLabel.TextSize = 18
incomeLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Text = "⚡ +$0/s"
incomeLabel.Parent = statsContainer

local rebirthsLabel = Instance.new("TextLabel")
rebirthsLabel.Name = "RebirthsLabel"
rebirthsLabel.Position = UDim2.new(0, 14, 0.52, 0)
rebirthsLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
rebirthsLabel.BackgroundTransparency = 1
rebirthsLabel.Font = Enum.Font.SourceSansSemibold
rebirthsLabel.TextSize = 16
rebirthsLabel.TextColor3 = Color3.fromRGB(0, 225, 255)
rebirthsLabel.TextXAlignment = Enum.TextXAlignment.Left
rebirthsLabel.Text = "🔄 Rebirth: 0 (Multiplier: x1.00)"
rebirthsLabel.Parent = statsContainer
statsContainer.Parent = screenGui

-- 3. Action Buttons (Left Side, clear of top-left menu)
local actionsFrame = Instance.new("Frame")
actionsFrame.Name = "ActionsFrame"
actionsFrame.Position = UDim2.new(0, 16, 0, 110)
actionsFrame.Size = UDim2.fromOffset(200, 120)
actionsFrame.BackgroundTransparency = 1

local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.Size = UDim2.new(1, 0, 0, 48)
lockButton.BackgroundColor3 = Color3.fromRGB(35, 140, 70)
lockButton.Font = Enum.Font.FredokaOne
lockButton.TextSize = 18
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.Text = "🛡️ [L] LOCK BASE ($100)"
createCorner(10, lockButton)
createStroke(2, Color3.fromRGB(70, 220, 110), lockButton)
lockButton.Parent = actionsFrame

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Position = UDim2.new(0, 0, 0, 56)
rebirthButton.Size = UDim2.new(1, 0, 0, 48)
rebirthButton.BackgroundColor3 = Color3.fromRGB(130, 45, 175)
rebirthButton.Font = Enum.Font.FredokaOne
rebirthButton.TextSize = 18
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.Text = "⭐ [R] REBIRTH (+25%)"
createCorner(10, rebirthButton)
createStroke(2, Color3.fromRGB(200, 90, 255), rebirthButton)
rebirthButton.Parent = actionsFrame
actionsFrame.Parent = screenGui

-- 4. Leaderboard Panel (Top-Right, below stats)
local lbFrame = Instance.new("Frame")
lbFrame.Name = "LeaderboardFrame"
lbFrame.AnchorPoint = Vector2.new(1, 0)
lbFrame.Position = UDim2.new(1, -16, 0, 88)
lbFrame.Size = UDim2.fromOffset(230, 200)
lbFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
lbFrame.BackgroundTransparency = 0.25
createCorner(10, lbFrame)
createStroke(1, Color3.fromRGB(60, 65, 80), lbFrame)

local lbTitle = Instance.new("TextLabel")
lbTitle.Size = UDim2.new(1, 0, 0, 30)
lbTitle.BackgroundTransparency = 1
lbTitle.Font = Enum.Font.FredokaOne
lbTitle.TextSize = 16
lbTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
lbTitle.Text = "🏆 TOP EARNERS"
lbTitle.Parent = lbFrame

local lbList = Instance.new("ScrollingFrame")
lbList.Name = "List"
lbList.Position = UDim2.new(0, 8, 0, 32)
lbList.Size = UDim2.new(1, -16, 1, -40)
lbList.BackgroundTransparency = 1
lbList.ScrollBarThickness = 4
lbList.CanvasSize = UDim2.new(0, 0, 0, 0)
local lbLayout = Instance.new("UIListLayout")
lbLayout.Padding = UDim.new(0, 4)
lbLayout.Parent = lbList
lbList.Parent = lbFrame
lbFrame.Parent = screenGui

-- 5. Owned Brainrots Deck (Bottom Dock)
local deckFrame = Instance.new("Frame")
deckFrame.Name = "DeckFrame"
deckFrame.AnchorPoint = Vector2.new(0.5, 1)
deckFrame.Position = UDim2.new(0.5, 0, 1, -12)
deckFrame.Size = UDim2.fromOffset(680, 82)
deckFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
deckFrame.BackgroundTransparency = 0.2
createCorner(12, deckFrame)
createStroke(2, Color3.fromRGB(65, 70, 90), deckFrame)

local deckTitle = Instance.new("TextLabel")
deckTitle.Size = UDim2.new(1, 0, 0, 20)
deckTitle.Position = UDim2.new(0, 0, 0, 2)
deckTitle.BackgroundTransparency = 1
deckTitle.Font = Enum.Font.SourceSansBold
deckTitle.TextSize = 14
deckTitle.TextColor3 = Color3.fromRGB(180, 185, 205)
deckTitle.Text = "BASE PEDESTAL SLOTS (8 MAX)"
deckTitle.Parent = deckFrame

local slotsContainer = Instance.new("Frame")
slotsContainer.Position = UDim2.new(0, 8, 0, 22)
slotsContainer.Size = UDim2.new(1, -16, 0, 54)
slotsContainer.BackgroundTransparency = 1
local slotsLayout = Instance.new("UIListLayout")
slotsLayout.FillDirection = Enum.FillDirection.Horizontal
slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
slotsLayout.Padding = UDim.new(0, 6)
slotsLayout.Parent = slotsContainer

local slotCards: { Frame } = {}
for i = 1, Config.Economy.SlotCount do
	local card = Instance.new("Frame")
	card.Name = "SlotCard_" .. i
	card.Size = UDim2.new(0, 76, 0, 52)
	card.BackgroundColor3 = Color3.fromRGB(32, 35, 48)
	createCorner(8, card)
	createStroke(1, Color3.fromRGB(55, 60, 75), card)

	local sNum = Instance.new("TextLabel")
	sNum.Name = "SlotNum"
	sNum.Size = UDim2.new(1, 0, 0.4, 0)
	sNum.BackgroundTransparency = 1
	sNum.Font = Enum.Font.SourceSansBold
	sNum.TextSize = 13
	sNum.TextColor3 = Color3.fromRGB(140, 145, 160)
	sNum.Text = "#" .. i
	sNum.Parent = card

	local sName = Instance.new("TextLabel")
	sName.Name = "CharName"
	sName.Position = UDim2.new(0, 2, 0.35, 0)
	sName.Size = UDim2.new(1, -4, 0.35, 0)
	sName.BackgroundTransparency = 1
	sName.Font = Enum.Font.FredokaOne
	sName.TextSize = 11
	sName.TextColor3 = Color3.fromRGB(220, 220, 220)
	sName.Text = "Empty"
	sName.TextTruncate = Enum.TextTruncate.AtEnd
	sName.Parent = card

	local sRate = Instance.new("TextLabel")
	sRate.Name = "IncomeRate"
	sRate.Position = UDim2.new(0, 2, 0.68, 0)
	sRate.Size = UDim2.new(1, -4, 0.3, 0)
	sRate.BackgroundTransparency = 1
	sRate.Font = Enum.Font.SourceSansBold
	sRate.TextSize = 11
	sRate.TextColor3 = Color3.fromRGB(80, 255, 120)
	sRate.Text = "$0/s"
	sRate.Parent = card

	card.Parent = slotsContainer
	table.insert(slotCards, card)
end
slotsContainer.Parent = deckFrame
deckFrame.Parent = screenGui

-- 6. Notification Banner / Toast
local notifyToast = Instance.new("Frame")
notifyToast.Name = "NotifyToast"
notifyToast.AnchorPoint = Vector2.new(0.5, 0)
notifyToast.Position = UDim2.new(0.5, 0, 0, 60)
notifyToast.Size = UDim2.fromOffset(440, 40)
notifyToast.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
notifyToast.BackgroundTransparency = 1
createCorner(8, notifyToast)
local notifyStroke = createStroke(1.5, Color3.fromRGB(255, 215, 0), notifyToast)
notifyStroke.Transparency = 1

local notifyText = Instance.new("TextLabel")
notifyText.Size = UDim2.fromScale(1, 1)
notifyText.BackgroundTransparency = 1
notifyText.Font = Enum.Font.FredokaOne
notifyText.TextSize = 16
notifyText.TextColor3 = Color3.fromRGB(255, 255, 255)
notifyText.TextTransparency = 1
notifyText.Text = ""
notifyText.Parent = notifyToast
notifyToast.Parent = screenGui

local function showNotification(msg: string, isAlert: boolean)
	notifyText.Text = msg
	notifyText.TextColor3 = isAlert and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 230, 90)
	notifyStroke.Color = isAlert and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 215, 0)

	notifyToast.BackgroundTransparency = 0.1
	notifyStroke.Transparency = 0
	notifyText.TextTransparency = 0

	task.delay(3.0, function()
		local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(notifyToast, tweenInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(notifyStroke, tweenInfo, { Transparency = 1 }):Play()
		TweenService:Create(notifyText, tweenInfo, { TextTransparency = 1 }):Play()
	end)
end

-- 7. Rebirth Modal Dialog
local rebirthModal = Instance.new("Frame")
rebirthModal.Name = "RebirthModal"
rebirthModal.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthModal.Position = UDim2.fromScale(0.5, 0.5)
rebirthModal.Size = UDim2.fromOffset(420, 260)
rebirthModal.BackgroundColor3 = Color3.fromRGB(26, 28, 38)
rebirthModal.Visible = false
createCorner(14, rebirthModal)
createStroke(2.5, Color3.fromRGB(180, 70, 255), rebirthModal)

local rmTitle = Instance.new("TextLabel")
rmTitle.Size = UDim2.new(1, 0, 0, 44)
rmTitle.BackgroundTransparency = 1
rmTitle.Font = Enum.Font.FredokaOne
rmTitle.TextSize = 22
rmTitle.TextColor3 = Color3.fromRGB(255, 225, 60)
rmTitle.Text = "🌟 REBIRTH UPGRADE 🌟"
rmTitle.Parent = rebirthModal

local rmDesc = Instance.new("TextLabel")
rmDesc.Position = UDim2.new(0, 24, 0, 48)
rmDesc.Size = UDim2.new(1, -48, 0, 60)
rmDesc.BackgroundTransparency = 1
rmDesc.Font = Enum.Font.SourceSans
rmDesc.TextSize = 16
rmDesc.TextColor3 = Color3.fromRGB(210, 215, 230)
rmDesc.TextWrapped = true
rmDesc.Text = "Reset your coins and brainrot slots in exchange for a permanent +25% income boost across all brainrots!"
rmDesc.Parent = rebirthModal

local rmCost = Instance.new("TextLabel")
rmCost.Name = "CostLabel"
rmCost.Position = UDim2.new(0, 24, 0, 118)
rmCost.Size = UDim2.new(1, -48, 0, 36)
rmCost.BackgroundTransparency = 1
rmCost.Font = Enum.Font.FredokaOne
rmCost.TextSize = 20
rmCost.TextColor3 = Color3.fromRGB(255, 215, 0)
rmCost.Text = "Cost: $25,000 Coins"
rmCost.Parent = rebirthModal

local rmConfirmBtn = Instance.new("TextButton")
rmConfirmBtn.Position = UDim2.new(0, 24, 0, 180)
rmConfirmBtn.Size = UDim2.new(0.48, -12, 0, 48)
rmConfirmBtn.BackgroundColor3 = Color3.fromRGB(140, 45, 190)
rmConfirmBtn.Font = Enum.Font.FredokaOne
rmConfirmBtn.TextSize = 18
rmConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rmConfirmBtn.Text = "CONFIRM"
createCorner(10, rmConfirmBtn)
createStroke(1.5, Color3.fromRGB(220, 100, 255), rmConfirmBtn)
rmConfirmBtn.Parent = rebirthModal

local rmCancelBtn = Instance.new("TextButton")
rmCancelBtn.Position = UDim2.new(0.52, 0, 0, 180)
rmCancelBtn.Size = UDim2.new(0.48, -12, 0, 48)
rmCancelBtn.BackgroundColor3 = Color3.fromRGB(55, 60, 75)
rmCancelBtn.Font = Enum.Font.FredokaOne
rmCancelBtn.TextSize = 18
rmCancelBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
rmCancelBtn.Text = "CANCEL"
createCorner(10, rmCancelBtn)
rmCancelBtn.Parent = rebirthModal
rebirthModal.Parent = screenGui

screenGui.Parent = playerGui

-- Button Actions & Modal Events
lockButton.MouseButton1Click:Connect(function()
	lockRemote:FireServer()
end)

rebirthButton.MouseButton1Click:Connect(function()
	local cost = Util.calculateRebirthCost(currentRebirths)
	rmCost.Text = string.format("Required Coins: $%s", Util.formatNumber(cost))
	if currentCoins >= cost then
		rmCost.TextColor3 = Color3.fromRGB(80, 255, 120)
	else
		rmCost.TextColor3 = Color3.fromRGB(255, 90, 90)
	end
	rebirthModal.Visible = true
end)

rmConfirmBtn.MouseButton1Click:Connect(function()
	rebirthModal.Visible = false
	rebirthRemote:FireServer()
end)

rmCancelBtn.MouseButton1Click:Connect(function()
	rebirthModal.Visible = false
end)

-- Input binding with ContextActionService
local function handleAction(actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if actionName == "LockBaseAction" then
		lockRemote:FireServer()
		return Enum.ContextActionResult.Sink
	elseif actionName == "RebirthAction" then
		if not rebirthModal.Visible then
			local cost = Util.calculateRebirthCost(currentRebirths)
			rmCost.Text = string.format("Required Coins: $%s", Util.formatNumber(cost))
			rebirthModal.Visible = true
		else
			rebirthModal.Visible = false
		end
		return Enum.ContextActionResult.Sink
	elseif actionName == "InteractAction" then
		-- E key: ProximityPrompts handle purchasing and stealing seamlessly!
		return Enum.ContextActionResult.Pass
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("LockBaseAction", handleAction, false, Enum.KeyCode.L)
ContextActionService:BindAction("RebirthAction", handleAction, false, Enum.KeyCode.R)
ContextActionService:BindAction("InteractAction", handleAction, false, Enum.KeyCode.E)

-- Remote Event Listeners
notifyRemote.OnClientEvent:Connect(function(msg: string, isAlert: boolean)
	showNotification(msg, isAlert)
end)

syncRemote.OnClientEvent:Connect(function(data: any)
	currentCoins = data.Coins
	currentRebirths = data.Rebirths
	currentIncome = data.Income
	baseId = data.BaseId
	isBaseLocked = data.BaseLocked
	lockTimeRemaining = data.LockRemaining
	inCooldown = data.InCooldown
	cooldownRemaining = data.CooldownRemaining
	ownedSlots = data.Slots or {}
	leaderboardData = data.Leaderboard or {}
	stormState = data.Storm and data.Storm.State or "Calm"
	stormTimeRemaining = data.Storm and data.Storm.TimeRemaining or 0

	-- Update Currency HUD
	coinsLabel.Text = string.format("💰 $%s", Util.formatNumber(currentCoins))
	incomeLabel.Text = string.format("⚡ +$%s/s", Util.formatNumber(currentIncome))
	local multiplier = 1 + (currentRebirths * Config.Economy.RebirthIncomeMultiplier)
	rebirthsLabel.Text = string.format("🔄 Rebirth: %d (x%.2f boost)", currentRebirths, multiplier)

	-- Update Base Lock Button State
	if isBaseLocked then
		lockButton.Text = string.format("🛡️ LOCKED (%ds)", lockTimeRemaining)
		lockButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	elseif inCooldown then
		lockButton.Text = string.format("⏳ COOLDOWN (%ds)", cooldownRemaining)
		lockButton.BackgroundColor3 = Color3.fromRGB(210, 140, 20)
	else
		lockButton.Text = string.format("🛡️ [L] LOCK BASE ($%d)", Config.Economy.BaseLockCost)
		lockButton.BackgroundColor3 = Color3.fromRGB(35, 140, 70)
	end

	-- Update Storm Banner
	if stormState == "Warning" then
		stormBanner.BackgroundColor3 = Color3.fromRGB(180, 90, 20)
		stormStroke.Color = Color3.fromRGB(255, 170, 0)
		stormLabel.Text = string.format("⚠️ WARNING: MEME STORM IN %ds! RUN TO YOUR BASE!", stormTimeRemaining)
		stormLabel.TextColor3 = Color3.fromRGB(255, 230, 90)
	elseif stormState == "Active" then
		stormBanner.BackgroundColor3 = Color3.fromRGB(150, 20, 60)
		stormStroke.Color = Color3.fromRGB(255, 40, 80)
		stormLabel.Text = string.format("🌪️ MEME STORM ACTIVE (%ds)! SAFE ZONE: YOUR BASE!", stormTimeRemaining)
		stormLabel.TextColor3 = Color3.fromRGB(255, 100, 120)
	else
		stormBanner.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
		stormStroke.Color = Color3.fromRGB(0, 220, 255)
		stormLabel.Text = string.format("☀️ BAZAAR IS CALM • Next Storm in %s", Util.formatTime(stormTimeRemaining))
		stormLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
	end

	-- Update Owned Slots Deck
	local slotMap = {}
	for _, s in ipairs(ownedSlots) do
		slotMap[s.SlotIndex] = s
	end

	for i = 1, Config.Economy.SlotCount do
		local card = slotCards[i]
		if card then
			local sData = slotMap[i]
			local nameLbl = card:FindFirstChild("CharName") :: TextLabel?
			local rateLbl = card:FindFirstChild("IncomeRate") :: TextLabel?
			local stroke = card:FindFirstChildOfClass("UIStroke")

			if sData then
				if nameLbl then
					nameLbl.Text = sData.Name
					nameLbl.TextColor3 = Util.getRarityColor(sData.Rarity)
				end
				if rateLbl then
					rateLbl.Text = string.format("+$%s/s", Util.formatNumber(sData.Income))
				end
				if stroke then
					stroke.Color = Util.getRarityColor(sData.Rarity)
					stroke.Thickness = 1.8
				end
			else
				if nameLbl then
					nameLbl.Text = "Empty"
					nameLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
				end
				if rateLbl then
					rateLbl.Text = "$0/s"
				end
				if stroke then
					stroke.Color = Color3.fromRGB(55, 60, 75)
					stroke.Thickness = 1.0
				end
			end
		end
	end

	-- Update Leaderboard
	for _, child in ipairs(lbList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for rank, entry in ipairs(leaderboardData) do
		if rank <= 8 then
			local row = Instance.new("Frame")
			row.Name = "Row_" .. rank
			row.Size = UDim2.new(1, 0, 0, 22)
			row.BackgroundTransparency = 1

			local rankText = Instance.new("TextLabel")
			rankText.Size = UDim2.new(0, 24, 1, 0)
			rankText.BackgroundTransparency = 1
			rankText.Font = Enum.Font.FredokaOne
			rankText.TextSize = 13
			rankText.TextColor3 = rank == 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 185, 200)
			rankText.Text = "#" .. rank
			rankText.Parent = row

			local nameText = Instance.new("TextLabel")
			nameText.Position = UDim2.new(0, 26, 0, 0)
			nameText.Size = UDim2.new(0.55, 0, 1, 0)
			nameText.BackgroundTransparency = 1
			nameText.Font = Enum.Font.SourceSansBold
			nameText.TextSize = 13
			nameText.TextColor3 = Color3.fromRGB(230, 230, 240)
			nameText.TextXAlignment = Enum.TextXAlignment.Left
			nameText.TextTruncate = Enum.TextTruncate.AtEnd
			nameText.Text = entry.Name
			nameText.Parent = row

			local statText = Instance.new("TextLabel")
			statText.Position = UDim2.new(0.65, 0, 0, 0)
			statText.Size = UDim2.new(0.35, 0, 1, 0)
			statText.BackgroundTransparency = 1
			statText.Font = Enum.Font.SourceSansBold
			statText.TextSize = 13
			statText.TextColor3 = Color3.fromRGB(255, 215, 0)
			statText.TextXAlignment = Enum.TextXAlignment.Right
			statText.Text = "$" .. Util.formatNumber(entry.Coins)
			statText.Parent = row

			row.Parent = lbList
		end
	end
	lbList.CanvasSize = UDim2.new(0, 0, 0, #leaderboardData * 26)
end)

print("[Brainrot Bazaar] Client HUD & Controls Initialized.")
