/*------------------------------------------
				Propkill init
------------------------------------------*/

/*------------------------------------------
				Includes
------------------------------------------*/

include("shared.lua")
include("shared/entity.lua")
include("shared/networking.lua")
include("server/player.lua")
include("server/entity.lua")
include("server/base.lua")
include("server/spectating.lua")
include("server/events.lua")
include("server/antilag.lua")
include("server/challonge.lua")

// events
include("events/duels.lua")
include("events/duelmaster.lua")
include("events/propgame.lua")
include("events/lastmanstanding.lua")
include("events/ffa.lua")
include("events/tournamentduel.lua")
include("events/timelord.lua")

// modifiers
include("modifiers/onesurf.lua")
AddCSLuaFile("modifiers/onesurf.lua")
include("modifiers/noscroll.lua")
include("modifiers/invertedscroll.lua")
include("modifiers/landmine.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("client/duels.lua")
AddCSLuaFile("client/hudmanager.lua")
AddCSLuaFile("client/hud.lua")
AddCSLuaFile("client/hax.lua")
AddCSLuaFile("client/derma.lua")
AddCSLuaFile("client/base.lua")
AddCSLuaFile("client/tournaments.lua")

AddCSLuaFile("shared/entity.lua")
AddCSLuaFile("shared/networking.lua")

// modules
AddCSLuaFile("modules/bindmenu.lua")

// Scoreboard/Menu
AddCSLuaFile("client/scoreboard/frame.lua")
AddCSLuaFile("client/scoreboard/scoreboard.lua")
AddCSLuaFile("client/scoreboard/leaderboard.lua")
AddCSLuaFile("client/scoreboard/settings.lua")
AddCSLuaFile("client/scoreboard/duel.lua")
AddCSLuaFile("client/scoreboard/tournament.lua")
AddCSLuaFile("client/scoreboard/director.lua")

function GM:Initialize()
	LogPrint("Initializing...")
end
