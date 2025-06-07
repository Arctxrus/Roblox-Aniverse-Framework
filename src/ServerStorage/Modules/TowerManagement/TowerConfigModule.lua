-- TowerConfigModule.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerConfigModule = {}

local towersFolder = ReplicatedStorage:WaitForChild("Units"):WaitForChild("Towers")
local towerTemplates = {}

-- Read all towers in the folder
for _, tower in ipairs(towersFolder:GetChildren()) do
	if tower:IsA("Model") then
		towerTemplates[tower.Name] = tower
	end
end

function TowerConfigModule.getTowerTemplate(towerName)
	return towerTemplates[towerName]
end

function TowerConfigModule.getAllTowers()
	return towerTemplates
end

return TowerConfigModule
