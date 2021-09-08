if SERVER then
	util.AddNetworkString("PK_Networking")
	util.AddNetworkString("PK_NetworkingReady")
end

PK.netCache = PK.netCache or {}

local networktypes = {
	String = "String",
	Bool = "Bool",
	Table = "Table",
	Number = "Double",
	Entity = "Entity"
}

for k,v in pairs(networktypes) do
	PK["GetNW" .. k] = function(id, default)
		return PK.netCache[id] or default
	end
end

if SERVER then
	for k,v in pairs(networktypes) do
		PK["SetNW" .. k] = function(id, value)
			if id == nil then return end
			PK.netCache[id] = value
			net.Start("PK_Networking")
				net.WriteString(id)
				net.WriteString(v)
				net["Write" .. v](value)
			net.Broadcast()
		end
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
		local vartype = net.ReadString()
		local value = net["Read" .. vartype]()
		PK.netCache[id] = value
	end)

	net.Receive("PK_NetworkingReady", function()
		PK.netCache = net.ReadTable()
	end)

	hook.Add("InitPostEntity", "PK_NetworkingReady", function()
		net.Start("PK_NetworkingReady")
		net.SendToServer()
	end)
end
