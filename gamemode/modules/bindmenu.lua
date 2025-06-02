local bindmenu_enable = CreateClientConVar("bindmenu_enable", "0", true, false, "enable bindmenu binds", 0, 1)
local savefile = "pkbinds.txt"
local filedata = file.Read(savefile, "DATA")
local defaults = {
	[KEY_X] = {
		bindtype = "prop",
		value = "models/props_junk/sawblade001a.mdl"
	},
	[KEY_C] = {
		bindtype = "prop",
		value = "models/props_phx/construct/metal_plate4x4.mdl"
	},
	[KEY_V] = {
		bindtype = "prop",
		value = "models/props/de_tides/gate_large.mdl"
	},
	[KEY_F] = {
		bindtype = "command",
		value = "ms_rotate2"
	},
	[KEY_Q] = {
		bindtype = "prop",
		value = "models/props/cs_militia/refrigerator01.mdl"
	},
	[KEY_J] = {
		bindtype = "command",
		value = "+menu"
	},
	[KEY_R] = {
		bindtype = "prop",
		value = "models/props_canal/canal_bars004.mdl"
	},
	[KEY_G] = {
		bindtype = "prop",
		value = "models/XQM/CoasterTrack/slope_225_3.mdl"
	},
	[KEY_T] = {
		bindtype = "command",
		value = "+voicerecord"
	},
}

local bindmeta = {}
bindmeta.__index = bindmeta

function bindmeta:addBind(key, bindtype, value)
	self[key] = {
		bindtype = bindtype,
		value = value
	}

	return true
end

function bindmeta:AddCommandBind(key, command)
	if IsConCommandBlocked(command) and string.lower(command) != "+voicerecord" then
		return false, "bindmenu cannot run this command"
	end
	
	return self:addBind(key, "command", command)
end

function bindmeta:AddPropBind(key, model)
	return self:addBind(key, "prop", model)
end

function bindmeta:GetType(key)
	return self[key] and self[key].bindtype
end

function bindmeta:GetValue(key)
	return self[key] and self[key].value
end

function bindmeta:SetValue(key, newvalue)
	if self[key] then
		self[key].value = newvalue
	end
end

function bindmeta:SetKey(key, newkey)
	if key == newkey then return end
	if self[newkey] then return key end

	self[newkey] = self[key]
	self[key] = nil
	return newkey
end

function bindmeta:Run(key, pressed)
	local bindtype = self:GetType(key)
	local value = self:GetValue(key)

	if bindtype == "command" then
		if value then
			if string.lower(value) == "+voicerecord" then
				permissions.EnableVoiceChat(pressed)
			elseif value:sub(1, 1) == "+" then
				if pressed then
					LocalPlayer():ConCommand(value)
				else
					LocalPlayer():ConCommand("-" .. value:sub(2))
				end
			elseif pressed then
				LocalPlayer():ConCommand(value)
			end
		end
	elseif bindtype == "prop" and pressed then
		RunConsoleCommand("gm_spawn", value)
	end
end

function bindmeta:IsBound(key)
	return self[key] != nil
end

function bindmeta:RemoveBind(key)
	self[key] = nil
end

function bindmeta:Save()
	file.Write(savefile, util.TableToJSON(self, true))
end

binds = util.JSONToTable(filedata or "") or defaults
setmetatable(binds, bindmeta)

hook.Add("PlayerBindPress", "custombinds", function(ply, bind, pressed, code)
	if not bindmenu_enable:GetBool() then return end

	if binds:IsBound(code) then
		binds:Run(code, pressed)
		return true
	end
end)

cvars.AddChangeCallback("bindmenu_enable", function(name, old, new)
	if new == "0" then return end
	if permissions.IsGranted("voicerecord") then return end
	for key, _ in next, binds do
		if string.lower(binds:GetValue(key)) == "+voicerecord" then
			permissions.EnableVoiceChat(true)
			return
		end
	end
end)

local function GetKeyName(code)
	local str = input.GetKeyName(code)
	if not str then str = "NONE" end
	return language.GetPhrase(str)
end

if IsValid(bindmenu_panel) and ispanel(bindmenu_panel) then
	bindmenu_panel:Remove()
	bindmenu_panel = nil
end

