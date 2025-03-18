local meta = FindMetaTable("Player")

function meta:CleanUp()
	local undotable = undo.GetTable()[self:UniqueID()]
	if not undotable then return end

	for k,v in ipairs(undotable) do
		if not v.Entities then continue end

		for l, ent in ipairs(v.Entities) do
			if not IsValid(ent) then continue end

			ent:Remove()
		end
	end
end

-- delete all but their last prop, which will be cleaned up 1 second after they die
function meta:LastStand()
	local undotable = undo.GetTable()[self:UniqueID()]
	if not undotable then return end

	for k,v in pairs(undotable) do
		if v.Entities and IsValid(v.Entities[1]) then
			if IsValid(last) then
				last:Remove()
			end

			last = v.Entities[1]
		end
	end
end

// play the kill sound for the player and anyone spectating the player
function meta:PlayKillSound()
	for k,v in next, player.GetHumans() do
		if v == self or v:GetObserverTarget() == self then
			v:SendLua([[surface.PlaySound("/buttons/lightswitch2.wav")]])
		end
	end
end

function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_DEATHMATCH)
	ply:Spawn()
	ply:AllowFlashlight(true)
	ply.lastTeamChange = CurTime() - 10
end

util.PrecacheModel("models/player/group01/male_07.mdl")

function GM:PlayerSetModel(ply)
	//local playermodel = ply:GetInfo("cl_playermodel")
	//local modelname = player_manager.TranslatePlayerModel(playermodel)
	
	ply:SetModel("models/player/group01/male_07.mdl")

	local col = ply:GetInfo("cl_playercolor")
	ply:SetPlayerColor(Vector(col))
end

function GM:PlayerLoadout(ply)
	if ply:Team() != TEAM_UNASSIGNED then
		ply:SetHealth(1)
		ply:StripWeapons()
		ply:Give("weapon_physgun")
	end

	local col = ply:GetInfo("cl_weaponcolor")
	ply:SetWeaponColor(Vector(col))
end

function GM:PlayerSpawn(ply)
	if ply:Team() == TEAM_SPECTATOR then
		GAMEMODE:PlayerSpawnAsSpectator(ply)
		return
	end

	player_manager.OnPlayerSpawn(ply)
	player_manager.RunClass(ply, "Spawn")

	hook.Call("PlayerLoadout", GAMEMODE, ply)
	hook.Call("PlayerSetModel", GAMEMODE, ply)
	ply:SetupHands()

	ply:SetCustomCollisionCheck(true)

	ply.PKStreak = 0
	ply:SetWalkSpeed(400)
	ply:SetRunSpeed(400)
	ply:SetJumpPower(200)
end

function GM:DoPlayerDeath(ply, attacker, dmg)
	if ply:Team() == TEAM_SPECTATOR then return end

	ply:CreateRagdoll()
	ply:AddDeaths(1)

	if IsValid(attacker) and attacker:IsPlayer() and attacker != ply then
		attacker:AddFrags(1)
	end
end

function ResetKillstreak()
	for k,v in next, player.GetAll() do
		v.PKStreak = 0
	end

	PK.SetNWVar("streakleader", NULL)
	PK.SetNWVar("streakkills", 0)
end

function GetHighestKillStreak()
	local ply = NULL
	local streak = 0

	for k,v in next, player.GetAll() do
		if v:Team() != TEAM_DEATHMATCH then continue end

		if (v.PKStreak or 0) > streak then
			streak = v.PKStreak
			ply = v
		end
	end

	return ply, streak
end

local function RemoveLeader(ply)
	ply.PKStreak = 0

	if ply == PK.GetNWVar("streakleader", NULL) then
		local leader, kills = GetHighestKillStreak()

		PK.SetNWVar("streakleader", ply)
		PK.SetNWVar("streakkills", kills)
	end
end

hook.Add("PlayerChangedTeam", "resetstreak", RemoveLeader)
hook.Add("PlayerDisconnected", "removeleader", RemoveLeader)

