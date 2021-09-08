/*------------------------------------------
					Fonts
------------------------------------------*/
surface.CreateFont( "team_font", {
	font = "Trebuchet24",
	size = 32,
	weight = 650,
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

surface.CreateFont( "menu_header_font", {
	font = "Trebuchet24",
	size = 48,
	weight = 650,
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

surface.CreateFont( "menu_subheader_font", {
	font = "Trebuchet24",
	size = 32,
	weight = 650,
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

surface.CreateFont( "loading_font", {
	font = "Default",
	size = 64,
	weight = 650,
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

/*------------------------------------------
				F1 Propkill Menu
------------------------------------------*/

function PKMenu()
	-------------------------------------------- HELP PANEL
	local mainframe = vgui.Create("DFrame")
	mainframe:SetSize(ScrW() - 200, ScrH() - 150)
	mainframe:Center()
	mainframe:ShowCloseButton(true)
	mainframe:SetDraggable(false)
	mainframe:SetTitle("Propkill Menu")
	function mainframe:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 170))
	end
	function mainframe:OnClose()
		mainframe:Remove()
	end
	mainframe:MakePopup()

	local sheet = vgui.Create("DPropertySheet", mainframe)
	sheet:Dock(FILL)
	sheet:SetPadding(0)
	function sheet:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 170))
	end

	local helppanel = vgui.Create("DPanel", sheet)
	helppanel:Dock(FILL)
	function helppanel:Paint(w, h)
		return
	end

	local html = vgui.Create("HTML", helppanel)
	html:StretchToParent(0,0,0,0)
	html:DockMargin( 0, 0, 0, 0 )
	html:OpenURL("http://steamcommunity.com/sharedfiles/filedetails/?id=572479773")
	sheet:AddSheet("Help", html, "icon16/html.png")
end

net.Receive("pk_helpmenu", PKMenu)

/*------------------------------------------
				F2 Team Select
------------------------------------------*/

local function RealTeams()
	local count = 0

	for k,v in pairs(team.GetAllTeams()) do
		if k < 1000 and k > 0 then
			count = count + 1
		end
	end
	return count
end

/*net.Receive("pk_teamselect", function()
	pk_cancloseteamselect = false
	hook.Add("Think", "pk_checkf2key", function()
		if !input.IsKeyDown(KEY_F2) then
			pk_cancloseteamselect = true
		end
   		if input.IsKeyDown(KEY_F2) and pk_cancloseteamselect then
   			if IsValid(pk_teamselectmenu) then
   				pk_teamselectmenu:Remove()
   			end
   			hook.Remove("Think", "pk_checkf2key")
   		end
	end)
	pk_teamselectmenu = vgui.Create("DFrame")
	pk_teamselectmenu:SetTitle("")
	pk_teamselectmenu:SetSize(ScrW()/2.5, ScrH())
	pk_teamselectmenu:AlignRight()
	pk_teamselectmenu:SetDraggable(false)
	pk_teamselectmenu:ShowCloseButton(false)
	function pk_teamselectmenu:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 150))
	end
	pk_teamselectmenu:MakePopup()

	local panel = vgui.Create("DPanel", pk_teamselectmenu)
	panel:SetSize(ScrW()/2.5, 150 * RealTeams())
	panel:Center()

	local tbl = {}

	for k,v in pairs(team.GetAllTeams()) do
		if k == 0 then continue end
		if k > 999 then return false end
		local btn = tbl[k]
		btn = vgui.Create("DButton", panel)
		btn:SetText(team.GetName(k))
		btn:Dock(TOP)
		btn:SetTextColor(Color(0,0,0))
		btn:SetFont("team_font")
		btn:SetSize(ScrW()/2.5, 150)

		if k == 0 then
			btn:SetText("Spectate")
			btn:Dock(BOTTOM)
		end

		function btn:DoClick()
			RunConsoleCommand("pk_team", tostring(k))
			pk_teamselectmenu:Remove()
		end
		function btn:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, team.GetColor(k))
		end
	end
	panel:Center()
end)*/

/*------------------------------------------
				Duel Invitation
------------------------------------------*/

function PK_DuelInviteMenu()
	sender = net.ReadEntity()
	surface.PlaySound("buttons/button17.wav")

	local mainframe = vgui.Create("DFrame")
	mainframe:SetSize(200, 200)
	mainframe:Center()
	mainframe:ShowCloseButton(true)
	mainframe:SetDraggable(false)
	mainframe:SetTitle("Duel Invitation")
	function mainframe:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 170))
	end
	function mainframe:OnClose()
		mainframe:Clear()
		timer.Destroy("PK_Update_Leaderboard_Rows")
		mainframe:Remove()
	end
	mainframe:MakePopup()

	local DLabel = vgui.Create("DLabel", mainframe)
	DLabel:Dock(TOP)
	DLabel:DockMargin(0,20,0,40)
	DLabel:SizeToContents()
	DLabel:SetText(sender:Nick() .. " has requested a duel!")

	local DermaButton = vgui.Create("DButton", mainframe)
	DermaButton:SetText("Accept")
	DermaButton:SetSize(100, 30)
	DermaButton:Dock(TOP)
	DermaButton.DoClick = function()
		net.Start("pk_acceptduel")
		net.SendToServer()
		mainframe:Remove()
	end

	local DermaButton = vgui.Create("DButton", mainframe)
	DermaButton:SetText("Decline")
	DermaButton:SetSize(100, 30)
	DermaButton:Dock(TOP)
	DermaButton.DoClick = function()
		net.Start("pk_declineduel")
		net.SendToServer()
		mainframe:Remove()
	end

end
net.Receive("pk_duelinvite", PK_DuelInviteMenu)