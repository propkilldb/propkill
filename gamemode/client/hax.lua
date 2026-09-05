-- ----------------------------------------------------
-- Module setup
-- ----------------------------------------------------
local UseMaterial = CreateMaterial("WallMaterial3", "VertexLitGeneric", {
	["$basetexture"] = "Models/Debug/debugwhite",
	["$nocull"] = 1,
	["$model"] = 1,
})

local Menu
local props = {}
local LP = LocalPlayer()
local MANUAL_DRAW = 512
local installed = false

CreateClientConVar("ms_enable", "1", true, false, "enable/disable builtin cheats")

surface.CreateFont("ass", {
	font = "coolvetica",
	size = 20,
	antialias = true
})

local ENTITY = FindMetaTable("Entity")
local MS = {
	PlayerWalls = true,
	PropWalls = true,
	WallsAlwaysSolid = true,
	ESP = true,
	Boxes = false,
	BHop = true,
	FOV = GetConVar("fov_desired"):GetInt(),
	PlayerOpacity = 95,
	PlayerColour = { 1, 1, 1 },
	PropOpacity = 30,
	PropNormalColour = { 0, 1, 0 },
	PropWallOpacity = 30
}

-- ----------------------------------------------------
-- Settings
-- ----------------------------------------------------
local function LoadData()
	local Data = sql.Query("SELECT * FROM MS_Settings")

	for k, v in pairs(Data) do
		local NewData
		if (v.Value == "true") then
			NewData = true
		elseif (v.Value == "false") then
			NewData = false
		elseif (string.find(v.Value, "|")) then
			local tbl = string.Explode("|", v.Value)
			NewData = tbl
		elseif (tonumber(v.Value)) then
			NewData = tonumber(v.Value)
		else
			NewData = v.Value
		end

		MS[v.Setting] = NewData
	end
end

local function SaveData()
	for k, v in pairs(MS) do
		local Key = tostring(k)
		local Query = sql.Query(string.format("SELECT * FROM MS_Settings WHERE Setting = '%s'", Key))
		local Data = ""
		if (type(v) == "table") then
			for k2, v2 in pairs(v) do
				Data = Data .. tostring(v2) .. "|"
			end
			Data = string.Left(Data, string.len(Data) - 1)
		else
			Data = tostring(v)
		end

		if (Query) then
			sql.Query(string.format("UPDATE MS_Settings SET Value = '%s' WHERE Setting = '%s'", Data, Key))
		else
			sql.Query(string.format("INSERT INTO MS_Settings('Setting', 'Value') VALUES( '%s', '%s' )", Key, Data))
		end
	end
end

if (sql.TableExists("MS_Settings")) then
	LoadData()
else
	sql.Query("CREATE TABLE MS_Settings( Setting varchar(255), Value varchar(255) )")
	SaveData()
end

-- ----------------------------------------------------
-- Entity helpers
-- ----------------------------------------------------
function ENTITY:IsProp()
	return self:GetClass() == "prop_physics"
end

-- ----------------------------------------------------
-- Wallhack
-- ----------------------------------------------------
local function PropRenderOverride(self, flag)
	if flag != MANUAL_DRAW then return end
	if not MS.PropWalls then return end

	cam.IgnoreZ(true)
	render.SuppressEngineLighting(true)
	render.SetBlend(MS.PropWallOpacity / 100)
	render.SetColorModulation(unpack(MS.PropNormalColour))
	render.MaterialOverride(UseMaterial)

	self:DrawModel()

	render.MaterialOverride(nil)
	render.SuppressEngineLighting(false)
	cam.IgnoreZ(false)
end

local function DoMaterialCheckSingle(ent)
	if not ent:IsProp() then return end
	
	if MS.PropWalls then
		ent.RenderOverride = PropRenderOverride
		props[ent] = true
	else
		ent.RenderOverride = nil
		props[ent] = nil
	end
end

local function MSPropRemoved(ent, fullUpdate)
	if fullUpdate or not ent:IsProp() then return end
	props[ent] = nil
end

local function DoMaterialCheck()
	for _, ent in ipairs(ents.GetAll()) do
		DoMaterialCheckSingle(ent)
	end
end

