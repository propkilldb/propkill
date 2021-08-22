local PANEL = {}
PANEL.Base = "DPanel"

function PANEL:Init()
	self:Dock(FILL)

	self.opponentselect = vgui.Create("DComboBox", self)
	self.opponentselect:Dock(TOP)
	self.opponentselect:SetSize(100, 20)
	self.opponentselect:SetValue("Select opponent")

	/*local ktpanel = vgui.Create("DPanel", self)
	ktpanel:Dock(TOP)
	ktpanel:SetSize(100, 20)*/


	local numkills = vgui.Create("DNumSlider", self)
	numkills:Dock(TOP)
	numkills:SetSize(100, 20)
	numkills:SetDecimals(0)
	numkills:SetMin(1)
	numkills:SetMax(60)
	numkills:SetValue(15)
	numkills:SetText("Kills")
	numkills:InvalidateLayout()

	function numkills:PerformLayout(w, h)
		self.Label:SetWide(30)
		self.Scratch:SetWide(50)
		self.Label:Dock(LEFT)
		self.Scratch:Dock(LEFT)
	end

	local numtime = vgui.Create("DNumSlider", self)
	numtime:Dock(TOP)
	numtime:SetSize(100, 20)
	numtime:SetDecimals(0)
	numtime:SetMin(1)
	numtime:SetMax(30)
	numtime:SetValue(10)
	numtime:SetText("Time")
	numtime:InvalidateLayout()

	function numtime:PerformLayout(w, h)
		self.Label:SetWide(30)
		self.Scratch:SetWide(50)
		self.Label:Dock(LEFT)
		self.Scratch:Dock(LEFT)
	end

	local duelinvitebutton = vgui.Create("DButton", self)
	duelinvitebutton:SetText("Send Invite")
	duelinvitebutton:Dock(TOP)
	duelinvitebutton:SetSize(250, 30)
	duelinvitebutton.DoClick = function()
		local nick, opponent = self.opponentselect:GetSelected()
		if not IsValid(opponent) then return end

		net.Start("pk_duelinvite")
			net.WriteEntity(opponent)
			net.WriteInt(numkills:GetValue() or 15, 8) // kills
			net.WriteInt(numtime:GetValue() or 10, 8) // time in minutes
		net.SendToServer()

	end

	self:Refresh()
end

function PANEL:Refresh()
	self.opponentselect:Clear()

	for k,v in pairs(player.GetAll()) do
		if v != LocalPlayer() then
			self.opponentselect:AddChoice(v:Nick(), v)
		end
	end
end

function PANEL:Paint(w, h)
	
end

return PANEL