
hook.Add("PlayerCheckLimit", "landmine mode", function(ply, name, cur, limit)
	if not PK.GetNWVar("landminemode", false) then return end

	-- this will probably break on anything other than propkill
	if cur >= limit then
		for k,v in pairs(undo.GetTable()[ply:UniqueID()]) do
			if IsValid(v.Entities[1]) then
				v.Entities[1]:Remove()
				break
			end
		end
	end
	
	return true
end)

hook.Add("CanUndo", "landmine mode", function(ply, tbl)
	if not PK.GetNWVar("landminemode", false) then return end
	return false
end)

concommand.Add("landmine", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	PK.SetNWVar("landminemode", not PK.GetNWVar("landminemode", false))

	ChatMsg({
		Color(0,120,255), "Landmine",
		Color(255,255,255), " mode ",
		Color(255,255,255), (PK.GetNWVar("landminemode", false) and "enabled" or "disabled"),
	})
end)
