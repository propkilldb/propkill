AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Propkill: Arena position editor"
ENT.Author = "Iced Coffee"
ENT.Purpose = "set positions"
ENT.Spawnable = false

if SERVER then
	function ENT:Initialize()
		//self:SetModel("models/editor/playerstart.mdl")
		self:SetMaterial("models/debug/debugwhite")
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_BBOX)
		self:SetUseType(SIMPLE_USE)
		self:DrawShadow(false)
		self.rotate = false
		self:setupWidget(self.rotate)
	end
	
	function ENT:Use(ply)
		if not ply:IsAdmin() then return end
		
		self.rotate = !self.rotate
		self:setupWidget(self.rotate)
	end
	
	function ENT:setupWidget(rotate)
		if IsValid(self.axis) then self.axis:Remove() end
		self.rotate = rotate or self.rotate
		local size = 32
		
		self.axis = ents.Create("widget_axis")
		self.axis:Setup(self, 0, self.rotate)
		self.axis.ArrowX:SetSize(size)
		self.axis.ArrowY:SetSize(size)
		self.axis.ArrowZ:SetSize(size)
		
		local ent = self
		local anglechange = Angle(0, 0, 0)

		local function PressEnd(self, ply)
			anglechange = Angle(0, 0, 0)
		end
		
		self.axis.ArrowX.PressEnd = PressEnd
		self.axis.ArrowY.PressEnd = PressEnd
		self.axis.ArrowZ.PressEnd = PressEnd

		function self.axis:OnArrowDragged(num, dist, ply, mv)
			if not ply:IsAdmin() then return end
			
			if ent.rotate then
				if num == 2 then
					anglechange.x = anglechange.x + dist
				elseif num == 3 then
					anglechange.y = anglechange.y + dist
				elseif num == 1 then
					anglechange.z = anglechange.z + dist
				end
				
				if anglechange.x >= 15 or anglechange.y >= 15 or anglechange.z >= 15 or anglechange.x <= -15 or anglechange.y <= -15 or anglechange.z <= -15 then
					local newang = anglechange + ent:GetAngles()
					newang.x = math.Round(newang.x / 15) * 15
					newang.y = math.Round(newang.y / 15) * 15
					newang.z = math.Round(newang.z / 15) * 15
					
					ent:SetAngles(newang + Angle(0,0,0.1)) -- stupid bug where the roll axis wont render if its exactly 0
					anglechange = Angle(0, 0, 0)
				end
			else
				local change = Vector(0, 0, 0)
				
				if num == 1 then
					change = ent:GetAngles():Forward() * dist
				elseif num == 2 then
					change = ent:GetAngles():Right() * -dist
				elseif num == 3 then
					change = ent:GetAngles():Up() * dist
				end
				
				ent:SetPos(ent:GetPos() + change)
			end
		end
		
		self.axis:Spawn()
		self:DeleteOnRemove(self.axis)
	end
end
function ENT:Draw()
	render.DrawWireframeBox(self:GetPos(), self:GetAngles(), self:OBBMins(), self:OBBMaxs(), Color(255,255,255))
	self:DrawModel()
end