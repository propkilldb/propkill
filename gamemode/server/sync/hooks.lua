sync.sendqueue = sync.sendqueue or {}
sync.propstosync = sync.propstosync or {}

FilterIncomingMessage(clc_VoiceData, function(netChan, read, write)
	write:WriteUInt(clc_VoiceData, NET_MESSAGE_BITS)

	local bits = read:ReadWord()
	write:WriteWord(bits)

	if bits > 0 then
		local voiceBuffer = {}
		for i = 1, bits do
			voiceBuffer[i] = read:ReadBit()
			write:WriteBit(voiceBuffer[i])
		end

		local ply = GetPlayerByIP(tostring(netChan:GetAddress()))

		if IsValid(ply) and ply:IsBot() then return end
		if not sync.sendqueue[sync.voicedata] then sync.sendqueue[sync.voicedata] = {} end
		
		sync.sendqueue[sync.voicedata][ply:GetCreationID()] = {
			bits = bits,
			voiceBuffer = voiceBuffer
		}
	end
end)

hook.Add("SetupMove", "queueplayerpositions", function(ply, mv, cmd)
	if not ply:IsBot() then
		if not sync.sendqueue[sync.playerupdate] then sync.sendqueue[sync.playerupdate] = {} end
		
		sync.sendqueue[sync.playerupdate][ply:GetCreationID()] = {
			pos = mv:GetOrigin(),
			ang = mv:GetAngles(),
			vel = mv:GetVelocity(),
			btn = mv:GetButtons(),
			scr = cmd:GetMouseWheel(),
			fla = ply:FlashlightIsOn(),
		}
	end
end)

hook.Add("Think", "syncpropmove", function()
	if not sync.sendqueue[sync.propupdate] then sync.sendqueue[sync.propupdate] = {} end
	
	for k,v in pairs(sync.propstosync) do
		if not IsValid(v) then
			sync.propstosync[k] = nil
			continue
		end
		
		local phys = v:GetPhysicsObject()
		if phys:IsAsleep() then continue end
		
		sync.sendqueue[sync.propupdate][k] = {
			pos = v:GetPos(),
			ang = v:GetAngles(),
			vel = v:GetVelocity(),
			inr = phys:GetInertia(),
			anv = phys:GetAngleVelocity(),
			freeze = IsValid(phys) and phys:IsMotionEnabled() or false
		}
	end
end)

hook.Add("PlayerInitialSpawn", "syncplayerspawn", function(ply)
	if ply:IsBot() then return end
	if not sync.sendqueue[sync.addplayers] then sync.sendqueue[sync.addplayers] = {} end
	
	sync.sendqueue[sync.addplayers][ply:GetCreationID()] = {
		name = ply:Name(),
		steamid = ply:SteamID(),
		pos = ply:GetPos(),
		ang = ply:GetAngles(),
		vel = ply:GetVelocity(),
		alive = ply:Alive(),
		wepcol = ply:GetInfo("cl_weaponcolor"),
		color = ply:GetInfo("cl_playercolor"),
		model = ply:GetInfo("cl_playermodel"),
		team = ply:Team()
	}
end)

hook.Add("PlayerDisconnected", "syncplayerdisconnect", function(ply)
	if not sync.sendqueue[sync.playerdisconnect] then sync.sendqueue[sync.playerdisconnect] = {} end
	
	sync.sendqueue[sync.playerdisconnect][ply:GetCreationID()] = true
end)

hook.Add("PlayerSpawnedProp", "syncpropspawns", function(ply, model, ent)
	if not sync.sendqueue[sync.spawnprops] then sync.sendqueue[sync.spawnprops] = {} end
	if not IsValid(ply) then return end
	if ply.SyncedPlayer then return end
	
	sync.sendqueue[sync.spawnprops][ent:GetCreationID()] = {
		model = model,
		pos = ent:GetPos(),
		ang = ent:GetAngles(),
		vel = ent:GetVelocity(),
		owner = ply:GetCreationID(),
	}

	local phys = ent:GetPhysicsObject()
	
	if phys then
		sync.sendqueue[sync.spawnprops][ent:GetCreationID()].anv = phys:GetAngleVelocity()
		sync.sendqueue[sync.spawnprops][ent:GetCreationID()].inr = phys:GetInertia()
	end
	
	sync.propstosync[ent:GetCreationID()] = ent
end)

hook.Add("EntityRemoved", "syncpropremove", function(ent)
	if not sync.sendqueue[sync.removeprops] then sync.sendqueue[sync.removeprops] = {} end
	
	if sync.propstosync[ent:GetCreationID()] then
		sync.propstosync[ent:GetCreationID()] = nil
	end

	if sync.sendqueue[sync.spawnprops] and sync.sendqueue[sync.spawnprops][ent:GetCreationID()] then
		sync.sendqueue[sync.spawnprops][ent:GetCreationID()] = nil
	end
	
	sync.sendqueue[sync.removeprops][ent:GetCreationID()] = true
end)

hook.Add("PlayerSay", "syncchat", function(ply, msg)
	if ply:IsBot() then return end
	if not sync.sendqueue[sync.chatmessage] then sync.sendqueue[sync.chatmessage] = {} end
	
	table.insert(sync.sendqueue[sync.chatmessage], {ply:GetCreationID(), msg})
end)

hook.Add("DoPlayerDeath", "syncplayerdeath", function(ply, att, dmg)
	if not sync.sendqueue[sync.playerkill] then sync.sendqueue[sync.playerkill] = {} end

	local inf = dmg:GetInflictor()
	
	sync.sendqueue[sync.playerkill][ply.SyncedPlayer and ply.SyncedPlayer or ply:GetCreationID()] = {
		IsValid(att) and att:GetCreationID() or NULL,
		IsValid(inf) and inf:GetCreationID() or NULL,
		dmg:GetDamageForce(),
		dmg:GetDamagePosition()
		}
end)

hook.Add("PlayerDeathThink", "syncrespawn", function(ply)
	if ply.SyncedPlayer then
		return false
	end
end)

hook.Add("PlayerSpawn", "syncplayerspawn", function(ply)
	if not sync.sendqueue[sync.playerspawn] then sync.sendqueue[sync.playerspawn] = {} end
	
	if not ply.SyncedPlayer then
		sync.sendqueue[sync.playerspawn][ply:GetCreationID()] = {
			ply:GetInfo("cl_weaponcolor"),
			ply:GetInfo("cl_playercolor"),
			ply:GetInfo("cl_playermodel"),
		}
	else
		ply:SelectWeapon("weapon_physgun")
	end
end)

hook.Add("PlayerChangedTeam", "syncteamchanges", function(ply, old, new)
	if ply.SyncedPlayer then return end
	if not sync.sendqueue[sync.playerteam] then sync.sendqueue[sync.playerteam] = {} end

	sync.sendqueue[sync.playerteam][ply:GetCreationID()] = new
end)
