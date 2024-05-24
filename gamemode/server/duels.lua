
PK.duels = PK.duels or {}
PK.duels.fighting = PK.duels.fighting or false

local event = newEvent("duel")

event:Hook("PK_CanSpectate", "duelists cant spectate", function(ply)
	if ply.dueling then return false end
end)

event:Hook("PK_CanStopSpectating", "no, u cant join in", function(ply)
	return false
end)

event:Hook("PlayerDeath", "PK_duel_ForceSpawn", function(ply)
	timer.Simple(3, function()
		if not ply:Alive() then
			ply:Spawn()
		end
	end)
end)

event:Hook("PlayerSpawn", "PK_duel_ForceSpectate", function(ply)
	if not ply.dueling then
		ply:SetSpectating(nil, true)
	end
end)

event:Hook("PlayerDisconnected", "PK_duel_AutoEnd", function(ply)
	if ply.dueling then
		event:End(ply)
	end
end)

event:Hook("PlayerDeath", "PK_duel_KillCounter", function(ply, inflictor, attacker)
	local opponent = ply.opponent
	if not IsValid(opponent) then return end

	opponent:SetNWInt("duelscore", opponent:GetNWInt("duelscore", 0) + 1)

	if opponent:GetNWInt("duelscore", 0) == GetGlobalInt("kills", 10) then
		event:End()
	end
end)

timer.Create("net_fight_timer", 1, 0, function()
	if not timer.Exists("fighttimer") then
		PK.SetNWVar("fighttimer", 0)
		return
	end

	local timeleft = timer.TimeLeft("fighttimer")
	PK.SetNWVar("fighttimer", timeleft)
end)

util.AddNetworkString("pk_duelinvite")
net.Receive("pk_duelinvite", function(_, fighter)
	local fightee = net.ReadEntity()
	local kills = net.ReadInt(8)
	local time = net.ReadInt(8)

	InvitePlayerToDuel(fighter, fightee, kills, time)
end)

util.AddNetworkString("pk_duelaccept")
net.Receive("pk_duelaccept", function(_, fightee)
	local fighter = net.ReadEntity()
	local accept = net.ReadBool()
	if accept then
		AcceptDuel(fighter, fightee)
	else
		DeclineDuel(fighter)
	end
end)

function InvitePlayerToDuel(fighter, fightee, kills, time, ranked)
	if PK.duels.fighting then return end
	if not IsValid(fightee) or not fightee:IsPlayer() then return end
	if not IsValid(fighter) or not fighter:IsPlayer() then return end
	if fighter == fightee then return end
	if (fighter.InviteCooldown or 0) > CurTime() then
		fighter:ChatPrint("Please wait before sending another invite")
		return
	end

	-- TODO: PK.invitecooldown
	fighter.InviteCooldown = CurTime() + 15

	kills = kills or 15
	time = time or 15

	local fightdata = {
		fightee = fightee,
		kills = kills,
		time = time,
		curtime = CurTime(),
	}
	fighter.PKDuelInvite = fightdata

	net.Start("pk_duelinvite")
		net.WriteEntity(fighter)
		net.WriteInt(kills, 8)
		net.WriteInt(time, 8)
	net.Send(fightee)
end

function AcceptDuel(fighter, fightee)
	if PK.duels.fighting then return end
	if not IsValid(fightee) or not fightee:IsPlayer() then return end
	if not IsValid(fighter) or not fighter:IsPlayer() then return end

	local fightdata = fighter.PKDuelInvite
	if not fightdata then return end
	if fightdata.fightee != fightee then return end
	-- TODO: PK.duelinviteexpiretimeorsomeshit
	if fightdata.curtime < CurTime() - 30 then
		fighter.PKDuelInvite = nil
		return
	end

	event:Start(fighter, fightee, fightdata.kills, fightdata.time)

	fighter.PKDuelInvite = nil
	print("fight accepted")
end

