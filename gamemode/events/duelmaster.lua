
local event = newEvent("duelmaster", "Duel Master", {
	minplayers = 3,
	freezeplayers = false
})
local queue = {}

event:Hook("PK_CanStopSpectating", "no, u cant join in", function(ply)
	return false
end)

event:Hook("PlayerJoinedEvent", "add them to the queue", function(ply)
	table.insert(queue, ply)
	ply:SetSpectating(nil, true)
end)

event:Hook("PlayerLeftEvent", "remove them from the queue", function(ply)
	DeleteDuelist(ply)
end)

event:Hook("PlayerDeath", "select next duelist", function(ply1)
	if not ply1.dueling then return end

	local ply2 = ply1.opponent

	//ply1:SetNWInt("duelscore", 0)
	ply2:SetNWInt("duelscore", ply2:GetNWInt("duelscore", 0) + 1)

	if ply2:GetNWInt("duelscore", 0) == GetGlobalInt("kills", 8) then
		event:End(ply2)
		return
	end

	timer.Simple(1, function()
		DespawnDuelist(ply1)
		SpawnNextDuelist(ply2)
	end)
end)

-- spawn the next duelist from the queue
function SpawnNextDuelist(opponent)
	local ply = table.remove(queue, 1)
	if not ply then
		print("[DuelMaster] next duelist wasn't valid")
		ChatMsg({Color(255,255,255), "DualMaster broke. error picking next opponent"})
		event:End(opponent)
		return
	end
	if not IsValid(ply) then
		return SpawnNextDuelist(opponent)
	end

	//ply:SetNWInt("duelscore", 0)
	ply.dueling = true
	ply.opponent = opponent
	opponent.opponent = ply

	if not GetGlobalEntity("player1", NULL).dueling then
		SetGlobalEntity("player1", ply)
	else
		SetGlobalEntity("player2", ply)
	end

	timer.Simple(1, function()
		if not IsValid(ply) then return end

		ply:StopSpectating(true)
	end)

	ply:PrintMessage(HUD_PRINTCENTER, "You're up!")
	
	for k,v in next, queue do
		if v.dueling then continue end

		v:PrintMessage(HUD_PRINTCENTER, queue[1]:Nick() .. " is next")
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
	ply:SetSpectating(ply.opponent, true)

	table.remove(queue, table.KeyFromValue(queue, ply))
	
	if #queue < 1 then
		event:End()
	end

	if ply.dueling then
		SpawnNextDuelist(ply.opponent)
	end

	ply.dueling = false
	ply.opponent = nil
end

event:OnSetup(function(kills)
	kills = kills or 8

	queue = table.Copy(event.players)
	table.Shuffle(queue)

	local ply1 = table.remove(queue, 1)
	local ply2 = table.remove(queue, 1)

	if not IsValid(ply1) or not IsValid(ply2) then return false end

	ply1.dueling = true
	ply2.dueling = true

	ply1.opponent = ply2
	ply2.opponent = ply1

	ply1:StopSpectating(true)
	ply2:StopSpectating(true)

	ply1:Spawn()
	ply2:Spawn()

	SetGlobalInt("kills", kills)
	SetGlobalEntity("player1", ply1)
	SetGlobalEntity("player2", ply2)

	for k,v in next, event.players do
		v:SetNWInt("duelscore", 0)
		
		if v.dueling then continue end

		v:SetSpectating(table.Random({ply1, ply2}), true)
	end
	
	ply1:PKFreeze(true)
	ply2:PKFreeze(true)

	local maxprops = GetConVar("sbox_maxprops")
	event.originalMaxProps = maxprops:GetInt()
	maxprops:SetInt(4)

	ChatMsg({
		Color(255,255,255), "Starting ",
		Color(0,120,255), "DuelMaster",
		Color(255,255,255), " event to ",
		Color(0,120,255), tostring(kills),
		Color(255,255,255), " kills",
	})

	ResetKillstreak()

	return true
end)

event:OnGameStart(function()
	for k, ply in next, event.players do
		if ply.dueling then
			ply:PKFreeze(false)
		end
	end
end)

event:OnGameEnd(function(winner)
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
end)

event:OnCleanup(function()
	SetGlobalEntity("player1", NULL)
	SetGlobalEntity("player2", NULL)

	for k, ply in next, event.players do
		ply.dueling = false
		ply.opponent = nil
	end

	GetConVar("sbox_maxprops"):SetInt(event.originalMaxProps)
	
	event.originalMaxProps = nil
end)

concommand.Add("duelmaster", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	if (PK.currentEvent or {}).id == "duelmaster" then
		PK.currentEvent:End()
		return
	end

	local kills = tonumber(args[1])
	if not isnumber(kills) then
		kills = 8
	end

	event:Start(kills)
end)
