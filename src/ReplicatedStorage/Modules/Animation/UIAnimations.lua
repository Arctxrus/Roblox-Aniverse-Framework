-- ReplicatedStorage/Modules/Animation/UIAnimations.lua

local TweenService = game:GetService("TweenService")

local UIAnimations = {}

-- Function to define the hover animation
function UIAnimations.createHoverAnimation(slot)
	-- Define the hover animation (scaling up)
	local hoverTween = TweenService:Create(
		slot,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(slot.Size.X.Scale * 1.1, 0, slot.Size.Y.Scale * 1.1, 0)}
	)

	-- Define the leave animation (scaling back to original size)
	local leaveTween = TweenService:Create(
		slot,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(slot.Size.X.Scale, 0, slot.Size.Y.Scale, 0)}
	)

	return hoverTween, leaveTween
end

-- Function to define the click animation
function UIAnimations.createClickAnimation(slot)
	-- Define the click animation (scaling down)
	local clickTweenDown = TweenService:Create(
		slot,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(slot.Size.X.Scale * 0.9, 0, slot.Size.Y.Scale * 0.9, 0)}
	)

	-- Define the click release animation (scaling back to original size)
	local clickTweenUp = TweenService:Create(
		slot,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(slot.Size.X.Scale, 0, slot.Size.Y.Scale, 0)}
	)

	return clickTweenDown, clickTweenUp
end

-- Function to toggle the equip glow visibility
function UIAnimations.toggleEquipGlow(equipGlow, equipped)
	-- Define the transparency based on the equipped state
	local transparency = equipped and 0 or 1

	-- Create and play the tween to change the image transparency
	TweenService:Create(
		equipGlow,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ImageTransparency = transparency}
	):Play()
end

return UIAnimations
