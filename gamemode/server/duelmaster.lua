
local event = newEvent("duelmaster")
local queue = {}

event:Hook("PK_CanSpectate", "duelists cant spectate", function(ply)
	if ply.dueling then return false end
end)

event:Hook("PK_CanStopSpectating", "no, u cant join in", function(ply)
	return false
end)

event:Hook("PlayerInitialSpawn", "add them to the queue", function(ply)
	table.insert(queue, ply)
end)

event:Hook("PlayerDisconnected", "remove them from the queue", function(ply)
	DeleteDuelist(ply)
end)

event:Hook("PlayerDeath", "select next duelist", function(ply1)
	local ply2 = ply1.opponent

	ply1:SetNWInt("duelscore", 0)
	ply2:SetNWInt("duelscore", ply2:GetNWInt("duelscore", 0) + 1)

	if ply2:GetNWInt("duelscore", 0) == GetGlobalInt("kills", 8) then
		event:End(ply2)
		return
	end

	DespawnDuelist(ply1)
	SpawnNextDuelist(ply2)
end)

-- spawn the next duelist from the queue
function SpawnNextDuelist(opponent)
	local ply = table.remove(queue, 1)

	ply:SetNWInt("duelscore", 0)
	ply.dueling = true
	ply.opponent = opponent
	opponent.opponent = ply
	ply:StopSpectating(true)

	if not GetGlobalEntity("player1", NULL).dueling then
		SetGlobalEntity("player1", ply)
	else
		SetGlobalEntity("player2", ply)
	end

	return ply
end

function DespawnDuelist(ply)
	ply:SetSpectating(ply.opponent, true)

	ply.dueling = false
	ply.opponent = nil

	table.insert(queue, ply)
end

-- for when they're afk or disconnect
function DeleteDuelist(ply)
	if ply.dueling then
		SpawnNextDuelist(ply.opponent)
	end

	ply:SetSpectating(ply.opponent, true)

	ply.dueling = false
	ply.opponent = nil

	table.remove(queue, table.KeyFromValue(ply))
	
	if #queue < 3 then
		event:End()
	end
end

event:StartFunc(function(kills)
	if #player.GetAll() < 3 then
		print("not enough players")
		return false
	end
	kills = kills or 8

	queue = table.Copy(player.GetAll())

	local ply1 = table.remove(queue, 1)
	local ply2 = table.remove(queue, 1)

	ply1.dueling = true
	ply2.dueling = true

	ply1.opponent = ply2
	ply2.opponent = ply1

	ply1:SetNWInt("duelscore", 0)
	ply2:SetNWInt("duelscore", 0)

	ply1:StopSpectating(true)
	ply2:StopSpectating(true)

	ply1:Spawn()
	ply2:Spawn()

	SetGlobalInt("kills", kills)
	SetGlobalEntity("player1", ply1)
	SetGlobalEntity("player2", ply2)

	for k,v in next, player.GetAll() do
		v:CleanUp()
		
		if v.dueling then continue end

		v:SetSpectating(table.Random({ply1, ply2}), true)
	end
	
	ply1:Freeze(true)
	ply2:Freeze(true)

	timer.Simple(2, function()
		-- dont need to end the fight here if they arent valid, cos the duel hooks are already created
		if not IsValid(ply1) or not IsValid(ply2) then return end

		ply1:Freeze(false)
		ply2:Freeze(false)
	end)

	ChatMsg({
		Color(0,120,255), "Starting DuelMaster",
		Color(255,255,255), " event to ",
		Color(0,120,255), tostring(kills),
		Color(255,255,255), " kills",
	})

	ResetKillstreak()
	
	return true
end)

event:EndFunc(function(winner)
	if IsValid(winner) then
		ChatMsg({
			Color(0,120,255), winner:Nick(),
			Color(255,255,255), " has proven he is the best propkiller by winning the Duel Master event to ",
			Color(0,120,255), tostring(GetGlobalInt("kills", 10)),
			Color(255,255,255), " kills"
		})
	else
		ChatMsg({
			Color(0,120,255), "DuelMaster",
			Color(255,255,255), " event ended"
		})
	end

	SetGlobalEntity("player1", NULL)
	SetGlobalEntity("player2", NULL)

	for k,v in next, player.GetAll() do
		v:CleanUp()
		v:StopSpectating(true)
		v.dueling = false
		v.opponent = nil
		v:Spawn()
	end

	ResetKillstreak()
end)
