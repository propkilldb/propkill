local PANEL = {}
PANEL.Base = "DHorizontalDivider"

local function AddPanelTitle(panel, text)
	local titleLabel = vgui.Create("DLabel", panel)
	titleLabel:SetText(text)
	titleLabel:SetFont("DermaDefaultBold")
	titleLabel:SetContentAlignment(5)
	titleLabel:Dock(TOP)
	titleLabel:SetTall(20)
	titleLabel:DockMargin(0, 0, 0, 5)
end

local function CreatePlayerSetupControls(panelInstance, parentControl, idPrefix, playerNumText)
	panelInstance[idPrefix .. "select"] = vgui.Create("DComboBox", parentControl)
	panelInstance[idPrefix .. "select"]:Dock(TOP)
	panelInstance[idPrefix .. "select"]:SetValue("Select Player " .. playerNumText)

	local playerScoreSlider = vgui.Create("DNumSlider", parentControl)
	playerScoreSlider:Dock(TOP)
	playerScoreSlider:SetDecimals(0)
	playerScoreSlider:SetMin(0)
	playerScoreSlider:SetMax(60)
	playerScoreSlider:SetValue(0)
	playerScoreSlider:SetText("Start Score")
	function playerScoreSlider:PerformLayout(w, h)
		self.Label:SizeToContentsX()
		self.Scratch:SetWide(50)
		self.Label:Dock(LEFT)
		self.Scratch:Dock(LEFT)
	end
	panelInstance[idPrefix .. "score"] = playerScoreSlider
end

local function CreateSettingsNumSlider(parentControl, text, minVal, maxVal, defaultVal, labelWidth)
	local numSlider = vgui.Create("DNumSlider", parentControl)
	numSlider:Dock(TOP)
	numSlider:SetDecimals(0)
	numSlider:SetMin(minVal)
	numSlider:SetMax(maxVal)
	numSlider:SetValue(defaultVal)
	numSlider:SetText(text)
	function numSlider:PerformLayout(w, h)
		self.Label:SetWide(labelWidth or 30)
		self.Scratch:SetWide(50)
		self.Label:Dock(LEFT)
		self.Scratch:Dock(LEFT)
	end
	return numSlider
end

local function CreateButton(parent, text, netMessageName, callback)
	local btn = vgui.Create("DButton", parent)
	btn:SetText(text)
	btn:Dock(TOP)
	btn:SetTall(25)
	btn:DockMargin(0, 2, 0, 0)
	btn.DoClick = function()
		net.Start(netMessageName)
		if callback then
			callback()
		end
		net.SendToServer()
	end
	return btn
end

local function CreateSectionHeader(parent, text)
	local header = vgui.Create("DLabel", parent)
	header:SetText(text)
	header:SetFont("DermaDefaultBold")
	header:Dock(TOP)
	header:SetTall(15)
	header:SetContentAlignment(4)
	header:DockMargin(0, 10, 0, 2)
end

local function CreatePlayerManagementControlSection(panelInstance, parentPanelForControls, playerNumText, getPlayerFunc)
	local nameLabel = vgui.Create("DLabel", parentPanelForControls)
	nameLabel:SetText("Player " .. playerNumText .. ": N/A")
	nameLabel:Dock(TOP)
	nameLabel:SetTall(15)
	nameLabel:DockMargin(0, 2, 0, 0)
	panelInstance["p" .. playerNumText .. "NameLabel"] = nameLabel

	CreateButton(parentPanelForControls, "+1 Score P" .. playerNumText, "pk_duel_adjust_score", function()
		local ply = getPlayerFunc()
		net.WriteEntity(ply)
		net.WriteInt(1, 8)
	end)

	CreateButton(parentPanelForControls, "-1 Score P" .. playerNumText, "pk_duel_adjust_score", function()
		local ply = getPlayerFunc()
		net.WriteEntity(ply)
		net.WriteInt(-1, 8)
	end)

	CreateButton(parentPanelForControls, "Respawn P" .. playerNumText, "pk_duel_respawn_player", function()
		local ply = getPlayerFunc()
		net.WriteEntity(ply)
	end)
end


