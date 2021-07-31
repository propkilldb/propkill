util.AddNetworkString("pk_duelinvite")

function requestSyncDuel(ply, opponent, kills, time)
	if sync.sendqueue[sync.duelinvite] == nil then sync.sendqueue[sync.duelinvite] = {} end
	if not IsValid(ply) or not IsValid(opponent) then return end

	local data = {
		initiator = ply:GetCreationID(),
		opponent = opponent:GetCreationID(),
		kills = kills or 15,
		time = time or 10,
	}

	table.insert(sync.sendqueue[sync.duelinvite], data)
end

net.Receive("pk_duelinvite", function(len, ply)
	local opponent = net.ReadEntity()
	local kills = net.ReadInt(8)
	local time = net.ReadInt(8)

	kills = math.Clamp(kills or 15, 1, 60)
	time = math.Clamp(time or 10, 1, 30)

	requestSyncDuel(ply, opponent, kills, time)
end)
