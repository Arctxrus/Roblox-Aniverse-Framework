local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local PlayerDataModule = require(ServerStorage.Modules.PlayerData:WaitForChild("PlayerDataModule"))
local UnitInitializer = require(ServerStorage.Modules.Attributes:WaitForChild("UnitInitializer"))
local TowerAttackModule = require(ServerStorage.Modules.TowerManagement:WaitForChild("TowerAttackModule"))

local PlaceTowerEvent = ReplicatedStorage.Events:WaitForChild("PlaceTower")
local ValidatePlacementEvent = ReplicatedStorage.Functions:WaitForChild("ValidatePlacement")
local UpgradeTowerEvent = ReplicatedStorage.Events:WaitForChild("UpgradeTower") -- New event for upgrading towers

local generatedUUIDs = {}
local activeTowers = {}

local function generateUniqueUUID()
	local uuid
	repeat
		uuid = HttpService:GenerateGUID(false)
	until not generatedUUIDs[uuid]
	generatedUUIDs[uuid] = true
	return uuid
end

local function isValidPlacement(target, towerType)
	if target then
		if towerType == "Ground" and target.Name == "Ground" then
			return true
		elseif towerType == "Hill" and target.Name == "Hill" then
			return true
		elseif towerType == "Hybrid" then
			return true
		end
	end
	return false
end

local function isWithinPlacementRadius(position, radius)
	for _, towerData in pairs(activeTowers) do
		local distance = (towerData.Position - position).Magnitude
		if distance < radius then
			return false
		end
	end
	return true
end

local function getTowerData(player, towerUUID)
	local playerTowers = PlayerDataModule.getPlayerTowers(player)
	local towerData = playerTowers[towerUUID]
	if not towerData then
		warn("Failed to get tower data for: " .. towerUUID)
		return nil
	end
	local towerAttributes = towerData.attributes
	if not towerAttributes then
		warn("Failed to get tower attributes for: " .. towerUUID)
		return nil
	end
	return towerData, towerAttributes
end

ValidatePlacementEvent.OnServerInvoke = function(player, position, target, towerUUID)
	local towerData, towerAttributes = getTowerData(player, towerUUID)
	if not towerData or not towerAttributes then
		return false
	end
	local towerType = towerAttributes.Type
	return isValidPlacement(target, towerType) and isWithinPlacementRadius(position, 3)
end

PlaceTowerEvent.OnServerEvent:Connect(function(player, target, towerUUID, position)
	local towerData, towerAttributes = getTowerData(player, towerUUID)
	if not towerData or not towerAttributes then
		return
	end
	local towerType = towerAttributes.Type

	if isValidPlacement(target, towerType) and isWithinPlacementRadius(position, 3) then
		local uniqueTowerID = generateUniqueUUID() -- Generate a unique UUID

		local tower = {
			ID = uniqueTowerID,
			Name = towerData.name,
			Owner = player.UserId,
			Position = position,
			Attributes = towerAttributes
		}

		activeTowers[uniqueTowerID] = tower

		-- Initialize tower attributes
		UnitInitializer("Towers", towerData.name, tower)
		local idleAnimation = towerAttributes.Idle

		-- Fire event to render tower on the client
		PlaceTowerEvent:FireAllClients(uniqueTowerID, towerData.name, position, idleAnimation)

		-- Add tower to attack module
		TowerAttackModule.addTower(tower)
	else
		warn("Invalid tower placement for: " .. towerData.name)
	end
end)

UpgradeTowerEvent.OnServerEvent:Connect(function(player, towerID, newAttributes)
	-- Update the tower attributes
	TowerAttackModule.updateTowerAttributes(towerID, newAttributes)
end)

return {
	activeTowers = activeTowers
}
