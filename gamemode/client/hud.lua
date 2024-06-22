surface.CreateFont( "stb24", {
	font = "Trebuchet24",
	size = 24,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
} )
surface.CreateFont( "ltb24", {
	font = "Trebuchet24",
	size = 64,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
} )

surface.CreateFont( "spec_font1", {
	font = "Default",
	size = 64,
	weight = 1000,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "spec_font2", {
	font = "Default",
	size = 16,
	weight = 1000,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "esp_font", {
	font = "CloseCaption_Bold",
	size = 12,
	weight = 550,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont("pk_duelvsfont", {
	font = "Verdana",
	size = 48,
	weight = 650,
	antialias = true,
	shadow = true,
})

surface.CreateFont("pk_duelfont", {
	font = "Verdana",
	size = 32,
	weight = 650,
	antialias = true,
	shadow = true,
})

surface.CreateFont("pk_hudfont", {
	font = "Verdana",
	size = 24,
	weight = 550,
	antialias = true,
	shadow = true,
})

local BlockedHUDElements = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudWeaponSelection = true,
}

function GM:HUDShouldDraw(name)
	if BlockedHUDElements[name] then
		return false
	end
	return true
end

if duelhud then duelhud:Remove() end
duelhud = vgui.Create("DPanel")
function duelhud:PerformLayout()
	self:SetSize(1000, 70)
	self:SetPos(ScrW()/2 - (self:GetWide()/2), 0)
end

function duelhud:Paint(w, h)
	if not IsValid(LocalPlayer()) then return end
	//local target = IsValid(LocalPlayer():GetObserverTarget()) and LocalPlayer():GetObserverTarget() or LocalPlayer()

	local kills = GetGlobalInt("kills", 0)
	local player1 = GetGlobalEntity("player1", NULL)
	local player2 = GetGlobalEntity("player2", NULL)

	if not IsValid(player1) or not IsValid(player2) then return end

	local p1score = player1:GetNWInt("duelscore", 0)
	local p2score = player2:GetNWInt("duelscore", 0)

	surface.SetDrawColor(80, 80, 80)
	if p1score > p2score then surface.SetDrawColor(33, 101, 230) end
	surface.DrawRect(0, 0, w/2, h)
	
	surface.SetDrawColor(80, 80, 80)
	if p2score > p1score then surface.SetDrawColor(33, 101, 230) end
	surface.DrawRect(w/2, 0, w/2, h)
	
	surface.SetDrawColor(48, 70, 120)
	draw.NoTexture()
	surface.DrawTexturedRectRotated(w/2-10, h, 80, 180, -15)
	
	draw.DrawText("vs", "pk_duelvsfont", w/2, 6, Color(255, 255, 255), TEXT_ALIGN_CENTER)
	
	draw.DrawText(player1:Nick() or "", "pk_duelfont", w/2-60, 10, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
	draw.DrawText(player2:Nick() or "", "pk_duelfont", w/2+60, 10, Color(255, 255, 255), TEXT_ALIGN_LEFT)
	
	draw.DrawText(p1score, "pk_duelfont", 20, 8, Color(255, 255, 255), TEXT_ALIGN_LEFT)
	draw.DrawText(p2score, "pk_duelfont", w-20, 8, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
	
	local width = math.floor((w-160)/2/kills)
	
	for i=1, kills do
		if i <= p1score then
			surface.SetDrawColor(255, 255, 255)
		else
			surface.SetDrawColor(50, 50, 50)
		end

		surface.DrawRect(w/2-60-width*i, 51, width-2, 5)
		
		if i <= p2score then
			surface.SetDrawColor(255, 255, 255)
		else
			surface.SetDrawColor(50, 50, 50)
		end
		
		surface.DrawRect(w/2+60+width*i-width, 51, width-2, 5)
	end
end

local hudheight = 35
local hudinset = 3

if bottomhud then bottomhud:Remove() end
bottomhud = vgui.Create("DIconLayout")
bottomhud:SetSpaceX(hudinset)
bottomhud:SetSize(ScrW(), hudheight)
bottomhud:SetPos(hudinset, ScrH()-hudheight-hudinset)
function bottomhud:Paint(w, h) end

hook.Add("OnScreenSizeChanged", "hudupdate", function()
	bottomhud:InvalidateLayout()
	bottomhud:SetSize(ScrW(), hudheight)
	bottomhud:SetPos(hudinset, ScrH()-hudheight-hudinset)
	duelhud:InvalidateLayout()
end)

local leaderhud = bottomhud:Add("pk_hudelement")
leaderhud:SetHeight(hudheight)
leaderhud:SetFont("pk_hudfont")
leaderhud:SetName("Leader")
leaderhud:SetValue("nobody (0)")
function leaderhud:Layout()
	bottomhud:Layout()
end
function leaderhud:SetLeader(ply, kills)
	if not IsValid(ply) or not ply:IsPlayer() then
		ply = NULL
		kills = 0
	end

	self:SetValue(string.format("%s (%d)", IsValid(ply) and ply:Nick() or "nobody", kills))
end
leaderhud:SetLeader(PK.GetNWVar("streakleader", NULL), PK.GetNWVar("streakkills", 0))

PK.SetNWVarProxy("streakleader", function(_, leader)
	if not ispanel(leaderhud) then return end

	leaderhud:SetLeader(leader, PK.GetNWVar("streakkills", 0))
end)

PK.SetNWVarProxy("streakkills", function(_, kills)
	if not ispanel(leaderhud) then return end

	leaderhud:SetLeader(PK.GetNWVar("streakleader", NULL), kills)
end)

function PrettyTime(seconds)
	local timestr = ""

	if seconds >= 60 then
		timestr = string.NiceTime(seconds) .. ", "
	end
	
	return timestr .. string.NiceTime(seconds % 60)
end

PK.SetNWVarProxy("fighttimer", function(_, timeleft)
	if timeleft == 0 then
		if ispanel(timelefthud) then
			timelefthud:Remove()
			timelefthud = nil
		end

		return
	end

	if not IsValid(timelefthud) then
		timelefthud = bottomhud:Add("pk_hudelement")
		timelefthud:SetHeight(hudheight)
		timelefthud:SetFont("pk_hudfont")
		timelefthud:SetName("Time Remaining")
		timelefthud:SetValue(PrettyTime(timeleft))
		function timelefthud:Layout()
			bottomhud:Layout()
		end

		return
	end

	timelefthud:SetValue(PrettyTime(timeleft))
end)

PK.SetNWVarProxy("onesurfmode", function(_, enabled)
	if not enabled then
		if ispanel(onesurfhud) then
			onesurfhud:Remove()
			onesurfhud = nil
		end

		return
	end

	if not IsValid(onesurfhud) then
		onesurfhud = bottomhud:Add("pk_hudelement")
		onesurfhud:SetHeight(hudheight)
		onesurfhud:SetFont("pk_hudfont")
		onesurfhud:SetName("Surfs")
		onesurfhud:SetValue(tostring(LocalPlayer():GetNW2Int("PKSurfs", 0)))
		function onesurfhud:Layout()
			bottomhud:Layout()
		end

		LocalPlayer():SetNW2VarProxy("PKSurfs", function(ent, name, old, new)
			if not ispanel(onesurfhud) then return end
			
			onesurfhud:SetValue(tostring(new))
		end)

		return
	end
end)

hook.Add("Think", "spechud", function()
	local target = LocalPlayer():GetObserverTarget()

	if not IsValid(target) then
		if ispanel(spectatorhud) then
			spectatorhud:Remove()
			spectatorhud = nil
		end

		return
	end

	if not IsValid(spectatorhud) then
		spectatorhud = bottomhud:Add("pk_hudelement")
		spectatorhud:SetHeight(hudheight)
		spectatorhud:SetFont("pk_hudfont")
		spectatorhud:SetName("Spectating")
		spectatorhud:SetValue(target:Nick())
		function spectatorhud:Layout()
			bottomhud:Layout()
		end
	end

	spectatorhud:SetValue(target:Nick())
end)

-- pasted from base gamemode to remove the health %
function GM:HUDDrawTargetID()
	if LocalPlayer():Team() == TEAM_SPECTATOR then return end

	local tr = util.GetPlayerTrace( LocalPlayer() )
	local trace = util.TraceLine( tr )
	if ( !trace.Hit ) then return end
	if ( !trace.HitNonWorld ) then return end

	local text = "ERROR"
	local font = "TargetID"

	if ( trace.Entity:IsPlayer() ) then
		text = trace.Entity:Nick()
	else
		--text = trace.Entity:GetClass()
		return
	end

	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )

	local MouseX, MouseY = input.GetCursorPos()

	if ( MouseX == 0 && MouseY == 0 || !vgui.CursorVisible() ) then

		MouseX = ScrW() / 2
		MouseY = ScrH() / 2

	end

	local x = MouseX
	local y = MouseY

	x = x - w / 2
	y = y + 25

	-- The fonts internal drop shadow looks lousy with AA on
	draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ) )
	draw.SimpleText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ) )
	draw.SimpleText( text, font, x, y, self:GetTeamColor( trace.Entity ) )
end
