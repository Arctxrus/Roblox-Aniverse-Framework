local InputModule = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local PreviewModule = require(script.Parent:WaitForChild("PreviewModule"))
local UISlotManager = require(ReplicatedStorage.Modules.UI:WaitForChild("UISlotManagerModule"))
local RenderTower = require(ReplicatedStorage.Modules:WaitForChild("RenderTower"))

local validatePlacement = ReplicatedStorage.Functions:WaitForChild("ValidatePlacement")

local equippedTowers = nil
local equippedTowerIndex = nil

-- Initialize function to receive data from the main script
function InputModule.initialize(equippedTowersData)
	equippedTowers = equippedTowersData

	-- Ensure that the data is not nil
	assert(equippedTowers, "Equipped towers data is nil")
end

local function toggleTowerEquip(index)
	local towerAttributes = equippedTowers[index]

	-- Play the animation regardless of equipping or unequipping
	UISlotManager.triggerButtonAnimation(index)

	if equippedTowerIndex == index then
		UISlotManager.triggerButtonAnimation(index) -- Trigger animation for unequipping the same slot
		equippedTowerIndex = nil
		PreviewModule.removePreviews()
	else
		if equippedTowerIndex then
			UISlotManager.triggerButtonAnimation(equippedTowerIndex) -- Trigger animation for the previously equipped slot
			PreviewModule.removePreviews()
		end
		equippedTowerIndex = index
		local mousePosition = mouse.Hit.Position

		PreviewModule.createPreview(mousePosition, towerAttributes)
	end

	-- Update UI to reflect the equip/unequip state
	UISlotManager.updateEquipGlow(equippedTowerIndex)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not equippedTowers then
		warn("Equipped towers data is nil")
		return
	end

	local keyMapping = {
		[Enum.KeyCode.One] = 1,
		[Enum.KeyCode.Two] = 2,
		[Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four] = 4,
		[Enum.KeyCode.Five] = 5,
		[Enum.KeyCode.Six] = 6,
	}

	local index = keyMapping[input.KeyCode]
	if index and not gameProcessed then
		if equippedTowers[index] then
			toggleTowerEquip(index)
		else
			warn("No tower equipped in slot " .. index)
		end
	end
end)

mouse.Button1Down:Connect(function()
	if equippedTowerIndex then
		local position, target = PreviewModule.getMousePositionIgnoringModels(mouse)
		local towerUUID = equippedTowers[equippedTowerIndex].uuid
		local isPlaceable = validatePlacement:InvokeServer(position, target, towerUUID)
		if isPlaceable then
			ReplicatedStorage.Events.PlaceTower:FireServer(target, towerUUID, position)
			toggleTowerEquip(equippedTowerIndex)  -- Toggle the tower equip state after placing
		else
			print("Cannot place tower: invalid placement area or too close to another tower")
		end
	else
	end
end)

-- Function to toggle equip state from UISlotManager
function InputModule.toggleEquipFromUI(index)
	if equippedTowers and equippedTowers[index] then
		toggleTowerEquip(index)
	else
		warn("No tower equipped in slot " .. tostring(index))
	end
end

return InputModule