
local event = newEvent("lastmanstanding", "Last Man Standing", {
	joinable = false,
	minplayers = 2,
})

event:Hook("PlayerDeath", "kick dead noob out to spectator", function(ply)
	ply.lives = (ply.lives or 1) - 1
	ply:SetNW2Int("livesleft", ply.lives)

	if ply.lives <= 0 then
		ply:SetSpectating(nil, true)
		ply.battling = false
	end

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

event:Hook("PlayerDeathThink", "force respawn", function(ply)
	if not IsValid(ply) then return end
	if ply:IsSpectating() then return end
	
	if ply.DeathTime + 5 < CurTime() then
		ply:Spawn()
	end
end)

event:OnSetup(function(lives)
	for k, ply in next, event.players do
		ply.battling = true
		ply.lives = lives
		ply:SetNW2Int("livesleft", lives)
	end

	PK.SetNWVar("liveshud", true)

	ChatMsg({
		Color(0,120,255), "Last Man Standing",
		Color(255,255,255), " event with " .. lives .. (lives == 1 and " life" or " lives") .. " starting...",
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

	PK.SetNWVar("liveshud", false)
end)

concommand.Add("lastmanstanding", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	if (PK.currentEvent or {}).id == "lastmanstanding" then
		PK.currentEvent:End()
		return
	end


	local lives = tonumber(args[1])
	if not isnumber(lives) then
		lives = 1
	end

	local success, err = event:Start(lives)
	if not success then
		ply:PrintMessage(HUD_PRINTCONSOLE, tostring(err))
	end
end)
