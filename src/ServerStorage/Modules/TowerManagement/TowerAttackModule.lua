local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local EnemyTargetingModule = require(ServerStorage.Modules.EnemyManagement:WaitForChild("EnemyTargeting"))
local AttackModule = require(ServerStorage.Modules.Combat:WaitForChild("AttackModule"))
local PlayAttackEvent = ReplicatedStorage.Events:WaitForChild("PlayAttack")
local ProjectileAttack = require(ReplicatedStorage.Modules.Attacks.AttackTypes:WaitForChild("ProjectileAttack"))
local BeamAttack = require(ReplicatedStorage.Modules.Attacks.AttackTypes:WaitForChild("BeamAttack"))

local TowerAttackModule = {}

local activeTowers = {}

local function waitForAttackCompletion(towerData, currentTarget, config)
	if config.Type == "Projectile" then
		local attackDelay = config.AttackDelay or 1.0
		wait(attackDelay)

		local firePosition = Vector3.new(unpack(config.RelativeFirePosition))
		local startPosition = towerData.Position + firePosition
		local targetPosition = currentTarget.Position
		local travelTime = ProjectileAttack.getTravelTime(config, startPosition, targetPosition)

		wait(travelTime)
	elseif config.Type == "Beam" then
		local attackDelay = config.AttackDelay or 1.0
		wait(attackDelay)

		local attackDuration = config.AttackDuration or 2.0
		local damageInterval = 0.5
		for i = 0, attackDuration, damageInterval do
			wait(damageInterval)
			-- Here, apply damage to the target
		end

		wait(attackDuration - attackDelay)
	else
		warn("Unknown attack type: " .. config.Type)
	end
end

local function attack(towerData)
	local range = towerData.Attributes.Range
	local attackSpeed = towerData.Attributes.AttackSpeed
	local damage = towerData.Attributes.Damage
	local attackType = towerData.Attributes.AttackType
	local element = towerData.Attributes.Element
	local critRate = towerData.Attributes.CritRate
	local critDamage = towerData.Attributes.CritDamage
	local slowPercentage = towerData.Attributes.SlowPercentage
	local slowDuration = towerData.Attributes.SlowDuration
	local ccType = towerData.Attributes.CCType
	local dotDamage = towerData.Attributes.DotDamage
	local dotDuration = towerData.Attributes.DotDuration
	local towerType = towerData.Attributes.Type
	local attack = towerData.Attributes.Attack

	local attackCooldown = attackSpeed
	local currentTarget = nil

	while true do
		wait(attackCooldown)
		-- Check for a new target when the tower is ready to attack
		if not currentTarget or (not currentTarget.Parent or (towerData.Position - currentTarget.Position).Magnitude > range) then
			currentTarget = EnemyTargetingModule.getTarget(towerData, range, "first")
		end

		if currentTarget then
			PlayAttackEvent:FireAllClients(towerData.ID, attack, currentTarget) -- Trigger on client once
			local config = require(ReplicatedStorage.AttackVFX.AttackInfo)[attack]

			waitForAttackCompletion(towerData, currentTarget, config)

			if attackType == "Single" then
				AttackModule.Single(towerData, currentTarget, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
			elseif attackType == "Full" then
				AttackModule.Full(towerData, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
			elseif attackType == "Line" then
				AttackModule.Line(towerData, currentTarget, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
			elseif attackType == "Circle" then
				AttackModule.Circle(towerData, currentTarget, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
			else
				warn("Unknown attack type: " .. tostring(attackType))
			end
		end
	end
end

function TowerAttackModule.addTower(towerData)
	activeTowers[towerData.ID] = towerData
	spawn(function()
		attack(towerData)
	end)
end

function TowerAttackModule.removeTower(towerID)
	activeTowers[towerID] = nil
end

function TowerAttackModule.updateTowerAttributes(towerID, newAttributes)
	local towerData = activeTowers[towerID]
	if towerData then
		for key, value in pairs(newAttributes) do
			towerData.Attributes[key] = value
		end
	else
		warn("Tower data not found for ID: " .. towerID)
	end
end

return TowerAttackModule
