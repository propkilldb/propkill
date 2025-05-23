local event = newEvent("tournamentduel", "1v1", {
	joinable = false,
	minplayers = 2,
	startfreezetime = 3,
	endfreezetime = 3,
})

event:Hook("PlayerCheckLimit", "prevent propspawn while paused", function(ply, name, current, max)
	if event.matchPaused then
		return false
	end
end)

event:Hook("CanUndo", "prevent undo while paused", function(ply, undo)
	if event.matchPaused then
		return false
	end
end)

event:Hook("PlayerDeath", "PK_duel_ForceSpawn", function(ply)
	timer.Simple(6, function()
		if not ply:Alive() then
			ply:Spawn()
		end
	end)
end)

event:Hook("PlayerDeath", "PK_duel_KillCounter", function(ply, inflictor, attacker)
	local opponent = ply.opponent
	if not IsValid(opponent) then return end

	opponent:SetNWInt("duelscore", opponent:GetNWInt("duelscore", 0) + 1)

	if opponent:GetNWInt("duelscore", 0) >= GetGlobalInt("kills", 10) then
		event:End()
		return
	end

	if event.matchid and event.matchid != 0 then
		local player1 = GetGlobalEntity("player1")
		local player2 = GetGlobalEntity("player2")

		ChallongeAPIPut("matches/" .. event.matchid, {
			match = {
				scores_csv = string.format("%s-%s", player1:GetNWInt("duelscore", 0), player2:GetNWInt("duelscore", 0))
			}
		})
	end
end)

timer.Create("tournament_update_timer", 1, 0, function()
	if not timer.Exists("fighttimer") then
		PK.SetNWVar("fighttimer", 0)
		return
	end

	local timeleft = math.abs(timer.TimeLeft("fighttimer")) -- timeleft is negative while paused
	PK.SetNWVar("fighttimer", timeleft)

	if (event.time or 0) > 1 then
		if not event.timeleftOneMin and timeleft <= 61 then
			event.timeleftOneMin = true

			ChatMsg({
				Color(0, 120, 255), "Duel",
				Color(255, 255, 255), ": 1 minute remaining!"
			})
		end

		if not event.timeleftTenSec and timeleft <= 11 then
			event.timeleftTenSec = true

			ChatMsg({
				Color(0, 120, 255), "Duel",
				Color(255, 255, 255), ": 10 seconds remaining!"
			})
		end
	end
end)

event:OnSetup(function(ply1, ply2, kills, time, disableAlltalk, matchid)
	if not IsValid(ply1) or not IsValid(ply2) then return false, "invalid player" end
	if ply1 == ply2 then return false, "you can't duel yourself" end

	kills = kills or 15
	time = time or 10

	event.players = { ply1, ply2 }
	event.time = time
	event.matchid = matchid

	if disableAlltalk then
		event.originalAlltalkValue = GetConVar("sv_alltalk"):GetInt()
		RunConsoleCommand("sv_alltalk", "0")
	end

	ply1.opponent = ply2
	ply2.opponent = ply1

	SetGlobalInt("kills", kills)
	SetGlobalEntity("player1", ply1)
	SetGlobalEntity("player2", ply2)

	ply1:SetNWInt("duelscore", 0)
	ply2:SetNWInt("duelscore", 0)

	ply1:StopSpectating(true)
	ply2:StopSpectating(true)

	local maxprops = GetConVar("sbox_maxprops")
	event.originalMaxProps = maxprops:GetInt()
	maxprops:SetInt(4)

	ChatMsg({
		Color(255,0,0), "[Tournament]",
		Color(255,255,255), " Starting match between ",
		Color(0,120,255), ply1:Nick(),
		Color(255,255,255), " and ",
		Color(0,120,255), ply2:Nick(),
		Color(255,255,255), " to " .. kills .. " kills in under " .. time .. " minutes"
	})

	if event.matchid and event.matchid != 0 then
		ChallongeAPIPost("matches/" .. event.matchid .. "/mark_as_underway", {}, function(data)
			if not IsValid(ply1) or not IsValid(ply2) then return end

			ply1.challongeid = data.match.player1_id
			ply2.challongeid = data.match.player2_id
		end)
	end

	return true
end)