local function Wallhack()
	local PlayerColor = MS.PlayerColour

	cam.Start3D(EyePos(), EyeAngles())
		cam.IgnoreZ(true)
		render.MaterialOverride(UseMaterial)
		render.SuppressEngineLighting(true)

		if (MS.PlayerWalls and MS.PlayerOpacity) then
			render.SetBlend(MS.PlayerOpacity / 100)
			render.SetColorModulation(PlayerColor[1], PlayerColor[2], PlayerColor[3])
			for k, v in pairs(player.GetAll()) do
				if v:GetObserverMode() != OBS_MODE_NONE then continue end
				if (IsValid(v) and v:Alive() and v:GetMoveType() ~= 0) then
					v:DrawModel()
				end
			end
		end

		cam.IgnoreZ(false)

		if (not MS.WallsAlwaysSolid) then
			if (MS.PlayerWalls) then
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				render.MaterialOverride(nil)
				for k, v in pairs(player.GetAll()) do
					if v:GetObserverMode() != OBS_MODE_NONE then continue end
					if (IsValid(v) and v:GetMoveType() ~= 0 and v:Alive()) then
						v:DrawModel()
					end
				end
			end
		end
		
		for ent, _ in next, props do
			if ent:IsDormant() then continue end
			ent:DrawModel(MANUAL_DRAW)
		end

		render.MaterialOverride(nil)
		render.SetColorModulation(1, 1, 1)
		render.SetBlend(1)
		cam.IgnoreZ(false)
		render.SuppressEngineLighting(false)
	cam.End3D()
end

local function TogglePropChams()
	MS.PropWalls = not MS.PropWalls
	DoMaterialCheck()
end

local function TogglePlayerChams()
	MS.PlayerWalls = not MS.PlayerWalls
	DoMaterialCheck()
end

-- ----------------------------------------------------
-- HUD
-- ----------------------------------------------------
local function InvertColour(c)
	return Color(255 - c.r, 255 - c.g, 255 - c.b, 255)
end

local function HUDPaint()
	local PlayerColor = MS.PlayerColour
	local PropColor = MS.PropNormalColour

	for k, v in pairs(player.GetAll()) do
		if (not IsValid(v) or v == LP or not v:Alive() or v:GetObserverMode() != OBS_MODE_NONE) then continue end
		local pos = (v:GetShootPos() + Vector(0, 0, 10)):ToScreen()

		if (MS.ESP) then
			draw.SimpleTextOutlined(string.upper(v:Nick()), "ass", pos.x, pos.y - 16, team.GetColor(v:Team()), 1, 1, 1, InvertColour(team.GetColor(v:Team())))
		end

		if (MS.Boxes) then
			cam.Start3D()
			render.DrawWireframeBox(v:GetPos(), v:GetAngles(), v:OBBMins(), v:OBBMaxs(), Color(PlayerColor[1] * 255, PlayerColor[2] * 255, PlayerColor[3] * 255), true)
			cam.End3D()
		end
	end
end

-- ----------------------------------------------------
-- FOV
-- ----------------------------------------------------
local function CalcView(ply, pos, angles, fov)
	local view = {
		fov = MS.FOV
	}

	return view
end

-- ----------------------------------------------------
-- Jump
-- ----------------------------------------------------
local dojump = false

local function JumpHook(cmd)
	if cmd:CommandNumber() == 0 then return end

	if LP:InVehicle() or LP:GetMoveType() != MOVETYPE_WALK or LP:WaterLevel() > 0 then
		dojump = false
		return
	end

	local wantJump = dojump or (MS.BHop and cmd:KeyDown(IN_JUMP))
	if not wantJump then return end

	if LP:IsOnGround() then
		dojump = false
		cmd:AddKey(IN_JUMP)
	else
		cmd:RemoveKey(IN_JUMP)
	end
end

-- ----------------------------------------------------
-- Rotate
-- ----------------------------------------------------
local function Rotate180()
	local E = LP:EyeAngles()
	LP:SetEyeAngles(Angle(E.p, E.y - 180, E.r))
end

local function Rotate180Up()
	local E = LP:EyeAngles()
	LP:SetEyeAngles(Angle(-E.p, E.y - 180, E.r))
	dojump = true
end

