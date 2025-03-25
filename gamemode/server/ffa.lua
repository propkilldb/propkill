
local event = newEvent("ffa")

event:Hook("PlayerDeath", "end condition checking", function(ply, inflictor, attacker)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	
	if attacker:Frags() == event.kills then
		event:End(attacker)
	end
end)

event:StartFunc(function(kills)
	if #player.GetAll() < 2 then
		return false, "not enough players"
	end
	event.kills = tonumber(kills or 30)

	for k, ply in next, player.GetAll() do
		if ply:Team() != TEAM_DEATHMATCH then continue end
		ply:Spawn()
		ply:CleanUp()
		ply:Freeze(true)
		ply:SetFrags(0)
	end
	
	timer.Simple(2, function()
		for k, ply in next, player.GetAll() do
			ply:Freeze(false)
		end

		ChatMsg({
			Color(0,120,255), "Free For All",
			Color(255,255,255), " GO!!!",
		})
	end)

	ChatMsg({
		Color(0,120,255), "Free For All",
		Color(255,255,255), " event to ",
		Color(0,120,255), tostring(event.kills),
		Color(255,255,255),  " kills starting...",
	})

	ResetKillstreak()

	return true
end)

event:EndFunc(function(winner)
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

	timer.Simple(2, function()
		for k,v in next, player.GetAll() do
			if v:Team() != TEAM_DEATHMATCH then continue end
			v:CleanUp()
			v:Spawn()
		end
	
		ResetKillstreak()
	end)
end)

concommand.Add("ffa", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	if (PK.currentEvent or {}).name == "ffa" then
		PK.currentEvent:End()
		return
	end

	local kills = tonumber(args[1])

	local success, err = event:Start(kills)
	if not success then
		ply:PrintMessage(HUD_PRINTCONSOLE, tostring(err))
	end
end)
