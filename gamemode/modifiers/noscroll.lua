
hook.Add("StartCommand", "noscroll modifier", function(ply, cmd)
	if not PK.GetNWVar("noscrollmode", false) then return end

	cmd:SetMouseWheel(0)
end)

concommand.Add("noscroll", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	PK.SetNWVar("noscrollmode", not PK.GetNWVar("noscrollmode", false))

	ChatMsg({
		Color(0,120,255), "NoScroll",
		Color(255,255,255), " mode ",
		Color(255,255,255), (PK.GetNWVar("noscrollmode", false) and "enabled" or "disabled"),
	})

	for k,v in next, player.GetAll() do 
		v:SetNW2Int("PKSurfs", 1)
	end
end)
