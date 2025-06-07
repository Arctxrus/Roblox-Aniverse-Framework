local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local PlayerDataModule = require(ServerStorage.Modules.PlayerData:WaitForChild("PlayerDataModule"))

-- Get the pre-created RemoteFunction and RemoteEvent instances
local requestEquippedTowers = ReplicatedStorage.Functions:WaitForChild("RequestEquippedTowers")
local getPlayerTowers = ReplicatedStorage.Functions:WaitForChild("GetPlayerTowers")

local equipTower = ReplicatedStorage.Events:WaitForChild("EquipTower")

-- Handle equipped towers requests
requestEquippedTowers.OnServerInvoke = function(player)
	return PlayerDataModule.getEquippedTowers(player)
end

-- Handle getting player's towers
getPlayerTowers.OnServerInvoke = function(player)
	return PlayerDataModule.getPlayerTowers(player)
end

-- Handle equip tower request
equipTower.OnServerEvent:Connect(function(player, towers)
	PlayerDataModule.setEquippedTowers(player, towers)
end)

-- Initialize player data when they join
Players.PlayerAdded:Connect(function(player)
	PlayerDataModule.initializePlayerData(player)
end)

-- Remove player data when they leave
Players.PlayerRemoving:Connect(function(player)
	PlayerDataModule.removePlayerData(player)
end)
