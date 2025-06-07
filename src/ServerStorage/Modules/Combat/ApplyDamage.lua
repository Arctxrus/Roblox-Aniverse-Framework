local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ElementalWeaknessModule = require(ServerStorage.Modules.Combat:WaitForChild("ElementalWeakness"))
local EnemyManager = require(ServerStorage.Modules.EnemyManagement:WaitForChild("EnemyManager"))

local UpdateEnemyStatusEvent = ReplicatedStorage.Events:WaitForChild("UpdateEnemyStatus")

local EnemyHitModule = {}

local CC_COOLDOWN = 2.5 -- Cooldown time for each CC type in seconds

-- Function to apply effects to the enemy
function EnemyHitModule.applyEffectsToEnemy(towerData, enemyData, critRate, critDamage, damage, dotDamage, dotDuration, element, slowDuration, slowPercentage, ccType, towerType)
	if enemyData then
		local enemyType = enemyData.Type

		-- Ensure the tower can only target the appropriate enemy types
		if (towerType == "Ground" and enemyType ~= "Ground") or (towerType ~= "Ground" and enemyType ~= "Ground" and enemyType ~= "Flying") then
			return -- Do not apply damage if the types are not compatible
		end

		local targetElement = enemyData.Element
		local damageModifier = ElementalWeaknessModule.GetModifier(element, targetElement)
		local isCrit = math.random() <= critRate
		local finalDamage = isCrit and (damage * critDamage) or damage
		finalDamage = finalDamage * damageModifier

		local currentShield = enemyData.Shield or 0
		local currentHealth = enemyData.Health or 0
		local damageType = "Health"

		if currentShield > 0 then
			if finalDamage <= currentShield then
				enemyData.Shield = currentShield - finalDamage
				damageType = "Shield"
				-- Update the client about the shield damage
				UpdateEnemyStatusEvent:FireAllClients(enemyData.ID, "Shield", finalDamage, ccType)
				return -- No health damage or DoT if shield absorbs all damage
			else
				finalDamage = finalDamage - currentShield
				enemyData.Shield = 0
				currentHealth = currentHealth - finalDamage
				enemyData.Health = currentHealth
				damageType = "Shield"
				-- Update the client about the shield break
				UpdateEnemyStatusEvent:FireAllClients(enemyData.ID, "Shield", currentShield, ccType)
				-- Update the client about the health damage
				UpdateEnemyStatusEvent:FireAllClients(enemyData.ID, "Health", finalDamage, ccType)
			end
		else
			currentHealth = currentHealth - finalDamage
			enemyData.Health = currentHealth
			-- Update the client about the health damage
			UpdateEnemyStatusEvent:FireAllClients(enemyData.ID, "Health", finalDamage, ccType)
		end

		if currentHealth <= 0 then
			EnemyManager.removeEnemy(enemyData.ID)
			-- Assume you have a function to remove enemyData from the active enemies list
			return
		end

		local currentTime = tick()
		if not enemyData.CCTimers then
			enemyData.CCTimers = {}
		end

		local canApplyCC = not enemyData.CCTimers[ccType] or (currentTime - enemyData.CCTimers[ccType] > CC_COOLDOWN)

		if canApplyCC then
			local originalSpeed = enemyData.OriginalSpeed or enemyData.Speed
			if not enemyData.OriginalSpeed then
				enemyData.OriginalSpeed = originalSpeed
			end

			local newSpeed = originalSpeed
			if ccType == "Slow" then
				newSpeed = math.max(0, originalSpeed * (1 - slowPercentage))
			elseif ccType == "Stun" then
				newSpeed = 0
			elseif ccType == "Fear" then
				newSpeed = -math.abs(originalSpeed * (1 + slowPercentage))
			elseif ccType == "KnockUp" then
				newSpeed = 0
				enemyData.Anchored = true
				delay(slowDuration, function()
					if enemyData.Parent then
						enemyData.Anchored = false
					end
				end)
			end

			enemyData.Speed = newSpeed
			-- Update the client about the CC effect
			UpdateEnemyStatusEvent:FireAllClients(enemyData.ID, "Speed", newSpeed, ccType)

			delay(slowDuration, function()
				if enemyData and enemyData.Health > 0 then
					enemyData.Speed = enemyData.OriginalSpeed
					-- Update the client about the speed restoration
					UpdateEnemyStatusEvent:FireAllClients(enemyData.ID, "Speed", enemyData.OriginalSpeed, nil)
				end
			end)

			enemyData.CCTimers[ccType] = currentTime
		else
			print("Cannot apply " .. ccType .. " to " .. enemyData.Name .. " yet. Cooldown in effect.")
		end

		if dotDamage > 0 and dotDuration > 0 and currentShield <= 0 then
			local dotTicks = 4
			local dotInterval = dotDuration / dotTicks
			for i = 1, dotTicks do
				delay(i * dotInterval, function()
					if enemyData and enemyData.Health > 0 then
						local currentHealth = enemyData.Health or 0
						currentHealth = currentHealth - dotDamage
						enemyData.Health = currentHealth
						print("Applied DoT damage of " .. dotDamage .. " to " .. enemyData.Name)
						-- Update the client about the DoT damage
						UpdateEnemyStatusEvent:FireAllClients(enemyData.ID, "Health", dotDamage, "DoT")

						if currentHealth <= 0 then
							print("Enemy " .. enemyData.Name .. " died from DoT.")
							EnemyManager.removeEnemy(enemyData.ID)
							return
						end
					end
				end)
			end
		end
	else
		print("No enemy data provided.")
	end
end

return EnemyHitModule
