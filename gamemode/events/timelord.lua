
local event = newEvent("timelord", "Time Lord", {
	joinable = false,
	minplayers = 2,
})

local function CheckRemainingPlayers()
	local playersleft = 0
	local lastplayer = NULL

	for k, ply in next, event.players do
		if ply.battling then
			playersleft = playersleft + 1
			lastplayer = ply
		end
	end

	if playersleft <= 1 then
		event:End(lastplayer)
	end
end

local function TimeCheck(ply)
	local timeleft = ply:GetNW2Float("timeleft", 0)

	if timeleft <= 0 then
		ply:SetSpectating(nil, true)
		ply.battling = false

		ChatMsg({
			Color(0,120,255), ply:Nick(),
			Color(255,255,255), " ran out of time!",
		})
	end
end

event:Hook("PlayerDeath", "kick dead noob out to spectator", function(ply, inflictor, attacker)
	local timeleft = ply:GetNW2Float("timeleft", 0)

	if IsValid(attacker) and attacker:IsPlayer() and attacker.battling and ply != attacker then
		local attackertimeleft = attacker:GetNW2Float("timeleft", 0)
		attackertimeleft = attackertimeleft + math.min(event.timesteal, timeleft)
		attacker:SetNW2Float("timeleft", attackertimeleft)
	end

	timeleft = timeleft - event.timesteal
	ply:SetNW2Float("timeleft", timeleft)

	TimeCheck(ply)
	CheckRemainingPlayers()
end)

event:Hook("PlayerDeathThink", "force respawn", function(ply)
	if not IsValid(ply) then return end
	if ply:IsSpectating() then return end
	
	if ply.DeathTime + 5 < CurTime() then
		ply:Spawn()
	end
end)

event:Hook("PlayerLeftEvent", "remove players from count and re-check", function(ply)
	ply.battling = false
	CheckRemainingPlayers()

	return true
end)

event:OnSetup(function(time, timesteal)
	event.timesteal = timesteal

	for k, ply in next, event.players do
		ply.battling = true
		ply:SetNW2Float("timeleft", time)
	end

	PK.AddHud("timeleft", {
		style = "infohud",
		label = "Time Left",
		value = { "%T", "p:timeleft" },
	})

	ChatMsg({
		Color(0,120,255), event.name,
		Color(255,255,255), " event with " .. PrettyTime(time) .. " starting time and " .. PrettyTime(timesteal) .. " of timesteal starting...",
	})
end)

event:OnGameStart(function()
	ChatMsg({
		Color(0,120,255), event.name,
		Color(255,255,255), " GO!!!",
	})

	timer.Create("deathclock_countdown", 0.1, 0, function()
		for k, ply in next, event.players do
			if not ply.battling then continue end

			local timeleft = ply:GetNW2Float("timeleft", 0)
			timeleft = timeleft - 0.1
			ply:SetNW2Float("timeleft", timeleft)

			TimeCheck(ply)
		end
		CheckRemainingPlayers()
	end)
end)

event:OnGameEnd(function(winner)
	timer.Remove("deathclock_countdown")

	if IsValid(winner) then
		local timeleft = winner:GetNW2Float("timeleft", 0)
		
		ChatMsg({
			Color(0,120,255), winner:Nick(),
			Color(255,255,255), " won the ",
			Color(0,120,255), event.name,
			Color(255,255,255), " event with " .. PrettyTime(timeleft) .. " to spare",
		})
	else
		ChatMsg({
			Color(0,120,255), event.name,
			Color(255,255,255), " event ended",
		})
	end
end)

event:OnCleanup(function()
	for k,v in next, player.GetAll() do
		v.battling = nil
	end

	PK.RemoveHud("timeleft")
end)

concommand.Add("timelord", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	if (PK.currentEvent or {}).id == "timelord" then
		PK.currentEvent:End()
		return
	end

	local time = tonumber(args[1])
	if not isnumber(time) then
		time = 60
	end

	local timesteal = tonumber(args[2])
	if not isnumber(timesteal) then
		timesteal = 5
	end

	local success, err = event:Start(time, timesteal)
	if not success then
		ply:PrintMessage(HUD_PRINTCONSOLE, tostring(err))
	end
end)
