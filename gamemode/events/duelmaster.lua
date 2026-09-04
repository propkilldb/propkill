
local event = newEvent("duelmaster", "Duel Master", {
	minplayers = 3,
	freezeplayers = false
})
local queue = {}
local ROUND_DELAY = 1

local function IsEventActive()
	return PK.currentEvent == event
end

local function Enqueue(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if ply.dueling then return end
	if table.KeyFromValue(queue, ply) then return end

	table.insert(queue, ply)
end

local function DequeueNextValid()
	while #queue > 0 do
		local ply = table.remove(queue, 1)

		if IsValid(ply) and ply:IsPlayer() and not ply.dueling then
			return ply
		end
	end
end

local function AnnounceDuelists(entrants)
	for _, ply in next, entrants do
		if not IsValid(ply) then continue end
		ply:PrintMessage(HUD_PRINTCENTER, "You're up!")
	end

	local nextup = queue[1]
	if not IsValid(nextup) then return end

	for _, v in next, queue do
		if not IsValid(v) or v.dueling then continue end
		v:PrintMessage(HUD_PRINTCENTER, nextup:Nick() .. " is next")
	end
end

local function FillDuel(despawn)
	if not IsEventActive() then return end

	local alive = {}
	for _, p in next, event.players do
		if IsValid(p) and p.dueling then
			table.insert(alive, p)
		end
	end

	local entrants = {}
	while #alive < 2 do
		local nxt = DequeueNextValid()
		if not nxt then break end

		nxt.dueling = true
		nxt.opponent = nil

		table.insert(alive, nxt)
		table.insert(entrants, nxt)
	end

	if #alive < 2 then
		event:End(alive[1])
		return
	end

	alive[1].opponent = alive[2]
	alive[2].opponent = alive[1]

	SetGlobal2Entity("player1", alive[1])
	SetGlobal2Entity("player2", alive[2])

	timer.Simple(ROUND_DELAY, function()
		if PK.currentEvent != event then return end

		for _, ply in next, entrants do
			if IsValid(ply) and ply.dueling and ply:IsSpectating() then
				ply:StopSpectating(true)
			end
		end

		if IsValid(despawn) and not despawn.dueling and not despawn:IsSpectating() then
			for _, ply in next, player.GetAll() do
				if ply != despawn and IsValid(ply) and plyp:Alive() and not ply:IsSpectating() then
					despawn:SetSpectating(nil, true)
					break
				end
			end
		end
	end)

	AnnounceDuelists(entrants)
end

function DeleteDuelist(ply)
	local wasDueling = IsValid(ply) and ply.dueling or false

	local idx = IsValid(ply) and table.KeyFromValue(queue, ply) or nil
	if idx then
		table.remove(queue, idx)
	end

	if IsValid(ply) then
		ply.dueling = false
		ply.opponent = nil
	end

	if not IsEventActive() then return end

	for _, ply in next, event.players do
		if IsValid(ply) and ply.opponent == ply then
			ply.opponent = nil
		end
	end

	if wasDueling then
		FillDuel(ply)
	end
end

event:Hook("PK_CanStopSpectating", "no, u cant join in", function(ply)
	return false
end)

event:Hook("PlayerJoinedEvent", "add them to the queue", function(ply)
	if not IsValid(ply) then return end

	ply:SetNW2Int("duelscore", 0)
	Enqueue(ply)

	if not ply:IsSpectating() then
		ply:SetSpectating(nil, true)
	end
end)

event:Hook("PlayerLeftEvent", "remove them from the queue", function(ply)
	DeleteDuelist(ply)
end)

local function ResolveKiller(victim, inflictor, attacker)
	if IsValid(inflictor) and inflictor:GetClass() == "prop_physics"
		and IsValid(inflictor.Owner) and inflictor.Owner:IsPlayer() then
		return inflictor.Owner
	end

	if IsValid(attacker) and attacker:IsPlayer() then
		return attacker
	end
end

event:Hook("PlayerDeath", "select next duelist", function(victim, inflictor, attacker)
	if not IsEventActive() then return end
	if not victim.dueling then return end // already evicted

	local opponent = victim.opponent

	victim.dueling = false
	victim.opponent = nil

	Enqueue(victim)

	local killer = ResolveKiller(victim, inflictor, attacker)

	local scorer = nil
	if IsValid(killer) and killer:IsPlayer() and killer != victim then
		scorer = killer
	elseif IsValid(opponent) and opponent:IsPlayer() then
		scorer = opponent
	end

	if IsValid(scorer) then
		scorer:SetNW2Int("duelscore", scorer:GetNW2Int("duelscore", 0) + 1)

		if scorer:GetNW2Int("duelscore", 0) >= GetGlobal2Int("kills", 8) then
			event:End(scorer)
			return
		end
	end

	FillDuel(victim)
end)

event:OnSetup(function(kills)
	kills = kills or 8

	queue = table.Copy(event.players)
	table.Shuffle(queue)

	local ply1 = DequeueNextValid()
	local ply2 = DequeueNextValid()

	if not IsValid(ply1) or not IsValid(ply2) then return false end

	ply1.dueling = true
	ply2.dueling = true

	ply1.opponent = ply2
	ply2.opponent = ply1

	SetGlobal2Int("kills", kills)
	SetGlobal2Entity("player1", ply1)
	SetGlobal2Entity("player2", ply2)

	for k,v in next, event.players do
		v:SetNW2Int("duelscore", 0)
	end

	ply1:PKFreeze(true)
	ply2:PKFreeze(true)

	for k,v in next, event.players do
		if not IsValid(v) then continue end
		if v.dueling then continue end

		v:SetSpectating(table.Random({ply1, ply2}), true)
	end

	local maxprops = GetConVar("sbox_maxprops")
	event.originalMaxProps = maxprops:GetInt()
	maxprops:SetInt(4)

	PK.AddHud("duelhud", {
		style = "duelhud"
	})

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
		if IsValid(ply) and ply.dueling then
			ply:PKFreeze(false)
		end
	end
end)

event:OnGameEnd(function(winner)
	if IsValid(winner) then
		ChatMsg({
			Color(0,120,255), winner:Nick(),
			Color(255,255,255), " has proven he is the best propkiller by winning the Duel Master event to ",
			Color(0,120,255), tostring(GetGlobal2Int("kills", 10)),
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
	queue = {}

	SetGlobal2Entity("player1", NULL)
	SetGlobal2Entity("player2", NULL)
	PK.RemoveHud("duelhud")

	for k, ply in next, event.players do
		if not IsValid(ply) then continue end
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
