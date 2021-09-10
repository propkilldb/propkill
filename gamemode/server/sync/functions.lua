function bytestoint(b1, b2, b3, b4)
    return tonumber(bit.tohex(b4, 2) .. bit.tohex(b3, 2) .. bit.tohex(b2, 2) .. bit.tohex(b1, 2), 16)
end

function packetlength(packet)
	local b1, b2, b3, b4 = string.match(bit.tohex(packet, 8), "(..)(..)(..)(..)")
	return string.char(tonumber(b4, 16), tonumber(b3, 16), tonumber(b2, 16), tonumber(b1, 16))
end

function GetPlayerByIP(ip)
	for k, v in next, player.GetHumans() do
		if v:IPAddress() == ip then
			return v
		end
	end

	return NULL
end

function generateInitialPacket()
	local plys = {}
	local props = {}
	
	for k,v in pairs(player.GetAll()) do
		if not v:IsBot() then
			plys[v:GetCreationID()] = {
				name = v:Name(),
				steamid = v:SteamID(),
				pos = v:GetPos(),
				ang = v:GetAngles(),
				vel = v:GetVelocity(),
				alive = v:Alive(),
				wepcol = v:GetInfo("cl_weaponcolor"),
				color = v:GetInfo("cl_playercolor"),
				model = v:GetInfo("cl_playermodel"),
				team = v:Team()
			}
		end
	end
	
	for k,v in pairs(ents.GetAll()) do
		if IsValid(v) && IsValid(v:GetNW2Entity("Owner", NULL)) then
			props[v:GetCreationID()] = {
				model = v:GetModel(),
				owner = v:GetNW2Entity("Owner"),
				pos = v:GetPos(),
				ang = v:GetAngles(),
				vel = v:GetVelocity()
			}
		end
	end
	
	return util.TableToJSON({[sync.addplayers] = plys, [sync.spawnprops] = props})
end

function GetPlayerByCreationID(id)
	for k,v in pairs(player.GetAll()) do
		if v:GetCreationID() == id then
			return v
		elseif v.SyncedPlayer and v.SyncedPlayer == id then
			return v
		end
	end

	return NULL
end

function GetBotByCreationID(id)
	for k,v in pairs(player.GetBots()) do
		if v.SyncedPlayer == id then
			return v
		end
	end

	return NULL
end

function GetPropByCreationID(id)
	for k,v in pairs(sync.syncedprops) do
		if k == id then
			return v
		end
	end

	for k,v in pairs(sync.propstosync) do
		if k == id then
			return v
		end
	end

	return NULL
end
