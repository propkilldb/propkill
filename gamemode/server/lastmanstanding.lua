
local event = newEvent("lastmanstanding")
local queue = {}

event:Hook("PK_CanSpectate", "battlers cant spectate", function(ply)
	if ply.battling then return false end
end)

event:Hook("PlayerSpawn", "nice try rejoining idiot", function(ply)
	ply.battling = false
	ply:SetSpectating(nil, true)
end)

event:Hook("PK_CanStopSpectating", "no, u cant join in", function(ply)
	return false
end)

event:Hook("PlayerDeath", "auto switch spectator on death", function(ply)
	for k,v in next, player.GetAll() do
		if v:GetObserverTarget() == ply then
			local nxt, prev = GetNextPlayer(v, ply)
			v:SpectateEntity(nxt)
		end
	end
end)

event:Hook("PlayerDeath", "kick dead noob out to spectator", function(ply)
	ply:SetSpectating(nil, true)
	ply.battling = false

	local playersleft = 0
	local lastplayer = NULL

	for k, ply in next, player.GetAll() do
		if ply.battling then
			playersleft = playersleft + 1
			lastplayer = ply
		end
	end

	if playersleft <= 1 then
		event:End(lastplayer)
	end
end)

event:StartFunc(function()
	if #player.GetAll() < 2 then
		return false, "not enough players"
	end

	for k, ply in next, player.GetAll() do
		ply:StopSpectating(true)
		ply:Spawn()
		ply.battling = true
		ply:CleanUp()
		ply:Freeze(true)
	
	end
	
	timer.Simple(2, function()
		for k, ply in next, player.GetAll() do
			ply:Freeze(false)
		end

		ChatMsg({
			//Color(255,255,255), "[",
			Color(0,120,255), "Last Man Standing",
			//Color(255,255,255), "]",
			Color(255,255,255), " GO!!!",
		})
	end)

	ChatMsg({
		//Color(255,255,255), "[",
		Color(0,120,255), "Last Man Standing",
		//Color(255,255,255), "]",
		Color(255,255,255), " event starting...",
	})

	ResetKillstreak()

	return true
end)

event:EndFunc(function(winner)
	if IsValid(winner) then
		ChatMsg({
			Color(0,120,255), winner:Nick(),
			Color(255,255,255), " has proven to be the best propkiller by winning the ",
			Color(0,120,255), "Last Man Standing",
			Color(255,255,255), " event",
		})
	else
		ChatMsg({
			Color(0,120,255), "Last Man Standing",
			Color(255,255,255), " event ended",
		})
	end

	timer.Simple(2, function()
		for k,v in next, player.GetAll() do
			v:CleanUp()
			v:StopSpectating(true)
			v.battling = false
			v:Spawn()
		end
	
		ResetKillstreak()
	end)
end)

concommand.Add("lastmanstanding", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	if (PK.currentEvent or {}).name == "lastmanstanding" then
		PK.currentEvent:End()
		return
	end

	local success, err = event:Start()
	if not success then
		ply:PrintMessage(HUD_PRINTCONSOLE, tostring(err))
	end
end)
