-- AnimationHandler.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationPlayer = require(ReplicatedStorage.Modules.Animation:WaitForChild("AnimationPlayer"))

local PlayAnimationEvent = ReplicatedStorage.Events:WaitForChild("PlayAnimation")

PlayAnimationEvent.OnClientEvent:Connect(function(tower, animationType, animationName)
	if animationType == "Idle" then
		AnimationPlayer.playIdleAnimation(tower, animationName)
	elseif animationType == "Attacks" then
		AnimationPlayer.playAttackAnimation(tower, animationName)
	elseif animationType == "Walking" then
		AnimationPlayer.playWalkingAnimation(tower, animationName)
	else
		warn("Unknown animation type:", animationType)
	end
end)
