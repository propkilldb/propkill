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
	font = "stb24",
	size = 48,
	weight = 650,
	antialias = true,
	shadow = true,
})

surface.CreateFont("pk_duelfont", {
	font = "stb24",
	size = 32,
	weight = 650,
	antialias = true,
	shadow = true,
})

hook.Add("HUDPaint", "PKHUD", function()
	local leader = GetGlobalString("PK_CurrentLeader", "Nobody")
	surface.SetFont("stb24")
	local name = "Leader: " .. leader
	local lw, lh = surface.GetTextSize(name)
	draw.RoundedBox(3, 2.5, ScrH() - 34, lw + 15, 33, Color(24, 24, 24, 150))
	draw.SimpleText(name, "stb24", 10, ScrH() - 30, Color(255, 255, 255, 200), 0, 0)
	
	if LocalPlayer():Team() == TEAM_SPECTATOR and IsValid(LocalPlayer():GetObserverTarget()) then
		local name = "Spectating: " .. tostring(LocalPlayer():GetObserverTarget():GetName())
		local sw, sh = surface.GetTextSize(name)
		draw.RoundedBox(3, lw + 21, ScrH() - 34, sw + 20, 33, Color(24, 24, 24, 150))
		draw.SimpleText(name , "stb24", lw + 30, ScrH() - 30, Color(255, 255, 255, 200), 0, 0)
	end

	if timer.Exists("hudmsg") then
		draw.SimpleText(hudmsg, "spec_font1", ScrW()/2, ScrH()/6, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	if GetGlobalBool("Warmup") then
		draw.SimpleText("Warm Up", "spec_font1", ScrW()/2, ScrH()/4, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
end)

if duelhud then duelhud:Remove() end
duelhud = vgui.Create("DPanel")
duelhud:SetSize(1000, 70)
duelhud:SetPos(ScrW()/2 - (duelhud:GetWide()/2), 0)
function duelhud:Paint(w, h)
	if not IsValid(LocalPlayer()) then return end
	local target = IsValid(LocalPlayer():GetObserverTarget()) and LocalPlayer():GetObserverTarget() or LocalPlayer()
	local arena = target:GetNWString("arena", "0")
	if not IsValid(target) or arena == "0" then return end

	local kills = GetGlobalInt(arena .. "kills", 0)
	local player1 = GetGlobalEntity(arena .. "player1", NULL)
	local player2 = GetGlobalEntity(arena .. "player2", NULL)

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

local BlockedHUDElements = {CHudHealth = true, CHudBattery = true, CHudAmmo = true, CHudSecondaryAmmo = true, CHudWeaponSelection = true}

function GM:HUDShouldDraw(name)
	if BlockedHUDElements[name] then
		return false
	end
	return true
end

function GM:HUDDrawTargetID()
	if LocalPlayer():Team() == TEAM_SPECTATOR then
		return false
	end
end

function PK_DuelHUD()
	if GetGlobalBool("PK_Dueling") then
		draw.SimpleText(GetGlobalInt("PK_ply1_score") .. "-" .. GetGlobalInt("PK_ply2_score"), "spec_font1", ScrW()/2, 20, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
end
hook.Add("HUDPaint", "PK_Duel_HUD", PK_DuelHUD)