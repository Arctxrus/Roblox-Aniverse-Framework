local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local AttackUtils = require(ReplicatedStorage.Modules.Attacks:WaitForChild("AttackUtils"))

local ProjectileAttack = {}

local activeProjectiles = {}  -- Table to store active projectiles

local function getVFXFolder(attackType)
	return ReplicatedStorage:WaitForChild("AttackVFX"):WaitForChild(attackType)
end

local function calculateTravelTime(startPosition, targetPosition, speed, parabolaHeight)
	local horizontalDistance = (targetPosition - startPosition).Magnitude
	local verticalDistance = parabolaHeight or 0
	local travelTime = horizontalDistance / speed
	if verticalDistance > 0 then
		local apexTime = travelTime / 2
		local totalTime = travelTime + (verticalDistance / speed)
		return totalTime
	else
		return travelTime
	end
end

function ProjectileAttack.createProjectile(config, attackType, startPosition, targetPosition, rig)
	local vfxFolder = getVFXFolder(attackType)
	local projectile = vfxFolder:WaitForChild(config.Model):Clone()
	projectile.Anchored = false
	projectile.CanCollide = false
	projectile.CFrame = CFrame.lookAt(startPosition, targetPosition) * CFrame.new(0, 0, -2)
	projectile.Parent = workspace

	local attachTo = rig:FindFirstChild(config.Location .. " Arm"):FindFirstChild(config.Location .. "GripAttachment")
	if attachTo then
		projectile.CFrame = attachTo.WorldCFrame * CFrame.new(0, -1, 1)
		projectile.Parent = attachTo

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = attachTo.Parent
		weld.Part1 = projectile
		weld.Parent = projectile
	else
		warn("Attachment point not found: " .. config.Location .. "GripAttachment")
	end

	local spawnAttachment = projectile:FindFirstChild("Spawn")
	if spawnAttachment then
		AttackUtils.emitParticles(spawnAttachment)
	end
	local chargeAttachment = projectile:FindFirstChild("Charge")
	if chargeAttachment then
		AttackUtils.handleAttachments(chargeAttachment, "Enable")
	end

	activeProjectiles[rig] = projectile
	return projectile
end

function ProjectileAttack.fireProjectile(projectile, config, attackType, startPosition, targetPosition)
	local fireAttachment = projectile:FindFirstChild("Fire")
	if fireAttachment then
		AttackUtils.emitParticles(fireAttachment)
	end
	local chargeAttachment = projectile:FindFirstChild("Charge")
	if chargeAttachment then
		AttackUtils.handleAttachments(chargeAttachment, "Disable")
	end

	local weld = projectile:FindFirstChildOfClass("WeldConstraint")
	if weld then
		weld:Destroy()
	end

	local parabolaHeight = config.ParabolaHeight or 10
	local totalTime = calculateTravelTime(startPosition, targetPosition, config.Speed)
	local damageDelay = config.DamageDelay or 0
	local startTime = tick()

	-- Print the calculated travel time including damage delay if applicable
	local totalTimeWithDelay = totalTime + damageDelay

	local connection
	local function updateVelocity()
		local elapsedTime = tick() - startTime
		local travelDistance = config.Speed * elapsedTime
		local direction = (targetPosition - startPosition).Unit
		local horizontalPosition = startPosition + direction * travelDistance
		local alpha = travelDistance / (startPosition - targetPosition).Magnitude
		local verticalOffset = Vector3.new(0, parabolaHeight * (4 * alpha * (1 - alpha)), 0)
		projectile.CFrame = CFrame.new(horizontalPosition + verticalOffset)

		if (projectile.Position - targetPosition).Magnitude < 2 then
			AttackUtils.handleExplosion(config.Explosion, targetPosition, attackType)
			projectile:Destroy()
			if connection then
				connection:Disconnect()
			end
		end
	end

	connection = RunService.Heartbeat:Connect(updateVelocity)
end

function ProjectileAttack.performAttack(config, attackType, rig, target, event)
	local startPosition = rig.PrimaryPart.Position
	local targetPosition = target.Position

	if event == "CreateAttack" then
		local projectile = ProjectileAttack.createProjectile(config, attackType, startPosition, targetPosition, rig)
		activeProjectiles[rig] = projectile
	elseif event == "FireAttack" then
		local projectile = activeProjectiles[rig]
		if projectile then
			ProjectileAttack.fireProjectile(projectile, config, attackType, startPosition, targetPosition)
			activeProjectiles[rig] = nil
		end
	end
end

function ProjectileAttack.getTravelTime(config, startPosition, targetPosition)
	local baseTime = calculateTravelTime(startPosition, targetPosition, config.Speed)
	local damageDelay = config.DamageDelay or 0
	return baseTime + damageDelay
end

return ProjectileAttack
