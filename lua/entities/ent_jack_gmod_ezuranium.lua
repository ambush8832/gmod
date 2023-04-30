-- Jackarunda 2021
AddCSLuaFile()
ENT.Base = "ent_jack_gmod_ezresource"
ENT.PrintName = "EZ Uranium Ore"
ENT.Category = "JMod - EZ Resources"
ENT.IconOverride = "materials/ez_resource_icons/uranium ore.png"
ENT.Spawnable = true
ENT.AdminSpawnable = true
---
ENT.EZsupplies = JMod.EZ_RESOURCE_TYPES.URANIUMORE
ENT.JModPreferredCarryAngles = Angle(0, 0, 0)
ENT.Model = "models/hunter/blocks/cube05x05x05.mdl"
ENT.Material = "models/mat_jack_gmod_uraniumore"
ENT.ModelScale = 1
ENT.Mass = 50
ENT.ImpactNoise1 = "Rock.ImpactHard"
ENT.DamageThreshold = 120
ENT.BreakNoise = "Boulder.ImpactHard"

if SERVER then
	function ENT:UseEffect(pos, ent, destructive)
		if destructive and not self.Sploomd then
			self.Sploomd = true
			local Owner, Count = self.EZowner, self:GetResource() / 10

			timer.Simple(.5, function()
				for k = 1, JMod.Config.Particles.NuclearRadiationMult * Count / 2 do
					local Gas = ents.Create("ent_jack_gmod_ezfalloutparticle")
					Gas.Range = 500
					Gas:SetPos(pos)
					JMod.SetEZowner(Gas, Owner or game.GetWorld())
					Gas:Spawn()
					Gas:Activate()
					Gas:GetPhysicsObject():SetVelocity(Vector(0, 0, 50 * JMod.Config.Particles.NuclearRadiationMult))
				end
			end)
		end
	end
end
