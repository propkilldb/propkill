PK.tournamentinfo = PK.tournamentinfo or {}

hook.Add("InitPostEntity", "please notify me of tournament happenings", function()
	net.Start("pk_tournementnotify")
	net.SendToServer()
end)

net.Receive("pk_tournementnotify", function()
	local name = net.ReadString()
	local state = net.ReadString()
	local date = net.ReadInt(32)

	PK.tournamentinfo = {
		name = name,
		state = state,
		date = date
	}

	if state != "open" then
		return
	end

	ShowTournamentInvite(name, date)
end)

function ShowTournamentInvite(name, date)
	if date < os.time() then return end -- already passed

	local lastdismiss = LocalPlayer():GetPData("tournamentinvitedismissed", 0)
	if os.time() - tonumber(lastdismiss) < 172800 then -- show again in 2 days
		return
	end

	if IsValid(tournyinvpanel) and ispanel(tournyinvpanel) then
		tournyinvpanel:Remove()
		tournyinvpanel = nil
	end

	tournyinvpanel = vgui.Create("pk_tournamentinvite")
	tournyinvpanel:SetInfo(name, date)
	function tournyinvpanel:DoAccept()
		net.Start("pk_tournamentenroll")
		net.SendToServer()
		LocalPlayer():SetPData("tournamentinvitedismissed", date - 172800)
		tournyinvpanel:Remove()
	end
	function tournyinvpanel:DoClose()
		LocalPlayer():SetPData("tournamentinvitedismissed", os.time())
		tournyinvpanel:Remove()
	end
end
