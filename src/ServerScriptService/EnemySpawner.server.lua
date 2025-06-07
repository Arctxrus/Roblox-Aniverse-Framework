local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WaveManager = require(ServerStorage.Modules.WaveManagement.WaveManager)
local SplineUtils = require(ReplicatedStorage.Modules.SplineUtils)

local DEBUG_DRAW_SPLINE = false

local function drawSpline(waypoints)
	for i = 1, #waypoints - 3 do
		for t = 0, 1, 0.01 do
			local position = SplineUtils.catmullRom(waypoints[i], waypoints[i + 1], waypoints[i + 2], waypoints[i + 3], t)
			local part = Instance.new("Part")
			part.Size = Vector3.new(0.2, 0.2, 0.2)
			part.Position = position
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 0.5
			part.Color = Color3.fromRGB(0, 0, 255)
			part.Parent = Workspace
		end
	end
end

local function main()
	local waypointsFolder = Workspace:WaitForChild("Waypoints")
	local waypoints = waypointsFolder:GetChildren()
	table.sort(waypoints, function(a, b) return a.Name < b.Name end)
	local positions = {}
	for _, waypoint in ipairs(waypoints) do
		table.insert(positions, waypoint.Position)
	end
	table.insert(positions, 1, positions[1])
	table.insert(positions, positions[#positions])

	if DEBUG_DRAW_SPLINE then
		if #positions >= 4 then
			drawSpline(positions)
		else
			warn("Not enough waypoints for Catmull-Rom spline")
		end
	else
		for _, waypoint in ipairs(waypoints) do
			if waypoint:IsA("BasePart") then
				waypoint.Transparency = 1
				waypoint.CanCollide = false
			end
		end
	end
	WaveManager.startWave()
end

main()
