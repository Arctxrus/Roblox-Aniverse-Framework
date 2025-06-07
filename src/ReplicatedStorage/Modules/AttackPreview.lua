local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local AnimationModule = require(game.ReplicatedStorage.Modules.Animation:WaitForChild("FadeGrowIn"))

local AttackPreviewModule = {}

local function createIndicatorPart()
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1  -- Start fully transparent for the fade-in effect
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 255, 255)
	part.Parent = Workspace
	PhysicsService:SetPartCollisionGroup(part, "Towers")
	return part
end

local function createCircleIndicator(position, radius)
	local indicator = createIndicatorPart()
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Size = Vector3.new(0.1, radius * 2, radius * 2)
	indicator.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	AnimationModule.growAndFadeIn(indicator, 0.5)
	return indicator
end

local function createLineIndicator(startPosition, endPosition, width)
	local length = (endPosition - startPosition).Magnitude
	local midpoint = (startPosition + endPosition) / 2

	local indicator = createIndicatorPart()
	indicator.Size = Vector3.new(width, 0.1, length)
	indicator.CFrame = CFrame.new(midpoint, endPosition)
	AnimationModule.growAndFadeIn(indicator, 0.5)
	return indicator
end

local function createRangeIndicator(radius)
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.Transparency = 1  -- Start fully transparent for the fade-in effect
	sphere.Color = Color3.new(1, 1, 1)
	sphere.Material = Enum.Material.ForceField
	sphere.CastShadow = false
	sphere.Parent = Workspace
	PhysicsService:SetPartCollisionGroup(sphere, "Towers")
	AnimationModule.growAndFadeIn(sphere, 0.5)
	return sphere
end

local function updateIndicatorPositionSmooth(indicator, targetPosition, smoothSpeed)
	if not indicator then return end
	local currentPosition = indicator.Position
	local newPosition = currentPosition:Lerp(targetPosition, smoothSpeed)
	indicator.Position = newPosition
end

function AttackPreviewModule.createSingleTargetPreview()
	local indicator = createCircleIndicator(Vector3.new(0, 0, 0), 1)
	return indicator
end

function AttackPreviewModule.createFullAoEPreview(radius)
	local indicator = createCircleIndicator(Vector3.new(0, 0, 0), radius)
	print("circle created")
	return indicator
end

function AttackPreviewModule.createLinePreview(startPosition, endPosition, width)
	local indicator = createLineIndicator(startPosition, endPosition, width)
	return indicator
end

function AttackPreviewModule.createCirclePreview(radius, startPosition, direction)
	local targetPosition = startPosition + (direction.Unit * radius)
	local indicator = createCircleIndicator(targetPosition, radius)
	return indicator
end

function AttackPreviewModule.createRangePreview(radius)
	local indicator = createRangeIndicator(radius)
	return indicator
end

function AttackPreviewModule.updateSingleTargetPreview(indicator, targetPosition, smoothSpeed)
	if not indicator then return end
	updateIndicatorPositionSmooth(indicator, targetPosition + Vector3.new(0, 0.05, 0), smoothSpeed)
end

function AttackPreviewModule.updateFullAoEPreview(indicator, towerPosition, smoothSpeed)
	if not indicator then return end
	updateIndicatorPositionSmooth(indicator, towerPosition, smoothSpeed)
end

function AttackPreviewModule.updateLinePreview(indicator, startPosition, endPosition, width, smoothSpeed)
	if not indicator then return end
	local length = (endPosition - startPosition).Magnitude
	local midpoint = (startPosition + endPosition) / 2
	indicator.Size = Vector3.new(width, 0.1, length)
	local currentCFrame = indicator.CFrame
	local targetCFrame = CFrame.new(midpoint, endPosition)
	local newCFrame = currentCFrame:Lerp(targetCFrame, smoothSpeed)
	indicator.CFrame = newCFrame
end

function AttackPreviewModule.updateCirclePreview(indicator, targetPosition, smoothSpeed)
	if not indicator then return end
	updateIndicatorPositionSmooth(indicator, targetPosition + Vector3.new(0, 0.05, 0), smoothSpeed)
end

function AttackPreviewModule.updateRangePreview(indicator, towerPosition)
	if not indicator then return end
	indicator.Position = towerPosition
end

return AttackPreviewModule
