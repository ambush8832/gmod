AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName       = "EZ Winch Hook"
ENT.Author			= "AdventureBoots"
ENT.Contact			= "Don't"
ENT.Purpose			= "A way to use a winch outside of sandbx"
ENT.Instructions	= "walk + use to attach and deploy the winch, \n attach the winch and press use on it to tighten"
ENT.Category		= "JMod - EZ Misc."
ENT.Spawnable 		= false
--
ENT.JModPreferredCarryAngles = Angle(0,0,0)
ENT.WinchSpool = nil
--
local STATE_DETATCHED,STATE_ATTATCHED = 0,1

function ENT:SetupDataTables()
	self:NetworkVar("Int",0,"State")
end
if(SERVER)then
    function ENT:SpawnFunction(ply, tr)
		local SpawnPos = tr.HitPos + tr.HitNormal*5
		local ent = ents.Create(self.ClassName)
		ent:SetAngles(Angle(0, 0, 0))
		ent:SetPos(SpawnPos)
		JMod.Owner(ent, ply)
		ent:Spawn()
		ent:Activate()
		--local effectdata=EffectData()
		--effectdata:SetEntity(ent)
		--util.Effect("propspawn",effectdata)
		JMod.Hint(ply,self.ClassName)
		return ent
	end
	function ENT:Initialize()
		self.Entity:SetModel("models/props_trainstation/payphone_reciever001a.mdl")
		self.Entity:PhysicsInit(SOLID_VPHYSICS)
		self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
		self.Entity:SetSolid(SOLID_VPHYSICS)
		self.Entity:DrawShadow(true)
		self.Entity:SetUseType(SIMPLE_USE)
		---
		timer.Simple(.01,function()
			self:GetPhysicsObject():SetMass(5)
			self:GetPhysicsObject():Wake()
		end)
	end
	function ENT:Use(Dude)
		Dude:PickupObject(self)
	end
	function ENT:PhysicsCollide(data, physobj)
		if not(IsValid(self))then return end
		if(data.DeltaTime > 0.2)then
			if(data.Speed > 50)then
				local SuccessfulWinch = self.WinchSpool:HookOn(self, data)
				if(SuccessfulWinch)then
					self:EmitSound("snd_jack_pinpull.wav")
				else
					self:EmitSound("Canister.ImpactHard")
				end
			end
		end
	end
elseif(CLIENT)then
end