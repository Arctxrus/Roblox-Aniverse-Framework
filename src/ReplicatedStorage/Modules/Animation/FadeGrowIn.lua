-- AnimationModule.lua
local TweenService = game:GetService("TweenService")

local AnimationModule = {}

-- Function to animate the fade-in effect
function AnimationModule.growAndFadeIn(part, duration)
	part.Transparency = 1

	local fadeTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeGoal = {Transparency = 0.2}  -- Adjust the final transparency as needed
	local fadeTween = TweenService:Create(part, fadeTweenInfo, fadeGoal)

	fadeTween:Play()
end

return AnimationModule
