if SERVER then
	util.AddNetworkString("PK_Networking")
	util.AddNetworkString("PK_NetworkingReady")
end

PK.netCache = PK.netCache or {}
PK.netProxies = PK.netProxies or {}

function PK.GetNWVar(id, default)
	local value = PK.netCache[id]
	if value != nil and default != nil and TypeID(value) != TypeID(default) then
		error(string.format("type mismatch for '%s' default is '%s', but stored is '%s'", id, type(default), type(value)), 2)
	end
	return value or default
end

function PK.SetNWVarProxy(id, func)
	if id == nil then return end
	if not isfunction(func) then return end

	PK.netProxies[id] = func
end

if SERVER then
	function PK.SetNWVar(id, value)
		if id == nil then return end
		-- temporary workaround to just always network tables, until i write a deep compare func
		if PK.netCache[id] == value and TypeID(value) != TYPE_TABLE then return end

		if PK.netProxies[id] then
			PK.netProxies[id](PK.netCache[id], value)
		end

		PK.netCache[id] = value

		net.Start("PK_Networking")
			net.WriteString(id)
			net.WriteType(value)
		net.Broadcast()
	end

	net.Receive("PK_NetworkingReady", function(len, ply)
		net.Start("PK_NetworkingReady")
			net.WriteTable(PK.netCache)
		net.Send(ply)
	end)
end

if CLIENT then
	net.Receive("PK_Networking", function()
		local id = net.ReadString()
		local value = net.ReadType()

		if PK.netProxies[id] then
			PK.netProxies[id](PK.netCache[id], value)
		end
		
		PK.netCache[id] = value
	end)

	net.Receive("PK_NetworkingReady", function()
		local netvars = net.ReadTable()
		for id, value in next, netvars do
			if PK.netProxies[id] then
				PK.netProxies[id](PK.netCache[id], value)
			end
			
			PK.netCache[id] = value
		end
	end)

	hook.Add("InitPostEntity", "PK_NetworkingReady", function()
		net.Start("PK_NetworkingReady")
		net.SendToServer()
	end)
end
