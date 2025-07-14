local PANEL = {}
PANEL.Base = "DPanel"

function PANEL:Init()
	local bindrow = vgui.Create("DPanel", self)
	bindrow:Dock(TOP)
	function bindrow:Paint() end

	local bindbutton = vgui.Create("DButton", bindrow)
	bindbutton:SetText("Open bindmenu")
	bindbutton:SetConsoleCommand("bindmenu")
	bindbutton:SizeToContentsX(20)
	bindbutton:SizeToContentsY(10)
	bindbutton:Dock(LEFT)

	local bindrow = vgui.Create("DPanel", self)
	bindrow:Dock(TOP)
	function bindrow:Paint() end

	local visuals = vgui.Create("DButton", bindrow)
	visuals:SetText("Toggle visuals")
	visuals:SetConsoleCommand("pk_visuals")
	visuals:SizeToContentsX(20)
	visuals:SizeToContentsY(10)
	visuals:Dock(LEFT)

	local bindrow = vgui.Create("DPanel", self)
	bindrow:Dock(TOP)
	function bindrow:Paint() end

	local wheelspeed = vgui.Create("DNumSlider", bindrow)
	wheelspeed:SetSize(500, 100)
	wheelspeed:Dock(LEFT)
	wheelspeed:SetText("Physgun scroll distance")
	wheelspeed:SetMin(10)
	wheelspeed:SetMax(200)
	wheelspeed:SetDecimals(0)
	wheelspeed:SetConVar("physgun_wheelspeed")
	
end

function PANEL:RefreshData()

end

function PANEL:Paint(w, h)
	
end

return PANEL