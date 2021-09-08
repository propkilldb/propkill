concommand.Add("rserver", function(ply)
	if ply == NULL or ply:IsSuperAdmin() then
		RunConsoleCommand("changelevel", game.GetMap(), engine.ActiveGamemode())
	end
end)

/*function ChangeTeam(ply, cmd, args)
	local teamindex = tonumber(args[1])

	if CurTime() - ply.lastTeamChange < 2 then return end
	if not team.Valid(teamindex) then return end
	if ply:Team() == teamindex then return end
	if teamindex > 1000 and teamindex < 0 then return end

	ply.lastTeamChange = CurTime()
	ply:SetTeam(teamindex)
	ply:Spawn()
end
concommand.Add("pk_team", ChangeTeam)*/
