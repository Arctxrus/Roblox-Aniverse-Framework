-- AttackUtils.lua
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AttackUtils = {}

local function getVFXFolder(attackType)
	if not attackType then
		warn("Attack type is nil in getVFXFolder")
		return nil
	end

	return ReplicatedStorage:WaitForChild("AttackVFX"):WaitForChild(attackType)
end

-- Function to emit particles
function AttackUtils.emitParticles(attachment)
	for _, emitter in ipairs(attachment:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			local emitCount = emitter:GetAttribute("EmitCount") or 10
			local emitDelay = emitter:GetAttribute("EmitDelay") or 0
			if emitDelay > 0 then
				task.delay(emitDelay, function()
					emitter:Emit(emitCount)
				end)
			else
				task.spawn(function()
					emitter:Emit(emitCount)
				end)
			end
		end
	end
end

-- Function to handle attachments
function AttackUtils.handleAttachments(parent, action)
	for _, attachment in ipairs(parent:GetChildren()) do
		if attachment:IsA("Attachment") then
			if action == "Emit" then
				AttackUtils.emitParticles(attachment)
			else
				for _, emitter in ipairs(attachment:GetDescendants()) do
					if emitter:IsA("ParticleEmitter") then
						emitter.Enabled = action == "Enable"
					end
				end
			end
		end
	end
end

-- Function to create and handle explosion
function AttackUtils.handleExplosion(explosionName, position, attackType)
	local vfxFolder = getVFXFolder(attackType)
	if not vfxFolder then
		warn("VFX folder not found for attack type: " .. tostring(attackType))
		return
	end

	local explosion = vfxFolder:WaitForChild(explosionName):Clone()
	explosion.Position = position
	explosion.Parent = workspace
	AttackUtils.handleAttachments(explosion, "Emit")
	Debris:AddItem(explosion, 2)
end

return AttackUtils