event:OnGameStart(function()
	event.matchPaused = false

	timer.Create("fighttimer", event.time*60, 1, function()
		event:End()
	end)

	PK.SetNWVar("fighttimer", timer.TimeLeft("fighttimer"))
end)

event:OnGameEnd(function(forfeitply)
	timer.Remove("fighttimer")
	PK.SetNWVar("fighttimer", 0)
	event.matchPaused = false

	if event.originalAlltalkValue != nil then
		RunConsoleCommand("sv_alltalk", tostring(event.originalAlltalkValue))
		event.originalAlltalkValue = nil
	end

	local ply1 = GetGlobalEntity("player1")
	local ply2 = GetGlobalEntity("player2")

	if not IsValid(ply1) or not IsValid(ply2) then return end

	local p1kills = ply1:GetNWInt("duelscore", 0)
	local p2kills = ply2:GetNWInt("duelscore", 0)

	local winner = p1kills > p2kills and ply1 or ply2
	local loser = p1kills < p2kills and ply1 or ply2
	local result = "won"

	if event.matchid and event.matchid != 0 then
		ChallongeAPIPut("matches/" .. event.matchid, {
			match = {
				scores_csv = string.format("%s-%s", p1kills, p2kills),
				winner_id = (winner == loser and "tie" or winner.challongeid)
			}
		})
	end
	
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
		Color(255,0,0), "[Tournament] ",
		Color(0,120,255), winner:Nick(),
		Color(255,255,255), " " .. result .. " the match against ",
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
	GetConVar("sbox_maxprops"):SetInt(event.originalMaxProps)

	-- have to do cleanup cos the event table gets reused, for now
	event.matchid = nil
	event.originalAlltalkValue = nil
	event.originalMaxProps = nil
	event.matchPaused = nil
end)

util.AddNetworkString("pk_tournamentduel")
util.AddNetworkString("pk_duel_pause_toggle")
util.AddNetworkString("pk_duel_abort")
util.AddNetworkString("pk_duel_toggle_alltalk")
util.AddNetworkString("pk_duel_adjust_time")
util.AddNetworkString("pk_duel_adjust_score")
util.AddNetworkString("pk_duel_respawn_player")
util.AddNetworkString("pk_get_challonge_matches")

net.Receive("pk_tournamentduel", function(len, ply)
	if not ply:IsSuperAdmin() then return end
	
	local opponent1 = net.ReadEntity()
	local opponent2 = net.ReadEntity()
	local kills = net.ReadInt(8)
	local time = net.ReadInt(8)
	local p1startscore = net.ReadInt(8)
	local p2startscore = net.ReadInt(8)
	local disableAlltalk = net.ReadBool()
	local matchid = net.ReadInt(32)

	if not (IsValid(opponent1) and opponent1:IsPlayer()) then return end
	if not (IsValid(opponent2) and opponent2:IsPlayer()) then return end

	local success, reason = event:Start(opponent1, opponent2, kills, time, disableAlltalk, matchid)
	if success then
		opponent1:SetNWInt("duelscore", p1startscore)
		opponent2:SetNWInt("duelscore", p2startscore)
	else
		if ply:IsPlayer() then
			ChatMsg(ply, {Color(255,0,0), "[Tournament] ", Color(255,255,255), "Failed to start duel: " .. (reason or "Unknown error")})
		end
	end
end)

net.Receive("pk_duel_pause_toggle", function(len, ply)
	if not ply:IsSuperAdmin() then return end
	if PK.currentEvent != event then return end
	if not timer.Exists("fighttimer") then return end

	if event.matchPaused then
		timer.UnPause("fighttimer")
		event.matchPaused = false

		for k,v in next, event.players do
			v:PKFreeze(false)
		end

		for k,v in next, ents.GetAll() do
			if not IsValid(v) or not IsValid(v:GetPhysicsObject()) then continue end
			if v:GetClass() != "prop_physics" then continue end
			local phys = v:GetPhysicsObject()
			
			phys:EnableMotion(v.PK_PauseMotion or true)
			phys:Wake()
		end

		ChatMsg({Color(255,0,0),"[Tournament] ", Color(255,255,255), "Match resumed"})
	else
		timer.Pause("fighttimer")
		event.matchPaused = true

		for k,v in next, event.players do
			v:PKFreeze(true)
		end

		for k,v in next, ents.GetAll() do
			if not IsValid(v) or not IsValid(v:GetPhysicsObject()) then continue end
			if v:GetClass() != "prop_physics" then continue end
			local phys = v:GetPhysicsObject()
			
			v.PK_PauseMotion = phys:IsMotionEnabled()
			phys:EnableMotion(false)
		end

		ChatMsg({Color(255,0,0),"[Tournament] ", Color(255,255,255), "Match paused"})
	end
end)

