
local event = newEvent("propgame")
local proplists = {
	{
		"models/props_canal/canal_bars004.mdl",
		"models/props/cs_militia/refrigerator01.mdl",
		"models/props/de_port/cargo_container01.mdl",
		"models/props_junk/bicycle01a.mdl",
		"models/props/cs_militia/bathroomwallhole01_tile.mdl",
		"models/props_junk/wheebarrow01a.mdl",
		"models/props_c17/statue_horse.mdl",
		"models/props_c17/playground_carousel01.mdl",
		"models/props/cs_militia/skylight_glass.mdl",
		"models/props_lab/cactus.mdl",
		"models/props_trainstation/light_256ceilingmounted001a.mdl",
		"models/props/de_train/utility_truck.mdl",
		"models/props_junk/gascan001a.mdl",
		"models/mechanics/wheels/wheel_spike_48.mdl",
		"models/props/de_tides/gate_large.mdl",
		"models/props_junk/watermelon01.mdl",
	},
	{
		"models/props/cs_militia/stove01.mdl",
		"models/props_phx/construct/concrete_pipe01.mdl",
		"models/props/de_tides/vending_cart.mdl",
		"models/props_junk/watermelon01.mdl",
		"models/props_debris/walldestroyed01a.mdl",
		"models/props_phx/construct/metal_plate4x4.mdl",
		"models/props/de_inferno/chimney01.mdl",
		"models/props_phx/misc/soccerball.mdl",
		"models/props/de_train/lockers_long.mdl",
		"models/props_phx/facepunch_logo.mdl",
		"models/props_vehicles/car002b.mdl",
		"models/props_phx/mk-82.mdl",
		"models/weapons/w_crowbar.mdl",
		"models/props_citizen_tech/guillotine001a_base01.mdl",
		"models/props/CS_militia/dryer.mdl",
		"models/props/de_inferno/goldfish.mdl",
	},
	{
		"models/props_vehicles/apc_tire001.mdl",
		"models/props/cs_italy/it_wndc2.mdl",
		"models/props/cs_assault/moneypallet02a.mdl",
		"models/maxofs2d/logo_gmod_b.mdl",
		"models/props/de_tides/vending_turtle.mdl",
		"models/props_phx/construct/wood/wood_angle360.mdl",
		"models/props_c17/gaspipes006a.mdl",
		"models/props_c17/furniturearmchair001a.mdl",
		"models/props_combine/combineinnerwall001c.mdl",
		"models/props_canal/canal_cap001.mdl",
		"models/props_debris/wood_board06a.mdl",
		"models/props/cs_militia/van.mdl",
		"models/props_phx/games/chess/white_rook.mdl",
		"models/props_trainstation/payphone001a.mdl",
		"models/props_wasteland/prison_celldoor001b.mdl",
		"models/items/item_item_crate.mdl",
		"models/props_phx/misc/potato_launcher_explosive.mdl",
		"models/props/cs_assault/barrelwarning.mdl",
		"models/xqm/jetbody3.mdl",
		"models/props/de_tides/menu_stand_p05.mdl",
	}
}

event:Hook("PlayerChangedTeam", "let people not play", function(ply, oldteam, newteam)
	if newteam == TEAM_DEATHMATCH then
		ply.battling = true
		ply.level = 1
	else
		ply.battling = false
	end
end)

event:Hook("PlayerDeath", "who killed who", function(ply, inflictor, attacker)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	attacker.level = attacker.level or 1

	// suicide
	if ply == attacker then
		attacker.level = math.max(attacker.level - 1, 1)
		return
	end

	// force them to get a kill with the final prop		
	if attacker.level == #event.proplist and IsValid(inflictor) and inflictor:GetModel() != event.proplist[#event.proplist] then
		return
	end

	attacker.level = attacker.level + 1
	
	if attacker.level == #event.proplist then
		ChatMsg({
			Color(0,120,255), attacker:Nick(),
			Color(255,255,255), " is on last level!!",
		})

		attacker:CleanUp()
	end

	// clean up props from previous levels 1 second after they level up
	timer.Create("propgame_cleanup_" .. attacker:SteamID(), 1, 1, function()
		if not IsValid(attacker) then return end
		local currentmodel = event.proplist[attacker.level]

		for k, ent in ipairs(attacker:GetProps()) do
			if not IsValid(ent) then continue end
			if ent:GetModel() != currentmodel then
				ent:Remove()
			end
		end
	end)

	if attacker.level > #event.proplist then
		event:End(attacker)
	end
end)

event:Hook("PlayerInitialSpawn", "add late joiners to the battle", function(ply)
	ply.battling = true
	ply.level = 1
end)

event:StartFunc(function(proplist)
	if #player.GetAll() < 2 then
		return false, "not enough players"
	end

	for k, ply in next, player.GetAll() do
		if ply:Team() != TEAM_DEATHMATCH then continue end
		ply:Spawn()
		ply.battling = true
		ply.level = 1
		ply:CleanUp()
		ply:Freeze(true)
		ply:SetFrags(0)
		ply:SetDeaths(0)
	end

	event.proplist = proplist

	-- kinda hacky, but it works i guess
	event.CCSpawn = CCSpawn
	CCSpawn = function(ply, cmd, args, str)
		args[1] = event.proplist[ply.level or 1] or ""
		return event.CCSpawn(ply, cmd, args, str)
	end
	
	timer.Simple(2, function()
		for k, ply in next, player.GetAll() do
			ply:Freeze(false)
		end

		ChatMsg({
			Color(0,120,255), "PropGame",
			Color(255,255,255), " STARTED!",
		})
	end)

	ChatMsg({
		Color(0,120,255), "PropGame",
		Color(255,255,255), " event starting with " .. tostring(#event.proplist) .. " levels",
	})

	ResetKillstreak()

	return true
end)

event:EndFunc(function(winner)
	if IsValid(winner) then
		ChatMsg({
			Color(0,120,255), winner:Nick(),
			Color(255,255,255), " has proven to be the melon king by winning the ",
			Color(0,120,255), "PropGame",
			Color(255,255,255), " event",
		})
	else
		ChatMsg({
			Color(0,120,255), "PropGame",
			Color(255,255,255), " event ended",
		})
	end

	CCSpawn = event.CCSpawn

	timer.Simple(2, function()
		for k,v in next, player.GetAll() do
			if v:Team() != TEAM_DEATHMATCH then continue end
			v:CleanUp()
			v.battling = false
			v:Spawn()
		end
	
		ResetKillstreak()
	end)
end)

concommand.Add("propgame", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	if (PK.currentEvent or {}).name == "propgame" then
		PK.currentEvent:End()
		return
	end

	local proplist = proplists[1]

	local listnum = tonumber(args[1])
	if isnumber(listnum) and proplists[listnum] then
		proplist = proplists[listnum]
	end

	local success, err = event:Start(proplist)
	if not success then
		ply:PrintMessage(HUD_PRINTCONSOLE, tostring(err))
	end
end)
