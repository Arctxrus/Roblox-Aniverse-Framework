local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")

local AnimationPlayer = require(ReplicatedStorage.Modules.Animation:WaitForChild("AnimationPlayer"))
local AttackPreviewModule = require(ReplicatedStorage.Modules.AttackPreview)

local PreviewModule = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local previewTower = nil
local rangeIndicator = nil
local attackIndicator = nil
local smoothSpeed = 0.1
local placementRadius = 3 -- Define the minimum distance between towers
local currentTowerAttributes = nil -- Store tower attributes at module level

local function createPreviewTower(towerAttributes, position)
	local towerModel = ReplicatedStorage.Units.Towers:FindFirstChild(towerAttributes.name):Clone()
	assert(towerModel, "Tower model not found in ReplicatedStorage.Units.Towers: " .. tostring(towerAttributes.name))
	towerModel.Parent = workspace
	
	local idleanimation = towerAttributes.attributes.Idle
	AnimationPlayer.playIdleAnimation(towerModel, idleanimation)

	-- Set properties and attributes for the preview tower
	for _, part in ipairs(towerModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CastShadow = false
			part.Transparency = (part == towerModel.PrimaryPart) and 1 or 0
			if part == towerModel.PrimaryPart or part.Name == "HumanoidRootPart" then
				part.Anchored = true
			else
				part.Anchored = false
			end
			PhysicsService:SetPartCollisionGroup(part, "Towers")
		end
	end

	local highlight = Instance.new("Highlight")
	highlight.Adornee = towerModel
	highlight.Enabled = true
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.new(1, 0.34902, 0.34902) -- Red for invalid placement initially
	highlight.OutlineTransparency = 0 -- Fully visible outline
	highlight.Parent = towerModel

	towerModel:SetPrimaryPartCFrame(CFrame.new(position))
	return towerModel
end

local function isValidPlacement(target, towerType)
	if target then
		if target.Name == "Ground" and (towerType == "Ground" or towerType == "Hybrid") then
			return true
		elseif target.Name == "Hill" and (towerType == "Hill" or towerType == "Hybrid") then
			return true
		end
	end
	return false
end

local function isWithinPlacementRadius(position, radius)
	for _, tower in pairs(Workspace.Towers:GetChildren()) do
		if tower:IsA("Model") then
			local distance = (tower.PrimaryPart.Position - position).Magnitude
			if distance < radius then
				return false
			end
		end
	end
	return true
end

function PreviewModule.createPreview(position, towerAttributes)
	currentTowerAttributes = towerAttributes.attributes -- Store tower attributes at module level

	if not previewTower then
		previewTower = createPreviewTower(towerAttributes, position)
	else
		previewTower:SetPrimaryPartCFrame(CFrame.new(position))
	end

	local towerRange = currentTowerAttributes.Range
	if not rangeIndicator then
		rangeIndicator = AttackPreviewModule.createRangePreview(towerRange)
	end
	rangeIndicator.Position = previewTower.PrimaryPart.Position

	local towerType = currentTowerAttributes.Type
	if towerType then
		previewTower:SetAttribute("Type", towerType)
	else
		warn("No Type attribute found for tower")
	end

	if not attackIndicator then
		local attackType = currentTowerAttributes.AttackType
		local attackSize = currentTowerAttributes.AttackSize
		if attackType and attackSize then
			local direction = previewTower.PrimaryPart.CFrame.LookVector
			local startPosition = previewTower.PrimaryPart.Position

			if attackType == "Single" then
				attackIndicator = AttackPreviewModule.createSingleTargetPreview()
			elseif attackType == "Full" then
				attackIndicator = AttackPreviewModule.createFullAoEPreview(towerRange)
			elseif attackType == "Line" then
				local endPosition = startPosition + direction * towerRange
				attackIndicator = AttackPreviewModule.createLinePreview(startPosition, endPosition, attackSize)
			elseif attackType == "Circle" then
				attackIndicator = AttackPreviewModule.createCirclePreview(attackSize, startPosition, direction)
			end
			if attackIndicator then
				PhysicsService:SetPartCollisionGroup(attackIndicator, "Towers")
			end
		end
	end
end

function PreviewModule.updatePreviewPosition(targetPosition, isPlaceable)
	if previewTower and previewTower.PrimaryPart then
		local currentCFrame = previewTower.PrimaryPart.CFrame
		local targetCFrame = CFrame.new(targetPosition)
		local newCFrame = currentCFrame:Lerp(targetCFrame, smoothSpeed)
		previewTower:SetPrimaryPartCFrame(newCFrame)

		if rangeIndicator then
			AttackPreviewModule.updateRangePreview(rangeIndicator, previewTower.PrimaryPart.Position)
		end

		local targetColor = isPlaceable and Color3.new(0.588235, 1, 0.52549) or Color3.new(1, 0.490196, 0.490196)
		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		for _, part in ipairs(previewTower:GetDescendants()) do
			if part:IsA("BasePart") then
				local colorTween = TweenService:Create(part, tweenInfo, {Color = targetColor})
				colorTween:Play()
			end
		end

		local highlight = previewTower:FindFirstChildOfClass("Highlight")
		if highlight then
			local outlineTween = TweenService:Create(highlight, tweenInfo, {OutlineColor = targetColor})
			outlineTween:Play()
		end

		-- Update the attack indicator position
		if attackIndicator and currentTowerAttributes then
			local towerRange = currentTowerAttributes.Range
			local attackType = currentTowerAttributes.AttackType
			local attackSize = currentTowerAttributes.AttackSize
			local direction = previewTower.PrimaryPart.CFrame.LookVector
			local startPosition = previewTower.PrimaryPart.Position

			if attackType == "Line" then
				local endPosition = startPosition + direction * towerRange
				AttackPreviewModule.updateLinePreview(attackIndicator, startPosition, endPosition, attackSize, smoothSpeed)
			elseif attackType == "Circle" then
				local targetPosition = startPosition + (direction.Unit * towerRange)
				AttackPreviewModule.updateCirclePreview(attackIndicator, targetPosition, smoothSpeed)
			else
				attackIndicator.Position = previewTower.PrimaryPart.Position
			end
		end
	end
end

function PreviewModule.removePreviews()
	if previewTower then
		previewTower:Destroy()
		previewTower = nil
	end
	if rangeIndicator then
		rangeIndicator:Destroy()
		rangeIndicator = nil
	end
	if attackIndicator then
		attackIndicator:Destroy()
		attackIndicator = nil
	end
end

function PreviewModule.getMousePositionIgnoringModels()
	local mouseRay = mouse.UnitRay
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local excludeList = {player.Character}
	if previewTower then
		table.insert(excludeList, previewTower)
	end
	if rangeIndicator then
		table.insert(excludeList, rangeIndicator)
	end
	if attackIndicator then
		table.insert(excludeList, attackIndicator)
	end
	for _, tower in pairs(workspace.Towers:GetChildren()) do
		if tower:IsA("Model") then
			table.insert(excludeList, tower)
		end
	end

	raycastParams.FilterDescendantsInstances = excludeList
	local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)

	if raycastResult then
		return raycastResult.Position, raycastResult.Instance
	else
		return nil, nil
	end
end

PreviewModule.isValidPlacement = function(position, target, towerType)
	return isValidPlacement(target, towerType) and isWithinPlacementRadius(position, placementRadius)
end

RunService.RenderStepped:Connect(function()
	if previewTower then
		local position, target = PreviewModule.getMousePositionIgnoringModels()
		local towerType = previewTower and previewTower:GetAttribute("Type")
		local isPlaceable = false

		if target and position then
			isPlaceable = PreviewModule.isValidPlacement(position, target, towerType)
		end

		PreviewModule.updatePreviewPosition(position or Vector3.new(0, 0, 0), isPlaceable)
	end
end)

return PreviewModule
