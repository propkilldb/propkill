local PANEL = {}
PANEL.Base = "DPanel"

function PANEL:Init()
	local columns = vgui.Create("DPanel", self)
	columns:SetHeight(30)
	columns:DockMargin(0,0,0,3)
	columns:Dock(TOP)
	function columns:Paint(w, h)
		draw.RoundedBox(4, 0, 0, w, h, PK.colors.primary)
	end

	local col1 = vgui.Create("DPanel", columns)
	col1:Dock(LEFT)
	function col1:Paint(w, h)
		draw.SimpleText("Name", "pk_playerrow", 15, h/2, PK.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local col2 = vgui.Create("DPanel", columns)
	col2:Dock(LEFT)
	function col2:Paint(w, h)
		draw.SimpleText("Kills", "pk_playerrow", 0, h/2, PK.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local col3 = vgui.Create("DPanel", columns)
	col3:Dock(LEFT)
	function col3:Paint(w, h)
		draw.SimpleText("Deaths", "pk_playerrow", 0, h/2, PK.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local col4 = vgui.Create("DPanel", columns)
	col4:Dock(LEFT)
	function col4:Paint(w, h)
		draw.SimpleText("ELO", "pk_playerrow", 0, h/2, PK.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local col5 = vgui.Create("DPanel", columns)
	col5:Dock(LEFT)
	function col5:Paint(w, h)
		draw.SimpleText("Ping", "pk_playerrow", 0, h/2, PK.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local scroll = vgui.Create("DScrollPanel", self)
	scroll:Dock(FILL)
	scroll.VBar:SetWidth(8)
	scroll.VBar:SetHideButtons(true)
	function scroll.VBar.btnGrip:Paint(w,h)
		draw.RoundedBox(4, 0, 0, w, h, PK.colors.accent)
	end
	function scroll.VBar:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, PK.colors.primary)
	end

	function columns:PerformLayout()
		local colwidth = self:GetWide()+4

		if scroll.VBar.Enabled then
			colwidth = colwidth - 8
		end

		col1:SetWidth(colwidth * 0.52)
		col2:SetWidth(colwidth * 0.12)
		col3:SetWidth(colwidth * 0.12)
		col4:SetWidth(colwidth * 0.12)
		col5:SetWidth(colwidth * 0.12+4)
	end

	self.teams = vgui.Create("DIconLayout", scroll)
	self.teams:Dock(FILL)
	self.teams:SetSpaceX(3)
	self.teams:SetSpaceY(3)

	self:Refresh()

	self.teams:InvalidateChildren(true)

	function self.teams:OnSizeChanged(w, h)
		self:InvalidateChildren(true)
	end

	self.arenas = vgui.Create("DHorizontalScroller", self)
	self.arenas:SetHeight(35)
	self.arenas:DockMargin(0, 4, 0, 0)
	self.arenas:Dock(BOTTOM)
	self.arenas:SetOverlap(-4)
	function self.arenas:Paint(w, h)
		draw.RoundedBox(4, 0, 0, w, h, PK.colors.primaryAlt)
	end
end

function PANEL:Paint(w, h)

end

function PANEL:Refresh()
	self:RefreshScoreboard()
	self:RefreshArenas()
end

function PANEL:RefreshScoreboard()
	if not IsValid(self.teams) then return end

	for k,v in pairs(self.teams:GetChildren()) do
		v:Remove()
	end

	for k,v in pairs(team.GetAllTeams()) do
		if k > 1000 or k < 1 then continue end
		if #team.GetPlayers(k) == 0 then continue end

		local item = self.teams:Add("DPanel")
		function item:Paint(w, h)
			draw.RoundedBox(4, 0, 0, w, h, PK.colors.primary)
		end

		local teamname = vgui.Create("DPanel", item)
		teamname:Dock(TOP)
		function teamname:Paint(w, h)
			draw.SimpleText(v.Name or "", "pk_teamfont", 8, h/2, v.Color or Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local players = vgui.Create("DIconLayout", item)
		players:DockMargin(5,0,5,0)
		players:DockPadding(0,0,0,5)
		players:Dock(TOP)
		players:SetSpaceY(3)
		function players:Paint(w, h) end

		for kk,vv in pairs(team.GetPlayers(k)) do
			local prow = players:Add("DPanel")
			prow:SetHeight(36)
			function prow:Paint(w, h)
				draw.RoundedBox(4, 0, 0, w, h, PK.colors.primaryDark)
			end

			local avatar = vgui.Create("AvatarImage", prow)
			avatar:SetSize(28, 28)
			avatar:DockMargin(4,4,0,4)
			avatar:Dock(LEFT)
			avatar:SetSteamID(util.SteamIDTo64(vv:SteamID()), 28)
			avatar.button = vgui.Create("DButton", avatar)
			avatar.button:Dock(FILL)
			avatar.button:SetText("")
			function avatar.button:Paint() end
			function avatar.button:DoClick()
				if not vv:IsBot() then
					vv:ShowProfile()
				end
			end

			local name = vgui.Create("DButton", prow)
			name:Dock(LEFT)
			function name:Paint(w, h)
				if not IsValid(vv) then PK.menu:Show() return end
				draw.SimpleText(vv:Name() or "", "pk_playerfont", 10, h/2, vv:Alive() and PK.colors.text or Color(100,100,100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			local kills = vgui.Create("DButton", prow)
			kills:Dock(LEFT)
			function kills:Paint(w, h)
				if not IsValid(vv) then return end
				draw.SimpleText(vv:Frags() or "", "pk_playerfont", 10, h/2, PK.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			local deaths = vgui.Create("DButton", prow)
			deaths:Dock(LEFT)
			function deaths:Paint(w, h)
				if not IsValid(vv) then return end
				draw.SimpleText(vv:Deaths() or "", "pk_playerfont", 10, h/2, PK.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			local elo = vgui.Create("DButton", prow)
			elo:Dock(LEFT)
			function elo:Paint(w, h)
				if not IsValid(vv) then return end
				draw.SimpleText(vv:GetNWInt("Elo") or "", "pk_playerfont", 10, h/2, PK.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			local ping = vgui.Create("DButton", prow)
			ping:Dock(LEFT)
			function ping:Paint(w, h)
				if not IsValid(vv) then return end
				draw.SimpleText(vv:Ping() or "", "pk_playerfont", 10, h/2, PK.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			function prow:PerformLayout()
				local colwidth = self:GetParent():GetWide()

				self:SetWidth(colwidth)
				name:SetWidth((colwidth - 64) * 0.52)
				kills:SetWidth(colwidth * 0.12)
				deaths:SetWidth(colwidth * 0.12)
				elo:SetWidth(colwidth * 0.12)
				ping:SetWidth(colwidth * 0.12)
			end

			for k,v in pairs(prow:GetChildren()) do
				v:SetText("")
				v.DoRightClick = function()
					if vv == LocalPlayer() then return end

					local right = vgui.Create("DMenu", v)
					local arena = vv:GetNWString("arena")

					right:AddOption("Profile", function()
						if not vv:IsBot() then
							vv:ShowProfile()
						end
					end)
					if IsValid(PK.arenas[arena]) and LocalPlayer():GetNWString("arena") != arena then
						right:AddOption("Join", function()
							net.Start("PK_ArenaNetJoinArena")
								net.WriteString(vv:GetNWString("arena"))
							net.SendToServer()
						end)
					end
					right:AddOption("Spectate", function()
						net.Start("PK_SpectatePlayer")
							net.WriteEntity(vv)
						net.SendToServer()
					end)
					right:AddOption("Duel", function()
						GAMEMODE.ScoreboardShow(GAMEMODE, "Duel", vv)
					end)
					right:AddOption((vv:IsMuted() and "Unmute" or "Mute"), function()
						vv:SetMuted(not vv:IsMuted())
					end)

					right:Open()
				end
				v.DoClick = v.DoRightClick
			end
		end

		function item:PerformLayout()
			local colwidth = self:GetParent():GetWide()

			teamname:SetSize(colwidth, 32)
			players:Layout()

			self:SizeToChildren(true, true)
		end

	end
end

function PANEL:RefreshArenas()
	if not IsValid(self.arenas) then return end

	for k,v in pairs(self.arenas.Panels) do
		v:Remove()
	end

	for k,v in pairs(table.Merge({global = {name = "Global", players = {1}}}, PK.arenas)) do
		if table.Count(v.players) < 1 then continue end

		local arenabtn = vgui.Create("DButton", self.arenas)
		arenabtn:DockMargin(0,0,4,0)
		arenabtn:Dock(LEFT)
		arenabtn:SetFont("pk_playerfont")
		arenabtn:SetText(v.name or "")
		arenabtn:SetWidth(arenabtn:GetTextSize() + 20)
		arenabtn:SetTextColor(PK.colors.text)
		arenabtn.arenaid = k
		function arenabtn:Paint(w, h)
			local col = PK.colors.primary
			if LocalPlayer():GetNWString("arena") == self.arenaid then
				col = PK.colors.secondary
			elseif PK.selectedarena == self.arenaid then
				col = PK.colors.primaryDark
			end
			draw.RoundedBox(4, 0, 0, w, h, col)
		end
		arenabtn.DoClick = function(this)
			PK.selectedarena = this.arenaid
			self:RefreshScoreboard()
		end

		self.arenas:AddPanel(arenabtn)
	end
end

return PANEL
