-- AttackInfo.lua
return {
	ChosoBloodBomb = {
		Type = "Projectile",
		Model = "ChosoBloodBall",
		Speed = 100,
		Explosion = "ChosoBloodExplosion",
		Animation = "ChosoBomb",  -- Animation name for this attack
		Location = "Left",  -- New variable to specify location
		ParabolaHeight = .5,  -- Height of the parabola
		Ground = false,  -- Aim 0.5 studs lower if true
		DamageDelay = 0.5,
		AttackDelay = 1.02,
		RelativeFirePosition = {1.8579351902008057, 1.1920727491378784, -1.2453306913375854},
		
	},
	ChosoBloodBeam = {
		Type = "Beam",
		BeamVFX = "BloodBeam",
		BeamLength = 30,
		ChargeVFX = "BeamCharge",  -- Simplified to just the name
		ChargeVFXLocation = "Right",  -- New variable to specify location
		Animation = "ChosoBeam",  -- Animation name for this attack
		AttackDelay = 1.05,
		AttackDuration = 2.03,
	}
}
