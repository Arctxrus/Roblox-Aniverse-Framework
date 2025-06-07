local EnemyManager = require(game.ServerStorage.Modules.EnemyManagement.EnemyManager)

local WaveManager = {}
local spawnInterval = 1
local waves = {
	{"Pirate"}
}
local currentWave = 1
local waveActive = false

local function checkEnemiesCleared()
	while #game.Workspace.Enemies:GetChildren() > 0 do
		wait(1)
	end
end

local function spawnEnemiesForWave(wave)
	print("Starting wave " .. currentWave)
	waveActive = true
	wait(2)
	for _, enemyName in ipairs(wave) do
		EnemyManager.spawnEnemy(enemyName)
		wait(spawnInterval)
	end
	checkEnemiesCleared()
	waveActive = false
	currentWave = currentWave + 1
	if currentWave <= #waves then
		spawnEnemiesForWave(waves[currentWave])
	else
		print("All waves completed")
	end
end

function WaveManager.startWave()
	if not waveActive and currentWave <= #waves then
		spawnEnemiesForWave(waves[currentWave])
	else
		print("No more waves to start or a wave is already in progress")
	end
end

return WaveManager
