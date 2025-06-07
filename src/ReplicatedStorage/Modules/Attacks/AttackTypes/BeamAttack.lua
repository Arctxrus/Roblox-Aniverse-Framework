-- BeamAttack.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AttackUtils = require(ReplicatedStorage.Modules.Attacks:WaitForChild("AttackUtils"))

local BeamAttack = {}

local activeChargeVFX = {}  -- Table to store active charge VFX
local activeBeams = {}  -- Table to store active beams

local function getVFXFolder(attackType)
	return ReplicatedStorage:WaitForChild("AttackVFX"):WaitForChild(attackType)
end

-- Function to grow/shrink a beam with given parameters
local function growShrinkBeam(beam, targetSizeZ, duration, shrinkFromStart)
	local originalSize = beam.Size
	local originalCFrame = beam.CFrame
	local originalAttachments = {}
	for _, child in ipairs(beam:GetChildren()) do
		if child:IsA("Attachment") then
			originalAttachments[child] = child.Position
		end
	end

	local targetSize = Vector3.new(originalSize.X, originalSize.Y, targetSizeZ)
	local startTime = tick()

	local function updateAttachments()
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local elapsedTime = tick() - startTime
			local alpha = math.min(elapsedTime / duration, 1)

			local newSizeZ = originalSize.Z + alpha * (targetSize.Z - originalSize.Z)
			beam.Size = Vector3.new(originalSize.X, originalSize.Y, newSizeZ)

			if shrinkFromStart then
				beam.CFrame = originalCFrame * CFrame.new(0, 0, (newSizeZ - originalSize.Z) / 2)
			else
				beam.CFrame = originalCFrame * CFrame.new(0, 0, -(newSizeZ - originalSize.Z) / 2)
			end

			local scaleFactor = Vector3.new(
				beam.Size.X / originalSize.X,
				beam.Size.Y / originalSize.Y,
				beam.Size.Z / originalSize.Z
			)

			for attachment, originalPosition in pairs(originalAttachments) do
				attachment.Position = Vector3.new(
					originalPosition.X * scaleFactor.X,
					originalPosition.Y * scaleFactor.Y,
					originalPosition.Z * scaleFactor.Z
				)
			end

			if alpha >= 1 then
				connection:Disconnect()
			end
		end)
	end

	updateAttachments()
end

function BeamAttack.handleChargeVFX(config, attackType, startPosition, rig)
	local vfxFolder = getVFXFolder(attackType)
	local chargeVFX = vfxFolder:WaitForChild(config.ChargeVFX):Clone()

	chargeVFX.Anchored = false
	chargeVFX.CanCollide = false
	chargeVFX.Massless = true

	local attachTo = rig:FindFirstChild(config.ChargeVFXLocation .. " Arm"):FindFirstChild(config.ChargeVFXLocation .. "GripAttachment")
	if attachTo then
		chargeVFX.CFrame = attachTo.WorldCFrame * CFrame.new(0, -0.3, 0)
		chargeVFX.Parent = attachTo

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = attachTo.Parent
		weld.Part1 = chargeVFX
		weld.Parent = chargeVFX
	else
		warn("Attachment point not found: " .. config.ChargeVFXLocation .. "GripAttachment")
	end

	local spawnAttachment = chargeVFX:FindFirstChild("Spawn")
	if spawnAttachment then
		AttackUtils.emitParticles(spawnAttachment)
	end

	local chargeAttachment = chargeVFX:FindFirstChild("Charge")
	if chargeAttachment then
		AttackUtils.handleAttachments(chargeAttachment, "Enable")
	end

	activeChargeVFX[rig] = chargeVFX
	return chargeVFX
end

function BeamAttack.handleBeam(config, attackType, startPosition, targetPosition, rig, chargeVFX)
	local vfxFolder = getVFXFolder(attackType)
	local beam = vfxFolder:WaitForChild(config.BeamVFX):Clone()

	-- Calculate direction with y-component set to zero to avoid vertical rotation
	local direction = (targetPosition - chargeVFX.Position)
	direction = Vector3.new(direction.X, 0, direction.Z).Unit * -1  -- Reverse the direction

	beam.CFrame = CFrame.new(chargeVFX.Position, chargeVFX.Position + direction)
	beam.Parent = workspace

	local fireAttachment = beam:FindFirstChild("Fire")
	if fireAttachment then
		AttackUtils.emitParticles(fireAttachment)
	end

	activeBeams[rig] = beam
	return beam
end

function BeamAttack.performAttack(config, attackType, rig, target, event)
	local startPosition = rig.PrimaryPart.Position
	local targetPosition = target.HumanoidRootPart.Position
	local beamLength = config.BeamLength or 40

	if event == "CreateAttack" then
		BeamAttack.handleChargeVFX(config, attackType, startPosition, rig)
	elseif event == "FireAttack" then
		local chargeVFX = activeChargeVFX[rig]
		if chargeVFX then
			local fireAttachment = chargeVFX:FindFirstChild("Fire")
			if fireAttachment then
				AttackUtils.emitParticles(fireAttachment)
			end

			if activeBeams[rig] then
				activeBeams[rig]:Destroy()
			end

			local beam = BeamAttack.handleBeam(config, attackType, startPosition, targetPosition, rig, chargeVFX)
			growShrinkBeam(beam, beamLength, 0.1, true)
		end
	elseif event == "EndAttack" then
		local beam = activeBeams[rig]
		if beam then
			growShrinkBeam(beam, 0, 0.1, false)
			wait(1)
			beam:Destroy()
			activeBeams[rig] = nil
		end

		local chargeVFX = activeChargeVFX[rig]
		if chargeVFX then
			chargeVFX:Destroy()
			activeChargeVFX[rig] = nil
		end
	end
end

return BeamAttack
