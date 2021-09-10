include("sourcenet/incoming.lua")
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

local function processNetworkedVoice(data)
    for k, v in next, player.GetHumans() do
        local entIndex = v:EntIndex()
        local netChan = CNetChan(entIndex)
        if not netChan then continue end

		local buf = netChan:GetVoiceBuffer()
        buf:WriteUInt(svc_VoiceData, NET_MESSAGE_BITS)
        buf:WriteByte(data.client) // figure out who client is (entindex - 1)
        buf:WriteByte(0) // proximity
        buf:WriteWord(data.bits)

        for i = 1, data.bits do	
            buf:WriteBit(data.voiceBuffer[i])
        end
    end
end

funcs[sync.voicedata] = function(data)
	for k, v in pairs(data) do
		local ply = GetBotByCreationID(k)
		v.client = ply:EntIndex() - 1

		processNetworkedVoice(v)
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
			else
				ply:SetTeam(v.team or TEAM_DEATHMATCH)
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
		if not IsValid(ply) then continue end
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
		if not IsValid(ply) then continue end

		if v == TEAM_SPECTATOR then
			ply:SetSpectating()
		elseif ply:Team() == TEAM_SPECTATOR then
			ply:StopSpectating()
		end

		ply:SetTeam(v)
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
			dmg:SetDamageForce(Vector(v[3]))
			dmg:SetDamagePosition(Vector(v[4]))
			dmg:SetDamageCustom(12)
			dmg:SetDamage(ply:Health()*1000)
			dmg:SetInflictor(prop)
			dmg:SetDamageType(DMG_CRUSH)
			dmg:SetAttacker(att)
			
			ply:TakeDamageInfo(dmg)
			
			if ply:Alive() then
				print("oops they didnt die")
				ply:Kill()
			end
		elseif IsValid(ply) and ply:Alive() then
			print("died to null prop")
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

		// add prop to bots undo table in case sync for some reason doesnt remove it
		undo.Create("Prop")
			undo.AddEntity(prop)
			undo.SetPlayer(owner)
		undo.Finish("Prop (" .. tostring(v.model) .. ")")
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

funcs[sync.duelinvite] = function(data)
	PrintTable(data)
	for arena,v in pairs(data) do
		PrintTable(v)
		local p1 = GetPlayerByCreationID(v.initiator)
		local p2 = GetPlayerByCreationID(v.opponent)
		print(p1, p2, v.initiator, v.opponent)

		p2.duelrequest = arena
		
		p2:ChatPrint(p1:Nick() .. " invited u to duel to " .. v.kills .. " in under " .. v.time .. " minutes")
		p2:ChatPrint("/accept to begin")
		print("duel with " .. p1:Nick() .. " and " .. p2:Nick() .. " to " .. v.kills .. " in under " .. v.time .. " minutes in arena " .. arena)
	end
end

funcs[sync.duelstart] = function(data)
	for arena,v in pairs(data) do
		local player1 = GetPlayerByCreationID(v.player1)
		local player2 = GetPlayerByCreationID(v.player2)

		startSyncDuel(player1, player2, arena, v.kills, v.time)
	end
end

funcs[sync.duelupdate] = function(data)
	for arena,v in pairs(data) do
		if not sync.duel[arena] then continue end

		sync.duel[arena].player1:SetNWInt("duelscore", v.p1k)
		sync.duel[arena].player2:SetNWInt("duelscore", v.p2k)
	end
end

funcs[sync.duelend] = function(data)
	for arena,v in pairs(data) do
		PrintTable(v)
		endSyncDuel(arena, v.player1kills, v.player2kills, v.reason, v.forfeitply)
	end
end

hook.Add("SetupMove", "setsyncedbotpositions", function(ply, mv, cmd)
	if not ply.SyncedPlayer then return end

	local data = playerupdate[ply.SyncedPlayer] or latestplayerupdate[ply.SyncedPlayer]
	if not data then return end

	ply:SetEyeAngles(data.ang)
	mv:SetOrigin(data.pos)
	mv:SetVelocity(data.vel)

	if (data.fla or false) != ply:FlashlightIsOn() then
		ply:Flashlight(data.fla)
	end

	playerupdate[ply.SyncedPlayer] = nil
end)

hook.Add("StartCommand", "setbotbuttons", function(ply, cmd)
	local data = latestplayerupdate[ply.SyncedPlayer]
	if not data then return end

	if ply.SyncedPlayer and data then
		cmd:SetButtons(data.btn or 0)
	end
end)
