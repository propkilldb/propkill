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
    if self[key] then
        return false, "Key already in use"
    end

    if bindtype == "command" and IsConCommandBlocked(value) and not string.lower(value) == "+voicerecord" then
        return false, "Console command is blocked"
    end

    self[key] = {
        bindtype = bindtype,
        value = value
    }
end

function bindmeta:AddCommandBind(key, command)
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

if IsValid(bindmenu) and ispanel(bindmenu) then
    bindmenu:Remove()
    bindmenu = nil
end

function bindmenu()
    bindmenu = vgui.Create("DFrame")
    bindmenu:SetSize(700, 325)
    bindmenu:Center()
    bindmenu:MakePopup()
    bindmenu:SetTitle("Bind Menu")
    function bindmenu:OnClose()
        binds:Save()
    end

    local menubar = vgui.Create("DPanel", bindmenu)
    menubar:Dock(TOP)
    function menubar:Paint() end

    local loaddefaults = vgui.Create("DButton", menubar)
    loaddefaults:SetText("Load Defaults")
    loaddefaults:SizeToContents()
    loaddefaults:DockMargin(0,0,5,0)
    loaddefaults:Dock(LEFT)

    local enablebox = vgui.Create("DCheckBoxLabel", menubar)
    enablebox:SetText("Enable binds")
    enablebox:SetConVar("bindmenu_enable")
    enablebox:SetValue(bindmenu_enable:GetBool())
    enablebox:Dock(LEFT)

    local addbutton = vgui.Create("DButton", menubar)
    addbutton:SetText("Add")
    addbutton:Dock(RIGHT)

    local bindlist = vgui.Create("DScrollPanel", bindmenu)
    bindlist:DockMargin(0,1,0,0)
    bindlist:Dock(FILL)

    local function LoadBinds()
        for _, v in next, bindlist:GetCanvas():GetChildren() do
            v:Remove()
        end

        for key, _ in pairs(binds) do
            local bindrow = vgui.Create("DPanel")
            bindlist:AddItem(bindrow)
            bindrow:SetTall(28)
            bindrow:Dock(TOP)

            function bindrow:DoRightClick()
                local menu = DermaMenu(false, bindmenu)
                local copy = menu:AddOption("Copy console bind")
                function copy:DoClick()
                    if binds:GetType(key) == "prop" then
                        SetClipboardText([[bind ]] .. GetKeyName(key) .. [[ "gm_spawn ]] .. binds:GetValue(key) .. [["]])
                    elseif binds:GetType(key) == "command" then
                        SetClipboardText([[bind ]] .. GetKeyName(key) .. [[ "]] .. binds:GetValue(key) .. [["]])
                    end
                end

                local edit = menu:AddOption("Edit bind")
                function edit:DoClick()
                    EditBind(binds:GetType(key), key, function(newkey, value)
                        binds:SetKey(key, newkey)
                        binds:SetValue(newkey, value)
                        LoadBinds()
                    end)
                end
                menu:Open()
            end

            local binder = vgui.Create("DButton", bindrow)
            binder:SetText(GetKeyName(key))
            binder:Dock(LEFT)
            binder.DoRightClick = bindrow.DoRightClick
            function binder:DoClick()
                EditBind(binds:GetType(key), key, function(newkey, value)
                    binds:SetKey(key, newkey)
                    binds:SetValue(newkey, value)
                    LoadBinds()
                end)
            end

            local del = vgui.Create("DButton", bindrow)
            del:Dock(RIGHT)
            del:SetText("Remove")
            del.DoRightClick = bindrow.DoRightClick
            function del:DoClick()
                bindrow:Remove()
                binds:RemoveBind(key)
            end

            local valtext = vgui.Create("DButton", bindrow)
            valtext:Dock(FILL)
            //valtext:SetTextColor(Color(0,0,0))
            valtext:SetTextInset(5, 0)
            valtext:SetContentAlignment(4)
            valtext:SetText(binds:GetValue(key))
            valtext.DoClick = binder.DoClick
            valtext.DoRightClick = bindrow.DoRightClick
        end
    end
    LoadBinds()

    function addbutton:DoClick()
        local menu = DermaMenu(false, bindmenu)
        menu:AddOption("Prop", function()
            EditBind("prop", 0, function(key, model)
                local success, err = binds:AddPropBind(key, model)
                if success == false then
                    Derma_Message("Error: " .. err, "Error", "Close")
                    return
                end
                LoadBinds()
            end)
        end)
        menu:AddOption("Command", function()
            EditBind("command", 0, function(key, command)
                local success, err = binds:AddCommandBind(key, command)
                if success == false then
                    Derma_Message("Error: " .. err, "Error", "Close")
                    return
                end
                LoadBinds()
            end)
        end)
        menu:Open()
    end

    function loaddefaults:DoClick()
        local function doreset()
            binds = table.Copy(defaults)
            setmetatable(binds, bindmeta)
            
            LoadBinds()
            binds:Save()
        end
        Derma_Query("This will reset your current binds", "Reset binds", "Ok", doreset, "Cancel")
    end
