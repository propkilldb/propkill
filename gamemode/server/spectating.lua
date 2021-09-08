local meta = FindMetaTable("Player")

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
				ply:SetNWString("arena", next:GetNWString("arena", "0"))
			end
		elseif key == IN_ATTACK2 then
			if IsValid(prev) then
				ply:SpectateEntity(prev)
				ply:SetNWString("arena", prev:GetNWString("arena", "0"))
			end
		elseif key == IN_RELOAD then
			if ply:GetObserverMode() == OBS_MODE_IN_EYE then
				ply:Spectate(OBS_MODE_ROAMING)
			else
				ply:Spectate(OBS_MODE_IN_EYE)
			end
		elseif key == IN_USE then
			ply:StopSpectating()
			ply:SetNWString("arena", "0")
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
	self:SetNWString("arena", target:GetNWString("arena", "0"))

	if not self.firstSpectate then
		self:ChatPrint("Press R for freecam or E to stop spectating")
		self.firstSpectate = true
	end
end

function meta:StopSpectating()
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

function GM:PlayerCanJoinTeam(ply, teamid)
	if ply.dueling then return false end

	return true
end
