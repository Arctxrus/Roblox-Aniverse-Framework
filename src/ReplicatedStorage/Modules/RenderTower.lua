-- ReplicatedStorage/Modules/RenderTower.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local AnimationPlayer = require(ReplicatedStorage.Modules.Animation:WaitForChild("AnimationPlayer"))

local TowerRenderModule = {}

function TowerRenderModule.renderTower(uniqueTowerID, towerName, position, idleAnimation)
	local TowersFolder = ReplicatedStorage.Units.Towers
	local towerTemplate = TowersFolder:FindFirstChild(towerName)
	if not towerTemplate then
		warn("Tower template not found for: " .. towerName)
		return
	end

	local towerModel = towerTemplate:Clone()
	towerModel.Name = uniqueTowerID -- Set the name to the unique ID for identification
	towerModel:SetPrimaryPartCFrame(CFrame.new(position))
	towerModel.Parent = Workspace.RenderedTowers

	-- Ensure only the base part is anchored
	for _, part in ipairs(towerModel:GetDescendants()) do
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, "Towers")
			part.CanCollide = false
			part.CastShadow = false
			if part.Name == "HumanoidRootPart" or part == towerModel.PrimaryPart then
				part.Anchored = true
			else
				part.Anchored = false
			end
		end
	end

	-- Play idle animation directly on the client
	AnimationPlayer.playIdleAnimation(towerModel, idleAnimation)
end

return TowerRenderModule
