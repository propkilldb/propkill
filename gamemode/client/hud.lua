surface.CreateFont("stb24", {
	font = "Trebuchet24",
	size = 24,
	weight = 500,
	shadow = true,
})

surface.CreateFont("pk_duelvsfont", {
	font = "Verdana",
	size = 48,
	weight = 650,
	shadow = true,
})

surface.CreateFont("pk_duelfont", {
	font = "Verdana",
	size = 32,
	weight = 650,
	shadow = true,
})

surface.CreateFont("pk_hudfont", {
	font = "Verdana",
	size = 24,
	weight = 550,
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


local hudheight = 35
local hudinset = 3

if not IsValid(bottomhud) then
	bottomhud = vgui.Create("DIconLayout")
end
bottomhud:ParentToHUD()
bottomhud:SetSpaceX(hudinset)
bottomhud:SetSize(ScrW(), hudheight)
bottomhud:SetPos(hudinset, ScrH()-hudheight-hudinset)
function bottomhud:OnScreenSizeChanged()
	self:SetSize(ScrW(), hudheight)
	self:SetPos(hudinset, ScrH()-hudheight-hudinset)
end

PK.RegisterHudElement("infohud",
	-- create
	function(data)
		local element = bottomhud:Add("pk_hudelement")
		element:SetHeight(hudheight)
		element:SetFont("pk_hudfont")
		function element:Layout()
			bottomhud:Layout()
		end
		
		return element
	end,
	-- update
	function(panel, data)
		panel:SetName(PK.formatHudString(data.label))
		panel:SetValue(PK.formatHudString(data.value))
	end
)

PK.RegisterHudElement("duelhud",
	-- create
	function(data)
		local duelhud = vgui.Create("DPanel")
		duelhud:ParentToHUD()
		function duelhud:PerformLayout()
			self:SetSize(1000, 70)
			self:SetPos(ScrW()/2 - (self:GetWide()/2), 0)
		end
		function duelhud:OnScreenSizeChanged()
			self:InvalidateLayout()
		end

		function duelhud:Paint(w, h)
			local kills = GetGlobal2Int("kills", 0)
			local player1 = GetGlobal2Entity("player1", NULL)
			local player2 = GetGlobal2Entity("player2", NULL)

			if not IsValid(player1) or not IsValid(player2) then return end

			local p1score = player1:GetNW2Int("duelscore", 0)
			local p2score = player2:GetNW2Int("duelscore", 0)

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
			
			draw.DrawText(player1:Nick(), "pk_duelfont", w/2-60, 10, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
			draw.DrawText(player2:Nick(), "pk_duelfont", w/2+60, 10, Color(255, 255, 255), TEXT_ALIGN_LEFT)
			
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

		return duelhud
	end,
	-- update
	function(panel, data)
	end
)

-- todo: port this to server side
hook.Add("PK_ObserverTargetChanged", "spechud", function(target)
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