function PANEL:Init()
	self:Dock(FILL)
	self:SetDividerWidth(4)

	local overallLeftContainer = vgui.Create("DPanel", self)
	function overallLeftContainer:Paint() end

	self.challongeMatchSelect = vgui.Create("DComboBox", overallLeftContainer)
	self.challongeMatchSelect:Dock(TOP)
	self.challongeMatchSelect:SetValue("Loading Challonge matches...")
	self.challongeMatchSelect.OnSelect = function(this, idx, val, data)
		if data.player1steamid then
			for k, v in next, self.player1select.Data do
				if IsValid(v) and v:IsPlayer() then
					if data.player1steamid == v:SteamID64() then
						self.player1select:ChooseOptionID(k)
						break
					end
				end
			end
		else
			self.player1select:SetValue("SELECT: " .. data.player1)
		end

		if data.player2steamid then
			for k, v in next, self.player2select.Data do
				if IsValid(v) and v:IsPlayer() then
					if data.player2steamid == v:SteamID64() then
						self.player2select:ChooseOptionID(k)
						break
					end
				end
			end
		else
			self.player2select:SetValue("SELECT: " .. data.player2)
		end
	end

	local playerSetupPanelsContainer = vgui.Create("DPanel", overallLeftContainer)
	playerSetupPanelsContainer:Dock(TOP)
	playerSetupPanelsContainer:SetTall(75)
	function playerSetupPanelsContainer:Paint() end

	local player1SetupPanel = vgui.Create("DPanel", playerSetupPanelsContainer)
	player1SetupPanel:Dock(LEFT)
	AddPanelTitle(player1SetupPanel, "Player 1 Setup")
	function player1SetupPanel:Paint() end
	CreatePlayerSetupControls(self, player1SetupPanel, "player1", "1")

	local player2SetupPanel = vgui.Create("DPanel", playerSetupPanelsContainer)
	player2SetupPanel:Dock(FILL)
	AddPanelTitle(player2SetupPanel, "Player 2 Setup")
	function player2SetupPanel:Paint() end
	CreatePlayerSetupControls(self, player2SetupPanel, "player2", "2")

	function playerSetupPanelsContainer:PerformLayout(w, h)
		if IsValid(player1SetupPanel) then
			player1SetupPanel:SetWide(w / 2)
		end
	end

	local settingspanel = vgui.Create("DPanel", overallLeftContainer)
	settingspanel:Dock(TOP)
	settingspanel:SetTall(130)
	AddPanelTitle(settingspanel, "Match Settings")
	settingspanel:DockPadding(5, 10, 5, 5)
	function settingspanel:Paint() end

	local numkills = CreateSettingsNumSlider(settingspanel, "Kills", 1, 60, 15, 40)
	local numtime = CreateSettingsNumSlider(settingspanel, "Time", 1, 30, 20, 40)

	self.disableAlltalkCheck = vgui.Create("DCheckBoxLabel", settingspanel)
	self.disableAlltalkCheck:Dock(TOP)
	self.disableAlltalkCheck:SetText("Disable Alltalk During Match")
	self.disableAlltalkCheck:SetTall(20)
	self.disableAlltalkCheck:SetValue(0)

	local startMatchButton = vgui.Create("DButton", overallLeftContainer)
	startMatchButton:SetText("Start Match")
	startMatchButton:Dock(TOP)
	startMatchButton:SetTall(30)
	startMatchButton:DockMargin(0, 5, 0, 0)

	local rightpanel = vgui.Create("DPanel", self)
	rightpanel:DockPadding(5, 0, 5, 5)
	function rightpanel:Paint() end

	self:SetLeft(overallLeftContainer)
	self:SetRight(rightpanel)

	CreateSectionHeader(rightpanel, "Match Controls")
	CreateButton(rightpanel, "Pause/Resume Match", "pk_duel_pause_toggle")
	CreateButton(rightpanel, "Abort Match", "pk_duel_abort")
	CreateButton(rightpanel, "Toggle Alltalk", "pk_duel_toggle_alltalk")

	CreateSectionHeader(rightpanel, "Time Controls")
	CreateButton(rightpanel, "+10 Seconds", "pk_duel_adjust_time", function() net.WriteInt(10, 16) end)
	CreateButton(rightpanel, "-10 Seconds", "pk_duel_adjust_time", function() net.WriteInt(-10, 16) end)
	CreateButton(rightpanel, "+1 Minutes", "pk_duel_adjust_time", function() net.WriteInt(60, 16) end)
	CreateButton(rightpanel, "-1 Minutes", "pk_duel_adjust_time", function() net.WriteInt(-60, 16) end)

	local playerManagementContainer = vgui.Create("DPanel", rightpanel)
	playerManagementContainer:Dock(TOP)
	playerManagementContainer:SetTall(120)
	function playerManagementContainer:Paint() end

	local player1ManagementPanel = vgui.Create("DPanel", playerManagementContainer)
	player1ManagementPanel:Dock(LEFT)
	function player1ManagementPanel:Paint() end
	AddPanelTitle(player1ManagementPanel, "Player 1 Management")
	CreatePlayerManagementControlSection(self, player1ManagementPanel, "1", function() return GetGlobalEntity("player1", NULL) end)

	local player2ManagementPanel = vgui.Create("DPanel", playerManagementContainer)
	player2ManagementPanel:Dock(FILL)
	function player2ManagementPanel:Paint() end
	AddPanelTitle(player2ManagementPanel, "Player 2 Management")
	CreatePlayerManagementControlSection(self, player2ManagementPanel, "2", function() return GetGlobalEntity("player2", NULL) end)
	
	function playerManagementContainer:PerformLayout(w,h)
		if IsValid(player1ManagementPanel) then
			player1ManagementPanel:SetWide(w/2 - 2)
		end
	end

	startMatchButton.DoClick = function()
		local _, player1 = self.player1select:GetSelected()
		local _, player2 = self.player2select:GetSelected()
		local _, matchid = self.challongeMatchSelect:GetSelected()

		net.Start("pk_tournamentduel")
			net.WriteEntity(player1)
			net.WriteEntity(player2)
			net.WriteInt(numkills:GetValue() or 15, 8)
			net.WriteInt(numtime:GetValue() or 10, 8)
			net.WriteInt(self.player1score:GetValue() or 0, 8)
			net.WriteInt(self.player2score:GetValue() or 0, 8)
			net.WriteBool(self.disableAlltalkCheck:GetChecked())
			net.WriteInt((matchid or {}).matchid or 0, 32)
		net.SendToServer()
	end

	//self:RefreshData()
