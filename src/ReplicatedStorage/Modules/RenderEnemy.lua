local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local AnimationPlayer = require(ReplicatedStorage.Modules.Animation:WaitForChild("AnimationPlayer"))
local Encoder = require(ReplicatedStorage.Modules.Utils:WaitForChild("Encoder"))
local FrustumCullingModule = require(ReplicatedStorage.Modules:WaitForChild("FrustumCullingModule"))
local EnemyUIManager = require(ReplicatedStorage.Modules.UI:WaitForChild("EnemyUIManagerModule"))

local RenderEnemyModule = {}

local lastGridCoordinates = {}
local enemyModels = {}
local targetPositions = {}

local GRID_CELL_SIZE = 4
local LERP_DURATION = 0.5
local MAX_X_DISPLACEMENT = 0.5

local function weldModel(model)
	local primaryPart = model.PrimaryPart
	if not primaryPart then return end

	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= primaryPart then
			local motor = Instance.new("Motor6D")
			motor.Part0 = primaryPart
			motor.Part1 = part
			motor.C0 = primaryPart.CFrame:Inverse() * part.CFrame
			motor.Parent = primaryPart
		end
	end
end

function RenderEnemyModule.removeEnemy(uniqueEnemyID)
	local enemyModel = enemyModels[uniqueEnemyID]
	if enemyModel then
		enemyModel:Destroy()
		enemyModels[uniqueEnemyID] = nil
		lastGridCoordinates[uniqueEnemyID] = nil
		targetPositions[uniqueEnemyID] = nil
	end
end

local function updateEnemyPosition(uniqueEnemyID, serverPosition, orientation)
	local enemyModel = enemyModels[uniqueEnemyID]
	if not enemyModel then
		warn("Enemy model not found for ID:", uniqueEnemyID)
		return
	end

	if not enemyModel.PrimaryPart then
		warn("PrimaryPart not set for enemy model ID:", uniqueEnemyID)
		return
	end

	targetPositions[uniqueEnemyID] = { Position = serverPosition, Orientation = orientation }
end

local function lerpEnemyPositions(deltaTime)
	local partList = {}
	local cframeList = {}

	for uniqueEnemyID, targetData in pairs(targetPositions) do
		local enemyModel = enemyModels[uniqueEnemyID]
		if enemyModel and enemyModel.PrimaryPart then
			local currentPosition = enemyModel.PrimaryPart.Position
			local targetPosition = targetData.Position
			local orientation = targetData.Orientation

			local displacement = enemyModel:GetAttribute("XDisplacement") or 0
			targetPosition = targetPosition + Vector3.new(displacement, 0, 0)

			local lerpFactor = math.min(deltaTime / LERP_DURATION, 1)

			local newPosition = currentPosition:Lerp(targetPosition, lerpFactor)
			local currentCFrame = enemyModel.PrimaryPart.CFrame
			local targetCFrame = CFrame.new(targetPosition) * CFrame.Angles(0, orientation, 0)
			local newCFrame = currentCFrame:Lerp(targetCFrame, lerpFactor)

			table.insert(partList, enemyModel.PrimaryPart)
			table.insert(cframeList, newCFrame)

			if (newPosition - targetPosition).Magnitude < 0.1 then
				enemyModel:SetPrimaryPartCFrame(targetCFrame)
				targetPositions[uniqueEnemyID] = nil
			end
		end
	end

	if #partList > 0 then
		Workspace:BulkMoveTo(partList, cframeList)
	end
end

local function updateEnemyVisibility()
	for _, enemyModel in pairs(enemyModels) do
		if enemyModel.PrimaryPart then
			local inView = FrustumCullingModule.isModelInView(enemyModel)
			for _, part in ipairs(enemyModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = inView and 0 or 1
				end
			end
		end
	end
end

function RenderEnemyModule.updateEnemyPositions(updates)
	for _, encodedData in ipairs(updates) do
		local uniqueEnemyID, orientation, x, z, gridX, gridZ, y

		if typeof(encodedData) == "Vector2int16" then
			local displacementX, displacementZ
			uniqueEnemyID, orientation, displacementX, displacementZ = Encoder.DecodePositioningData(encodedData)
			local lastGrid = lastGridCoordinates[uniqueEnemyID]
			if lastGrid then
				gridX, gridZ, y = lastGrid.GridX, lastGrid.GridZ, lastGrid.Y
				x = gridX * GRID_CELL_SIZE + displacementX
				z = gridZ * GRID_CELL_SIZE + displacementZ
			else
				warn("No last grid coordinates for ID:", uniqueEnemyID)
				continue
			end
		else
			uniqueEnemyID, orientation, x, z, gridX, gridZ = Encoder.DecodeGridChangeData(encodedData)
			local lastGrid = lastGridCoordinates[uniqueEnemyID]
			if lastGrid then
				y = lastGrid.Y
			else
				warn("No last Y value for ID:", uniqueEnemyID)
				y = 15
			end
			lastGridCoordinates[uniqueEnemyID] = { GridX = gridX, GridZ = gridZ, Y = y }
			x = gridX * GRID_CELL_SIZE + x
			z = gridZ * GRID_CELL_SIZE + z
		end

		local serverPosition = Vector3.new(x, y, z)

		updateEnemyPosition(uniqueEnemyID, serverPosition, orientation)
	end
end

function RenderEnemyModule.renderEnemy(position, enemyData)
	local uniqueEnemyID = enemyData.ID
	local enemyName = enemyData.Name
	local walkingAnim = enemyData.WalkingAnim -- Ensure that the walkingAnim attribute exists in enemyData

	if enemyModels[uniqueEnemyID] then
		warn("Duplicate enemy creation attempt for ID:", uniqueEnemyID)
		return
	end

	local EnemiesFolder = ReplicatedStorage.Units.Enemies
	local enemyTemplate = EnemiesFolder:FindFirstChild(enemyName)
	if not enemyTemplate then
		warn("Enemy template not found for:", enemyName)
		return
	end

	local enemyModel = enemyTemplate:Clone()
	enemyModel.Name = tostring(uniqueEnemyID)

	local randomXDisplacement = math.random(-MAX_X_DISPLACEMENT * 100, MAX_X_DISPLACEMENT * 100) / 100
	enemyModel:SetAttribute("XDisplacement", randomXDisplacement)

	local spawnPosition = position + Vector3.new(randomXDisplacement, 0, 0)
	enemyModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
	enemyModel.Parent = Workspace.RenderedEnemies

	weldModel(enemyModel)

	for _, part in ipairs(enemyModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CastShadow = false
			if part == enemyModel.PrimaryPart then
				part.Anchored = true
			else
				part.Anchored = false
			end
		end
	end

	enemyModel:SetAttribute("WalkingAnim", walkingAnim)
	AnimationPlayer.playEnemyWalkingAnimation(enemyModel)

	local initialGridX = math.floor(position.X / GRID_CELL_SIZE)
	local initialGridZ = math.floor(position.Z / GRID_CELL_SIZE)
	lastGridCoordinates[uniqueEnemyID] = { GridX = initialGridX, GridZ = initialGridZ, Y = position.Y }
	enemyModels[uniqueEnemyID] = enemyModel

	EnemyUIManager.createEntityUI(enemyModel, enemyData)
end

RunService.Heartbeat:Connect(function(deltaTime)
	if next(targetPositions) then
		lerpEnemyPositions(deltaTime)
	end
	--updateEnemyVisibility()
end)

return RenderEnemyModule