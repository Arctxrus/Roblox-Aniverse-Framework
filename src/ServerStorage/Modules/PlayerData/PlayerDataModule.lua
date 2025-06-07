local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local TowerAttributes = require(ServerStorage.Modules.Attributes:WaitForChild("TowerAttributesModule"))

local PlayerDataModule = {}

-- Placeholder for player data storage, in a real implementation this might be a DataStore
local playerData = {}

local defaultTowers = {
	{name = "Mahuna", uuid = HttpService:GenerateGUID()},
	{name = "Dedid", uuid = HttpService:GenerateGUID()},
	{name = "Chozzi", uuid = HttpService:GenerateGUID()}
} -- Default towers for testing

-- Initialize player data
function PlayerDataModule.initializePlayerData(player)
	playerData[player.UserId] = {
		equippedTowers = defaultTowers,
		customStats = {},
		towerInventory = {}
	}

	-- Initialize tower inventory with base stats
	for _, tower in ipairs(defaultTowers) do
		playerData[player.UserId].towerInventory[tower.uuid] = {
			name = tower.name,
			attributes = TowerAttributes[tower.name] -- Copy base stats from global templates
		}
	end
end

-- Remove player data
function PlayerDataModule.removePlayerData(player)
	playerData[player.UserId] = nil
end

function PlayerDataModule.getEquippedTowers(player)
	if playerData[player.UserId] then
		local equippedTowers = playerData[player.UserId].equippedTowers
		for _, tower in ipairs(equippedTowers) do
			tower.attributes = playerData[player.UserId].towerInventory[tower.uuid].attributes
		end
		return equippedTowers
	else
		return {}
	end
end

function PlayerDataModule.getCustomStats(player)
	return playerData[player.UserId] and playerData[player.UserId].customStats or {}
end

function PlayerDataModule.setEquippedTowers(player, towers)
	if playerData[player.UserId] then
		playerData[player.UserId].equippedTowers = towers
	end
end

function PlayerDataModule.setCustomStats(player, stats)
	if playerData[player.UserId] then
		playerData[player.UserId].customStats = stats
	end
end

-- Get player-specific tower attributes
function PlayerDataModule.getTowerAttributes(player, towerUUID)
	if playerData[player.UserId] and playerData[player.UserId].towerInventory[towerUUID] then
		return playerData[player.UserId].towerInventory[towerUUID].attributes
	else
		return nil
	end
end

-- Set player-specific tower attributes
function PlayerDataModule.setTowerAttributes(player, towerUUID, attributes)
	if playerData[player.UserId] then
		playerData[player.UserId].towerInventory[towerUUID].attributes = attributes
	end
end

-- Modify player-specific tower attributes
function PlayerDataModule.modifyTowerAttributes(player, towerUUID, modifications)
	if playerData[player.UserId] and playerData[player.UserId].towerInventory[towerUUID] then
		local attributes = playerData[player.UserId].towerInventory[towerUUID].attributes
		for k, v in pairs(modifications) do
			if attributes[k] then
				attributes[k] = attributes[k] + v
			else
				attributes[k] = v
			end
		end
	end
end

-- Add a tower to player's inventory
function PlayerDataModule.addTowerToInventory(player, towerName)
	if not playerData[player.UserId] then return end
	local uuid = HttpService:GenerateGUID()
	playerData[player.UserId].towerInventory[uuid] = {
		name = towerName,
		attributes = TowerAttributes[towerName] -- Copy base stats from global templates
	}
	return uuid
end

-- Get the entire player inventory structured like TowerAttributesModule
function PlayerDataModule.getPlayerTowers(player)
	if playerData[player.UserId] then
		return playerData[player.UserId].towerInventory
	else
		return {}
	end
end

return PlayerDataModule