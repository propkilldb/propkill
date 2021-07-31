local funcs = {}
local playerupdate = playerupdate or {}
local latestplayerupdate = latestplayerupdate or {}
sync.syncedprops = sync.syncedprops or {}

function processSync(data)
	if not data then return end

	for k,v in pairs(data) do
		if funcs[k] then
			funcs[k](v)
		end
	end
end

funcs[sync.addplayers] = function(data)
	for k,v in pairs(data) do
		local ply = player.CreateNextBot(v.name .. "/sync")
		if not IsValid(ply) then continue end
		if not ply.SyncedPlayer then
			ply.SyncedPlayer = k
			playerupdate[k] = v
			ply:SetNWString("sync_steamid", v.steamid)
			ply:SelectWeapon("weapon_physgun")
			ply:SetWeaponColor(Vector(v.wepcol))
			ply:SetPlayerColor(Vector(v.color))
			local model = player_manager.TranslatePlayerModel(v.model)
			util.PrecacheModel(model)
			ply:SetModel(model)

			if v.team == TEAM_SPECTATOR then
				ply:SetSpectating()
			elseif v.team == TEAM_DEATHMATCH then
				ply:StopSpectating()
			end

			if ply:Alive() and !v.alive then
				ply:KillSilent()
			end
		end
	end
end

funcs[sync.playerspawn] = function(data)
	for k,v in pairs(data) do
		local ply = GetBotByCreationID(k)
		if IsValid(ply) and ply:IsBot() then
			ply:Spawn()
			ply:SetWeaponColor(Vector(v[1]))
			ply:SetPlayerColor(Vector(v[2]))
			local model = player_manager.TranslatePlayerModel(v[3] or "kleiner")
			ply:SetModel(model)
		end
	end
end

funcs[sync.playerdisconnect] = function(data)
	for k,v in pairs(data) do
		local ply = GetBotByCreationID(k)
		ply:Kick()
	end
end

funcs[sync.playerupdate] = function(data)
	for ply, packet in pairs(data) do
		playerupdate[ply] = packet
		latestplayerupdate[ply] = packet
	end
end

funcs[sync.playerteam] = function(data)
	for k, v in pairs(data) do
		local ply = GetBotByCreationID(k)

		if v == TEAM_SPECTATOR then
			ply:SetSpectating()
		elseif v == TEAM_DEATHMATCH then
			ply:StopSpectating()
		end
	end
end

funcs[sync.playerkill] = function(data)
	for k,v in pairs(data) do
		local ply = GetPlayerByCreationID(k)
		local att = GetPlayerByCreationID(v[1])
		local prop = GetPropByCreationID(v[2])
		
		if not IsValid(att) and IsValid(prop) and prop.Owner and IsValid(prop.Owner) then
			att = prop.Owner
		end
		
		print("kill:", ply, att, prop)
		if IsValid(ply) and IsValid(prop) and ply:Alive() then
			local dmg = DamageInfo()
			dmg:SetDamageForce(v[3] or Vector())
			dmg:SetDamagePosition(v[4] or Vector())
			dmg:SetDamageCustom(12)
			dmg:SetDamage(ply:Health()*1000)
			if IsValid(att) then
				dmg:SetAttacker(att)
			end
			if IsValid(prop) then
				dmg:SetInflictor(prop)
			end
			dmg:SetDamageType(DMG_CRUSH)
			
			ply:TakeDamageInfo(dmg)
			
			if ply:Alive() then
				print("oops they didnt die")
				ply:Kill()
			end
		elseif IsValid(ply) and ply:Alive() then
			ply:Kill()
		end
	end
end

funcs[sync.spawnprops] = function(data)
	for k,v in pairs(data) do
		local owner = GetBotByCreationID(v.owner)
		if not IsValid(owner) then continue end

		local prop = ents.Create("prop_physics")
		if not IsValid(prop) then continue end

		prop:SetModel(v.model or "")
		prop:SetPos(v.pos or Vector())
		prop:SetAngles(v.ang or Angle())
		prop:Spawn()

		prop.SyncedProp = true
		prop.Owner = owner
		sync.syncedprops[k] = prop

		hook.Run("PlayerSpawnedProp", owner, v.model or "", prop)
	end
end

funcs[sync.propupdate] = function(data)
	for k,v in pairs(data) do
		local prop = sync.syncedprops[k]
		
		if not IsValid(prop) then continue end
		local phys = prop:GetPhysicsObject()
		if not IsValid(phys) then continue end
		phys:EnableMotion(v.freeze)
		if not v.freeze then continue end
		phys:SetPos(v.pos)
		phys:SetAngles(v.ang)
		phys:SetVelocity(v.vel)
		phys:SetAngleVelocity(v.anv)
		phys:SetInertia(v.inr or phys:GetInertia())
	end
end

funcs[sync.removeprops] = function(data)
	for k,v in pairs(data) do
		if sync.syncedprops[k] and IsValid(sync.syncedprops[k]) then
			sync.syncedprops[k]:Remove()
			sync.syncedprops[k] = nil
		end
	end
end

funcs[sync.chatmessage] = function(data)
	for k,v in pairs(data) do
		GetBotByCreationID(v[1]):Say(v[2])
	end
end

hook.Add("SetupMove", "setsyncedbotpositions", function(ply, mv, cmd)
	if ply.SyncedPlayer and playerupdate[ply.SyncedPlayer] then
		local data = playerupdate[ply.SyncedPlayer]

		ply:SetEyeAngles(data.ang)
		mv:SetOrigin(data.pos)
		mv:SetVelocity(data.vel)

		if (data.fla or false) != ply:FlashlightIsOn() then
			ply:Flashlight(data.fla)
		end

		playerupdate[ply.SyncedPlayer] = nil
	end

	if ply.SyncedPlayer and latestplayerupdate[ply.SyncedPlayer] then
		local data = latestplayerupdate[ply.SyncedPlayer]
		ply:SetEyeAngles(data.ang)
	end
end)

hook.Add("StartCommand", "setbotbuttons", function(ply, cmd)
	local data = latestplayerupdate[ply.SyncedPlayer]

	if ply.SyncedPlayer and data then
		cmd:SetButtons(data.btn or 0)
		cmd:SetMouseWheel(data.scr or 0)
	end
end)
