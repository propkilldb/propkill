// wallhack taken from noobler by ownage

local b = debug.getregistry()
local d = concommand.Add
local e = sql
local RCC = RunConsoleCommand
local g = CreateMaterial("WallMaterial3", "VertexLitGeneric", {["$basetexture"] = "Models/Debug/debugwhite", ["$nocull"] = 1, ["$model"] = 1})
local h = {}
local ENTITY = FindMetaTable("Entity")

function pk_save_client_settings()
	file.Write("pkr_settings.txt", util.TableToJSON(pk_ms_settings_table))
end

pk_settings_file = file.Read("pkr_settings.txt")

pk_ms_settings_table = nil

if pk_settings_file then
	pk_ms_settings_table = util.JSONToTable(pk_settings_file)
else
	pk_ms_settings_table = {
		PlayerWalls=true,
		PropWalls=true,
		WallsAlwaysSolid=true,
		ESP=true,
		ESPOffset=Vector(0,0,15),
		Boxes=false,
		PlayerOpacity=100,
		PlayerColour={1,1,1},
		PropOpacity=30,
		PropNormalColour={0.525,0,1},
		PropWallOpacity=60,
		VertBeam = false,
		RoofTiles = false,
		RemoveSkybox = false,
		NoLerp = false,
	}
	pk_save_client_settings()
end

function ENTITY:IsProp()
	return self:GetClass()=="prop_physics" or self:GetClass()=="gmod_button"
end

local function u()
	local v = player.GetAll()
	local v = table.Add(v, ents.FindByClass("prop_physics"))
	local v = table.Add(v, ents.FindByClass("gmod_button"))
	return v
end

local function w()
	h = ents.FindByClass("gmod_button")
	h = table.Add(h, ents.FindByClass("prop_physics"))
	h = table.Add(h, ents.FindByClass("ctf_flag"))
end

hook.Add("Think", "addbuttons", w)

local function ms_onentcreated(entname)
	local y = entname
	if pk_ms_settings_table.PropWalls then
		if not y.Mat and y:GetClass()=="prop_physics" or y:GetClass()=="gmod_button" then
			y.Mat=y:GetMaterial()
			y:SetNoDraw(true)
			y:DrawShadow(false)
		end
	else
		if y.Mat and y:GetClass()=="prop_physics" or y:GetClass()=="gmod_button" then
			local z=y.Mat or ""y:SetNoDraw(false)
			y:DrawShadow(true)
			y.Mat=nil
		end
	end
end

hook.Add("OnEntityCreated", "MSEntityCreated", ms_onentcreated)

local function A()
	for l,m in pairs(h) do
		ms_onentcreated(m)
	end
end

local function B(C)
	return Color(255-C.r,255-C.g,255-C.b,255)
end

local function ms_prop_screenspace_stuff()
	local E=pk_ms_settings_table.PropNormalColour
	cam.Start3D(EyePos(),EyeAngles())
	cam.IgnoreZ(true)
	render.MaterialOverride(g)
	render.SuppressEngineLighting(true)
	if pk_ms_settings_table.PropWalls and pk_ms_settings_table.PropWallOpacity then
		render.SetBlend(pk_ms_settings_table.PropWallOpacity/100)
		for l,m in pairs(h) do
			if IsValid(m) then
				if m:GetClass() == "ctf_flag" then
					local tc = team.GetColor(m:GetTeam())
					render.SetColorModulation(tc["r"]/255,tc["g"]/255,tc["b"]/255)
				else
					render.SetColorModulation(E[1],E[2],E[3])
				end
				m:SetNoDraw(true)
				m:DrawModel()
			end
		end
	end

	if pk_ms_settings_table.PlayerWalls and pk_ms_settings_table.PlayerOpacity then
		render.SetBlend(pk_ms_settings_table.PlayerOpacity/100)
		for l,m in pairs(player.GetAll()) do
			if m:Team() == TEAM_UNASSIGNED or m:Team() == TEAM_SPECTATOR then continue end
			local tc = team.GetColor(m:Team())
			render.SetColorModulation(tc["r"]/255,tc["g"]/255,tc["b"]/255)
			if IsValid(m) and m:Alive() and m:GetMoveType()~=0 then
				m:DrawModel()
			end
		end
	end

	cam.IgnoreZ(false)

	if not pk_ms_settings_table.WallsAlwaysSolid then
		if pk_ms_settings_table.PlayerWalls then
			render.SetBlend(1)
			render.SetColorModulation(1,1,1)
			render.MaterialOverride(nil)
			for l,m in pairs(player.GetAll()) do
				if IsValid(m) and m:GetMoveType()~=0 and m:Alive() then
					m:DrawModel()
				end
			end
		end

		if pk_ms_settings_table.PropWalls and pk_ms_settings_table.PropOpacity then
			render.MaterialOverride(g)
			render.SetColorModulation(E[1],E[2],E[3])
			render.SetBlend(pk_ms_settings_table.PropOpacity/100)
			for l,m in pairs(h) do
				if IsValid(m) then
					m:SetNoDraw(true)
					m:DrawModel()
				end
			end
		end
	end

	render.MaterialOverride(nil)
	render.SetColorModulation(1,1,1)
	render.SetBlend(1)
	cam.IgnoreZ(false)
	render.SuppressEngineLighting(false)
	cam.End3D()
end

hook.Add("RenderScreenspaceEffects", "MSRender", ms_prop_screenspace_stuff)

