util.AddNetworkString("pk_duelinvite")

sync.arenas = {
	[1] = {
		available = true,
		spawn = Vector(3604.828369, -2698.306152, -131.968750)
	},
	[2] = {
		available = true,
		spawn = Vector(-8659.470703, -2698.306152, -131.968750)
	}
}

function requestSyncDuel(ply, opponent, kills, time)
	if sync.sendqueue[sync.duelinvite] == nil then sync.sendqueue[sync.duelinvite] = {} end
	if not IsValid(ply) or not IsValid(opponent) then return end
	if ply.dueling or opponent.dueling then return end

	local data = {
		initiator = ply:GetCreationID(),
		opponent = opponent:IsBot() and opponent.SyncedPlayer or opponent:GetCreationID(),
		kills = kills or 15,
		time = time or 10,
	}

	table.insert(sync.sendqueue[sync.duelinvite], data)
end

net.Receive("pk_duelinvite", function(len, ply)
	local opponent = net.ReadEntity()
	local kills = net.ReadInt(8)
	local time = net.ReadInt(8)

	if not IsValid(opponent) then return end
	if ply == opponent then return end

	kills = math.Clamp(kills or 15, 1, 60)
	time = math.Clamp(time or 10, 1, 30)

	requestSyncDuel(ply, opponent, kills, time)
end)

hook.Add("PlayerCanJoinTeam", "sync duel team change", function(ply, team)
	print("is this being called")
	if ply.dueling then
		print("dueling no team change")
		return false
	end
end)

function startSyncDuel(ply, opponent, arena, kills, time)
	ply:StopSpectating()
	opponent:StopSpectating()

	ply.dueling = arena
	opponent.dueling = arena

	ply:ChatPrint("You can /forfeit at any time")
	opponent:ChatPrint("You can /forfeit at any time")

	// using a string for this is dumb but im doing it anyway for consistency with arena
	ply:SetNWString("arena", tostring(arena))
	opponent:SetNWString("arena", tostring(arena))

	SetGlobalInt(arena .. "kills", kills)
	SetGlobalEntity(arena .. "player1", ply)
	SetGlobalEntity(arena .. "player2", opponent)

	ply:SetNWInt("duelscore", 0)
	opponent:SetNWInt("duelscore", 0)

	ChatMsg({
		Color(0,120,255), ply:Nick(),
		Color(255,255,255), " started a duel against ",
		Color(0,120,255), opponent:Nick(),
		Color(255,255,255), " to " .. kills .. " kills"
	})

	sync.arenas[arena].available = false

	sync.duel[arena] = {
		player1 = ply,
		player2 = opponent
	}

	ply:Spawn()
	opponent:Spawn()
	ply:Freeze(true)
	opponent:Freeze(true)

	timer.Simple(1.5, function()
		ply:Freeze(false)
		opponent:Freeze(false)
	end)

end

function endSyncDuel(arena, p1kills, p2kills, reason)
	local ply1 = sync.duel[arena].player1
	local ply2 = sync.duel[arena].player2

	if not IsValid(ply1) or not IsValid(ply2) then
		forceEndSyncDuel(ply1, ply2, p1kills, p2kills)
		return
	end

	ply1.duelscore = p1kills
	ply2.duelscore = p2kills

	local winner = p1kills > p2kills and ply1 or ply2
	local loser = p1kills < p2kills and ply1 or ply2
	local result = "won"
	
	if winner == loser then
		winner = ply1
		result = "tied"
	end

	if reason == "forfeit" then
		result = "forfeited"
	end

	ChatMsg({
		Color(0,120,255), winner:Nick(),
		Color(255,255,255), " " .. result .. " a duel against ",
		Color(0,120,255), loser:Nick(),
		Color(255,255,255), " " .. winner.duelscore .. "-" .. loser.duelscore
	})

	timer.Simple(3, function()
		sync.duel[arena].available = true

		if not IsValid(ply1) or not IsValid(ply2) then
			forceEndSyncDuel(ply1, ply2, p1kills, p2kills)
		end

		ply1.dueling = nil
		ply2.dueling = nil

		ply1:SetNWString("arena", "0")
		ply2:SetNWString("arena", "0")

		ply1:Spawn()
		ply2:Spawn()
	end)
end

function forceEndSyncDuel(ply1, ply2, p1kills, p2kills)
	pcall(function()
		ply1.dueling = nil
		ply1:SetNWString("arena", "0")
		ply1:Spawn()
	end)

	pcall(function()
		ply2.dueling = nil
		ply2:SetNWString("arena", "0")
		ply2:Spawn()
	end)

	pcall(function()
		ChatMsg({
			Color(255,255,255), "Duel with ",
			Color(0,120,255), IsValid(ply1) and ply1:Nick() or "unknown",
			Color(255,255,255), " and ",
			Color(0,120,255), IsValid(ply2) and ply2:Nick() or "unknown",
			Color(255,255,255), " was forcibly ended " .. p1kills .. "-" .. p2kills
		})
	end)
end

hook.Add("PlayerSpawn", "pk_duelspawn", function(ply)
	if ply.dueling then
		ply:SetPos(sync.arenas[ply.dueling].spawn)
	end
end)

hook.Add("PlayerSay", "duelaccept", function(ply, msg)
	if string.Trim(msg) != "/accept" then return end
	if ply:IsBot() then return end
	if not ply.duelrequest then return end
	if ply.dueling then return end

	if not sync.sendqueue[sync.duelresponse] then sync.sendqueue[sync.duelresponse] = {} end
	table.insert(sync.sendqueue[sync.duelresponse], {"accept", ply.duelrequest})

	return ""
end)

hook.Add("PlayerSay", "duelforfeit", function(ply, msg)
	if string.Trim(msg) != "/forfeit" then return end
	if ply:IsBot() then return end
	if not ply.dueling then return end

	if not sync.sendqueue[sync.duelresponse] then sync.sendqueue[sync.duelresponse] = {} end
	table.insert(sync.sendqueue[sync.duelresponse], {"forfeit", ply.dueling})

	return ""
end)

hook.Add("PlayerDisconnected", "pk_dueldisconnect", function(ply)
	if ply:IsBot() then return end
	if not ply.dueling then return end

	if not sync.sendqueue[sync.duelresponse] then sync.sendqueue[sync.duelresponse] = {} end
	table.insert(sync.sendqueue[sync.duelresponse], {"forfeit", ply.dueling})
end)
