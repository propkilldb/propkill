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

// move the player up if they spawn a prop clipping into their feet
hook.Add("PlayerSpawnedProp", "pk_moveplayerup", function(ply, model, ent)
	local tr = util.TraceHull({
		start = ply:GetPos()+Vector(0,0,10),
		endpos = ply:GetPos(),
		maxs = ply:OBBMaxs(),
		mins = ply:OBBMins(),
		filter = ply
	})

	if tr.Entity == ent then
		ply:SetPos(tr.HitPos)
	end
end)

function GM:ShowTeam(ply) net.Start("pk_teamselect") net.Send(ply) end
function GM:ShowHelp(ply) net.Start("pk_helpmenu") net.Send(ply) end
function GM:ShowSpare2(ply) net.Start("pk_settingsmenu") net.Send(ply) end
