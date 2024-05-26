
local PANEL = {}

AccessorFunc(PANEL, "namecolor", "NameColor", FORCE_COLOR)
AccessorFunc(PANEL, "valuecolor", "ValueColor", FORCE_COLOR)
AccessorFunc(PANEL, "textcolor", "TextColor", FORCE_COLOR)

function PANEL:Init()
	local this = self

	local lname = vgui.Create("DLabel", self)
	lname:SetFont("HudDefault")
	lname:SetColor(Color(255, 255, 255))
	lname:SetText("none")
	lname:SizeToContentsX(18)
	lname:SetContentAlignment(5)
	lname:Dock(LEFT)
	function lname:Paint(w, h)
		surface.SetDrawColor(this.namecolor or Color(0, 120, 255))
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(this.valuecolor or Color(60, 60, 60))
		draw.NoTexture()
		surface.DrawTexturedRectRotated(w+5, h/2, 10, h+10, -15)
	end

	local lvalue = vgui.Create("DLabel", self)
	lvalue:SetFont("HudDefault")
	lvalue:SetColor(Color(255, 255, 255))
	lvalue:SetText("none")
	lvalue:SizeToContentsX(18)
	lvalue:SetContentAlignment(5)
	lvalue:Dock(LEFT)
	function lvalue:Paint(w, h)
		surface.SetDrawColor(this.valuecolor or Color(60, 60, 60))
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(this.namecolor or Color(0, 120, 255))
		draw.NoTexture()
		surface.DrawTexturedRectRotated(-5, h/2, 10, h+10, -15)
	end

	self.lname = lname
	self.lvalue = lvalue
end

function PANEL:SetName(txt)
	self.lname:SetText(txt)
	self:Update()
end

function PANEL:SetValue(txt)
	self.lvalue:SetText(txt)
	self:Update()
end

function PANEL:SetFont(font)
	self.lname:SetFont(font)
	self.lvalue:SetFont(font)
	self:Update()
end

function PANEL:SetTextColor(col)
	self.lname:SetTextColor(col)
	self.lvalue:SetTextColor(col)
end

function PANEL:Update()
	self.lname:SizeToContentsX(18)
	self.lvalue:SizeToContentsX(18)
	self:GetParent():Layout()
end

function PANEL:PerformLayout(w, h)
	self:SizeToChildren(true, false)
	self:Layout()
end

function PANEL:Layout()
	-- for override
end

function PANEL:Paint(w, h)

end

vgui.Register("pk_hudelement", PANEL, "DPanel")

surface.CreateFont("pk_dueltitle", {
	font = "Verdana",
	size = 28,
	weight = 550,
	antialias = true,
	shadow = false,
})

surface.CreateFont("pk_duelbutton", {
	font = "Verdana",
	size = 24,
	weight = 550,
	antialias = true,
	shadow = false,
})

surface.CreateFont("pk_dueltext", {
	font = "Verdana",
	size = 23,
	weight = 550,
	antialias = true,
	shadow = true,
})

surface.CreateFont("pk_duelinfo", {
	font = "Verdana",
	size = 18,
	weight = 550,
	antialias = true,
	shadow = false,
})

PANEL = {}

function PANEL:Init()
	self:SetSize(375, 175)
	self:SetPos(50, 50)
	function self:Paint(w, h)
		surface.SetDrawColor(60,60,60,220)
		surface.DrawRect(20, 0, w-40, h-44)
	end

	local name = vgui.Create("DLabel", self)
	name:SetText("Duel invite")
	name:SetTall(self:GetTall()/4)
	name:SetContentAlignment(5)
	name:SetTextColor(Color(250, 250, 250))
	name:SetFont("pk_dueltitle")
	name:Dock(TOP)
	function name:Paint(w, h)
		surface.SetDrawColor(255,255,255,255)
		draw.NoTexture()
		surface.SetDrawColor(0, 100, 220)
		surface.DrawTexturedRectRotated(w/2, h/2, w-32, h+100, -8)
	end

	local info = vgui.Create("DPanel", self)
	info:SetTall(self:GetTall()/2)
	info:DockMargin(20,0,20,0)
	info:Dock(TOP)

	self.duelname = markup.Parse("<font=pk_dueltext><colour=240,240,240,255>loading...</colour></font>")
	self.duelinfo = markup.Parse("<font=pk_duelinfo><colour=240,240,240,255>loading...</colour></font>")

	function info:Paint(w, h)
		local this = self:GetParent()
		this.duelname:Draw(w/2, 22, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 255, TEXT_ALIGN_CENTER)
		this.duelinfo:Draw(w/2, h-10, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 255, TEXT_ALIGN_CENTER)
	end

	local accept = vgui.Create("DButton", self)
	accept:SetFont("pk_duelbutton")
	accept:SetText("Accept")
	accept:SetTextColor(Color(255,255,255))
	accept:SetWide(self:GetWide()/2)
	accept:DockMargin(4,4,4,4)
	accept:Dock(LEFT)
	function accept:Paint(w, h)
		if self:IsHovered() then
			surface.SetDrawColor(60, 240, 60)
		else
			surface.SetDrawColor(60, 200, 60)
		end

		draw.NoTexture()
		surface.DrawTexturedRectRotated(w/2, h/2, w-12, h+100, -6)
	end
	accept.DoClick = function() self:DoAccept() end

	local decline = vgui.Create("DButton", self)
	decline:SetFont("pk_duelbutton")
	decline:SetText("Decline")
	decline:SetTextColor(Color(255,255,255))
	decline:SetWide(self:GetWide()/2)
	decline:DockMargin(4,4,4,4)
	decline:Dock(RIGHT)
	function decline:Paint(w, h)
		if self:IsHovered() then
			surface.SetDrawColor(240, 60, 60)
		else
			surface.SetDrawColor(200, 60, 60)
		end

		draw.NoTexture()
		surface.DrawTexturedRectRotated(w/2, h/2, w-12, h+100, -6)
	end
	decline.DoClick = function() self:DoDecline() end
end

function PANEL:DoAccept()
	-- for override
end

function PANEL:DoDecline()
	-- for override
end

function PANEL:SetDuelist(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	self.duelist = ply
	self.duelname = markup.Parse(string.format("<font=pk_dueltext><colour=240,240,240,255>%s</colour></font>", markup.Escape(ply:Nick())))
end

function PANEL:SetInfo(kills, time)
	self.kills = kills or 15
	self.time = time or 10
	self.duelinfo = markup.Parse(string.format("<font=pk_duelinfo><colour=240,240,240,255>%d kills\n%d minutes</colour></font>", self.kills, self.time))
end

vgui.Register("pk_duelinvite", PANEL, "DPanel")
