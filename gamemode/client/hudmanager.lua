
PK.registeredHudElements = PK.registeredHudElements or {}
PK.currentHudElements = PK.currentHudElements or {}
PK.hudNWVars = PK.hudNWVars or {}

local formatmap = {}

-- custom %p = player name
formatmap["%p"] = function(ply, var)
	local target = ply:GetNW2Entity(var)
	if IsValid(target) and target:IsPlayer() then
		return target:Nick()
	end

	return "nobody"
end

-- custom %t = time hh:mm:ss or mm:ss
formatmap["%t"] = function(ply, var)
	local value = ply:GetNW2Int(var)
	value = math.floor(tonumber(value) or 0)

	local hours = math.floor(value / 3600)
	local minutes = math.floor((value % 3600) / 60)
	local seconds = value % 60

	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, seconds)
	else
		return string.format("%d:%02d", minutes, seconds)
	end
end

-- custom %T = expanded time 301 = 5 minutes, 1 second
formatmap["%T"] = function(ply, var)
	local value = ply:GetNW2Int(var)
	return PrettyTime(value)
end

formatmap["%s"] = function(ply, var)
	return ply:GetNW2String(var)
end

formatmap["%d"] = function(ply, var)
	return ply:GetNW2Int(var)
end

formatmap["%f"] = function(ply, var)
	return ply:GetNW2Float(var)
end

formatmap["%n"] = function(ply, var)
	return ""
end

for k, v in next, {"%i", "%u", "%o", "%c", "%x", "%X"} do
	formatmap[v] = formatmap["%d"]
end

for k, v in next, {"%F", "%e", "%E", "%g", "%G", "%a", "%A"} do
	formatmap[v] = formatmap["%f"]
end

function GetObservedPlayer()
	local ply = LocalPlayer()

	if ply:GetObserverMode() != OBS_MODE_NONE and IsValid(ply:GetObserverTarget()) and ply:GetObserverTarget():IsPlayer() then
		ply = ply:GetObserverTarget()
	end

	return ply
end

function PK.formatHudString(tbl)
	if not istable(tbl) then return tbl end

	tbl = table.Copy(tbl)

	local formatstr = table.remove(tbl, 1)
	local args = {}
	local ply = GetObservedPlayer()

	for v in formatstr:gmatch("%%[pdiuoxXfFeEgGaAcsntT]") do
		local getvar = formatmap[v]
		local netvar = table.remove(tbl, 1)
		local value = ""
		local scope = netvar:sub(1,2):lower()

		if scope == "g:" then
			value = tostring(getvar(game.GetWorld(), netvar:sub(3)))
		elseif scope == "p:" then
			value = tostring(getvar(ply, netvar:sub(3)))
		else
			value = tostring(getvar(ply, netvar)) -- default to player scope
		end

		table.insert(args, value)
	end

	formatstr = string.gsub(formatstr, "%%[ptT]", "%%s")

	return string.format(formatstr, unpack(args))
end

function PK.RegisterHudElement(style, create, update)
	PK.registeredHudElements[style] = {
		create = create,
		update = update
	}
end

hook.Add("EntityNetworkedVarChanged", "update hud vars", function(ent, nwvar, old, new)
	local entmap = PK.hudNWVars[ent]
	if not entmap then return end
	local varmap = entmap[nwvar]
	if not varmap then return end

	for id, v in next, varmap do
		local panel = PK.currentHudElements[id]
		if not IsValid(panel) then
			varmap[id] = nil
			continue
		end

		-- delay 1 frame cos the nwvar isnt updated until after this hook
		timer.Simple(0, function()
			if IsValid(panel) then
				panel:UpdateValues()
			else
				varmap[id] = nil
			end
		end)
	end
end)

local function addNWVarProxy(ent, nwvar, id)
	PK.hudNWVars[ent] = PK.hudNWVars[ent] or {}
	PK.hudNWVars[ent][nwvar] = PK.hudNWVars[ent][nwvar] or {}
	PK.hudNWVars[ent][nwvar][id] = true
end

local function setupNWVarProxies(id, data)
	local netvars = {}

	for k, v in next, data do
		if not istable(v) then continue end
		for i=2, #v do
			table.insert(netvars, v[i])
		end
	end

	local viewply = GetObservedPlayer()

	for k, nwvar in next, netvars do
		local scope = nwvar:sub(1,2):lower()

		if scope == "g:" then
			addNWVarProxy(game.GetWorld(), nwvar:sub(3), id)
		elseif scope == "p:" then
			addNWVarProxy(viewply, nwvar:sub(3), id)
		else
			addNWVarProxy(viewply, nwvar, id)
		end
	end
end

local function createHudElement(id, data)
	local existing = PK.currentHudElements[id]
	if IsValid(existing) then
		return -- element already exists
	end

	local element = PK.registeredHudElements[data.style]
	if not element then
		error("attempt to create unknown hud style '" .. tostring(data.style) .. "'", 2)
	end

	local newelement = element.create(data)
	if not IsValid(newelement) then
		error("panel was not returned by hud element '" .. tostring(id) .. "'", 2)
	end

	if element.update then
		-- nest the function so we can keep data cached
		newelement.UpdateValues = function()
			element.update(newelement, data)
		end
		newelement:UpdateValues()

		setupNWVarProxies(id, data)
	end

	PK.currentHudElements[id] = newelement
end

local function LoadHudElements(data)
	for k, v in next, PK.currentHudElements do
		if not data[k] then
			print("Removing hud element", k)
			v:Remove()
			PK.currentHudElements[k] = nil
		end
	end

	for k, v in next, data do
		if not IsValid(PK.currentHudElements[k]) then
			print("Adding hud element", k)
			createHudElement(k, v)
		end
	end
end

hook.Add("PK_ObserverTargetChanged", "update hud on spectate", function()
	local hudstate = PK.GetNWVar("hudstate", {})
	LoadHudElements(hudstate)
	
	for id, panel in next, PK.currentHudElements do
		if not IsValid(panel) then continue end

		setupNWVarProxies(id, hudstate[id])
		panel:UpdateValues()
	end
end)

PK.SetNWVarProxy("hudstate", function(oldstate, newstate)
	if not istable(newstate) then return end
	LoadHudElements(newstate)
end)
