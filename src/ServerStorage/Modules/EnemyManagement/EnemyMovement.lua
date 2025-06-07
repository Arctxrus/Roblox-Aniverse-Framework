local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SplineUtils = require(game.ReplicatedStorage.Modules.SplineUtils)
local GridModule = require(game.ServerStorage.Modules.EnemyManagement.GridModule)

local EnemyMovement = {}

local activeEnemies = {}
local maxEnemiesPerBatch = 20

-- Function to move the enemy along the resampled spline at a constant speed
function EnemyMovement.moveEnemyAlongResampledSpline(enemy, resampledPoints)
	local currentIndex = 1
	local totalDistanceTraveled = 0
	local lastPosition = resampledPoints[currentIndex]

	activeEnemies[enemy] = {
		resampledPoints = resampledPoints,
		currentIndex = currentIndex,
		totalDistanceTraveled = totalDistanceTraveled,
		lastPosition = lastPosition,
	}
end

local updateInterval = 0.1 -- Update every 0.1 seconds
local timeSinceLastUpdate = 0

RunService.Heartbeat:Connect(function(deltaTime)
	timeSinceLastUpdate = timeSinceLastUpdate + deltaTime

	if timeSinceLastUpdate >= updateInterval then
		local enemiesProcessed = 0

		for enemy, data in pairs(activeEnemies) do
			if enemiesProcessed >= maxEnemiesPerBatch then
				break
			end

			if not enemy or not enemy.Parent or (enemy:GetAttribute("Health") and enemy:GetAttribute("Health") <= 0) then
				activeEnemies[enemy] = nil
				if enemy and enemy.Parent then
					print("Reached the end of the path. Destroying enemy.")
					GridModule.removeFromGrid(enemy)
					enemy:Destroy()
				end
			else
				local resampledPoints = data.resampledPoints
				local currentIndex = data.currentIndex
				local totalDistanceTraveled = data.totalDistanceTraveled
				local lastPosition = data.lastPosition

				local nextPosition = resampledPoints[currentIndex + 1]
				if not nextPosition then
					activeEnemies[enemy] = nil
				else
					local direction = (nextPosition - lastPosition).Unit
					local distanceToNext = (nextPosition - lastPosition).Magnitude
					local speed = enemy:GetAttribute("Speed") or 0
					local distanceTraveled = speed * timeSinceLastUpdate

					if distanceTraveled >= distanceToNext then
						currentIndex = currentIndex + 1
						lastPosition = nextPosition
					else
						lastPosition = lastPosition + direction * distanceTraveled
					end

					totalDistanceTraveled = totalDistanceTraveled + distanceTraveled

					enemy:SetAttribute("DistanceTraveled", totalDistanceTraveled)
					GridModule.addToGrid(enemy) -- Update the grid with the new position

					enemy.Position = lastPosition

					data.currentIndex = currentIndex
					data.totalDistanceTraveled = totalDistanceTraveled
					data.lastPosition = lastPosition
				end
			end

			enemiesProcessed = enemiesProcessed + 1
		end

		timeSinceLastUpdate = 0
	end
end)

return EnemyMovement
