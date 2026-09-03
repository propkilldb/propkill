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

	local wheelspeed = vgui.Create("DNumSlider", bindrow)
	wheelspeed:SetSize(500, 100)
	wheelspeed:Dock(LEFT)
	wheelspeed:SetText("Physgun scroll distance")
	wheelspeed:SetMin(10)
	wheelspeed:SetMax(200)
	wheelspeed:SetDecimals(0)
	wheelspeed:SetConVar("physgun_wheelspeed")

	local bindrow = vgui.Create("DPanel", self)
	bindrow:Dock(TOP)
	function bindrow:Paint() end

	local mscheck = vgui.Create("DCheckBoxLabel", bindrow)
	mscheck:SetText("Enable mingscript")
	mscheck:SetConVar("ms_enable")
	mscheck:SizeToContents()
	mscheck:Dock(LEFT)

	local bindrow = vgui.Create("DPanel", self)
	bindrow:Dock(TOP)
	function bindrow:Paint() end

	local luaphysgun = vgui.Create("DCheckBoxLabel", bindrow)
	luaphysgun:SetText("Spawn with lua physgun")
	luaphysgun:SetConVar("pk_luaphysgun")
	luaphysgun:SizeToContents()
	luaphysgun:Dock(LEFT)
end

function PANEL:RefreshData()

end

function PANEL:Paint(w, h)
	
end

return PANEL