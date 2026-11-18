--!strict
-- Server Configuration Bridge

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ServerConfig = {}

-- Inherit all shared config properties
for key, value in pairs(SharedConfig) do
	ServerConfig[key] = value
end

-- Server-specific constants
ServerConfig.SaveInterval = 30
ServerConfig.IncomeTickRate = 1.0
ServerConfig.ConveyorCheckRate = 0.5

return ServerConfig
