local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientAnimationManager = {}

function ClientAnimationManager.playWalkingAnimation(humanoid)
	if humanoid then
		local walkingAnimName = humanoid:GetAttribute("WalkingAnim")
		if walkingAnimName and type(walkingAnimName) == "string" then
			local animation = ReplicatedStorage.Animations.Walking:FindFirstChild(walkingAnimName)
			if animation and animation:IsA("Animation") then
				local animator = humanoid:FindFirstChildOfClass("Animator")
				if not animator then
					animator = Instance.new("Animator")
					animator.Parent = humanoid
				end
				local animTrack = animator:LoadAnimation(animation)
				animTrack:Play()
			else
				warn("Animation not found or not an Animation instance for name: " .. tostring(walkingAnimName))
			end
		else
			warn("No WalkingAnim attribute found or not a string for humanoid")
		end
	else
		warn("No Humanoid found")
	end
end

return ClientAnimationManager