-- ----------------------------------------------------
-- Menu
-- ----------------------------------------------------
local function OpenMenu()
	if (IsValid(Menu)) then Menu:SetVisible(true) return end
	Menu = vgui.Create("DFrame")
	Menu:SetSize(275, 280)
	Menu:SetPos(ScrW() / 2 - 137.5, ScrH() / 2 - 140)
	Menu:ShowCloseButton(false)
	Menu:SetTitle("Minge Script - Noobler Version")
	Menu:MakePopup()
	Menu.Paint = function(self)
		draw.RoundedBox(2, 0, 0, self:GetWide(), self:GetTall(), Color(80, 80, 80, 260))
		draw.RoundedBox(0, 0, 20, self:GetWide(), 2, Color(120, 120, 120, 255))
	end

	local Panel = vgui.Create("DPanel", Menu)
	Panel:SetSize(267.5, 250)
	Panel:SetPos(4, 25)
	Panel.Paint = function(self)
		draw.RoundedBox(2, 0, 0, self:GetWide(), self:GetTall(), Color(60, 60, 60, 260))
	end

	local PWalls = vgui.Create("DCheckBoxLabel", Panel)
	PWalls:SetPos(5, 5)
	PWalls:SetText("Player Wallhack")
	PWalls:SizeToContents()
	PWalls:SetValue(MS.PlayerWalls)
	PWalls.OnChange = function(self, bVal)
		MS.PlayerWalls = bVal
		DoMaterialCheck()
	end

	local PWalls = vgui.Create("DCheckBoxLabel", Panel)
	PWalls:SetPos(130, 5)
	PWalls:SetText("Solid Walls Only")
	PWalls:SizeToContents()
	PWalls:SetValue(MS.WallsAlwaysSolid)
	PWalls.OnChange = function(self, bVal)
		MS.WallsAlwaysSolid = bVal
	end
	PWalls:SetToolTip("Makes Player/Prop wallhack ignore visibility")

	local POpacity = vgui.Create("DNumSlider", Panel)
	POpacity:SetPos(10, 20)
	POpacity:SetSize(250, 20)
	POpacity:SetMin(0)
	POpacity:SetMax(99)
	POpacity:SetText("Player Transperency")
	POpacity:SetValue(MS.PlayerOpacity)
	POpacity.OnValueChanged = function(self, val)
		MS.PlayerOpacity = val
	end

	local PRed = vgui.Create("DNumSlider", Panel)
	PRed:SetPos(10, 35)
	PRed:SetSize(250, 20)
	PRed:SetMin(0)
	PRed:SetMax(100)
	PRed:SetText("Player Red Colour")
	PRed:SetValue(MS.PlayerColour[1] * 100)
	PRed.OnValueChanged = function(self, val)
		MS.PlayerColour[1] = val / 100
	end

	local PGreen = vgui.Create("DNumSlider", Panel)
	PGreen:SetPos(10, 50)
	PGreen:SetSize(250, 20)
	PGreen:SetMin(0)
	PGreen:SetMax(100)
	PGreen:SetText("Player Green Colour")
	PGreen:SetValue(MS.PlayerColour[2] * 100)
	PGreen.OnValueChanged = function(self, val)
		MS.PlayerColour[2] = val / 100
	end

	local PBlue = vgui.Create("DNumSlider", Panel)
	PBlue:SetPos(10, 65)
	PBlue:SetSize(250, 20)
	PBlue:SetMin(0)
	PBlue:SetMax(100)
	PBlue:SetText("Player Blue Colour")
	PBlue:SetValue(MS.PlayerColour[3] * 100)
	PBlue.OnValueChanged = function(self, val)
		MS.PlayerColour[3] = val / 100
	end

	local PrWalls = vgui.Create("DCheckBoxLabel", Panel)
	PrWalls:SetPos(5, 95)
	PrWalls:SetText("Prop Wallhack")
	PrWalls:SizeToContents()
	PrWalls:SetValue(MS.PropWalls)
	PrWalls.OnChange = function(self, bVal)
		MS.PropWalls = bVal
		DoMaterialCheck()
	end

	local PrOpacity = vgui.Create("DNumSlider", Panel)
	PrOpacity:SetPos(10, 110)
	PrOpacity:SetSize(250, 20)
	PrOpacity:SetMin(0)
	PrOpacity:SetMax(99)
	PrOpacity:SetText("Prop Wall Opacity")
	PrOpacity:SetValue(MS.PropWallOpacity)
	PrOpacity.OnValueChanged = function(self, val)
		MS.PropWallOpacity = val
	end

	local PrOpacity = vgui.Create("DNumSlider", Panel)
	PrOpacity:SetPos(10, 125)
	PrOpacity:SetSize(250, 20)
	PrOpacity:SetMin(0)
	PrOpacity:SetMax(99)
	PrOpacity:SetText("Prop Base Opacity")
	PrOpacity:SetValue(MS.PropOpacity)
	PrOpacity.OnValueChanged = function(self, val)
		MS.PropOpacity = val
	end

	local PRed = vgui.Create("DNumSlider", Panel)
	PRed:SetPos(10, 140)
	PRed:SetSize(250, 20)
	PRed:SetMin(0)
	PRed:SetMax(100)
	PRed:SetDecimals(0)
	PRed:SetText("Prop Red Colour")
	PRed:SetValue(MS.PropNormalColour[1] * 100)
	PRed.OnValueChanged = function(self, val)
		MS.PropNormalColour[1] = val / 100
	end

	local PGreen = vgui.Create("DNumSlider", Panel)
	PGreen:SetPos(10, 155)
	PGreen:SetSize(250, 20)
	PGreen:SetMin(0)
	PGreen:SetMax(100)
	PGreen:SetDecimals(0)
	PGreen:SetText("Prop Green Colour")
	PGreen:SetValue(MS.PropNormalColour[2] * 100)
	PGreen.OnValueChanged = function(self, val)
		MS.PropNormalColour[2] = val / 100
	end

	local PBlue = vgui.Create("DNumSlider", Panel)
	PBlue:SetPos(10, 170)
	PBlue:SetSize(250, 20)
	PBlue:SetMin(0)
	PBlue:SetMax(100)
	PBlue:SetDecimals(0)
	PBlue:SetText("Prop Blue Colour")
	PBlue:SetValue(MS.PropNormalColour[3] * 100)
	PBlue.OnValueChanged = function(self, val)
		MS.PropNormalColour[3] = val / 100
	end

	local FOV = vgui.Create("DNumSlider", Panel)
	FOV:SetPos(10, 185)
	FOV:SetSize(250, 20)
	FOV:SetMin(1)
	FOV:SetMax(160)
	FOV:SetDecimals(0)
	FOV:SetText("FOV")
	FOV:SetValue(MS.FOV)
	FOV.OnValueChanged = function(self, val)
		MS.FOV = val
	end

	local ESP = vgui.Create("DCheckBoxLabel", Panel)
	ESP:SetValue(MS.ESP)
	ESP:SetText("Player ESP")
	ESP:SetPos(5, 210)
	ESP:SizeToContents()
	ESP.OnChange = function(self, bVal)
		MS.ESP = bVal
	end

	local Boxes = vgui.Create("DCheckBoxLabel", Panel)
	Boxes:SetValue(MS.Boxes)
	Boxes:SetText("Bounding Boxes")
	Boxes:SetPos(130, 210)
	Boxes:SizeToContents()
	Boxes.OnChange = function(self, bVal)
		MS.Boxes = bVal
	end

	local BHop = vgui.Create("DCheckBoxLabel", Panel)
	BHop:SetValue(MS.BHop)
	BHop:SetText("Auto BHop")
	BHop:SetPos(5, 228)
	BHop:SizeToContents()
	BHop.OnChange = function(self, bVal)
		MS.BHop = bVal
	end
