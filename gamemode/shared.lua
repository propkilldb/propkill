GM.Name = "Propkill"
GM.Author = "Iced Coffee & Almighty Laxz"
GM.Email = "N/A"
GM.Website = "N/A"
GM.TeamBased = false

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