end
concommand.Add("bindmenu", bindmenu)

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
    frame:SetSize(800, 600)
    frame:SetTitle("Select a model")
    frame:Center()
    frame:MakePopup()
    frame:SetBackgroundBlur(true)

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)

    for _, title in ipairs(tabOrder) do
        local proplist = modellist[title]

        local propselect = vgui.Create("PropSelect")
        propselect:Dock(FILL)
        propselect.Height = 0
        sheet:AddSheet(title, propselect)

        function propselect:OnSelect(model)
            if callback then
                callback(model)
            end
            frame:Close()
        end

        for _, v in ipairs(proplist) do
            propselect:AddModel(v)
        end
    end
end

function EditBind(type, key, callback)
    local frame = vgui.Create("DFrame")
    if type == "prop" then
        frame:SetSize(200, 200)
    else
        frame:SetSize(400, 125)
    end
    frame:SetTitle("Bind editor")
    frame:Center()
    frame:MakePopup()
    frame:SetBackgroundBlur(true)

    local buttons = vgui.Create("DPanel", frame)
    buttons:SetTall(25)
    buttons:Dock(BOTTOM)
    function buttons:Paint() end

    local accept = vgui.Create("DButton", buttons)
    accept:SetText("Accept")
    accept:SetWide(70)
    accept:DockMargin(3,0,0,0)
    accept:Dock(RIGHT)
    accept:SetEnabled(false)
    accept:SetTooltip("Please select a key")
    function accept:DoClick()
        if callback then
            callback(self.selectedKey, self.selectedValue)
        end
        frame:Close()
    end
    function accept:checkEnable()
        self:SetEnabled(false)
        
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

    local cancel = vgui.Create("DButton", buttons)
    cancel:SetText("Cancel")
    cancel:SetWide(70)
    cancel:Dock(RIGHT)
    function cancel:DoClick()
        frame:Close()
    end

    local bindinfo = vgui.Create("DPanel", frame)
    bindinfo:Dock(FILL)
    function bindinfo:Paint() end

    local bindselect = vgui.Create("DBinder", bindinfo)
    bindselect:Dock(TOP)
    function bindselect:OnChange(key)
        accept:SetKey(key)
    end
    bindselect:SetValue(key)

    if type == "prop" then
        local propselect = vgui.Create("SpawnIcon", bindinfo)
        propselect:DockMargin(40,2,40,2)
        propselect:Dock(FILL)
        function propselect:DoClick()
            ModelSelect(function(model)
                self:SetModel(model)
                accept:SetValue(model)
            end)
        end
        propselect:SetModel(binds:GetValue(key) or nil)
        accept:SetValue(binds:GetValue(key) or nil)
    elseif type == "command" then
        local command = vgui.Create("DTextEntry", bindinfo)
        command:DockMargin(0,2,0,2)
        command:Dock(TOP)
        function command:OnChange()
            local value = self:GetValue()
            if value == "" or value == nil then return end
            accept:SetValue(value)
        end
        command:SetValue(binds:GetValue(key) or "")
        command:SetPlaceholderText("command")
        command:OnChange()
    end
end
