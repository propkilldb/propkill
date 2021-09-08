hook.Add("ShutDown", "shutdown unsync", function()
	onDisconnect()
	clientsock:Destroy()
end)

hook.Add("PlayerDisconnected", "disconnect unsync", function()
	if #player.GetAll() == 1 then
		onDisconnect()
	end
end)

hook.Add("PlayerInitialSpawn", "disconnect unsync", function(ply)
	if #player.GetAll() == 1 then
		connectSync(sync.ip, sync.port)
	end

	ply:SetNWString("arena", "0")
end)

hook.Add("PhysgunPickup", "fix synced bots unfreezing", function(ply, ent)
	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then return end

	if ply.SyncedPlayer and not phys:IsMotionEnabled() then
		return false
	end
end)

// im lazy lol
local meta = FindMetaTable("Entity")
oGetCreationID = oGetCreationID or meta.GetCreationID
creationIDOffset = creationIDOffset or math.random(10000)

function meta:GetCreationID()
	return oGetCreationID(self) + creationIDOffset
end
