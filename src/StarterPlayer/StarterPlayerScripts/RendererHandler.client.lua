-- StarterPlayer/StarterPlayerScripts/RendererHandler.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RenderTower = require(ReplicatedStorage.Modules.RenderTower)
local RenderEnemy = require(ReplicatedStorage.Modules.RenderEnemy)

-- Listen for PlaceTower event to render towers on the client
ReplicatedStorage.Events.PlaceTower.OnClientEvent:Connect(function(uniqueTowerID, towerName, position, idleAnimation)
	RenderTower.renderTower(uniqueTowerID, towerName, position, idleAnimation)
end)

-- Listen for PlaceEnemy event to render enemies on the client
ReplicatedStorage.Events.PlaceEnemy.OnClientEvent:Connect(function(position, enemyData)
	RenderEnemy.renderEnemy(position, enemyData)
end)

-- Listen for UpdateEnemies event to update enemies' positions
ReplicatedStorage.Events.UpdateEnemies.OnClientEvent:Connect(function(updates)
	RenderEnemy.updateEnemyPositions(updates)
end)

-- Listen for RemoveEnemy event to remove enemies on the client
ReplicatedStorage.Events.RemoveEnemy.OnClientEvent:Connect(function(enemyID)
	RenderEnemy.removeEnemy(enemyID)
end)
