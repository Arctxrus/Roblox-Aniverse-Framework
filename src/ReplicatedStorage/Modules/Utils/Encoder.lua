local Encoder = {}

local GRID_CELL_SIZE = 4
local ORIENTATION_MULTIPLIER = 128 -- 2^7 = 128 unique values

function Encoder.EncodePositioningData(Hash, Orientation, X, Z)
	local packedOrientation = math.floor(Orientation * ORIENTATION_MULTIPLIER / (2 * math.pi))
	local displacementX = math.floor((X % GRID_CELL_SIZE) * 128 / GRID_CELL_SIZE) -- Use 7 bits (0-127)
	local displacementZ = math.floor((Z % GRID_CELL_SIZE) * 128 / GRID_CELL_SIZE) -- Use 7 bits (0-127)

	local packedData = bit32.bor(
		bit32.lshift(bit32.band(Hash, 0x7FF), 21),
		bit32.lshift(bit32.band(packedOrientation, 0x7F), 14),
		bit32.lshift(bit32.band(displacementX, 0x7F), 7), -- 7 bits for displacementX
		bit32.lshift(bit32.band(displacementZ, 0x7F), 0) -- 7 bits for displacementZ
	)

	return Vector2int16.new(bit32.arshift(packedData, 16), bit32.band(packedData, 0xFFFF))
end

function Encoder.DecodePositioningData(PositioningData)

	local packedData = bit32.bor(bit32.lshift(PositioningData.X, 16), bit32.band(PositioningData.Y, 0xFFFF))

	local Hash = bit32.band(bit32.rshift(packedData, 21), 0x7FF)
	local packedOrientation = bit32.band(bit32.rshift(packedData, 14), 0x7F)
	local displacementX = bit32.band(bit32.rshift(packedData, 7), 0x7F)
	local displacementZ = bit32.band(packedData, 0x7F)

	local Orientation = (packedOrientation * (2 * math.pi)) / ORIENTATION_MULTIPLIER
	local X = displacementX * GRID_CELL_SIZE / 128
	local Z = displacementZ * GRID_CELL_SIZE / 128

	return Hash, Orientation, X, Z
end

-- Encode grid change data into a 48-bit Vector3int16
function Encoder.EncodeGridChangeData(Hash, Orientation, X, Z, GridX, GridZ)
	local packedOrientation = math.floor(Orientation * ORIENTATION_MULTIPLIER / (2 * math.pi))
	local displacementX = math.floor((X % GRID_CELL_SIZE) * 128 / GRID_CELL_SIZE) -- Use 7 bits (0-127)
	local displacementZ = math.floor((Z % GRID_CELL_SIZE) * 128 / GRID_CELL_SIZE) -- Use 7 bits (0-127)


	local packedData1 = bit32.bor(
		bit32.lshift(bit32.band(Hash, 0x7FF), 21),
		bit32.lshift(bit32.band(packedOrientation, 0x7F), 14),
		bit32.lshift(bit32.band(displacementX, 0x7F), 7), -- 7 bits for displacementX
		bit32.lshift(bit32.band(displacementZ, 0x7F), 0) -- 7 bits for displacementZ
	)
	local packedData2 = bit32.bor(
		bit32.lshift(bit32.band(GridX, 0xFF), 8), -- 8 bits for GridX
		bit32.band(GridZ, 0xFF) -- 8 bits for GridZ
	)

	return Vector3int16.new(bit32.arshift(packedData1, 16), bit32.band(packedData1, 0xFFFF), packedData2)
end

function Encoder.DecodeGridChangeData(PositioningData)
	local packedData1 = bit32.bor(bit32.lshift(PositioningData.X, 16), bit32.band(PositioningData.Y, 0xFFFF))
	local packedData2 = PositioningData.Z

	local Hash = bit32.band(bit32.rshift(packedData1, 21), 0x7FF)
	local packedOrientation = bit32.band(bit32.rshift(packedData1, 14), 0x7F)
	local displacementX = bit32.band(bit32.rshift(packedData1, 7), 0x7F)
	local displacementZ = bit32.band(packedData1, 0x7F)
	local GridX = bit32.band(bit32.rshift(packedData2, 8), 0xFF)
	local GridZ = bit32.band(packedData2, 0xFF)

	local Orientation = (packedOrientation * (2 * math.pi)) / ORIENTATION_MULTIPLIER
	local X = displacementX * GRID_CELL_SIZE / 128
	local Z = displacementZ * GRID_CELL_SIZE / 128

	return Hash, Orientation, X, Z, GridX, GridZ
end

return Encoder
