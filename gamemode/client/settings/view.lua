-- Remove Skybox

/*function PK.Client.RemoveSkybox()
	if PK.Client.Config:Get("RemoveSkybox").Value then
		hook.Add("PostDrawSkyBox", "removeSkybox", function()
			render.Clear(50, 50, 50, 255)
			return true
		end)
		hook.Add("PostDraw2DSkyBox", "removeSkybox", function()
			render.Clear(50, 50, 50, 255)
			return true
		end)
	else
		hook.Remove("PostDrawSkyBox", "removeSkybox")
		hook.Remove("PostDraw2DSkyBox", "removeSkybox")
	end
end

-- Roof Tiles

local DrawPos
local params = {
	["$basetexture"] = "phoenix_storms/pack2/train_floor",
	["$nodecal"] = 1,
	["$model"] = 1,
	["$additive"] = 0,
	["$nocull"] = 1,
	["$alpha"] = 0.95
}
local RoofMaterial = CreateMaterial("RoofMaterialTest8", "UnlitGeneric", params)

timer.Create("DrawRoofTiles", 0.1, 0, function()
	if not IsValid(LocalPlayer()) then return end
	local tracedata = {}
	tracedata.start = LocalPlayer():GetShootPos()
	tracedata.endpos = tracedata.start + Vector(0,0,9999999)
	tracedata.filter = LocalPlayer()
	tracedata.mask = MASK_NPCWORLDSTATIC
	local trace = util.TraceLine(tracedata)
	if trace.HitWorld and (trace.HitTexture == "TOOLS/TOOLSSKYBOX" or trace.HitTexture == "TOOLS/TOOLSSKYBOX2D") then
		DrawPos = DrawPos or trace.HitPos
		DrawPos.z = trace.HitPos.z
	end
	if IsValid(DrawPos) then
		timer.Remove("DrawRoofTiles")
	end
end)

function PK.Client.RoofTiles()
	if PK.Client.Config:Get("RoofTiles").Value then
		hook.Add("PostDrawOpaqueRenderables", "ReplaceSkyBox", function()
			if not DrawPos then return end
			local pos1 = DrawPos + Vector( 5000,  5000, 0)
			local pos2 = DrawPos + Vector(-5000,  5000, 0)
			local pos3 = DrawPos + Vector(-5000, -5000, 0)
			local pos4 = DrawPos + Vector( 5000, -5000, 0)
			cam.Start3D(EyePos(), EyeAngles())
				render.SuppressEngineLighting(true)
				render.SetBlend(0.4)
				render.SetMaterial(RoofMaterial)

				render.DrawQuad(pos1, pos2, pos3, pos4)
				render.DrawQuad(pos1 + Vector(5000), pos2 + Vector(5000), pos3 + Vector(5000), pos4 + Vector(5000))
				render.DrawQuad(pos1 - Vector(5000), pos2 - Vector(5000), pos3 - Vector(5000), pos4 - Vector(5000))
				render.DrawQuad(pos1 - Vector(5000, 5000), pos2 - Vector(5000, 5000), pos3 - Vector(5000, 5000), pos4 - Vector(5000, 5000))
				render.DrawQuad(pos1 - Vector(5000, -5000), pos2 - Vector(5000, -5000), pos3 - Vector(5000, -5000), pos4 - Vector(5000, -5000))
				render.DrawQuad(pos1 - Vector(0, -5000), pos2 - Vector(0, -5000), pos3 - Vector(0, -5000), pos4 - Vector(0, -5000))
				render.DrawQuad(pos1 + Vector(0, -5000), pos2 + Vector(0, -5000), pos3 + Vector(0, -5000), pos4 + Vector(0, -5000))

				render.DrawQuad(pos1 - Vector(-5000, -5000), pos2 - Vector(-5000, -5000), pos3 - Vector(-5000, -5000), pos4 - Vector(-5000, -5000))
				render.DrawQuad(pos1 - Vector(-5000, 5000), pos2 - Vector(-5000, 5000), pos3 - Vector(-5000, 5000), pos4 - Vector(-5000, 5000))


				render.SuppressEngineLighting(false)
				render.SetBlend(1)
			cam.End3D()
		end)
	else
		hook.Remove("PostDrawOpaqueRenderables", "ReplaceSkyBox")
	end
end

-- Use Custom FOV

ViewPos = nil
ViewAng = nil

function PK.Client.UseCustomFOV()
	if PK.Client.Config:Get("UseCustomFOV").Value then
		local function fov(ply, ori, ang, fov, nz, fz)
			local view = {}
			view.origin = ori
			view.angles = ang
			_G.ViewPos = ori
			_G.ViewAng = ang
			view.fov = PK.Client.Config:Get("CustomFOV").Value or 100
			return view
		end
		hook.Add("CalcView", "PK_CustomFOV", fov)
	else
		hook.Remove("CalcView", "PK_CustomFOV")
	end
end

-- Use Custom Viewmodel Offset

function PK.Client.UseCustomViewmodelOffset()
	if PK.Client.Config:Get("UseCustomViewmodelOffset").Value then
		local function ViewmodelOffset(wep, vm, oldPos, oldAng, pos, ang)
			local view = {}
			pos = pos + ang:Right() * PK.Client.Config:Get("CustomViewmodelOffset").Value.x
			pos = pos + ang:Forward() * PK.Client.Config:Get("CustomViewmodelOffset").Value.y
			pos = pos + ang:Up() * PK.Client.Config:Get("CustomViewmodelOffset").Value.z
			view.angles = ang
			return pos, ang
		end
		hook.Add("CalcViewModelView", "PK_CustomViewmodelOffset", ViewmodelOffset)
	else
		hook.Remove("CalcViewModelView", "PK_CustomViewmodelOffset")
	end
end

-- Hide Viewmodel

function PK.Client.HideViewmodel()
	if PK.Client.Config:Get("HideViewmodel").Value then
		local function HideViewmodel()
			for i = 0, 2 do
				LocalPlayer():DrawViewModel(false, i)
			end
		end
		//HideViewmodel()
		hook.Add("PreDrawViewModel", "PK_Hideviewmodel", HideViewmodel)
	else
		for i = 0, 2 do
			LocalPlayer():DrawViewModel(true, i)
		end
		hook.Remove("PreDrawViewModel", "PK_Hideviewmodel")
	end
end

local function EternalSin( Freak, Trough, Peak )
	local Diff = ( Peak -Trough )
	local ActualTrough = ( Trough +Peak ) /2
	local ActualPeak = ActualTrough +Diff
	return TimedSin( Freak, ActualTrough, ActualPeak, 0 )
end

function PK.Client.TrackPlayers()
	if PK.Client.Config:Get("TrackPlayers").Value then
		local function TrackPlayers()
			cam.Start3D()
			local BeamStart, Pulse  = _G.ViewPos + _G.ViewAng:Forward() * 50, EternalSin( 1, 1, 255 )
			FriendsCol, AdminCol, PropCol = Color( 0, Pulse, 0 ), Color( Pulse, 0, 0 ), Color( Pulse, 200 -Pulse, 0 )
			render.SetMaterial(Material("sprites/lookingat"))
			for k,v in pairs(player.GetAll()) do
				if !IsValid(v) then continue end
				if v == LocalPlayer() or v:Team() == TEAM_UNASSIGNED then continue end
				local Centre = v:LocalToWorld(v:OBBCenter())
				local Col, OuterCol = PropCol, nil
				local Dist = BeamStart:Distance( Centre )
				local WidthUnclamped = Dist / 1200
				local ArrowLength = -math.Clamp( Dist / ( WidthUnclamped * 10 ), 60, 120 ) --needs work
				local Width = math.Clamp( WidthUnclamped, 0.5, 2 )
				if (v:IsPlayer()) then
					if ( !v:Alive() ) then continue end
						//Col = team.GetColor( k )
						if (v:GetFriendStatus() == "friend") then
							OuterCol = FriendsCol
						elseif ( v:IsAdmin() ) then
							OuterCol = AdminCol
						end
						OuterCol = AdminCol
						//else
						//	Col = PropCol
						//end
						if (OuterCol) then
							render.DrawBeam(Centre, BeamStart, Width / 0.6, ArrowLength, 0, OuterCol )
						end
						render.DrawBeam(Centre, BeamStart, Width, ArrowLength, 0, Col )
					end
				end
			cam.End3D()
		end
		//HideViewmodel()
		hook.Add("PostDrawHUD", "PK_TrackPlayers", TrackPlayers)
	else
		hook.Remove("PostDrawHUD", "PK_TrackPlayers")
	end
end

// Autorun all enabled settings on start
for k,v in pairs(PK.Client) do
	if not PK.Client.Config:Get(k) then continue end
	if isbool(PK.Client.Config:Get(k).Value) and PK.Client.Config:Get(k).Value == true then
		v()
	end
end
*/