function GM:PlayerDeath(ply, inflictor, attacker)
	if IsValid(inflictor) and inflictor:GetClass() == "prop_physics" then
		attacker = inflictor.Owner

		attacker.PKStreak = (attacker.PKStreak or 0) + 1
		attacker:PlayKillSound()

		if attacker == ply then
			self:SendDeathNotice(nil, inflictor:GetClass(), ply, 0)
		else
			self:SendDeathNotice(attacker, inflictor:GetClass(), ply, 0)
		end
	end

	ply.PKStreak = 0
	ply.NextSpawnTime = CurTime() + 1

	local updateLeader = false

	-- if it was the leader who died, find the next highest streak
	if PK.GetNWVar("streakleader", NULL) == ply then
		local leader, kills = GetHighestKillStreak()

		PK.SetNWVar("streakleader", leader)
		PK.SetNWVar("streakkills", kills)
	end

	-- if the attackers kills are higher than the current leader, make them the new leader
	if attacker.PKStreak > PK.GetNWVar("streakkills", 0) then
		PK.SetNWVar("streakleader", attacker)
		PK.SetNWVar("streakkills", attacker.PKStreak)
	end

	ply:LastStand()
	
	timer.Simple(1, function()
		if not IsValid(ply) then return end
		ply:CleanUp()
	end)
end

hook.Add("PlayerDeath", "streak end chat message", function(ply, inflictor, attacker)
	if not IsValid(inflictor) or not inflictor:GetClass() == "prop_physics" then return end
	attacker = inflictor.Owner
	if not IsValid(attacker) or not attacker:IsPlayer() then return end

	if ply.PKStreak and ply.PKStreak > 7 then
		ChatMsg({
			Color(0,120,255), attacker:Nick(),
			Color(255,255,255), " just ended ",
			Color(0,120,255), attacker == ply and "their own " or ply:Nick() .. "'s ",
			Color(255,255,255), tostring(ply.PKStreak), " killstreak"
		})
	end
end)

function GM:PlayerConnect(name, ip)
	ip = string.Explode(":", ip)[1]
	ip = string.Replace(ip, ".", "%2E")
	http.Fetch(string.format("http://ip-api.com/json/%s?fields=country", ip), function(body)
		local data = util.JSONToTable(body)

		print(name, "is connecting from", data["country"])
		ChatMsg({Color(0,120,255), name, Color(255,255,255), " is connecting from ", Color(0,225,0), data["country"]})
	end,
	function(err)
		print("[PlayerConnect] join message ERROR", err, name, ip)
		ChatMsg({Color(0,120,255), name, Color(255,255,255), " is connecting"})
	end)
end

function GM:PlayerDisconnected(ply)
	ply:CleanUp()
	ChatMsg({Color(0,120,255), ply:Nick(), Color(255,255,255), " has disconnected"})
end

hook.Add("PlayerShouldTakeDamage", "PK_PlayerShouldTakeDamage", function(ply, attacker)
	if ply:Team() == TEAM_UNASSIGNED then
		return false
	end

	if attacker == game.GetWorld() then
		return false
	end

	if IsValid(attacker) and attacker:IsPlayer() then
		if attacker:Team() == TEAM_UNASSIGNED then
			return false
		end
	elseif IsValid(attacker) and attacker:GetClass() == "trigger_hurt" then
		return true
	end
end)

function GM:EntityTakeDamage(target, dmg)
	local inflictor = dmg:GetInflictor()
		
	if not target:IsPlayer() then return end

	if IsValid(inflictor) and IsValid(inflictor.Owner) and inflictor.Owner:IsPlayer() then		
		dmg:SetAttacker(inflictor.Owner)
	end

	dmg:AddDamage(target:Health()+1)

	if dmg:IsExplosionDamage() then
		dmg:SetDamage(0)
	end
end

function GM:PlayerDeathSound()
	// disables flatline sound
	return true
end

function GM:GetFallDamage()
	// disable fall crunch
	return 0
end

util.AddNetworkString("pk_teamselect")

function GM:ShowTeam(ply) net.Start("pk_teamselect") net.Send(ply) end
function GM:ShowHelp(ply) net.Start("pk_helpmenu") net.Send(ply) end
function GM:ShowSpare2(ply) net.Start("pk_settingsmenu") net.Send(ply) end
