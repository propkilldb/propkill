
hook.Add("StartCommand", "inverted scroll modifier", function(ply, cmd)
	if not PK.GetNWVar("invertedscrollmode", false) then return end

	cmd:SetMouseWheel(-cmd:GetMouseWheel())
end)

concommand.Add("invertedscroll", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	PK.SetNWVar("invertedscrollmode", not PK.GetNWVar("invertedscrollmode", false))

	ChatMsg({
		Color(0,120,255), "InvertedScroll",
		Color(255,255,255), " mode ",
		Color(255,255,255), (PK.GetNWVar("invertedscrollmode", false) and "enabled" or "disabled"),
	})
end)