local function visualstoggle()
	if !pk_ms_settings_table.PropWalls then
		surface.PlaySound("buttons/button1.wav")
	else
		surface.PlaySound("buttons/button19.wav")
	end
	pk_ms_settings_table.PropWalls = not pk_ms_settings_table.PropWalls
	pk_ms_settings_table.PlayerWalls = not pk_ms_settings_table.PlayerWalls
	pk_ms_settings_table.ESP = not pk_ms_settings_table.ESP
	pk_save_client_settings()
end

concommand.Add("pk_visuals", visualstoggle)

function pk_esp()
	for k,v in pairs(player.GetAll()) do
		if v != LocalPlayer() and pk_ms_settings_table.ESP and v:Alive() and v:Team() != TEAM_UNASSIGNED and v:Team() != TEAM_SPECTATOR then
			local pos1 = v:GetBonePosition(v:LookupBone("ValveBiped.Bip01_Head1") or -1) + Vector(0,0,15)
			local pos = pos1:ToScreen()
			draw.SimpleText(v:Nick(), "stb24", pos.x, pos.y, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

		end
	end
end
hook.Add("HUDPaint", "pk_esp", pk_esp)

function pk_flagesp()
	for k,v in pairs(ents.GetAll()) do
		if v:GetClass() == "ctf_flag" then
			local pos1 = v:GetPos()+Vector(0,0,100)
			local pos = pos1:ToScreen()
			draw.SimpleText(string.Replace(team.GetName(v:GetTeam()), "Team", "Flag"), "stb24", pos.x, pos.y, team.GetColor(v:GetTeam()) , TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
	end
end
hook.Add("HUDPaint", "pk_flagesp", pk_flagesp)

local function msrotate()
	local ply = LocalPlayer()
	local a = ply:EyeAngles()
	ply:SetEyeAngles(Angle(a.p, a.y-180, a.r))
end
concommand.Add("ms_rotate", msrotate)

local function msrotate2()
	local ply = LocalPlayer()
	local a = ply:EyeAngles() ply:SetEyeAngles(Angle(a.p-a.p-a.p, a.y-180, a.r))
	RunConsoleCommand("+jump")
	timer.Simple(0.2, function() ply:ConCommand("-jump") end)
end
concommand.Add("ms_rotate2", msrotate2)

local function vertBeam()
	if !pk_ms_settings_table.VertBeam then
		hook.Add("PostPlayerDraw", "pk_vertbeam", function()
			for k,v in pairs(player.GetAll()) do
				if v != LocalPlayer() then
					local t = {start = v:GetPos(), endpos = v:GetPos()+Vector(0,0,10000), filter = {v}, mask = MASK_SHOT}
					local t2 = {start = v:GetPos() + Vector(0,0,10), endpos = v:GetPos()+Vector(0,0,-10000), filter = {v}, mask = MASK_SHOT}
					local traceup = util.TraceLine(t)
					local tracedown = util.TraceLine(t2)

					render.SetMaterial(Material("sprites/tp_beam001"))

					local centre = v:LocalToWorld(v:OBBCenter())

					render.DrawBeam(centre, traceup.HitPos, 10, 0, 0, team.GetColor(v:Team()))
					render.DrawBeam(centre, tracedown.HitPos, 10, 0, 0, team.GetColor(v:Team()))
				end
			end
		end)
		pk_ms_settings_table.VertBeam = !pk_ms_settings_table.VertBeam
	else
		hook.Remove("PostPlayerDraw", "pk_vertbeam")
		pk_ms_settings_table.VertBeam = !pk_ms_settings_table.VertBeam
	end
	pk_save_client_settings()
end
concommand.Add("pk_vertbeam", vertBeam)

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

local function roofTiles()
	if !pk_ms_settings_table.RoofTiles then
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
		pk_ms_settings_table.RoofTiles = !pk_ms_settings_table.RoofTiles
	else
		hook.Remove("PostDrawOpaqueRenderables", "ReplaceSkyBox")
		pk_ms_settings_table.RoofTiles = !pk_ms_settings_table.RoofTiles
	end
	pk_save_client_settings()
end
concommand.Add("pk_rooftiles", roofTiles)

local function removeSkybox()
	PK_SetConfig("RemoveSkybox", !PK.GetConfig("RemoveSkybox"))
end
concommand.Add("pk_removeskybox", removeSkybox)

function UseLerpCommand(ply, cmd, args)
	PK_SetConfig("UseLerpCommand", !PK.GetConfig("UseLerpCommand"))
end
concommand.Add("pk_cl_physics", UseLerpCommand)

local bhopEnabled = true

hook.Add("Think", "PK_Bhop", function()
	if not bhopEnabled then return end
	local Hopped = input.IsKeyDown(KEY_SPACE)
	local StopHop = vgui.CursorVisible()
	local LP = LocalPlayer()
	local MS = {}

	if( !StopHop and !MS.Spectating and MS.Hopping != Hopped ) then
		if(!Hopped) then RunConsoleCommand("-jump") end
		MS.Hopping = Hopped
	end

	if( MS.Hopping ) then
		if( StopHop ) then
			MS.Hopping = false
			RunConsoleCommand("-jump")
			return
		end
		if(LP:GetGroundEntity() != NULL or LP:WaterLevel() >0 or LP:GetMoveType() == MOVETYPE_NOCLIP or LP:InVehicle()) then
			RunConsoleCommand("+jump")
		else
			RunConsoleCommand("-jump")
		end
	end
end)

concommand.Add("pk_bhop", function()
	bhopEnabled = !bhopEnabled
	print("bhop " .. (bhopEnabled and "enabled" or "disabled"))
end)