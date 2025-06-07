local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local FrustumCullingModule = {}

-- Define the buffer factor for the FOV
local FOV_BUFFER_FACTOR = 1.2 -- Adjust this value to change the buffer size (1.2 means 20% larger view)

-- Checks if a point is within the camera's view frustum with a buffer
function FrustumCullingModule.isPointInView(point)
	local screenPoint, onScreen = Camera:WorldToViewportPoint(point)
	local bufferX = Camera.ViewportSize.X * (FOV_BUFFER_FACTOR - 1) / 2
	local bufferY = Camera.ViewportSize.Y * (FOV_BUFFER_FACTOR - 1) / 2

	return onScreen and screenPoint.Z > 0
		and screenPoint.X > -bufferX
		and screenPoint.X < Camera.ViewportSize.X + bufferX
		and screenPoint.Y > -bufferY
		and screenPoint.Y < Camera.ViewportSize.Y + bufferY
end

-- Checks if a model is within the camera's view frustum with a buffer
function FrustumCullingModule.isModelInView(model)
	if not model.PrimaryPart then
		return false
	end
	return FrustumCullingModule.isPointInView(model.PrimaryPart.Position)
end

return FrustumCullingModule
