AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName       = "EZ Winch"
ENT.Author			= "AdventureBoots"
ENT.Contact			= "Don't"
ENT.Purpose			= "A way to use the winch outside of sandbox"
ENT.Instructions	= "Non yet"
ENT.Category		= "JMod - EZ Misc."
ENT.Spawnable 		= true
--
ENT.JModPreferredCarryAngles = Angle(0,90,0)
ENT.MaxLength = 200
ENT.CurrentLength = 0
ENT.WinchStrength = 1000
ENT.StuckStick = nil
ENT.Winch = nil
ENT.Rope = nil
ENT.LengthConstraint = nil
ENT.WinchHook = nil
ENT.HookedTo = nil
--
local STATE_DETATCHED,STATE_ATTATCHED,STATE_HOOKING,STATE_WINCHING = 0,1,2,3

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "State")
end
if (SERVER) then
	function ENT:SpawnFunction(ply, tr)
		local SpawnPos = tr.HitPos + tr.HitNormal * 5
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
		self.Entity:SetModel("models/jmod/claymore.mdl")
		self.Entity:PhysicsInit(SOLID_VPHYSICS)
		self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
		self.Entity:SetSolid(SOLID_VPHYSICS)
		self.Entity:DrawShadow(true)
		self:SetUseType(ONOFF_USE)
		---
		timer.Simple(.01,function()
			self:GetPhysicsObject():SetMass(10)
			self:GetPhysicsObject():Wake()
		end)
		---
		self:SetState(STATE_DETATCHED)
		self.NextStick=0
	end
	function ENT:Use(activator, activatorAgain, onOff)
		local Dude = activator or activatorAgain
		JMod.Owner(self, Dude)
		local Time = CurTime()

		if (tobool(onOff)) then
			local State = self:GetState()
			local Alt=Dude:KeyDown(JMod.Config.AltFunctionKey)

			if(self.Winch == nil)then
				if(State == STATE_WINCHING)then
					self:SetState(STATE_ATTATCHED)
				end
				if(self.WinchHook)then
					SafeRemoveEntity(self.WinchHook)
				end
			end

			if (State == STATE_ATTATCHED) then
                if (Alt) then
					self:StartHooking(Dude)
					self:EmitSound("snd_jack_minearm.wav", 60, 100)
				else
					self:RemoveConstraintsAndPickup(Dude)
				end
            elseif (State == STATE_HOOKING)then
                if (Alt) then
					if(self.WinchHook)then
						SafeRemoveEntity(self.WinchHook)
					end
                    self:StartHooking(Dude)
					self:EmitSound("snd_jack_minearm.wav", 60, 100)
				else
					self:RemoveConstraintsAndPickup(Dude)
					if(self.WinchHook)then
						SafeRemoveEntity(self.WinchHook)
					end
                end
            elseif (State == STATE_WINCHING)then
				if (self.Winch == nil)then SetState(STATE_ATTATCHED) return end
				if (Alt) then
					self:Ratchet(-5)
					local RatchetSound = CreateSound(self, "snds_jack_gmod/slow_ratchet.wav", 60, 100)
					RatchetSound:Play()
				else
					self:Ratchet(5)
					self:EmitSound("snd_jack_metallicclick.wav", 60, 100)
				end
			else
            	Dude:PickupObject(self)
			end
			
			print(State)
		else
			if ((self:IsPlayerHolding()) and (self.NextStick < Time)) then
				local Tr=util.QuickTrace(Dude:GetShootPos(), Dude:GetAimVector()*80, {self, Dude})

				if Tr.Hit and (IsValid(Tr.Entity:GetPhysicsObject())) and not (Tr.Entity:IsNPC()) and not (Tr.Entity:IsPlayer()) then
					self.NextStick=Time+.5
					local Ang=Tr.HitNormal:Angle()
					Ang:RotateAroundAxis(Ang:Right(), -90)
					Ang:RotateAroundAxis(Ang:Up(), 90)
					self:SetAngles(Ang)
					self:SetPos(Tr.HitPos)

					-- crash prevention
					if (Tr.Entity:GetClass() == "func_breakable") then
						timer.Simple(0, function()
							self:GetPhysicsObject():Sleep()
						end)
					else
						local Weld = constraint.Weld(self, Tr.Entity, 0, Tr.PhysicsBone, 3000, false, false)
						self.StuckTo = Tr.Entity
						self.StuckStick = Weld
                        self:SetState(STATE_ATTATCHED)
					end

					self:EmitSound("snd_jack_claythunk.wav", 65, math.random(80, 120))
					Dude:DropObject()
					JMod.Hint(Dude, "arm")
				end
			end
		end
	end
	
	function ENT:RemoveConstraintsAndPickup(Dude)
		local Time = CurTime()
		constraint.RemoveAll(self)
		self.StuckStick = nil
		self.StuckTo = nil
		Dude:PickupObject(self)
		self.NextStick = Time + .5
		JMod.Hint(Dude, "sticky")
		self:SetState(STATE_DETATCHED)
	end

	function ENT:StartHooking(Dude)
		local TopOfWinch = self:GetAngles():Up() * 10
		-- Get rid of the old hook
		if(self.WinchHook)then
			SafeRemoveEntity(self.WinchHook)
		end
		-- Create a new hook
		local Hooky = ents.Create("ent_jack_gmod_ezwinchhook")
		Hooky:SetAngles(Angle(0, 0, 0))
		Hooky:SetPos(self:GetPos() + TopOfWinch * 6)
		JMod.Owner(Hooky, Dude)
		Hooky.WinchSpool = self
		Hooky:Spawn()
		Hooky:Activate()
		Dude:PickupObject(Hooky)
		self.WinchHook = Hooky

		local TopOfHook = self.WinchHook:GetAngles():Up() * 10
		local Constraint, Rope = constraint.Rope(self, self.WinchHook, 0, 0, self:WorldToLocal(self:GetPos() + TopOfWinch), self.WinchHook:WorldToLocal(self.WinchHook:GetPos() + TopOfHook), self.MaxLength, 0, 1000, 2, "cable/cable2", true)
		self.Winch = Constraint
		self.Rope = Rope
		self.CurrentLength = self.MaxLength
		-- If succesful we can set the state to hooking
		if(self.Winch)then
			self:SetState(STATE_HOOKING)
			print("Winching now")
		else
			print("Winch rope failed")
			return false
		end
	end

	function ENT:HookOn(Hook, ColData)
		local State = self:GetState()
		local Target = ColData.HitEntity
		if not(State == STATE_HOOKING)then print(State) return false end
		if not((Target == self.ClassName) and (Target:IsNPC()) and (Target:IsPlayer())) and (IsValid(Target:GetPhysicsObject()))then 
			print("Invalid Hit: "..tostring(ColData.HitEntity)) 
			return false 
		end
		if (ColData.HitPos:Distance(self:GetPos()) > self.MaxLength)then print("To far away") return false end

		timer.Simple(0.1, function()
			local TopOfWinch = self:GetAngles():Up() * 10
			local Constraint, Rope = constraint.Elastic(self, Target, 0, 0, self:WorldToLocal(self:GetPos() + TopOfWinch), ColData.HitEntity:WorldToLocal(ColData.HitPos), 1000, 50, 1, "cable/cable2", 2, true)
			if not(Constraint)then print("Winch Failed") return false end
			self.CurrentLength = ColData.HitPos:Distance(self:GetPos() + TopOfWinch)
			self.Winch = Constraint
			self.Rope = Rope
			self.HookedTo = Target
			--print("Constraint is new winch")
			if(self.WinchHook)then
				print("Removing: "..tostring(self.WinchHook))
				self.WinchHook:Remove()
			end
		end)
		self:StartWinching()
		print("State: Winching")
		return true
	end

	function ENT:StartWinching()
		self:SetState(STATE_WINCHING)
	end

	function ENT:Ratchet(value)
		local targetValue = math.ceil(self.CurrentLength + value)
		self.CurrentLength = math.Clamp(targetValue, 5, self.MaxLength)
		if IsValid(self.Winch) then 
			self.Winch:Fire("SetSpringLength", self.CurrentLength, 0) 
			self.Rope:Fire("SetLength", self.CurrentLength, 0)
		else
			self:SetState(STATE_ATTATCHED)
			return false
		end
		print(self.CurrentLength)
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 and data.Speed > 25 then
			self:EmitSound("snd_jack_claythunk.wav", 55, math.random(80, 120))
		end
	end

    function ENT:OnRemove()
		if(self.WinchHook)then
    		SafeRemoveEntity(self.WinchHook)
		end
    end
	--[[function ENT:Think()
		-- These were supposed to be safety checks, but I don't know if I need them here.
		local State = self:GetState()
		if(State == STATE_DETATCHED)then
			return
		elseif(State == STATE_ATTATCHED)then
			if not(StuckStick)then
				self:SetState(STATE_DETATCHED)
			end
		elseif(State == STATE_HOOKING)then
			if not(self.WinchHook) then return false end
			if not(self.Winch)then 
				SafeRemoveEntity(self.WinchHook)
				self:SetState(STATE_ATTATCHED)
				return false
			end
		end
        self:NextThink(CurTime() + 0.1)
    end]]--
elseif (CLIENT) then
end