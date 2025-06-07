local TweenService = game:GetService("TweenService")

local HealthBarModule = {}

function HealthBarModule.updateHealthBar(healthBarFill, healthBarDelayEffect, healthCounter, currentHealth, maxHealth)
	currentHealth = tonumber(currentHealth)
	maxHealth = tonumber(maxHealth)

	healthCounter.Text = math.floor(currentHealth) .. " / " .. math.floor(maxHealth)

	-- Tween the size of the health bar fill
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {Size = UDim2.new(currentHealth / maxHealth, 0, 1, 0)}
	local tween = TweenService:Create(healthBarFill, tweenInfo, goal)
	tween:Play()

	-- Delay effect
	if healthBarDelayEffect then
		if healthBarDelayEffect.Size.X.Scale > currentHealth / maxHealth then
			local delayTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local delayGoal = {Size = UDim2.new(currentHealth / maxHealth, 0, 1, 0)}
			local delayTween = TweenService:Create(healthBarDelayEffect, delayTweenInfo, delayGoal)
			delayTween:Play()
		else
			healthBarDelayEffect.Size = UDim2.new(currentHealth / maxHealth, 0, 1, 0)
		end
	end
end

return HealthBarModule
