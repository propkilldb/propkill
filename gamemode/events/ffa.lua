
local event = newEvent("ffa", "Free For All", {
	minplayers = 2
})

event:Hook("PlayerDeath", "end condition checking", function(ply, inflictor, attacker)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	
	if attacker:Frags() == event.kills then
		event:End(attacker)
	end
end)

event:OnSetup(function(kills)
	event.kills = tonumber(kills or 30)

	ChatMsg({
		Color(0,120,255), "Free For All",
		Color(255,255,255), " event to ",
		Color(0,120,255), tostring(event.kills),
		Color(255,255,255),  " kills starting...",
	})

	return true
end)

event:OnGameStart(function()
	ChatMsg({
		Color(0,120,255), "Free For All",
		Color(255,255,255), " GO!!!",
	})
end)

event:OnGameEnd(function(winner)
	if IsValid(winner) then
		ChatMsg({
			Color(0,120,255), winner:Nick(),
			Color(255,255,255), " is the new #1 global propkiller from winning the ",
			Color(0,120,255), "Free For All",
			Color(255,255,255), " event",
		})
	else
		ChatMsg({
			Color(0,120,255), "Free For All",
			Color(255,255,255), " event ended",
		})
	end
end)

event:OnCleanup(function()
	-- nothing needs to be done anymore???
end)

concommand.Add("ffa", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	if (PK.currentEvent or {}).id == "ffa" then
		PK.currentEvent:End()
		return
	end

	local kills = tonumber(args[1])

	local success, err = event:Start(kills)
	if not success then
		ply:PrintMessage(HUD_PRINTCONSOLE, tostring(err))
	end
end)
