local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local EnemyHitModule = require(ServerStorage.Modules.Combat:WaitForChild("ApplyDamage"))
local GridModule = require(ServerStorage.Modules.Utils:WaitForChild("GridModule"))

local AttackModule = {}

local function getEnemiesInRadius(position, radius, towerType)
	local enemiesInRange = GridModule.getEnemiesInRange(position, radius)
	local validEnemies = {}

	for _, enemyData in ipairs(enemiesInRange) do
		local enemyType = enemyData.Type
		if (towerType == "Ground" and enemyType == "Ground") or 
			(towerType ~= "Ground" and (enemyType == "Ground" or enemyType == "Flying")) then
			table.insert(validEnemies, enemyData)
		end
	end

	return validEnemies
end

local function getEnemiesInLine(startPosition, direction, length, width, towerType)
	local enemiesInRange = GridModule.getEnemiesInRange(startPosition, length)
	local validEnemies = {}

	for _, enemyData in ipairs(enemiesInRange) do
		local enemyType = enemyData.Type
		local toEnemy = enemyData.Position - startPosition
		local projectionLength = toEnemy:Dot(direction)
		local perpendicularDistance = (toEnemy - direction * projectionLength).Magnitude

		if projectionLength >= 0 and projectionLength <= length and perpendicularDistance <= width / 2 then
			if (towerType == "Ground" and enemyType == "Ground") or 
				(towerType ~= "Ground" and (enemyType == "Ground" or enemyType == "Flying")) then
				table.insert(validEnemies, enemyData)
			end
		end
	end

	return validEnemies
end

function AttackModule.Single(towerData, targetData, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
	EnemyHitModule.applyEffectsToEnemy(towerData, targetData, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
end

function AttackModule.Full(towerData, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
	local range = towerData.Range
	local enemiesInRange = getEnemiesInRadius(towerData.Position, range, towerType)
	for _, enemyData in ipairs(enemiesInRange) do
		EnemyHitModule.applyEffectsToEnemy(towerData, enemyData, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
	end
end

function AttackModule.Line(towerData, targetData, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
	local range = towerData.Range
	local attackSize = towerData.AttackSize
	local direction = (targetData.Position - towerData.Position).Unit
	local enemiesInRange = getEnemiesInLine(towerData.Position, direction, range, attackSize, towerType)
	for _, enemyData in ipairs(enemiesInRange) do
		EnemyHitModule.applyEffectsToEnemy(towerData, enemyData, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
	end
end

function AttackModule.Circle(towerData, targetData, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
	local attackSize = towerData.AttackSize
	local enemiesInRange = getEnemiesInRadius(targetData.Position, attackSize, towerType)
	for _, enemyData in ipairs(enemiesInRange) do
		EnemyHitModule.applyEffectsToEnemy(towerData, enemyData, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
	end
end

return AttackModule
