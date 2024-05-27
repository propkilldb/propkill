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

// i guess i didnt know about the next() function when i made this
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
			-- continue after in case they are the only player on the server
			if v == spectator then continue end
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
		elseif key == IN_RELOAD then
			if ply:GetObserverMode() == OBS_MODE_ROAMING then
				ply:Spectate(OBS_MODE_IN_EYE)
			elseif ply:GetObserverMode() == OBS_MODE_IN_EYE then
				ply:Spectate(OBS_MODE_CHASE)
			else
				ply:Spectate(OBS_MODE_ROAMING)
			end
		elseif key == IN_USE then
			ply:StopSpectating()
		end
	end
end)

function meta:SetSpectating(target, force)
	if self:Team() != TEAM_SPECTATOR and not force and hook.Run("PK_CanSpectate", self) == false then return end
	if not IsValid(target) or not target:IsPlayer() or target:Team() == TEAM_SPECTATOR then
		target = GetNextPlayer(self)
	end

	self:CleanUp()
	self.OriginalFlashlightState = self:CanUseFlashlight()
	if self:FlashlightIsOn() then
		self:Flashlight(false)
	end
	self:AllowFlashlight(false)

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

	//if not self.firstSpectate then
		self:ChatPrint("Press E to stop spectating, or R to switch spectator modes")
		//self.firstSpectate = true
	//end
end

function meta:StopSpectating(force)
	if not force and hook.Run("PK_CanStopSpectating", self) == false then return end

	self:AllowFlashlight(self.OriginalFlashlightState or true)
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

hook.Add("CanPlayerSuicide", "no spec suicide", function(ply)
	if ply:Team() == TEAM_SPECTATOR then
		return false
	end
end)

hook.Add("PlayerDeath", "auto switch spectator on death", function(ply)
	for k,v in next, player.GetAll() do
		if v:GetObserverTarget() == ply then
			local nxt, prev = GetNextPlayer(v, ply)
			v:SpectateEntity(nxt)
		end
	end
end)

function GM:PlayerCanJoinTeam(ply, teamid)
	if ply.dueling then return false end

	return true
end
