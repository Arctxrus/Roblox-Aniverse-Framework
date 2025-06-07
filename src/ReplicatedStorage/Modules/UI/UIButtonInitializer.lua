local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationPlayer = require(ReplicatedStorage.Modules.Animation:WaitForChild("AnimationPlayer"))

local UIButtonInitializer = {}

-- Function to set the gradients based on rarity
function UIButtonInitializer.setGradientsBasedOnRarity(slot, rarity)
	local background = slot:WaitForChild("Background")
	local uiStroke = background:WaitForChild("UIStroke")
	local equipGlow = slot:WaitForChild("EquipGlow")

	local gradientsFolder = ReplicatedStorage:WaitForChild("Gradients"):WaitForChild("Rarities")
	local gradient

	if rarity == "Epic" then
		gradient = gradientsFolder:WaitForChild("Epic")
	elseif rarity == "Legendary" then
		gradient = gradientsFolder:WaitForChild("Legendary")
	elseif rarity == "Mythic" then
		gradient = gradientsFolder:WaitForChild("Mythic")
	elseif rarity == "Rare" then
		gradient = gradientsFolder:WaitForChild("Rare")
	elseif rarity == "Secret" then
		gradient = gradientsFolder:WaitForChild("Secret")
	else
		warn("Unknown rarity: " .. rarity)
		return
	end

	-- Assign the gradients to the necessary UI elements
	local uiGradient1 = gradient:Clone()
	uiGradient1.Parent = background

	local uiGradient2 = gradient:Clone()
	uiGradient2.Parent = uiStroke

	local equipGlowGradient = gradient:Clone()
	equipGlowGradient.Parent = equipGlow
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationPlayer = require(ReplicatedStorage.Modules.Animation:WaitForChild("AnimationPlayer"))

-- Function to set the model display
function UIButtonInitializer.setModelDisplay(slot, modelName, idle)
	local characterDisplay = slot:WaitForChild("CharacterDisplay")
	local camera = characterDisplay:FindFirstChild("Camera")

	if not camera then
		-- Create the camera if it doesn't exist
		camera = Instance.new("Camera")
		camera.Name = "Camera"
		camera.Parent = characterDisplay
		characterDisplay.CurrentCamera = camera
		print("Created Camera in CharacterDisplay for slot: " .. slot.Name)
	else
		print("Camera found in CharacterDisplay for slot: " .. slot.Name)
	end

	-- Clear previous model if any
	local worldModel = characterDisplay:FindFirstChild("WorldModel")
	if worldModel then
		worldModel:Destroy()
	end

	-- Create a new World model
	worldModel = Instance.new("WorldModel")
	worldModel.Name = "WorldModel"
	worldModel.Parent = characterDisplay
	

	-- Get the new model
	local model = ReplicatedStorage.Units.Towers:FindFirstChild(modelName)
	if not model then
		warn("Model not found for: " .. modelName)
		return
	end

	model = model:Clone()
	model.Parent = worldModel
	model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	
	-- Ensure only the base part is anchored
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Keep the HumanoidRootPart anchored to control the enemy's position
			if part.Name == "HumanoidRootPart" then
				part.Anchored = true
			else
				-- Unanchor other parts for animation, but ensure they are attached correctly
				part.Anchored = false
			end
			part.CastShadow = false
		end
	end

	AnimationPlayer.playIdleAnimation(model, idle)

	-- Set the camera to view the model
	camera.CFrame = CFrame.new(0, 1.7, -1.5) * CFrame.Angles(0, math.rad(180), 0)
	print("Model and camera set for:", modelName)
end




-- Function to initialize the button
function UIButtonInitializer.initializeButton(slot, towerData)

	-- Ensure towerData and attributes are not nil
	if not towerData or not towerData.attributes then
		warn("Invalid tower data or attributes missing")
		return
	end

	local rarity = towerData.attributes.Rarity
	local modelName = towerData.name
	local cost = towerData.attributes.Cost
	local level = towerData.attributes.Level
	local idle = towerData.attributes.Idle

	-- Set gradients based on rarity
	UIButtonInitializer.setGradientsBasedOnRarity(slot, rarity)

	-- Set model display
	UIButtonInitializer.setModelDisplay(slot, modelName, idle)

	-- Set cost and level text
	local costLabel = slot:WaitForChild("Cost")
	local levelLabel = slot:WaitForChild("Level")

	costLabel.Text = "$" .. tostring(cost)
	levelLabel.Text = "Lvl " .. tostring(level)

	-- Initialize the equip glow as invisible
	local equipGlow = slot:WaitForChild("EquipGlow")
	equipGlow.ImageTransparency = 1
end

return UIButtonInitializer
