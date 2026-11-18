--!strict
-- Meme Storm Hazard Wave & Environmental Event Service

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Config"))
local BaseService = require(ServerScriptService:WaitForChild("Server"):WaitForChild("BaseService"))
local PlayerService = require(ServerScriptService:WaitForChild("Server"):WaitForChild("PlayerService"))

local EventService = {}

type StormState = "Calm" | "Warning" | "Active"

local currentState: StormState = "Calm"
local stateEndTime: number = 0
local lastDrainPulseTime: number = 0
local remotesFolder: Folder

local originalLighting = {
	Ambient = Color3.fromRGB(25, 25, 25),
	OutdoorAmbient = Color3.fromRGB(100, 115, 130),
	Brightness = 2.5,
}

function EventService.Init()
	remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder

	stateEndTime = os.clock() + Config.MemeStorm.Interval

	task.spawn(function()
		while true do
			task.wait(1.0)
			EventService.Tick()
		end
	end)
end

function EventService.GetStormStatus(): { State: string, TimeRemaining: number }
	local remaining = math.max(0, math.ceil(stateEndTime - os.clock()))
	return {
		State = currentState,
		TimeRemaining = remaining,
	}
end

function EventService.BroadcastStormUpdate()
	local stormRemote = remotesFolder:FindFirstChild("StormWarning") :: RemoteEvent?
	if stormRemote then
		local status = EventService.GetStormStatus()
		stormRemote:FireAllClients(status)
	end
end

function EventService.BroadcastNotification(message: string, isAlert: boolean)
	local notifyRemote = remotesFolder:FindFirstChild("Notify") :: RemoteEvent?
	if notifyRemote then
		notifyRemote:FireAllClients(message, isAlert)
	end
end

function EventService.Tick()
	local now = os.clock()

	if currentState == "Calm" then
		if now >= stateEndTime then
			-- Transition to Warning
			currentState = "Warning"
			stateEndTime = now + Config.MemeStorm.WarningDuration
			EventService.BroadcastStormUpdate()
			EventService.BroadcastNotification("⚠️ MEME STORM INCOMING IN 15s! SEEK SHELTER IN YOUR BASE!", true)
		end
	elseif currentState == "Warning" then
		if now >= stateEndTime then
			-- Transition to Active Storm
			currentState = "Active"
			stateEndTime = now + Config.MemeStorm.StormDuration
			EventService.ApplyStormLighting(true)
			EventService.BroadcastStormUpdate()
			EventService.BroadcastNotification("🌪️ MEME STORM ACTIVE! PLAYERS OUTSIDE TAKE SLOWDOWN & COIN DRAIN!", true)
		end
	elseif currentState == "Active" then
		if now >= stateEndTime then
			-- Transition back to Calm
			currentState = "Calm"
			stateEndTime = now + Config.MemeStorm.Interval
			EventService.ApplyStormLighting(false)
			EventService.ResetAllWalkSpeeds()
			EventService.BroadcastStormUpdate()
			EventService.BroadcastNotification("☀️ The Meme Storm has passed! The Bazaar plaza is safe!", false)
		else
			-- Process hazard damage pulse to unprotected players
			EventService.ProcessHazardTick()
		end
	end
end

function EventService.ProcessHazardTick()
	local now = os.clock()
	local drainInterval = Config.MemeStorm.CoinDrainInterval or 2.5
	local shouldDrain = false
	if now - lastDrainPulseTime >= drainInterval then
		shouldDrain = true
		lastDrainPulseTime = now
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?

			if humanoid and rootPart then
				local isSafe = BaseService.IsPositionInsideAnyClaimedBase(rootPart.Position)

				if isSafe then
					-- Protected inside base plot
					if humanoid.WalkSpeed ~= 16 then
						humanoid.WalkSpeed = 16
					end
				else
					-- Caught outside in the Meme Storm!
					humanoid.WalkSpeed = Config.MemeStorm.SlowWalkSpeed or 8
					if shouldDrain then
						local drained = PlayerService.DeductCoinsPercent(player, Config.MemeStorm.CoinDrainPercent or 0.03)
						if drained > 0 then
							local notifyRemote = remotesFolder:FindFirstChild("Notify") :: RemoteEvent?
							if notifyRemote then
								notifyRemote:FireClient(player, string.format("💨 Meme Storm wind blew away $%d! Run to your base!", drained), true)
							end
						end
					end
				end
			end
		end
	end
end

function EventService.ResetAllWalkSpeeds()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
			if humanoid then
				humanoid.WalkSpeed = 16
			end
		end
	end
end

function EventService.ApplyStormLighting(isStormActive: boolean)
	if isStormActive then
		Lighting.Ambient = Color3.fromRGB(45, 10, 55)
		Lighting.OutdoorAmbient = Color3.fromRGB(30, 15, 45)
		Lighting.Brightness = 1.0
	else
		Lighting.Ambient = originalLighting.Ambient
		Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
		Lighting.Brightness = originalLighting.Brightness
	end
end

return EventService
