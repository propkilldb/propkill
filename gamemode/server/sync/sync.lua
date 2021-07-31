hook.Add("ShutDown", "shutdown unsync", function()
	onDisconnect(clientsock)
	clientsock:Destroy()
end)

hook.Add("PlayerDisconnected", "disconnect unsync", function()
	if #player.GetAll() == 1 then
		onDisconnect(clientsock)
	end
end)

hook.Add("PlayerInitialSpawn", "disconnect unsync", function()
	if #player.GetAll() == 1 then
		connectSync(sync.ip, sync.port)
	end
end)

hook.Add("PhysgunPickup", "fix synced bots unfreezing", function(ply, ent)
	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then return end

	if ply.SyncedPlayer and not phys:IsMotionEnabled() then
		return false
	end
end)
