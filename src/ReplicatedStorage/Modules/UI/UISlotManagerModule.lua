local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIAnimations = require(ReplicatedStorage.Modules.Animation:WaitForChild("UIAnimations"))
local UIButtonInitializer = require(ReplicatedStorage.Modules.UI:WaitForChild("UIButtonInitializer"))

local UISlotManager = {}

local rotationSpeed = 180 -- degrees per second
local equippedSlots = {} -- Table to track equipped slots by index
local originalSizes = {} -- Table to track original sizes of containers
local hoverSizes = {} -- Table to track hover sizes of containers
local shrinkSizes = {} -- Table to track shrink sizes of containers
local activeTweens = {} -- Table to track active tweens
local isHovered = {} -- Table to track if the container is being hovered

-- Function to rotate the gradients for a specific slot
local function rotateGradients(container)
	coroutine.wrap(function()
		local background = container:WaitForChild("Background")
		local uiStroke = background:WaitForChild("UIStroke")
		local equipGlow = container:WaitForChild("EquipGlow")

		local startTime = tick()

		while true do
			local elapsedTime = tick() - startTime
			local rotation = (elapsedTime * rotationSpeed) % 360

			-- Update the rotation of all gradients
			for _, gradient in ipairs({"Rare", "Epic", "Legendary", "Mythic", "Secret"}) do
				if background:FindFirstChild(gradient) then
					background[gradient].Rotation = rotation
				end
				if uiStroke:FindFirstChild(gradient) then
					uiStroke[gradient].Rotation = rotation
				end
				if equipGlow:FindFirstChild(gradient) then
					equipGlow[gradient].Rotation = rotation
				end
			end

			-- Yield to prevent freezing the game
			task.wait()
		end
	end)()
end

-- Function to update the equip glow for a specific slot
function UISlotManager.updateEquipGlow(equippedIndex)
	for i, slot in ipairs(equippedSlots) do
		local container = slot:WaitForChild("Container")
		local equipGlow = container:WaitForChild("EquipGlow")
		equipGlow.ImageTransparency = (i == equippedIndex) and 0 or 1
	end
end

-- Function to trigger button animation for a specific slot
function UISlotManager.triggerButtonAnimation(index)
	local slot = equippedSlots[index]
	if not slot then return end

	local container = slot:WaitForChild("Container")

	-- Cancel any active tweens for this slot
	if activeTweens[index] then
		for _, tween in ipairs(activeTweens[index]) do
			tween:Cancel()
		end
	end

	-- Define the hover and shrink sizes
	local defaultSize = originalSizes[index]
	local hoverSize = hoverSizes[index]
	local shrinkSize = shrinkSizes[index]

	local clickTweenUp, clickTweenDown

	-- Check if the slot is being hovered
	if isHovered[index] then
		-- Animation sequence: shrink -> default -> hover
		clickTweenDown = TweenService:Create(container, TweenInfo.new(0.1), {Size = shrinkSize})
		clickTweenUp = TweenService:Create(container, TweenInfo.new(0.1), {Size = defaultSize})
		clickTweenUp.Completed:Connect(function()
			TweenService:Create(container, TweenInfo.new(0.1), {Size = hoverSize}):Play()
		end)
	else
		-- Animation sequence: default -> hover -> shrink -> default
		clickTweenUp = TweenService:Create(container, TweenInfo.new(0.1), {Size = hoverSize})
		clickTweenDown = TweenService:Create(container, TweenInfo.new(0.1), {Size = defaultSize})
	end

	activeTweens[index] = {clickTweenUp, clickTweenDown}

	-- Play the animations
	clickTweenUp:Play()
	clickTweenUp.Completed:Connect(function()
		clickTweenDown:Play()
	end)
end

-- Function to calculate hover and shrink sizes based on the original size
local function calculateSize(size, factor)
	return UDim2.new(size.X.Scale * factor, size.X.Offset * factor, size.Y.Scale * factor, size.Y.Offset * factor)
end

-- Function to initialize a single slot
local function initializeSlot(slot, index, towerData, toggleEquipCallback)
	equippedSlots[index] = slot -- Store the slot in equippedSlots table
	local container = slot:WaitForChild("Container")
	originalSizes[index] = container.Size -- Store the original size of the container
	hoverSizes[index] = calculateSize(container.Size, 1.1) -- Define the hover size (10% larger)
	shrinkSizes[index] = calculateSize(container.Size, 0.9) -- Define the shrink size (10% smaller)

	-- Initialize the button with the tower data
	UIButtonInitializer.initializeButton(container, towerData)

	-- Create the hover and leave animations
	local hoverTween = TweenService:Create(container, TweenInfo.new(0.1), {Size = hoverSizes[index]})
	local leaveTween = TweenService:Create(container, TweenInfo.new(0.1), {Size = originalSizes[index]})

	local imageButton = container:WaitForChild("ImageButton")

	-- Connect the button click event to toggle equip state and play click animations
	imageButton.MouseButton1Click:Connect(function()
		toggleEquipCallback(index)
	end)

	-- Connect the mouse enter event to play the hover animation
	imageButton.MouseEnter:Connect(function()
		hoverTween:Play()
		isHovered[index] = true
	end)

	-- Connect the mouse leave event to play the leave animation
	imageButton.MouseLeave:Connect(function()
		leaveTween:Play()
		isHovered[index] = false
	end)

	-- Start rotating the gradients
	rotateGradients(container)
end

-- Function to initialize all slots
function UISlotManager.initializeSlots(slots, equippedTowers, toggleEquipCallback)
	for index, slot in ipairs(slots) do
		local towerData = equippedTowers[index]
		if towerData then
			initializeSlot(slot, index, towerData, toggleEquipCallback)
		else
			warn("No tower data for slot:", index)
		end
	end
end

return UISlotManager
