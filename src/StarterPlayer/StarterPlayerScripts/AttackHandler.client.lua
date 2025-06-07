local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local AttackInfo = require(ReplicatedStorage.AttackVFX:WaitForChild("AttackInfo"))
local BeamAttack = require(ReplicatedStorage.Modules.Attacks.AttackTypes:WaitForChild("BeamAttack"))
local ProjectileAttack = require(ReplicatedStorage.Modules.Attacks.AttackTypes:WaitForChild("ProjectileAttack"))
local AnimationPlayer = require(ReplicatedStorage.Modules.Animation:WaitForChild("AnimationPlayer"))

local PlayAttackEvent = ReplicatedStorage.Events:WaitForChild("PlayAttack")

local function getVFXFolder(attackType)
	return ReplicatedStorage.AttackVFX:WaitForChild(attackType)
end

local function performAttack(attackType, rig, target, event)
	local config = AttackInfo[attackType]
	if not config then
		warn("Invalid attack type: " .. attackType)
		return
	end

	if config.Type == "Projectile" then
		ProjectileAttack.performAttack(config, attackType, rig, target, event)
	elseif config.Type == "Beam" then
		BeamAttack.performAttack(config, attackType, rig, target, event)
	else
		warn("Unknown attack type: " .. config.Type)
	end
end

local function rotateTowerToFaceTarget(tower, target)
	if tower and target then
		local towerPrimaryPart = tower.PrimaryPart or tower
		local targetPosition = target.Position

		local direction = (targetPosition - towerPrimaryPart.Position).Unit
		direction = Vector3.new(direction.X, 0, direction.Z).Unit -- Lock vertical rotation
		local targetCFrame = CFrame.new(towerPrimaryPart.Position, towerPrimaryPart.Position + direction)

		if tower:IsA("Model") then
			tower:SetPrimaryPartCFrame(targetCFrame)
			print("Rotated model tower", tower.Name, "to face target", target.Name)
		else
			tower.CFrame = targetCFrame
			print("Rotated part tower", tower.Name, "to face target", target.Name)
		end
	end
end

local function playAttack(tower, attack, target)
	rotateTowerToFaceTarget(tower, target)

	local animationTrack = AnimationPlayer.playAttackAnimation(tower, attack)

	if animationTrack then
		print("Playing attack animation for tower", tower.Name)
		animationTrack:GetMarkerReachedSignal("CreateAttack"):Connect(function()
			performAttack(attack, tower, target, "CreateAttack")
		end)
		animationTrack:GetMarkerReachedSignal("FireAttack"):Connect(function()
			performAttack(attack, tower, target, "FireAttack")
		end)
		animationTrack:GetMarkerReachedSignal("EndAttack"):Connect(function()
			performAttack(attack, tower, target, "EndAttack")
		end)
	end
end

PlayAttackEvent.OnClientEvent:Connect(function(towerName, attack, target)
	local renderedTower = Workspace.RenderedTowers:FindFirstChild(towerName)
	if renderedTower and target then
		print("Found rendered tower", renderedTower.Name, "and target", target.Name)
		playAttack(renderedTower, attack, target)
	else
		if not renderedTower then
			warn("Rendered tower not found: " .. tostring(towerName))
		end
		if not target then
			warn("Target not found: " .. tostring(target))
		end
	end
end)