end

local function CloseMenu()
	SaveData()
	Menu:SetVisible(false)
end

-- ----------------------------------------------------
-- Lifecycle
-- ----------------------------------------------------
local function Install()
	if installed then return end
	installed = true
	LP = LocalPlayer()

	RunConsoleCommand("cl_drawspawneffect", 0)

	hook.Add("EntityRemoved", "MSPropListRemove", MSPropRemoved)
	hook.Add("NetworkEntityCreated", "MSEntityCreated", DoMaterialCheckSingle)
	hook.Add("InitPostEntity", "MSInitialiseEntites", DoMaterialCheck)
	hook.Add("PreDrawHUD", "MSRender", Wallhack)
	hook.Add("HUDPaint", "MSHUDPaint", HUDPaint)
	hook.Add("CalcView", "MSCalcView", CalcView)
	hook.Add("CreateMove", "MSJump", JumpHook)

	concommand.Add("ms_rotate", Rotate180)
	concommand.Add("ms_rotate2", Rotate180Up)
	concommand.Add("+ms_menu", OpenMenu)
	concommand.Add("-ms_menu", CloseMenu)
	concommand.Add("ms_propchams", TogglePropChams)
	concommand.Add("ms_playerchams", TogglePlayerChams)

	DoMaterialCheck()
end

local function Uninstall()
	if not installed then return end
	installed = false
	dojump = false

	hook.Remove("EntityRemoved", "MSPropListRemove")
	hook.Remove("NetworkEntityCreated", "MSEntityCreated")
	hook.Remove("InitPostEntity", "MSInitialiseEntites")
	hook.Remove("PreDrawHUD", "MSRender")
	hook.Remove("HUDPaint", "MSHUDPaint")
	hook.Remove("CalcView", "MSCalcView")
	hook.Remove("CreateMove", "MSJump")

	concommand.Remove("ms_rotate")
	concommand.Remove("ms_rotate2")
	concommand.Remove("+ms_menu")
	concommand.Remove("-ms_menu")
	concommand.Remove("ms_propchams")
	concommand.Remove("ms_playerchams")

	for ent in pairs(props) do
		if IsValid(ent) then
			ent.RenderOverride = nil
		end
	end
	table.Empty(props)

	if IsValid(Menu) then
		Menu:Remove()
		Menu = nil
	end
end

local function SetEnabled(on)
	if on then
		Install()
	else
		Uninstall()
	end
end

cvars.AddChangeCallback("ms_enable", function(name, old, new)
	SetEnabled(tonumber(new) ~= 0)
end)

hook.Add("InitPostEntity", "MSInstaller", function()
	if GetConVar("ms_enable"):GetBool() == true then
		Install()
	end
end)
