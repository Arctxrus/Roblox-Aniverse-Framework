local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Units = ReplicatedStorage:WaitForChild("Units")
local UnitInitializer = require(ServerStorage.Modules.Attributes:WaitForChild("UnitInitializer"))
local SplineUtils = require(ReplicatedStorage.Modules.SplineUtils)
local Encoder = require(ReplicatedStorage.Modules.Utils:WaitForChild("Encoder"))
local GridModule = require(ServerStorage.Modules.Utils:WaitForChild("GridModule"))

local PlaceEnemyEvent = ReplicatedStorage.Events:WaitForChild("PlaceEnemy")
local UpdateEnemiesEvent = ReplicatedStorage.Events:WaitForChild("UpdateEnemies")
local RemoveEnemyEvent = ReplicatedStorage.Events:WaitForChild("RemoveEnemy")

local EnemyManager = {}

local activeEnemies = {}
local enemyIdCounter = 0
local updateInterval = 0.1 -- Update every 0.1 seconds
local timeSinceLastUpdate = 0

local GRID_CELL_SIZE = 4

-- Cache waypoints and resampled points once
local waypoints = Workspace.Waypoints:GetChildren()
table.sort(waypoints, function(a, b) return a.Name < b.Name end)

local waypointPositions = {}
for _, waypoint in ipairs(waypoints) do
	table.insert(waypointPositions, waypoint.Position)
end
table.insert(waypointPositions, 1, waypointPositions[1])
table.insert(waypointPositions, waypointPositions[#waypointPositions])

local resampledPoints
if #waypointPositions >= 4 then
	resampledPoints = SplineUtils.resampleSpline(waypointPositions, 100, 1000)
else
	warn("Not enough waypoints for Catmull-Rom spline")
end

local function initializeEnemyAttributes(enemyData, enemyName)
	UnitInitializer("Enemies", enemyName, enemyData)
end

local function getGridCell(x, z)
	return math.floor(x / GRID_CELL_SIZE), math.floor(z / GRID_CELL_SIZE)
end

function EnemyManager.spawnEnemy(enemyName)
	local enemyTemplate = Units.Enemies:FindFirstChild(enemyName)
	if not enemyTemplate then
		warn("No enemy template found for " .. enemyName)
		return
	end

	local uniqueEnemyID = enemyIdCounter
	enemyIdCounter = enemyIdCounter + 1

	local enemyData = {
		ID = uniqueEnemyID,
		Name = enemyName,
		X = 0,
		Y = 0, -- Set this to the constant value for your game
		Z = 0,
		CurrentIndex = 1,
		TotalDistanceTraveled = 0,
		LastX = 0,
		LastZ = 0,
		CurrentGridX = 0,
		CurrentGridZ = 0,
		Speed = enemyTemplate:GetAttribute("Speed") or 0
	}

	local ClientEnemyData = {
		ID = uniqueEnemyID,
		Name = enemyName,
	}
	initializeEnemyAttributes(ClientEnemyData, enemyName)
	initializeEnemyAttributes(enemyData, enemyName)

	if not resampledPoints then
		warn("Resampled points not available")
		return
	end

	enemyData.X = resampledPoints[2].X
	enemyData.Y = resampledPoints[2].Y -- Initial Y value
	enemyData.Z = resampledPoints[2].Z
	enemyData.LastX = resampledPoints[2].X
	enemyData.LastZ = resampledPoints[2].Z
	enemyData.CurrentGridX, enemyData.CurrentGridZ = getGridCell(enemyData.X, enemyData.Z)
	activeEnemies[uniqueEnemyID] = enemyData

	local position = Vector3.new(enemyData.X, enemyData.Y, enemyData.Z)
	enemyData.Position = position
	GridModule.addToGrid(enemyData)

	PlaceEnemyEvent:FireAllClients(position, ClientEnemyData)
end

function EnemyManager.removeEnemy(enemyID)
	local enemyData = activeEnemies[enemyID]
	if enemyData then
		GridModule.removeFromGrid(enemyData)
		activeEnemies[enemyID] = nil
		RemoveEnemyEvent:FireAllClients(enemyID)
	end
end

RunService.Heartbeat:Connect(function(deltaTime)
	timeSinceLastUpdate = timeSinceLastUpdate + deltaTime

	if timeSinceLastUpdate >= updateInterval then
		local updates = {}

		for id, data in pairs(activeEnemies) do
			local currentIndex = data.CurrentIndex

			local nextPosition = resampledPoints[currentIndex + 1]
			if not nextPosition then
				activeEnemies[id] = nil
				GridModule.removeFromGrid(data)
			else
				local direction = (nextPosition - Vector3.new(data.LastX, data.Y, data.LastZ)).Unit
				local distanceToNext = (nextPosition - Vector3.new(data.LastX, data.Y, data.LastZ)).Magnitude
				local distanceTraveled = data.Speed * timeSinceLastUpdate

				if distanceTraveled >= distanceToNext then
					currentIndex = currentIndex + 1
					data.LastX = nextPosition.X
					data.LastZ = nextPosition.Z
				else
					data.LastX = data.LastX + direction.X * distanceTraveled
					data.LastZ = data.LastZ + direction.Z * distanceTraveled
				end

				data.CurrentIndex = currentIndex
				data.TotalDistanceTraveled = data.TotalDistanceTraveled + distanceTraveled
				data.X = data.LastX
				data.Z = data.LastZ

				local orientation = math.atan2(direction.X, direction.Z) + math.pi -- Adding 180 degrees to correct direction
				local newGridX, newGridZ = getGridCell(data.LastX, data.LastZ)

				local encodedData
				if newGridX ~= data.CurrentGridX or newGridZ ~= data.CurrentGridZ then
					-- Grid change detected
					data.CurrentGridX = newGridX
					data.CurrentGridZ = newGridZ
					encodedData = Encoder.EncodeGridChangeData(id, orientation, data.LastX, data.LastZ, newGridX, newGridZ)
				else
					encodedData = Encoder.EncodePositioningData(id, orientation, data.LastX, data.LastZ)
				end
				table.insert(updates, encodedData)

				GridModule.updateGrid(data, data.LastX, data.LastZ)
			end
		end

		if #updates > 0 then
			UpdateEnemiesEvent:FireAllClients(updates)
		end

		timeSinceLastUpdate = 0
	end
end)

return EnemyManager
