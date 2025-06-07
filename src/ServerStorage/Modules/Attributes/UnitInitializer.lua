local ServerStorage = game:GetService("ServerStorage")
local TowerAttributes = require(ServerStorage.Modules.Attributes:WaitForChild("TowerAttributesModule"))
local EnemyAttributes = require(ServerStorage.Modules.Attributes:WaitForChild("EnemyAttributesModule"))

local function initializeUnit(unitType, unitName, attributesTable)
	local attributes = nil

	if unitType == "Towers" then
		attributes = TowerAttributes[unitName]
	elseif unitType == "Enemies" then
		attributes = EnemyAttributes[unitName]
	end

	if not attributes then
		warn("No attributes found for unit type: " .. tostring(unitType) .. " with name: " .. tostring(unitName))
		return
	end

	for key, value in pairs(attributes) do
		if typeof(value) == "table" then
			for subKey, subValue in pairs(value) do
				attributesTable[subKey] = subValue
			end
		else
			attributesTable[key] = value
		end
	end

	-- Set default values for attributes that may not be provided
	if attributesTable["MaxHP"] then
		attributesTable["Health"] = attributesTable["Health"] or attributesTable["MaxHP"]
	end
	if attributesTable["MaxShield"] then
		attributesTable["Shield"] = attributesTable["Shield"] or 0
	end
end

return initializeUnit
