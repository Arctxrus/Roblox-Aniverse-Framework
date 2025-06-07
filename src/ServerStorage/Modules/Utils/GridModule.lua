local GridModule = {}

local gridSize = 20
local grid = {}

local function getGridIndex(x, z)
	local xIndex = math.floor(x / gridSize)
	local zIndex = math.floor(z / gridSize)
	return xIndex, zIndex
end

function GridModule.addToGrid(enemyData)
	if not enemyData or not enemyData.Position then
		warn("Enemy has no Position:", enemyData and enemyData.Name or "Unknown")
		return
	end
	local xIndex, zIndex = getGridIndex(enemyData.Position.X, enemyData.Position.Z)
	grid[xIndex] = grid[xIndex] or {}
	grid[xIndex][zIndex] = grid[xIndex][zIndex] or {}
	grid[xIndex][zIndex][enemyData.ID] = enemyData
end

function GridModule.removeFromGrid(enemyData)
	if not enemyData then return end
	for xIndex, zColumns in pairs(grid) do
		for zIndex, enemies in pairs(zColumns) do
			if enemies[enemyData.ID] then
				enemies[enemyData.ID] = nil
				return
			end
		end
	end
end

function GridModule.updateGrid(enemyData, newX, newZ)
	local oldXIndex, oldZIndex = getGridIndex(enemyData.Position.X, enemyData.Position.Z)
	local newXIndex, newZIndex = getGridIndex(newX, newZ)

	-- Update only if the enemy has moved to a new grid cell
	if oldXIndex ~= newXIndex or oldZIndex ~= newZIndex then
		GridModule.removeFromGrid(enemyData)
		enemyData.Position = Vector3.new(newX, enemyData.Position.Y, newZ)
		GridModule.addToGrid(enemyData)
	else
		enemyData.Position = Vector3.new(newX, enemyData.Position.Y, newZ)
	end
end

function GridModule.getEnemiesInRange(position, range)
	local enemiesInRange = {}
	local minXIndex = math.floor((position.X - range) / gridSize)
	local maxXIndex = math.floor((position.X + range) / gridSize)
	local minZIndex = math.floor((position.Z - range) / gridSize)
	local maxZIndex = math.floor((position.Z + range) / gridSize)

	for xIndex = minXIndex, maxXIndex do
		for zIndex = minZIndex, maxZIndex do
			if grid[xIndex] and grid[xIndex][zIndex] then
				for _, enemyData in pairs(grid[xIndex][zIndex]) do
					if enemyData and enemyData.Position and (enemyData.Position - position).Magnitude <= range then
						table.insert(enemiesInRange, enemyData)
					end
				end
			end
		end
	end
	return enemiesInRange
end

return GridModule