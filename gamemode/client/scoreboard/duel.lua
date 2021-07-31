local PANEL = {}
PANEL.Base = "DPanel"

function PANEL:Init()
	self:Dock(FILL)

	self.opponentselect = vgui.Create("DComboBox", self)
	self.opponentselect:Dock(TOP)
	self.opponentselect:SetSize(100, 20)
	self.opponentselect:SetValue("Select opponent")

	self.duelinvitebutton = vgui.Create("DButton", self)
	self.duelinvitebutton:SetText("Send Invite")
	self.duelinvitebutton:Dock(TOP)
	self.duelinvitebutton:SetSize(250, 30)
	self.duelinvitebutton.DoClick = function()
		local nick, opponent = self.opponentselect:GetSelected()
		if not IsValid(opponent) then return end

		net.Start("pk_duelinvite")
			net.WriteEntity(opponent)
			net.WriteInt(15, 8) // kills
			net.WriteInt(10, 8) // time in minutes
		net.SendToServer()

		/*self.duelinvitebutton:SetEnabled(false)

		timer.Create("PK_duelinvitebutton", 60, 1, function()
			if IsValid(self.duelinvitebutton) then
				self.duelinvitebutton:SetEnabled(true)
			end
		end)*/
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

	if timer.Exists("PK_duelinvitebutton") then
		self.duelinvitebutton:SetEnabled(false)
	end

end

function PANEL:Paint(w, h)
	
end

return PANEL