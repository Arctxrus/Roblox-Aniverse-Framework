-- ElementalWeaknessModule
local ElementalWeakness = {}

-- Define weaknesses and strengths
ElementalWeakness.Modifiers = {
	Infernal = { Dendro = 1.35, Hydro = 0.65 },
	Hydro = { Infernal = 1.35, Gale = 0.65 },
	Gale = { Hydro = 1.35, Terra = 0.65 },
	Terra = { Gale = 1.35, Dendro = 0.65 },
	Dendro = { Terra = 1.35, Infernal = 0.65 },
	Electric = { Spectral = 1.35, Umbral = 0.65 },
	Spectral = { Electric = 1.35, Umbral = 1.35 },
	Umbral = { Spectral = 1.35, Electric = 1.35 },
	Physical = { all = 1.10 },
}

-- Function to get the damage modifier based on attacker and target elements
function ElementalWeakness.GetModifier(attackerElement, targetElement)
	if attackerElement == "Physical" then
		return ElementalWeakness.Modifiers.Physical.all
	end

	local modifiers = ElementalWeakness.Modifiers[attackerElement]
	if modifiers and modifiers[targetElement] then
		return modifiers[targetElement]
	end

	return 1 -- No modifier if elements don't interact specially
end

return ElementalWeakness
