
local event = newEvent("duel", "1v1", {
	joinable = false,
	minplayers = 2,
	startfreezetime = 3,
	endfreezetime = 3,
})

event:Hook("PlayerCheckLimit", "duel prop limit", function(ply, name, current, max)
	-- TODO: PK.config.maxduelprops
	if name == "props" and current >= 3 then
		return false
	end
end)

event:Hook("PlayerDeath", "PK_duel_ForceSpawn", function(ply)
	timer.Simple(3, function()
		if not ply:Alive() then
			ply:Spawn()
		end
	end)
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
	if PK.currentEvent then return end
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
	if PK.currentEvent then return end
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

event:OnSetup(function(ply1, ply2, kills, time, ranked)
	if not IsValid(ply1) or not IsValid(ply2) then return false, "invalid player" end
	if ply1 == ply2 then return false, "you can't duel yourself" end

	kills = kills or 15
	time = time or 10
	ranked = ranked or false

	event.players = { ply1, ply2 }
	event.time = time

	ply1.opponent = ply2
	ply2.opponent = ply1

	SetGlobalInt("kills", kills)
	SetGlobalEntity("player1", ply1)
	SetGlobalEntity("player2", ply2)
	SetGlobalBool("ranked", ranked)

	ply1:SetNWInt("duelscore", 0)
	ply2:SetNWInt("duelscore", 0)

	ChatMsg({
		Color(0,120,255), ply1:Nick(),
		Color(255,255,255), " started a duel against ",
		Color(0,120,255), ply2:Nick(),
		Color(255,255,255), " to " .. kills .. " kills in under " .. time .. " minutes"
	})

	return true
end)

event:OnGameStart(function()
	timer.Create("fighttimer", event.time*60, 1, function()
		event:End()
	end)

	PK.SetNWVar("fighttimer", timer.TimeLeft("fighttimer"))
end)

event:OnGameEnd(function(forfeitply)
	timer.Remove("fighttimer")

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

event:OnCleanup(function()
	SetGlobalEntity("player1", NULL)
	SetGlobalEntity("player2", NULL)
end)