end

function PANEL:RefreshData()
	self.player1select:Clear()
	self.player2select:Clear()

	self.player1select:SetValue("Player 1")
	self.player2select:SetValue("Player 2")

	for _, ply in ipairs(player.GetAll()) do
		self.player1select:AddChoice(ply:Nick(), ply)
		self.player2select:AddChoice(ply:Nick(), ply)
	end

	local p1 = GetGlobalEntity("player1", NULL)
	if IsValid(self.p1NameLabel) then
		self.p1NameLabel:SetText("Player 1: " .. (IsValid(p1) and p1:Nick() or "N/A"))
	end

	local p2 = GetGlobalEntity("player2", NULL)
	if IsValid(self.p2NameLabel) then
		self.p2NameLabel:SetText("Player 2: " .. (IsValid(p2) and p2:Nick() or "N/A"))
	end

	net.Start("pk_get_challonge_matches")
	net.SendToServer()
	self.challongeMatchSelect:Clear()
	self.challongeMatchSelect:SetValue("Loading Challonge matches...")

	net.Receive("pk_get_challonge_matches", function()
		local matches = net.ReadTable()
		
		self.challongeMatchSelect:SetValue("Select Challonge match")
		for k, v in next, matches do
			if v.state != "open" then continue end
			self.challongeMatchSelect:AddChoice("Round " .. v.round .. " - " .. v.player1 .. " vs " .. v.player2, v)
		end
	end)
end

function PANEL:ApplySchemeSettings()
	local parentWide = self:GetParent():GetWide()
	if parentWide <= 0 then return end

	self:SetLeftWidth(parentWide / 2)
end

function PANEL:Paint(w, h)
end

return PANEL
