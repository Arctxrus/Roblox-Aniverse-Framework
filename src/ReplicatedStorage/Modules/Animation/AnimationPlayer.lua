local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RenderedTowers = game.Workspace:FindFirstChild("RenderedTowers")

local AnimationPlayer = {}

local function getAnimation(attackType, animationName)
	local attackVFXFolder = ReplicatedStorage:WaitForChild("AttackVFX"):WaitForChild(attackType)
	return attackVFXFolder:FindFirstChild(animationName)
end

-- Function to play idle animation on a model
function AnimationPlayer.playIdleAnimation(model, animationName)
	local animationController = model:FindFirstChild("AnimationController")
	local animator = animationController and animationController:FindFirstChildOfClass("Animator")
	if not animator then
		warn("Animator not found in model: " .. model.Name)
		return
	end

	local animationFolder = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Idle")
	local animation = animationFolder:FindFirstChild(animationName)
	if animation then
		local animationTrack = animator:LoadAnimation(animation)
		animationTrack:Play()
	else
		warn("Idle Animation not found: " .. animationName)
	end
end

-- Function to play attack animation on a model
function AnimationPlayer.playAttackAnimation(model, attackType)
	local animationController = model:FindFirstChild("AnimationController")
	local animator = animationController and animationController:FindFirstChildOfClass("Animator")
	if not animator then
		warn("Animator not found in model: " .. model.Name)
		return
	end

	local attackInfo = require(ReplicatedStorage.AttackVFX:WaitForChild("AttackInfo"))
	local config = attackInfo[attackType]
	if not config then
		warn("No configuration found for attack type: " .. attackType)
		return
	end

	local animation = getAnimation(attackType, config.Animation)
	if animation then
		local animationTrack = animator:LoadAnimation(animation)
		animationTrack:Play()
		return animationTrack
	else
		warn("Attack Animation not found: " .. config.Animation)
		return nil
	end
end

-- Function to play walking animation on a model
function AnimationPlayer.playWalkingAnimation(model, animationName)
	local animationController = model:FindFirstChild("AnimationController")
	local animator = animationController and animationController:FindFirstChildOfClass("Animator")
	if not animator then
		warn("Animator not found in model: " .. model.Name)
		return
	end

	local animationFolder = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Walking")
	local animation = animationFolder:FindFirstChild(animationName)
	if animation then
		local animationTrack = animator:LoadAnimation(animation)
		animationTrack:Play()
	else
		warn("Walking Animation not found: " .. animationName)
	end
end

-- Function to play walking animation for enemies
function AnimationPlayer.playEnemyWalkingAnimation(enemy)
	local animationController = enemy:FindFirstChild("AnimationController")
	local animator = animationController and animationController:FindFirstChildOfClass("Animator")
	if not animator then
		warn("Animator not found in enemy: " .. enemy.Name)
		return
	end

	local animName = enemy:GetAttribute("WalkingAnim")
	if animName then
		local animationFolder = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Walking")
		local walkAnim = animationFolder:FindFirstChild(animName)
		if walkAnim then
			local animationTrack = animator:LoadAnimation(walkAnim)
			animationTrack:Play()
		else
			warn("Walking animation not found in ReplicatedStorage: " .. animName)
		end
	else
		warn("WalkingAnim attribute not set for enemy")
	end
end

return AnimationPlayer
