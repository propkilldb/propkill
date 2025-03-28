
local event = newEvent("lastmanstanding", "Last Man Standing", {
	joinable = false,
	minplayers = 2,
})

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

	for k, ply in next, event.players do
		if ply.battling then
			playersleft = playersleft + 1
			lastplayer = ply
		end
	end

	if playersleft <= 1 then
		event:End(lastplayer)
	end
end)

event:OnSetup(function()
	for k, ply in next, event.players do
		ply.battling = true
	end

	ChatMsg({
		Color(0,120,255), "Last Man Standing",
		Color(255,255,255), " event starting...",
	})

	return true
end)

event:OnGameStart(function()
	ChatMsg({
		Color(0,120,255), "Last Man Standing",
		Color(255,255,255), " GO!!!",
	})
end)

event:OnGameEnd(function(winner)
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
end)

event:OnCleanup(function()
	for k,v in next, player.GetAll() do
		v.battling = false
	end
end)

concommand.Add("lastmanstanding", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	if (PK.currentEvent or {}).id == "lastmanstanding" then
		PK.currentEvent:End()
		return
	end

	local success, err = event:Start()
	if not success then
		ply:PrintMessage(HUD_PRINTCONSOLE, tostring(err))
	end
end)
