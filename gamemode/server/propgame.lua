
local event = newEvent("propgame")
local proplist = {
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
}

event:Hook("PlayerChangedTeam", "battlers cant spectate", function(ply, oldteam, newteam)
	if newteam == TEAM_DEATHMATCH then
		ply.battling = true
		ply.level = 1
	else
		ply.battling = false
	end
end)

event:Hook("PlayerDeath", "who killed who", function(ply, inflictor, attacker)
	attacker.level = (attacker.level or 1) + 1
	
	if attacker.level == #proplist then
		ChatMsg({
			Color(0,120,255), attacker:Nick(),
			Color(255,255,255), " is on last level!!",
		})
	end

	if attacker.level > #proplist then
		event:End(attacker)
	end
end)

event:Hook("PlayerInitialSpawn", "add late joiners to the battle", function(ply)
	ply.battling = true
end)

event:StartFunc(function()
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
	end

	-- kinda hacky, but it works i guess
	event.CCSpawn = CCSpawn
	CCSpawn = function(ply, cmd, args, str)
		args[1] = proplist[ply.level or 1] or ""
		return event.CCSpawn(ply, cmd, args, str)
	end
	
	timer.Simple(2, function()
		for k, ply in next, player.GetAll() do
			ply:Freeze(false)
		end

		ChatMsg({
			//Color(255,255,255), "[",
			Color(0,120,255), "PropGame",
			//Color(255,255,255), "]",
			Color(255,255,255), " STARTED!",
		})
	end)

	ChatMsg({
		//Color(255,255,255), "[",
		Color(0,120,255), "PropGame",
		//Color(255,255,255), "]",
		Color(255,255,255), " event starting...",
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

	timer.Simple(2, function()
		CCSpawn = event.CCSpawn

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

	local success, err = event:Start()
	if not success then
		ply:PrintMessage(HUD_PRINTCONSOLE, tostring(err))
	end
end)
