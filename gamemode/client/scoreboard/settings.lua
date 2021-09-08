local PANEL = {}
PANEL.Base = "DColumnSheet"

function PANEL:Init()
	self:MakeSettings()
end

function PANEL:Refresh()
	for k,v in pairs(self.Items) do
		v.Panel:Remove()
		v.Button:Remove()
	end
	self:MakeSettings()
end

function PANEL:MakeSettings()


	self.clientSettings = vgui.Create("Panel", self)
	self.serverSettings = vgui.Create("Panel", self)
/*
	PK.GetServerConfig()

	self.settings = {}

	for k,v in pairs(PK.Client.Config:Get()) do
		if v.Type == "bool" then
			local checkbox = vgui.Create("DCheckBoxLabel", self.clientSettings)
			checkbox:Dock(TOP)
			checkbox:SetText(v.LongName)
			checkbox:SetValue(v.Value)
			checkbox:SizeToContents()
			function checkbox:OnChange(val)
				PK.Client.Config:Set(k, val)
			end
			table.insert(self.settings, checkbox)
		elseif v.Type == "number" then
			local numslider = vgui.Create("DNumSlider", self.clientSettings)
			numslider:Dock(TOP)
			numslider:SetText(v.LongName)
			numslider:SetMin(40)
			numslider:SetMax(170)
			numslider:SetDecimals(0)
			numslider:SetDefaultValue(v.Value)
			numslider:ResetToDefaultValue()
			numslider:SizeToContents()
			function numslider:OnValueChanged(val)
				PK.Client.Config:Set(k, math.Round(val))
			end
			table.insert(self.settings, numslider)
		elseif v.Type == "vector" then
			local vectorPanel = vgui.Create("Panel", self.clientSettings)
			vectorPanel:Dock(TOP)

			local label = vgui.Create("DLabel", vectorPanel)
			label:SetText(v.LongName)
			label:SizeToContents()
			label:Dock(LEFT)

			local vectorMin = -50
			local vectorMax = 50

			local x = vgui.Create("DNumberWang", vectorPanel) -- HAHA WANG
			x:Dock(LEFT)
			x:SizeToContents()
			x:SetMin(vectorMin)
			x:SetMax(vectorMax)
			function x:OnValueChanged(val)
				PK.Client.Config:Set(k, Vector(x:GetValue(), v.Value.y, v.Value.z))
			end

			local y = vgui.Create("DNumberWang", vectorPanel)
			y:Dock(LEFT)
			y:SizeToContents()
			y:SetMin(vectorMin)
			y:SetMax(vectorMax)
			function y:OnValueChanged(val)
				PK.Client.Config:Set(k, Vector(v.Value.x, y:GetValue(), v.Value.z))
			end

			local z = vgui.Create("DNumberWang", vectorPanel)
			z:Dock(LEFT)
			z:SizeToContents()
			z:SetMin(vectorMin)
			z:SetMax(vectorMax)
			function z:OnValueChanged(val)
				PK.Client.Config:Set(k, Vector(v.Value.x, v.Value.y, z:GetValue()))
			end
			vectorPanel:SizeToContents()
			table.insert(self.settings, x)
			table.insert(self.settings, y)
			table.insert(self.settings, z)
		end
	end
	self.clientSettings:Dock(FILL)
	self:AddSheet("Client", self.clientSettings, "icon16/cog.png")

	for k,v in pairs(PK.ServerConfig or {}) do
		if v.Type == "bool" then
			local checkbox = vgui.Create("DCheckBoxLabel", self.serverSettings)
			checkbox:Dock(TOP)
			checkbox:SetText(v.LongName)
			checkbox:SetValue(v.Value)
			checkbox:SizeToContents()
			function checkbox:OnChange(val)
				PK.SetServerConfig(k, val)
			end
			table.insert(self.settings, checkbox)
		elseif v.Type == "number" then
			local numslider = vgui.Create("DNumSlider", self.serverSettings)
			numslider:Dock(TOP)
			numslider:SetText(v.LongName)
			numslider:SetMin(1)
			numslider:SetMax(20)
			numslider:SetDecimals(0)
			numslider:SetDefaultValue(v.Value)
			numslider:ResetToDefaultValue()
			numslider:SizeToContents()
			function numslider:OnValueChanged(val)
				local function updateConfig()
					if not numslider:IsEditing() then
						PK.SetServerConfig(k, math.Round(val))
					else
						timer.Create("PK_Menu_Setting_Antispam", 0.2, 1, updateConfig)
					end
				end
				timer.Create("PK_Menu_Setting_Antispam", 0.2, 1, updateConfig)
			end
			table.insert(self.settings, numslider)
		elseif v.Type == "vector" then
			local vectorPanel = vgui.Create("Panel", self.serverSettings)
			vectorPanel:Dock(TOP)

			local label = vgui.Create("DLabel", vectorPanel)
			label:SetText(v.LongName)
			label:SizeToContents()
			label:Dock(LEFT)

			local vectorMin = -50
			local vectorMax = 50

			local x = vgui.Create("DNumberWang", vectorPanel) -- HAHA WANG
			x:Dock(LEFT)
			x:SizeToContents()
			x:SetMin(vectorMin)
			x:SetMax(vectorMax)
			function x:OnValueChanged(val)
				PK.SetServerConfig(k, Vector(x:GetValue(), v.Value.y, v.Value.z))
			end

			local y = vgui.Create("DNumberWang", vectorPanel)
			y:Dock(LEFT)
			y:SizeToContents()
			y:SetMin(vectorMin)
			y:SetMax(vectorMax)
			function y:OnValueChanged(val)
				PK.SetServerConfig(k, Vector(v.Value.x, y:GetValue(), v.Value.z))
			end

			local z = vgui.Create("DNumberWang", vectorPanel)
			z:Dock(LEFT)
			z:SizeToContents()
			z:SetMin(vectorMin)
			z:SetMax(vectorMax)
			function z:OnValueChanged(val)
				PK.SetServerConfig(k, Vector(v.Value.x, v.Value.y, z:GetValue()))
			end
			vectorPanel:SizeToContents()
			table.insert(self.settings, x)
			table.insert(self.settings, y)
			table.insert(self.settings, z)
		end
	end
	self.serverSettings:Dock(FILL)
	self:AddSheet("Server", self.serverSettings, "icon16/cog.png")*/
end


function PANEL:Paint(w, h)
	
end

return PANEL