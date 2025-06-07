local Workspace = game:GetService("Workspace")
local GridModule = require(game.ServerStorage.Modules.Utils.GridModule)

local EnemyTargeting = {}

function EnemyTargeting.getTarget(towerData, range, criterion)
	local towerType = towerData.Type

	local enemiesInRange = GridModule.getEnemiesInRange(towerData.Position, range)

	local function isValidTarget(enemyData)
		local enemyType = enemyData.Type
		if (towerType == "Ground" and enemyType == "Ground") or 
			(towerType ~= "Ground" and (enemyType == "Ground" or enemyType == "Flying")) then
			return true
		end
		return false
	end

	-- Filter out invalid targets
	local validTargets = {}
	for _, enemyData in ipairs(enemiesInRange) do
		if isValidTarget(enemyData) then
			table.insert(validTargets, enemyData)
		end
	end

	if #validTargets == 0 then
		return nil
	end

	table.sort(validTargets, function(a, b)
		if criterion == "first" then
			return (a.TotalDistanceTraveled or 0) > (b.TotalDistanceTraveled or 0)
		elseif criterion == "last" then
			return (a.TotalDistanceTraveled or 0) < (b.TotalDistanceTraveled or 0)
		elseif criterion == "strongest" then
			return a.Health > b.Health
		elseif criterion == "weakest" then
			return a.Health < b.Health
		elseif criterion == "closest" then
			return (towerData.Position - a.Position).Magnitude < (towerData.Position - b.Position).Magnitude
		elseif criterion == "furthest" then
			return (towerData.Position - a.Position).Magnitude > (towerData.Position - b.Position).Magnitude
		end
	end)
	return validTargets[1]
end

return EnemyTargeting
