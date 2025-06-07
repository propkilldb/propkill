GM.Name = "Propkill"
GM.Author = "Iced Coffee & Almighty Laxz"
GM.Email = "N/A"
GM.Website = "N/A"
GM.TeamBased = true

DeriveGamemode("sandbox")

PK = PK or {
	debug = true, // enable or disable prints from dprint
	config = {},
	arenas = {},
}

function GM:CreateTeams()
	TEAM_DEATHMATCH = 1
	TEAM_SPECTATOR = 2
	team.SetUp(TEAM_DEATHMATCH, "Deathmatch", Color(0, 235, 20, 255))
	team.SetUp(TEAM_SPECTATOR, "Spectator", Color(120, 120, 120, 255))
end

// modules
AddCSLuaFile("modules/autoundo.lua")
include("modules/autoundo.lua")
AddCSLuaFile("modules/spawnfix.lua")
include("modules/spawnfix.lua")


--remove bhop clamp
local base = baseclass.Get('player_sandbox')
base['FinishMove'] = function() end
baseclass.Set('player_sandbox', base)

hook.Add("ShouldCollide", "noteamcollide", function(ent, ent2)
	if IsValid(ent) and ent:IsPlayer() and IsValid(ent2) and ent2:IsPlayer() then
		return false
	end
	if IsValid(ent) and ent:GetClass() == "ent_pos" or IsValid(ent2) and ent2:GetClass() == "ent_pos" then
		return false
	end
end)

function PrettyTime(seconds)
	local timestr = ""

	if seconds >= 60 then
		timestr = string.NiceTime(seconds) .. ", "
	end
	
	return timestr .. string.NiceTime(seconds % 60)
end
