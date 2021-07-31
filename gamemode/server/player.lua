local meta = FindMetaTable("Player")

function meta:CleanUp()
	local undotable = undo.GetTable()[self:UniqueID()]
	if not undotable then return end

	for k,v in ipairs(undotable) do
		for l, ent in ipairs(v.Entities) do
			if not IsValid(ent) then continue end
			ent:Remove()
		end
	end
end

function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_DEATHMATCH)
	ply:Spawn()
	ply:AllowFlashlight(true)
	ply.lastTeamChange = CurTime() - 10
end

function GM:PlayerSetModel(ply)
	local playermodel = ply:GetInfo("cl_playermodel")
	local modelname = player_manager.TranslatePlayerModel(playermodel)
	util.PrecacheModel(modelname)
	ply:SetModel(modelname)

	local col = ply:GetInfo("cl_playercolor")
	ply:SetPlayerColor(Vector(col))
end

hook.Add("PlayerLoadout", "PK_PlayerSpawn", function(ply)
	if ply:Team() != TEAM_UNASSIGNED then
		ply:SetHealth(1)
		ply:Give("weapon_physgun")
	end

	local col = ply:GetInfo("cl_weaponcolor")
	ply:SetWeaponColor(Vector(col))
end)


function GM:PlayerSpawn(ply)
	player_manager.OnPlayerSpawn(ply)
	player_manager.RunClass(ply, "Spawn")

	hook.Call("PlayerLoadout", GAMEMODE, ply)
	hook.Call("PlayerSetModel", GAMEMODE, ply)
	ply:SetupHands()

	ply:SetCustomCollisionCheck(true)

	ply.streak = 0
	ply:SetWalkSpeed(400)
	ply:SetRunSpeed(400)
	ply:SetJumpPower(200)
end

function GM:DoPlayerDeath(ply, attacker, dmg)
	ply:CreateRagdoll()
	ply:AddDeaths(1)

	if IsValid(attacker) and attacker:IsPlayer() and attacker != ply then
		attacker:AddFrags(1)
	end
end

util.AddNetworkString("KilledByProp")

function GM:PlayerDeath(ply, inflictor, attacker)
	if IsValid(inflictor) and inflictor:GetClass() == "prop_physics" then
		attacker = inflictor.Owner
		attacker:SendLua("surface.PlaySound(\"/buttons/lightswitch2.wav\")")
		//attacker:SendLua("surface.PlaySound(\"garrysmod/balloon_pop_cute.wav\")")
		attacker.streak = attacker.streak + 1
	end

	ply.streak = 0
	ply.NextSpawnTime = CurTime() + 1

	net.Start("KilledByProp")
		net.WriteEntity(ply)
		net.WriteString(inflictor:GetClass())
		net.WriteEntity(attacker)
	net.Broadcast()

	ply:CleanUp()
end

function GM:PlayerConnect(name, ip)
	ChatMsg({Color(120,120,255), name, Color(255,255,255), " is connecting"})
end

function GM:PlayerDisconnected(ply)
	ply:CleanUp()
	ChatMsg({Color(120,120,255), ply:Nick(), Color(255,255,255), " has disconnected"})
end

hook.Add("PlayerShouldTakeDamage", "PK_PlayerShouldTakeDamage", function(ply, attacker)
	if ply:Team() == TEAM_UNASSIGNED then
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
	if inflictor == game.GetWorld() then return end // TODO: find closest prop if world damages

	if IsValid(inflictor) and IsValid(inflictor.Owner) and inflictor.Owner:IsPlayer() then		
		dmg:SetAttacker(inflictor.Owner)
	end

	dmg:AddDamage(target:Health()+10000)

	if inflictor.SyncedProp and dmg:GetDamageCustom() != 12 then
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

local function GetValidPlayers(tbl)
	if not tbl then tbl = player.GetAll() end
	local ret = {}
	
	for k,v in pairs(tbl) do
		if v:Alive() and v:Team() != TEAM_SPECTATOR then
			table.insert(ret, v)
		end
	end

	return ret
end

function GetNextPlayer(spectator, spectating)
	local players = GetValidPlayers()
	local picknext = false
	local choice = NULL
	local prev = NULL
	local last = NULL

	if table.Count(players) == 0 then
		return NULL, NULL
	end

	for k,v in pairs(players) do
		if v == spectating then
			picknext = true
			prev = last
			continue
		end

		if picknext then
			choice = v
			break
		end

		last = v
	end

	if not IsValid(choice) then
		for k,v in pairs(players) do
			choice = v
			break
		end
	end

	if not IsValid(prev) then
		for k,v in pairs(players) do
			prev = v
		end
	end

	return choice, prev
end

hook.Add("KeyPress", "speccontrols", function(ply, key)
	if ply:GetObserverMode() != OBS_MODE_NONE then
		local next, prev = GetNextPlayer(ply, ply:GetObserverTarget())

		if key == IN_ATTACK then
			if IsValid(next) then
				ply:SpectateEntity(next)
			end
		elseif key == IN_ATTACK2 then
			if IsValid(prev) then
				ply:SpectateEntity(prev)
			end
		elseif key == IN_USE then
			ply:StopSpectating()
		end
	end
end)

function meta:SetSpectating(target)
	if not GAMEMODE:PlayerCanJoinTeam(self, TEAM_SPECTATOR) then return end
	if IsValid(target) and target:IsPlayer() and target:Team() == TEAM_SPECTATOR then return end

	self:SetTeam(TEAM_SPECTATOR)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetSolid(SOLID_NONE)
	self:StripWeapons()
	GAMEMODE:PlayerSpawnAsSpectator(self)
	self:Spectate(OBS_MODE_IN_EYE)

	if not IsValid(target) then
		for k,v in pairs(GetValidPlayers()) do
			target = v
			break
		end
	end
	self:SpectateEntity(target)

	if not self.firstSpectate then
		self:ChatPrint("Press E to stop spectating")
		self.firstSpectate = true
	end
end

function meta:StopSpectating(target)
	if not GAMEMODE:PlayerCanJoinTeam(self, TEAM_DEATHMATCH) then return end

	self:SetTeam(TEAM_DEATHMATCH)
	self:UnSpectate()
	self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	self:SetSolid(SOLID_BBOX)
	self:Spawn()
end

util.AddNetworkString("PK_SpectatePlayer")
net.Receive("PK_SpectatePlayer", function(len, ply)
	local target = net.ReadEntity()
	ply:SetSpectating(target)
end)

function GM:ShowTeam(ply) net.Start("pk_teamselect") net.Send(ply) end
function GM:ShowHelp(ply) net.Start("pk_helpmenu") net.Send(ply) end
function GM:ShowSpare2(ply) net.Start("pk_settingsmenu") net.Send(ply) end
