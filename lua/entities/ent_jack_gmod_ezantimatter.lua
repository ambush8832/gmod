﻿-- Jackarunda 2021
AddCSLuaFile()
ENT.Base = "ent_jack_gmod_ezresource"
ENT.PrintName = "EZ Antimatter"
ENT.Category = "JMod - EZ Resources"
ENT.IconOverride = "materials/ez_resource_icons/antimatter.png"
ENT.Spawnable = true
ENT.AdminOnly = true
---
ENT.EZsupplies = JMod.EZ_RESOURCE_TYPES.ANTIMATTER
ENT.JModPreferredCarryAngles = Angle(0, 0, 0)
ENT.Model = "models/thedoctor/darkmatter.mdl"
ENT.ModelScale = 1
-- 10 micrograms
ENT.Mass = 100
ENT.ImpactNoise1 = "Canister.ImpactHard"
ENT.ImpactNoise2 = "Weapon.ImpactSoft"
ENT.ImpactSensitivity = 800
ENT.DamageThreshold = 50
ENT.BreakNoise = "Metal_Box.Break"
ENT.Hint = "antimatter"
ENT.WeightlessResource = true

---
if SERVER then
	function ENT:UseEffect(pos, ent, destructive)
		if destructive and not self.Sploomd then
			local Resources = self:GetResource()
			self.Sploomd = true
			local Blam = EffectData()
			Blam:SetOrigin(pos)
			Blam:SetScale(5 * (Resources / 200))
			util.Effect("eff_jack_plastisplosion", Blam, true, true)
			util.ScreenShake(pos, 99999, 99999, 1, 750 * 5)

			for i = 1, 2 do
				sound.Play("BaseExplosionEffect.Sound", pos, 120, math.random(90, 110))
			end

			for i = 1, 2 do
				sound.Play("ambient/explosions/explode_" .. math.random(1, 9) .. ".wav", pos + VectorRand() * 1000, 140, math.random(90, 110))
			end

			timer.Simple(.1, function()
				local MeltBlast = DamageInfo()
				MeltBlast:SetInflictor(game.GetWorld())
				MeltBlast:SetAttacker(game.GetWorld())
				MeltBlast:SetDamage(Resources * 5)
				MeltBlast:SetDamageType(DMG_DISSOLVE)
				util.BlastDamageInfo(MeltBlast, pos, Resources * 8)
				for k, v in pairs(ents.FindInSphere(pos, Resources * 5)) do 
					if v:GetClass() == "npc_strider" then
						v:Fire("break")
					end
				end
			end)
		end
	end

	function ENT:AltUse(ply)
	end
	--
elseif CLIENT then
	function ENT:Draw()
		self:DrawModel()

		JMod.HoloGraphicDisplay(self, Vector(1, -6.2, 8), Angle(90, 0, 90), .02, 300, function()
			JMod.StandardResourceDisplay(JMod.EZ_RESOURCE_TYPES.ANTIMATTER, self:GetResource(), nil, 0, 0, 200, true)
		end)
	end

	language.Add(ENT.ClassName, ENT.PrintName)
end