net.Receive("pk_duel_abort", function(len, ply)
	if not ply:IsSuperAdmin() then return end
	if PK.currentEvent != event then return end
	
	event:End()
	ChatMsg({Color(255,0,0),"[Tournament] ", Color(255,255,255), "Match aborted"})
end)

net.Receive("pk_duel_toggle_alltalk", function(len, ply)
	if not ply:IsSuperAdmin() then return end
	if PK.currentEvent != event then return end
	
	local currentAlltalk = GetConVar("sv_alltalk"):GetInt()
	local newAlltalk = currentAlltalk == 1 and 0 or 1

	RunConsoleCommand("sv_alltalk", tostring(newAlltalk))

	ChatMsg({Color(255,0,0),"[Tournament] ", Color(255,255,255), "sv_alltalk manually set to " .. newAlltalk})
end)

net.Receive("pk_duel_adjust_time", function(len, ply)
	if not ply:IsSuperAdmin() then return end
	if PK.currentEvent != event then return end

	local timeAdjustment = net.ReadInt(16)

	if timer.Exists("fighttimer") then
		local currentTimeLeft = math.abs(timer.TimeLeft("fighttimer"))
		local newTargetDelay = math.max(0, currentTimeLeft + timeAdjustment)
		
		timer.Adjust("fighttimer", newTargetDelay)
		PK.SetNWVar("fighttimer", newTargetDelay)

		local action = timeAdjustment >= 0 and "added to" or "removed from"
		local absTime = math.abs(timeAdjustment)

		ChatMsg({Color(255,0,0),"[Tournament] ", Color(255,255,255), absTime .. " seconds " .. action .. " match timer"})
	end
end)

net.Receive("pk_duel_adjust_score", function(len, ply)
	if not ply:IsSuperAdmin() then return end
	if PK.currentEvent != event then return end

	local targetPly = net.ReadEntity()
	local scoreAdjustment = net.ReadInt(8)
	if not (IsValid(targetPly) and targetPly:IsPlayer()) then return end

	local oldScore = targetPly:GetNWInt("duelscore", 0)
	local newScore = math.max(0, oldScore + scoreAdjustment)

	targetPly:SetNWInt("duelscore", newScore)
	
	local action = scoreAdjustment >= 0 and "added to" or "removed from"
	local absScore = math.abs(scoreAdjustment)

	ChatMsg({Color(255,0,0),"[Tournament] ", Color(255,255,255), absScore .. " point(s) " .. action .. " ", Color(0,120,255), targetPly:Nick()})

	if targetPly:GetNWInt("duelscore", 0) >= GetGlobalInt("kills", 10) then
		event:End()
	end
end)

net.Receive("pk_duel_respawn_player", function(len, ply)
	if not ply:IsSuperAdmin() then return end
	if PK.currentEvent != event then return end
	
	local targetPly = net.ReadEntity()
	if not (IsValid(targetPly) and targetPly:IsPlayer()) then return end
	targetPly:Spawn()

	ChatMsg({Color(255,0,0),"[Tournament] ", Color(0,120,255), targetPly:Nick(), Color(255,255,255), " respawned"})
end)

net.Receive("pk_get_challonge_matches", function(len, ply)
	if not ply:IsSuperAdmin() then return end

	ChallongeGetMatchData(function(matches, players)
		net.Start("pk_get_challonge_matches")
			net.WriteTable(matches)
		net.Send(ply)
	end)
end)

-- roll command specifically for disagreements in tournament decisions
hook.Add("PlayerSay", "pk roll command", function(ply, text)
	local cmd = string.TrimRight(text)

	if cmd == "/roll" or cmd == "!roll" then
		ChatMsg({
			Color(0,120,255), ply:Nick(),
			Color(255,255,255), " rolled " .. tostring(math.random(1, 100)),
		})

		return ""
	end
end)
