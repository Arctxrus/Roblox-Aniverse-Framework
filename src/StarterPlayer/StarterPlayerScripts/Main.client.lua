local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PreviewModule = require(ReplicatedStorage.Modules:WaitForChild("PreviewModule"))
local InputModule = require(ReplicatedStorage.Modules:WaitForChild("InputModule"))
local EnemyUIManager = require(ReplicatedStorage.Modules.UI:WaitForChild("EnemyUIManagerModule"))
local UISlotManager = require(ReplicatedStorage.Modules.UI:WaitForChild("UISlotManagerModule"))

local requestEquippedTowers = ReplicatedStorage.Functions:WaitForChild("RequestEquippedTowers")

-- Ensure that the player is ready
local player = Players.LocalPlayer

-- Get the PlayerGui
local playerGui = player:WaitForChild("PlayerGui")

-- Get the slots from the hotbar (assuming they are named Slot1, Slot2, etc.)
local hotbar = playerGui:WaitForChild("InGameHud"):WaitForChild("Hotbar")
assert(hotbar, "Hotbar not found")

local slots = {
	hotbar:WaitForChild("Slot1"),
	hotbar:WaitForChild("Slot2"),
	hotbar:WaitForChild("Slot3"),
	hotbar:WaitForChild("Slot4"),
	hotbar:WaitForChild("Slot5"),
	hotbar:WaitForChild("Slot6")
}

-- Function to initialize InputModule
local function initializeInputModule()
	local equippedTowers = requestEquippedTowers:InvokeServer()

	-- Initialize the InputModule with the necessary data
	print(equippedTowers)
	InputModule.initialize(equippedTowers)
end

-- Initialize the UISlotManager with the slots and equipped towers
local function initializeUISlots()
	local equippedTowers = requestEquippedTowers:InvokeServer()
	assert(equippedTowers, "Failed to fetch equipped towers")

	-- Initialize the UISlotManager with the slots and equipped towers' full data
	UISlotManager.initializeSlots(slots, equippedTowers, InputModule.toggleEquipFromUI)
end

-- Call the initialization function after a delay to ensure all elements are ready
task.wait(1)
initializeInputModule()
initializeUISlots()
