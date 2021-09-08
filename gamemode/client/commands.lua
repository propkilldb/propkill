pk_leaderboard = {}
pk_matchhistory = {}

function PK_RequestLeaderboard()
	net.Start("pk_leaderboard")
	net.SendToServer()
	print("Requesting leaderboard...")
end

net.Receive("pk_leaderboard", function()
	pk_leaderboard = net.ReadTable()
	print("Leaderboard updated!")
end)

function PK_RequestMatchHistory()
	net.Start("pk_matchhistory")
	net.SendToServer()
	print("Requesting match history...")
end

net.Receive("pk_matchhistory", function()
	pk_matchhistory = net.ReadTable()
	print("Match history updated!")
end)

function PK_ToggleWeaponSelect(ply, cmd, args)
	if istable(BlockedHUDElements) then
		BlockedHUDElements["CHudWeaponSelection"] = !BlockedHUDElements["CHudWeaponSelection"]
		if BlockedHUDElements["CHudWeaponSelection"] then
			ply:ChatPrint("Disabled weapon select")
		else
			ply:ChatPrint("Enabled weapon select")
		end
	end
end
concommand.Add("pk_toggleweaponselect", PK_ToggleWeaponSelect)