function bindmenu()
	bindmenu_panel = vgui.Create("DFrame")
	bindmenu_panel:SetSize(600, 650)
	bindmenu_panel:Center()
	bindmenu_panel:MakePopup()
	bindmenu_panel:SetTitle("Bind Menu")
	bindmenu_panel.Paint = function(self, w, h)
		surface.SetDrawColor(30, 30, 40, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(60, 60, 100, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		surface.DrawOutlinedRect(1, 1, w-2, h-2)
	end
	function bindmenu_panel:OnClose()
		binds:Save()
	end

	local mainPanel = vgui.Create("DPanel", bindmenu_panel)
	mainPanel:Dock(FILL)
	mainPanel:DockMargin(10, 10, 10, 10)
	mainPanel.Paint = function(self, w, h)
		surface.SetDrawColor(40, 40, 50, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(70, 70, 120, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local titleLabel = vgui.Create("DLabel", mainPanel)
	titleLabel:SetPos(20, 10)
	titleLabel:SetFont("DermaLarge")
	titleLabel:SetText("Active Binds")
	titleLabel:SetTextColor(Color(220, 220, 255))
	titleLabel:SizeToContents()

	local controlPanel = vgui.Create("DPanel", mainPanel)
	controlPanel:SetPos(5, 50)
	controlPanel:SetSize(560, 50)
	controlPanel.Paint = function(self, w, h)
		surface.SetDrawColor(30, 30, 45, 200)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(60, 60, 100, 200)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local enablebox = vgui.Create("DCheckBox", controlPanel)
	enablebox:SetPos(10, 15)
	enablebox:SetSize(20, 20)
	enablebox:SetConVar("bindmenu_enable")
	enablebox:SetValue(bindmenu_enable:GetBool())
	enablebox.Paint = function(self, w, h)
		surface.SetDrawColor(20, 20, 35, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(100, 100, 150, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		if self:GetChecked() then
			surface.SetDrawColor(100, 200, 120, 255)
			surface.DrawRect(3, 3, w-6, h-6)
		end
	end

	local enableLabel = vgui.Create("DLabel", controlPanel)
	enableLabel:SetPos(35, 18)
	enableLabel:SetText("Enable Binds")
	enableLabel:SetFont("DermaDefaultBold")
	enableLabel:SetTextColor(Color(255, 255, 255))
	enableLabel:SizeToContents()

	local loaddefaults = vgui.Create("DButton", controlPanel)
	loaddefaults:SetPos(200, 10)
	loaddefaults:SetSize(120, 30)
	loaddefaults:SetText("Load Defaults")
	loaddefaults:SetFont("DermaDefaultBold")
	loaddefaults:SetTextColor(Color(255, 255, 255))
	loaddefaults.Paint = function(self, w, h)
		if self:IsHovered() then
			surface.SetDrawColor(60, 80, 160, 255)
		else
			surface.SetDrawColor(50, 60, 120, 255)
		end
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(100, 120, 200, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local addbutton = vgui.Create("DButton", controlPanel)
	addbutton:SetPos(340, 10)
	addbutton:SetSize(120, 30)
	addbutton:SetText("Add Bind")
	addbutton:SetFont("DermaDefaultBold")
	addbutton:SetTextColor(Color(255, 255, 255))
	addbutton.Paint = function(self, w, h)
		if self:IsHovered() then
			surface.SetDrawColor(60, 160, 80, 255)
		else
			surface.SetDrawColor(50, 120, 60, 255)
		end
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(100, 200, 120, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local bindlistContainer = vgui.Create("DPanel", mainPanel)
	bindlistContainer:SetPos(5, 110)
	bindlistContainer:SetSize(560, 480)
	bindlistContainer.Paint = function(self, w, h)
		surface.SetDrawColor(30, 30, 45, 200)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(60, 60, 100, 200)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local bindlist = vgui.Create("DScrollPanel", bindlistContainer)
	bindlist:SetPos(5, 5)
	bindlist:SetSize(550, 480)

	local function LoadBinds()
		for _, v in next, bindlist:GetCanvas():GetChildren() do
			v:Remove()
		end

		for key, _ in pairs(binds) do
			local bindrow = vgui.Create("DPanel")
			bindrow:SetTall(40)
			bindrow:Dock(TOP)
			bindrow:DockMargin(5, 5, 5, 0)
			bindrow.Paint = function(self, w, h)
				if self:IsHovered() then
					surface.SetDrawColor(50, 50, 80, 150)
				else
					surface.SetDrawColor(40, 40, 60, 150)
				end
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(70, 70, 120, 255)
				surface.DrawOutlinedRect(0, 0, w, h)
			end

			function bindrow:DoRightClick()
				local menu = DermaMenu(false, bindmenu_panel)
				local copy = menu:AddOption("Copy console bind", function()
					local bindText = ""
					if binds:GetType(key) == "prop" then
						bindText = 'bind ' .. GetKeyName(key) .. ' "gm_spawn ' .. binds:GetValue(key) .. '"'
					elseif binds:GetType(key) == "command" then
						bindText = 'bind ' .. GetKeyName(key) .. ' "' .. binds:GetValue(key) .. '"'
					end
					SetClipboardText(bindText)
				end)
				copy:SetIcon("icon16/page_copy.png")

				local edit = menu:AddOption("Edit bind", function()
					EditBind(binds:GetType(key), key, function(newkey, value)
						binds:SetKey(key, newkey)
						binds:SetValue(newkey, value)
						LoadBinds()
					end)
				end)
				edit:SetIcon("icon16/pencil.png")

				menu:AddSpacer()
				local remove = menu:AddOption("Remove bind", function()
					bindrow:Remove()
					binds:RemoveBind(key)
				end)
				remove:SetIcon("icon16/delete.png")

				menu:Open()
			end

			local binder = vgui.Create("DButton", bindrow)
			binder:SetText(GetKeyName(key))
			binder:SetWide(80)
			binder:Dock(LEFT)
			binder:DockMargin(5, 5, 5, 5)
			binder:SetFont("DermaDefaultBold")
			binder:SetTextColor(Color(255, 255, 255))
			binder.Paint = function(self, w, h)
				if self:IsHovered() then
					surface.SetDrawColor(70, 70, 120, 255)
				else
					surface.SetDrawColor(60, 60, 100, 255)
				end

				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(100, 100, 150, 255)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
			binder.DoRightClick = bindrow.DoRightClick
			binder.DoClick = function()
				EditBind(binds:GetType(key), key, function(newkey, value)
					binds:SetKey(key, newkey)
					binds:SetValue(newkey, value)
					LoadBinds()
				end)
			end

			local typeIcon = vgui.Create("DImage", bindrow)
			typeIcon:SetWide(26)
			typeIcon:Dock(LEFT)
			typeIcon:DockMargin(5, 8, 5, 8)
			if binds:GetType(key) == "prop" then
				typeIcon:SetImage("icon16/bricks.png")
			else
				typeIcon:SetImage("icon16/application_xp_terminal.png")
			end

			local valtext = vgui.Create("DButton", bindrow)
			valtext:Dock(FILL)
			valtext:DockMargin(5, 5, 5, 5)
			valtext:SetTextInset(10, 0)
			valtext:SetContentAlignment(4)
			valtext:SetText(binds:GetValue(key))
			valtext:SetFont("DermaDefaultBold")
			valtext:SetTextColor(Color(255, 255, 255))
			valtext.Paint = function(self, w, h)
				surface.SetDrawColor(30, 30, 50, 150)
				surface.DrawRect(0, 0, w, h)
			end
			valtext.DoClick = binder.DoClick
			valtext.DoRightClick = bindrow.DoRightClick

			local del = vgui.Create("DButton", bindrow)
			del:Dock(RIGHT)
			del:SetWide(60)
			del:DockMargin(5, 5, 5, 5)
			del:SetText("Remove")
			del:SetFont("DermaDefaultBold")
			del:SetTextColor(Color(255, 255, 255))
			del.Paint = function(self, w, h)
				if self:IsHovered() then
					surface.SetDrawColor(200, 50, 50, 255)
				else
					surface.SetDrawColor(150, 40, 40, 255)
				end
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(255, 100, 100, 255)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
			del.DoRightClick = bindrow.DoRightClick
			del.DoClick = function()
				bindrow:Remove()
				binds:RemoveBind(key)
			end

			bindlist:AddItem(bindrow)
		end
	end
	LoadBinds()

	addbutton.DoClick = function()
		local menu = DermaMenu(false, bindmenu_panel)
		menu:AddOption("Add Prop Bind", function()
			EditBind("prop", 0, function(key, model)
				local success, err = binds:AddPropBind(key, model)
				if success == false then
					Derma_Message("Error: " .. err, "Error", "Close")
					return
				end
				LoadBinds()
			end)
		end):SetIcon("icon16/bricks.png")
		menu:AddOption("Add Command Bind", function()
			EditBind("command", 0, function(key, command)
				local success, err = binds:AddCommandBind(key, command)
				if success == false then
					Derma_Message("Error: " .. err, "Error", "Close")
					return
				end
				LoadBinds()
			end)
		end):SetIcon("icon16/application_xp_terminal.png")
		menu:Open()
	end

	loaddefaults.DoClick = function()
		local function doreset()
			binds = table.Copy(defaults)
			setmetatable(binds, bindmeta)

			LoadBinds()
			binds:Save()
		end
		Derma_Query("This will reset all your current binds to defaults!", "Reset binds", "Yes, reset", doreset, "Cancel")
	end
end

concommand.Add("bindmenu", function(ply, cmd, args, str)
	if #args == 0 then
		return bindmenu()
	end
	
	local keycode = input.GetKeyCode(args[1])
	if keycode == -1 then
		print('"' .. args[1] .. "\" is not a valid key")
		return
	end
	
	local command = args[2]
	if string.sub(command, 0, 9) == "gm_spawn " then
		local success, err = binds:AddPropBind(keycode, string.sub(command, 10))
		if success == false then
			print(err)
			return
		end
	else
		local success, err = binds:AddCommandBind(keycode, command)
		if success == false then
			print(err)
			return
		end
	end
end)

local modellist = {
	["Tides"] = {
		"models/props/de_tides/gate_large.mdl",
		"models/props/de_train/lockers_long.mdl",
		"models/props_citizen_tech/guillotine001a_base01.mdl",
		"models/props/de_nuke/electricalbox01.mdl",
		"models/props/cs_assault/billboard.mdl",
		"models/props/cs_militia/logpile2.mdl",
		"models/props/cs_militia/sheetrock_leaning.mdl",
		"models/props_wasteland/prison_gate001b.mdl",
		"models/props_canal/canal_bars004.mdl",
		"models/props_canal/canal_bars002.mdl",
		"models/props_wasteland/prison_archwindow001.mdl",
		"models/props/cs_militia/bathroomwallhole01_tile.mdl",
		"models/props_wasteland/prison_slidingdoor001a.mdl",
		"models/props_lab/servers.mdl",
		"models/props_c17/playground_carousel01.mdl",
		"models/props_c17/substation_transformer01a.mdl",
		"models/props/de_nuke/truck_nuke.mdl",
		"models/props/cs_militia/van.mdl",
		"models/props_vehicles/van001a_physics.mdl",
		"models/props_vehicles/van001a.mdl",
		"models/props_c17/factorymachine01.mdl",
		"models/props/de_tides/flowerbed.mdl",
		"models/hunter/misc/roundthing1.mdl",
		"models/hunter/misc/roundthing4.mdl",
		"models/hunter/misc/roundthing3.mdl",
		"models/hunter/misc/roundthing2.mdl",
		"models/mechanics/articulating/arm2x20d.mdl",
		"models/mechanics/articulating/arm2x20d2.mdl",
	},
	["Locker"] = {
		"models/props/cs_militia/refrigerator01.mdl",
		"models/props_c17/Lockers001a.mdl",
		"models/props/cs_militia/stove01.mdl",
		"models/props/de_train/train_wheels.mdl",
		"models/props/cs_militia/furnace01.mdl",
		"models/props_wasteland/medbridge_post01.mdl",
		"models/props/de_prodigy/wall_console3.mdl",
		"models/props/cs_militia/television_console01.mdl",
		"models/props/de_inferno/fireplace.mdl",
		"models/props_buildings/short_building001a.mdl",
		"models/props/cs_militia/gun_cabinet_glass.mdl",
		"models/props/de_prodigy/wall_console2.mdl",
		"models/props_lab/hev_case.mdl",
		"models/props_wasteland/controlroom_storagecloset001b.mdl",
		"models/props_trainstation/trainstation_ornament001.mdl",
		"models/props_c17/substation_stripebox01a.mdl",
		"models/props_vehicles/car001b_hatchback.mdl",
		"models/props_c17/gravestone001a.mdl",
		"models/props/de_inferno/crate_fruit_break.mdl",
		"models/props/de_inferno/crate_fruit_break_p1.mdl",
		"models/props/de_prodigy/transformer.mdl",
		"models/props/de_train/utility_truck.mdl",
		"models/mechanics/roboticslarge/claw_hub_8.mdl",
		"models/mechanics/roboticslarge/claw_hub_8l.mdl",
		"models/props_wasteland/laundry_dryer001.mdl",
		"models/props/de_prodigy/ammo_can_03.mdl",
		"models/props/de_prodigy/concretebags.mdl",
		"models/props/de_inferno/hay_bail_stack.mdl",
		"models/props/cs_assault/moneypallet.mdl",
		"models/props/de_inferno/chimney01.mdl",
		"models/props_combine/combine_window001.mdl",
		"models/props_phx/construct/metal_plate_curve180.mdl",
		"models/props_phx/construct/metal_plate_curve2.mdl",
	},
	["Defense"] = {
		"models/props_debris/walldestroyed01a.mdl",
		"models/props_buildings/collapsedbuilding01awall.mdl",
		"models/props_debris/walldestroyed01a.mdl",
		"models/props_wasteland/interior_fence001c.mdl",
		"models/props_wasteland/interior_fence001d.mdl",
		"models/props_debris/barricade_tall03a.mdl",
		"models/props_debris/barricade_tall04a.mdl",
		"models/props/de_cbble/cb_wnddbl32.mdl",
		"models/props/de_inferno/plasterinfwndwg_inside.mdl",
		"models/props/cs_assault/box_stack1.mdl",
		"models/props_debris/plaster_wall002a.mdl",
		"models/props/de_inferno/brokenwall.mdl",
		"models/props/cs_militia/bathroomwallhole01_wood_broken_01.mdl",
		"models/props_debris/walldestroyed07b.mdl",
		"models/props_debris/building_brokenexterior002a.mdl",
		"models/props_debris/building_brokenexterior001a.mdl",
		"models/props/de_dust/door01a.mdl",
		"models/props/de_cbble/cb_doorarch.mdl",
		"models/props/cs_italy/it_entarch1.mdl",
		"models/props_rooftop/attic_window.mdl",
		"models/props/cs_havana/gazebo.mdl",
		"models/props_combine/combine_booth_short01a.mdl",
		"models/props_combine/combine_barricade_tall02b.mdl",
	},
	["Head Smashing"] = {
		"models/props_phx/construct/metal_plate4x4.mdl",
		"models/hunter/plates/plate4x4.mdl",
		"models/props_debris/walldestroyed09a.mdl",
		"models/props_phx/facepunch_logo.mdl",
		"models/props_debris/walldestroyed09e.mdl",
		"models/xqm/coastertrack/special_station.mdl",
		"models/props/de_nuke/ibeams_warehouseroof.mdl",
	},
	["Birding"] = {
		"models/props_phx/wheels/moped_tire.mdl",
		"models/props_junk/sawblade001a.mdl",
		"models/props/de_inferno/wine_barrel_p11.mdl",
		"models/props/de_inferno/wine_barrel_p10.mdl",
		"models/props_phx/trains/wheel_medium.mdl",
		"models/props_phx/trains/medium_wheel_2.mdl",
		"models/props_phx/wheels/wooden_wheel1.mdl",
		"models/props/de_dust/grainbasket01c.mdl",
		"models/props/cs_militia/skylight_glass_p9.mdl",
		"models/props_phx/wheels/trucktire.mdl",
		"models/mechanics/wheels/wheel_smooth_18r.mdl",
		"models/props_phx/smallwheel.mdl",
		"models/props_phx/chrome_tire.mdl",
		"models/props_phx/normal_tire.mdl",
		"models/noesis/donut.mdl",
		"models/props_phx/games/chess/white_dama.mdl",
		"models/props_phx/games/chess/black_dama.mdl",
		"models/props_c17/clock01.mdl",
		"models/props_phx/construct/glass/glass_angle360.mdl",
		"models/props_phx/construct/plastic/plastic_angle_360.mdl",
		"models/props_phx/construct/metal_angle360.mdl",
		"models/props_phx/construct/wood/wood_angle360.mdl",
		"models/hunter/tubes/circle2x2.mdl",
		"models/hunter/tubes/circle4x4.mdl",
		"models/props_phx/construct/windows/window_angle360.mdl",
		"models/squad/sf_tubes/sf_tube1x360.mdl",
		"models/mechanics/wheels/wheel_smooth_48.mdl",
		"models/mechanics/wheels/wheel_rounded_36s.mdl",
		"models/mechanics/wheels/wheel_rounded_72.mdl",
		"models/props_phx/wheels/747wheel.mdl",
		"models/mechanics/wheels/wheel_speed_72.mdl",
		"models/mechanics/robotics/xfoot.mdl",
		"models/mechanics/roboticslarge/xfoot.mdl",
		"models/props/de_dust/dustteeth_1.mdl",
		"models/props_trainstation/trainstation_ornament002.mdl",
		"models/mechanics/gears/gear24x6_small.mdl",
		"models/Mechanics/gears2/gear_36t1.mdl",
		"models/mechanics/gears2/bevel_36t1.mdl",
		"models/mechanics/gears2/vert_36t1.mdl",
		"models/props_phx/gears/spur36.mdl",
		"models/props_phx/mechanics/biggear.mdl",
		"models/props_phx/mechanics/medgear.mdl",
		"models/props_junk/garbage_carboard002a.mdl",
		"models/props_phx/construct/metal_plate1.mdl",
		"models/props_phx/construct/glass/glass_plate1x1.mdl",
		"models/props_phx/construct/plastic/plastic_panel1x1.mdl",
		"models/props_phx/construct/windows/window1x1.mdl",
		"models/props_phx/construct/wood/wood_panel1x1.mdl",
		"models/props_phx/construct/metal_plate2x2.mdl",
		"models/props_junk/trashdumpster02b.mdl",
		"models/props_junk/wood_pallet001a.mdl",
		"models/hunter/geometric/hex1x1.mdl",
		"models/props_phx/wheels/metal_wheel1.mdl",
		"models/props_phx/wheels/metal_wheel2.mdl",
	},
	["Rebirding"] = {
		"models/XQM/CoasterTrack/slope_225_2.mdl",
		"models/XQM/CoasterTrack/slope_225_3.mdl",
		"models/xqm/coastertrack/slope_225_4.mdl",
		"models/hunter/misc/cone4x1.mdl",
		"models/hunter/misc/cone2x05.mdl",
		"models/props_phx/construct/metal_dome360.mdl",
		"models/props_phx/construct/glass/glass_dome360.mdl",
		"models/hunter/misc/shell2x2a.mdl",
		"models/props_phx/construct/wood/wood_dome360.mdl",
		"models/hunter/misc/sphere1x1.mdl",
		"models/hunter/tubes/tube4x4x1to2x2.mdl",
		"models/props/de_tides/vending_cart_top.mdl",
		"models/props_phx/trains/tracks/track_45_up.mdl",
	}
}

local tabOrder = {
	"Tides",
	"Locker",
	"Defense",
	"Head Smashing",
	"Birding",
	"Rebirding"
}

local function ModelSelect(callback)
	local frame = vgui.Create("DFrame")
	frame:SetSize(1200, 700)
	frame:SetTitle("Model Selection")
	frame:Center()
	frame:MakePopup()
	frame:SetBackgroundBlur(true)
	frame.Paint = function(self, w, h)
		surface.SetDrawColor(30, 30, 40, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(60, 60, 100, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		surface.DrawOutlinedRect(1, 1, w-2, h-2)
	end

	local mainContainer = vgui.Create("DPanel", frame)
	mainContainer:Dock(FILL)
	mainContainer:DockMargin(10, 10, 10, 10)
	mainContainer.Paint = function() end

	local leftPanel = vgui.Create("DPanel", mainContainer)
	leftPanel:Dock(LEFT)
	leftPanel:SetWide(850)
	leftPanel.Paint = function(self, w, h)
		surface.SetDrawColor(40, 40, 50, 255)
		surface.DrawRect(0, 0, w, h)
	end

	local rightPanel = vgui.Create("DPanel", mainContainer)
	rightPanel:Dock(FILL)
	rightPanel:DockMargin(10, 0, 0, 0)
	rightPanel.Paint = function(self, w, h)
		surface.SetDrawColor(40, 40, 50, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(70, 70, 120, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local previewTitle = vgui.Create("DLabel", rightPanel)
	previewTitle:SetPos(20, 5)
	previewTitle:SetFont("DermaLarge")
	previewTitle:SetText("Model Preview")
	previewTitle:SetTextColor(Color(220, 220, 255))
	previewTitle:SizeToContents()

	local previewPanel = vgui.Create("DPanel", rightPanel)
	previewPanel:SetPos(15, 40)
	previewPanel:SetSize(280, 300)
	previewPanel.Paint = function(self, w, h)
		surface.SetDrawColor(20, 20, 35, 200)
		surface.DrawRect(0, 0, w, h)
	end

	local modelPreview = vgui.Create("DModelPanel", previewPanel)
	modelPreview:SetSize(270, 290)
	modelPreview:SetPos(5, 5)
	modelPreview:SetModel("")
	local function SetupModelView(panel, model)
		if not IsValid(panel) then return end
		panel:SetModel(model or "")
		if not panel.Entity or not IsValid(panel.Entity) then return end
		local mins, maxs = panel.Entity:GetRenderBounds()
		if not mins or not maxs then return end
		local size = 0
		size = math.max(size, math.abs(mins.x) + math.abs(maxs.x))
		size = math.max(size, math.abs(mins.y) + math.abs(maxs.y))
		size = math.max(size, math.abs(mins.z) + math.abs(maxs.z))
		panel:SetCamPos(Vector(size, size, size * 0.5))
		panel:SetLookAt((mins + maxs) * 0.5)
		panel.Angles = Angle(0, 0, 0)
		panel.LayoutEntity = function(pnl, ent)
			if not ent or not IsValid(ent) then return end
			if not panel or not IsValid(panel) then return end
			if not panel.bAnimated then return end
			if not panel.Angles then panel.Angles = Angle(0, 0, 0) end
			
			pcall(function()
				panel.Angles.y = (panel.Angles.y + 0.5) % 360
				ent:SetAngles(panel.Angles)
			end)
		end
		panel.bAnimated = true
	end

	local pathLabel = vgui.Create("DLabel", rightPanel)
	pathLabel:SetPos(25, 350)
	pathLabel:SetSize(270, 60)
	pathLabel:SetFont("DermaDefaultBold")
	pathLabel:SetText("Path: None selected")
	pathLabel:SetTextColor(Color(255, 255, 255))
	pathLabel:SetWrap(true)

	local selectBtn = vgui.Create("DButton", rightPanel)
	selectBtn:SetPos(20, 420)
	selectBtn:SetSize(270, 40)
	selectBtn:SetText("Select Model")
	selectBtn:SetFont("HudHintTextLarge")
	selectBtn:SetTextColor(Color(150, 150, 170))
	selectBtn:SetEnabled(false)
	selectBtn.Paint = function(self, w, h)
		if not self:IsEnabled() then
			surface.SetDrawColor(60, 60, 80, 255)
		elseif self:IsHovered() then
			surface.SetDrawColor(60, 160, 80, 255)
		else
			surface.SetDrawColor(50, 120, 60, 255)
		end
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(100, 200, 120, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	local selectedModel = nil
	selectBtn.DoClick = function()
		if selectedModel and callback then
			callback(selectedModel)
			frame:Close()
		end
	end

	local tabPanel = vgui.Create("DPanel", leftPanel)
	tabPanel:SetPos(5, 5)
	tabPanel:SetSize(840, 50)
	tabPanel.Paint = function() end

	local contentPanel = vgui.Create("DPanel", leftPanel)
	contentPanel:SetPos(5, 60)
	contentPanel:SetSize(840, 600)
	contentPanel.Paint = function() end

	local tabs = {}
	local panels = {}
	local activeTab = 1

	for i, title in ipairs(tabOrder) do
		local tab = vgui.Create("DButton", tabPanel)
		tab:SetPos((i-1) * 140, 0)
		tab:SetSize(139, 50)
		tab:SetText(title)
		tab:SetFont("DermaDefaultBold")
		tab:SetTextColor(Color(220, 220, 255))
		tab.isActive = i == 1
		tab.Paint = function(self, w, h)
			if self.isActive then
				surface.SetDrawColor(80, 80, 120, 255)
			else
				surface.SetDrawColor(50, 50, 70, 255)
			end

			surface.DrawRect(0, 0, w, h)

			if self:IsHovered() and not self.isActive then
				surface.SetDrawColor(70, 70, 100, 255)
				surface.DrawRect(0, 0, w, h)
			end

			surface.SetDrawColor(100, 100, 150, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		tab.DoClick = function()
			for k, t in pairs(tabs) do
				t.isActive = false
			end
			tab.isActive = true
			activeTab = i
			for k, p in pairs(panels) do
				p:SetVisible(k == i)
			end
		end
		tabs[i] = tab

		local scrollPanel = vgui.Create("DScrollPanel", contentPanel)
		scrollPanel:SetPos(0, 0)
		scrollPanel:SetSize(840, 600)
		scrollPanel:SetVisible(i == 1)

		local grid = vgui.Create("DGrid", scrollPanel)
		grid:SetPos(5, 5)
		grid:SetCols(6)
		grid:SetColWide(130)
		grid:SetRowHeight(130)

		local proplist = modellist[title]
		for _, modelPath in ipairs(proplist) do
			local icon = vgui.Create("SpawnIcon")
			icon:SetModel(modelPath)
			icon:SetSize(120, 120)
			icon:SetToolTip(modelPath)
			icon.DoClick = function()
				selectedModel = modelPath
				SetupModelView(modelPreview, modelPath)
				pathLabel:SetText("Path: " .. modelPath)
				selectBtn:SetEnabled(true)
				selectBtn:SetTextColor(Color(255, 255, 255))
			end
			icon.DoDoubleClick = function()
				if callback then
					callback(modelPath)
					frame:Close()
				end
			end
			icon.DoRightClick = function()
				local menu = DermaMenu(false, frame)
				local copy = menu:AddOption("Copy To ClipBoard", function()
					SetClipboardText(modelPath)
				end)
				copy:SetIcon("icon16/page_copy.png")
				menu:Open()
			end

			grid:AddItem(icon)
		end
		panels[i] = scrollPanel
	end
end

function EditBind(type, key, callback)
	local frame = vgui.Create("DFrame")
	if type == "prop" then
		frame:SetSize(500, 650)
	else
		frame:SetSize(500, 350)
	end
	frame:SetTitle("Bind Editor - " .. (type == "prop" and "Prop Bind" or "Command Bind"))
	frame:Center()
	frame:MakePopup()
	frame:SetBackgroundBlur(true)
	frame.Paint = function(self, w, h)
		surface.SetDrawColor(30, 30, 40, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(60, 60, 100, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		surface.DrawOutlinedRect(1, 1, w-2, h-2)
	end

	local container = vgui.Create("DPanel", frame)
	container:Dock(FILL)
	container:DockMargin(20, 20, 20, 20)
	container.Paint = function(self, w, h)
		surface.SetDrawColor(40, 40, 50, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(70, 70, 120, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local keyLabel = vgui.Create("DLabel", container)
	keyLabel:SetPos(20, 20)
	keyLabel:SetFont("HudHintTextLarge")
	keyLabel:SetText("Key Binding:")
	keyLabel:SetTextColor(Color(255, 255, 255))
	keyLabel:SizeToContents()

	local bindselect = vgui.Create("DBinder", container)
	bindselect:SetPos(20, 50)
	bindselect:SetSize(420, 30)
	bindselect:SetValue(key)
	bindselect:SetFont("HudHintTextLarge")
	bindselect:SetTextColor(Color(255, 255, 255))
	bindselect.Paint = function(self, w, h)
		if self:IsHovered() then
			surface.SetDrawColor(70, 70, 120, 255)
		else
			surface.SetDrawColor(60, 60, 100, 255)
		end
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(100, 100, 150, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local buttons = vgui.Create("DPanel", frame)
	buttons:SetTall(50)
	buttons:Dock(BOTTOM)
	buttons:DockMargin(130, 0, 130, 20)
	buttons.Paint = function() end

	local accept = vgui.Create("DButton", buttons)
	accept:SetText("Accept")
	accept:SetWide(100)
	accept:DockMargin(0, 0, 10, 0)
	accept:Dock(RIGHT)
	accept:SetFont("HudHintTextLarge")
	accept:SetTextColor(Color(150, 150, 170))
	accept:SetEnabled(false)
	accept:SetTooltip("Please select a key")
	accept.Paint = function(self, w, h)
		if not self:IsEnabled() then
			surface.SetDrawColor(60, 60, 80, 255)
		elseif self:IsHovered() then
			surface.SetDrawColor(60, 160, 80, 255)
		else
			surface.SetDrawColor(50, 120, 60, 255)
		end

		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(100, 200, 120, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local cancel = vgui.Create("DButton", buttons)
	cancel:SetText("Cancel")
	cancel:SetWide(100)
	cancel:Dock(RIGHT)
	cancel:SetFont("HudHintTextLarge")
	cancel:SetTextColor(Color(255, 255, 255))
	cancel.Paint = function(self, w, h)
		if self:IsHovered() then
			surface.SetDrawColor(200, 50, 50, 255)
		else
			surface.SetDrawColor(150, 40, 40, 255)
		end

		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(255, 100, 100, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	cancel.DoClick = function()
		frame:Close()
	end

	function accept:checkEnable()
		self:SetEnabled(false)
		self:SetTextColor(Color(150, 150, 170))

		if not self.selectedKey then
			self:SetTooltip("Please select a key")
		elseif not self.selectedValue then
			if type == "prop" then
				self:SetTooltip("Please select a prop")
			elseif type == "command" then
				self:SetTooltip("Please enter a command to run")
			end
		elseif self.selectedKey != key and binds:IsBound(self.selectedKey) then
			self:SetTooltip("That key is already in use by another bind")
		else
			self:SetEnabled(true)
			self:SetTooltip(nil)
			self:SetTextColor(Color(255, 255, 255))
		end
	end
	function accept:SetKey(key)
		if key == nil or key == 0 then return end
		self.selectedKey = key
		self:checkEnable()
	end
	function accept:SetValue(value)
		if value == nil or value == "" then return end
		self.selectedValue = value
		self:checkEnable()
	end
	function accept:DoClick()
		if callback then
			callback(self.selectedKey, self.selectedValue)
		end
		frame:Close()
	end

	function bindselect:OnChange(key)
		accept:SetKey(key)
	end
	bindselect:OnChange(key)

	if type == "prop" then
		local propLabel = vgui.Create("DLabel", container)
		propLabel:SetPos(20, 100)
		propLabel:SetFont("HudHintTextLarge")
		propLabel:SetText("Model Selection:")
		propLabel:SetTextColor(Color(255, 255, 255))
		propLabel:SizeToContents()

		local propPanel = vgui.Create("DPanel", container)
		propPanel:SetPos(15, 130)
		propPanel:SetSize(420, 300)
		propPanel.Paint = function(self, w, h)
			surface.SetDrawColor(20, 20, 35, 200)
			surface.DrawRect(0, 0, w, h)
		end

		local modelPreview = vgui.Create("DModelPanel", propPanel)
		modelPreview:SetSize(410, 290)
		modelPreview:SetPos(5, 5)
		modelPreview:SetModel(binds:GetValue(key) or "")

		local function SetupModelView(panel, model)
			if not IsValid(panel) then return end

			panel:SetModel(model or "")
			if not panel.Entity or not IsValid(panel.Entity) then return end

			local mins, maxs = panel.Entity:GetRenderBounds()
			if not mins or not maxs then return end

			local size = 0
			size = math.max(size, math.abs(mins.x) + math.abs(maxs.x))
			size = math.max(size, math.abs(mins.y) + math.abs(maxs.y))
			size = math.max(size, math.abs(mins.z) + math.abs(maxs.z))

			panel:SetCamPos(Vector(size, size, size * 0.5))
			panel:SetLookAt((mins + maxs) * 0.5)
			panel.Angles = Angle(0, 0, 0)
			panel.LayoutEntity = function(pnl, ent)
				if not ent or not IsValid(ent) then return end
				if not panel or not IsValid(panel) then return end
				if not panel.bAnimated then return end
				if not panel.Angles then panel.Angles = Angle(0, 0, 0) end
				pcall(function()
					panel.Angles.y = (panel.Angles.y + 0.5) % 360
					ent:SetAngles(panel.Angles)
				end)
			end
			panel.bAnimated = true
		end

		if binds:GetValue(key) then
			SetupModelView(modelPreview, binds:GetValue(key))
		end

		accept:SetValue(binds:GetValue(key) or nil)

		local selectPropBtn = vgui.Create("DButton", container)
		selectPropBtn:SetPos(20, 440)
		selectPropBtn:SetSize(420, 35)
		selectPropBtn:SetText("Browse Models...")
		selectPropBtn:SetFont("HudHintTextLarge")
		selectPropBtn:SetTextColor(Color(255, 255, 255))
		selectPropBtn.Paint = function(self, w, h)
			if self:IsHovered() then
				surface.SetDrawColor(70, 70, 120, 255)
			else
				surface.SetDrawColor(60, 60, 100, 255)
			end
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(100, 100, 150, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		selectPropBtn.DoClick = function()
			ModelSelect(function(model)
				SetupModelView(modelPreview, model)
				accept:SetValue(model)
			end)
		end
	elseif type == "command" then
		local cmdLabel = vgui.Create("DLabel", container)
		cmdLabel:SetPos(20, 100)
		cmdLabel:SetFont("HudHintTextLarge")
		cmdLabel:SetText("Console Command:")
		cmdLabel:SetTextColor(Color(255, 255, 255))
		cmdLabel:SizeToContents()

		local command = vgui.Create("DTextEntry", container)
		command:SetPos(20, 130)
		command:SetSize(420, 35)
		command:SetFont("HudHintTextLarge")
		command:SetTextColor(Color(255, 255, 255))
		command:SetValue(binds:GetValue(key) or "")
		command:SetPlaceholderText("Enter console command...")
		command.Paint = function(self, w, h)
			surface.SetDrawColor(20, 20, 35, 200)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(60, 60, 100, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
			self:DrawTextEntryText(self:GetTextColor(), Color(100, 100, 150), Color(255, 255, 255))
		end
		function command:OnChange()
			local value = self:GetValue()
			if value == "" or value == nil then return end
			accept:SetValue(value)
		end
		command:OnChange()
	end
end
