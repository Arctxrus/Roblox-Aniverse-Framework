local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HealthBarModule = require(ReplicatedStorage.Modules.UI:WaitForChild("HealthBarModule"))

local enemyUITemplate = ReplicatedStorage.GUI.EnemyGUI:WaitForChild("RegularEnemy")
local UpdateEnemyStatusEvent = ReplicatedStorage.Events:WaitForChild("UpdateEnemyStatus")

local EnemyUIManager = {}

-- Function to create the UI for an entity
function EnemyUIManager.createEntityUI(enemyModel, enemyData)
	local entityUIGui = enemyUITemplate:Clone()
	entityUIGui.Parent = enemyModel
	entityUIGui.Adornee = enemyModel:FindFirstChild("Head")
	entityUIGui.Enabled = true

	-- Set the name label to the value of the .Name attribute
	local nameLabel = entityUIGui:FindFirstChild("NameLabel")
	if nameLabel then
		local displayName = enemyData.Name
		nameLabel.Text = displayName
	else
		warn("No NameLabel found in the UI template")
	end

	-- Setup health and shield bar updates
	local healthBarFrame = entityUIGui:WaitForChild("HealthBarFrame")
	local healthBarFill = healthBarFrame:WaitForChild("HealthBarFill")
	local healthBarDelayEffect = healthBarFrame:WaitForChild("HealthBarDelayEffect")
	local healthCounter = healthBarFrame:WaitForChild("HealthCounter")

	local shieldBarFrame = entityUIGui:FindFirstChild("ShieldBarFrame")
	local shieldBarFill = shieldBarFrame and shieldBarFrame:FindFirstChild("ShieldBarFill")
	local shieldCounter = shieldBarFrame and shieldBarFrame:FindFirstChild("ShieldCounter")

	local function updateStatus(newHealth, maxHealth, newShield, maxShield)
		HealthBarModule.updateHealthBar(healthBarFill, healthBarDelayEffect, healthCounter, newHealth, maxHealth)
		if shieldBarFill then
			HealthBarModule.updateHealthBar(shieldBarFill, nil, shieldCounter, newShield, maxShield)
		end
	end

	-- Set initial health and shield
	updateStatus(enemyData.Health, enemyData.MaxHP, enemyData.Shield, enemyData.MaxShield)

	-- Connect to the status update event
	UpdateEnemyStatusEvent.OnClientEvent:Connect(function(uniqueEnemyID, statusType, amount, ccType)
		if enemyModel.Name == tostring(uniqueEnemyID) then
			if statusType == "Health" then
				enemyData.Health = enemyData.Health - amount
			elseif statusType == "Shield" then
				enemyData.Shield = enemyData.Shield - amount
			end
			updateStatus(enemyData.Health, enemyData.MaxHP, enemyData.Shield, enemyData.MaxShield)
		end
	end)

	return entityUIGui
end

-- Function to find the head of an entity and add UI
function EnemyUIManager.findHeadAndAddUI(entity)
	local head = entity:WaitForChild("Head")
	if head then
		EnemyUIManager.createEntityUI(entity)
	else
		print("No head found for entity: " .. entity.Name)
	end
end

return EnemyUIManager