function DeclineDuel(fighter, fightee)
	if not IsValid(fighter) or not fighter:IsPlayer() then return end

	local fightdata = fighter.PKDuelInvite
	if not fightdata then return end
	if fightdata.fightee != fightee then return end

	fighter.PKDuelInvite = nil
	print("fight declined")
end

event:StartFunc(function(ply1, ply2, kills, time, ranked)
	if PK.duels.fighting then return end
	if not IsValid(ply1) or not IsValid(ply2) then return end
	if ply1 == ply2 then return end

	PK.duels.fighting = true

	kills = kills or 15
	time = time or 10
	ranked = ranked or false

	ply1.dueling = true
	ply2.dueling = true

	ply1.opponent = ply2
	ply2.opponent = ply1

	ply1:StopSpectating(true)
	ply2:StopSpectating(true)

	event:Start()

	ResetKillstreak()

	-- TODO: store their original spectate state?
	for k,v in next, player.GetAll() do
		v:CleanUp()
		
		if v.dueling then continue end

		v:SetSpectating(table.Random({ply1, ply2}), true)
	end

	SetGlobalInt("kills", kills)
	SetGlobalEntity("player1", ply1)
	SetGlobalEntity("player2", ply2)
	SetGlobalBool("ranked", ranked)

	ply1:SetNWInt("duelscore", 0)
	ply2:SetNWInt("duelscore", 0)

	ply1:Spawn()
	ply2:Spawn()

	ply1:Freeze(true)
	ply2:Freeze(true)

	timer.Simple(2, function()
		-- dont need to end the fight here if they arent valid, cos the duel hooks are already created
		if not IsValid(ply1) or not IsValid(ply2) then return end

		timer.Create("fighttimer", time*60, 1, function()
			event:End()
		end)

		PK.SetNWVar("fighttimer", timer.TimeLeft("fighttimer"))

		ply1:Freeze(false)
		ply2:Freeze(false)
	end)

	ChatMsg({
		Color(0,120,255), ply1:Nick(),
		Color(255,255,255), " started a duel against ",
		Color(0,120,255), ply2:Nick(),
		Color(255,255,255), " to " .. kills .. " kills in under " .. time .. " minutes"
	})
end)

event:EndFunc(function(forfeitply)
	timer.Remove("fighttimer")
	timer.Simple(3, ActuallyEndTheFight)

	local ply1 = GetGlobalEntity("player1")
	local ply2 = GetGlobalEntity("player2")

	if not IsValid(ply1) or not IsValid(ply2) then return end

	p1kills = ply1:GetNWInt("duelscore", 0)
	p2kills = ply2:GetNWInt("duelscore", 0)

	local winner = p1kills > p2kills and ply1 or ply2
	local loser = p1kills < p2kills and ply1 or ply2
	local result = "won"
	
	if winner == loser then
		winner = ply1
		result = "tied"
	end

	if IsValid(forfeitply) then
		if forfeitply == winner then
			winner = loser
			loser = forfeitply
		end

		result = "won"
	end

	local message = {
		Color(0,120,255), winner:Nick(),
		Color(255,255,255), " " .. result .. " a duel against ",
		Color(0,120,255), loser:Nick(),
		Color(255,255,255), " " .. winner:GetNWInt("duelscore", 0) .. "-" .. loser:GetNWInt("duelscore", 0)
	}

	if IsValid(forfeitply) then
		table.Add(message, {
			Color(255,255,255), " because ",
			Color(0,120,255), forfeitply:Nick(),
			Color(255,255,255), " forfeited"
		})
	end

	ChatMsg(message)
end)

function ActuallyEndTheFight()
	PK.duels.fighting = false

	SetGlobalEntity("player1", NULL)
	SetGlobalEntity("player2", NULL)

	for k,v in next, player.GetAll() do
		v:CleanUp()
		v:StopSpectating(true)
		v.dueling = false
	end

	ResetKillstreak()
end