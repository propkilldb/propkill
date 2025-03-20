/*------------------------------------------
				Propkill init
------------------------------------------*/

/*------------------------------------------
				Includes
------------------------------------------*/

include("shared.lua")
include("server/player.lua")
include("server/entity.lua")
include("server/base.lua")
include("server/spectating.lua")
include("server/events.lua")
include("server/duels.lua")
include("server/duelmaster.lua")
include("server/lastmanstanding.lua")
include("server/antilag.lua")
include("shared/entity.lua")
include("shared/onesurf.lua")
include("shared/networking.lua")


AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("client/duels.lua")
AddCSLuaFile("client/hud.lua")
AddCSLuaFile("client/hax.lua")
AddCSLuaFile("client/derma.lua")
AddCSLuaFile("client/base.lua")

AddCSLuaFile("shared/entity.lua")
AddCSLuaFile("shared/networking.lua")
AddCSLuaFile("shared/onesurf.lua")

// Scoreboard/Menu
AddCSLuaFile("client/scoreboard/frame.lua")
AddCSLuaFile("client/scoreboard/scoreboard.lua")
AddCSLuaFile("client/scoreboard/leaderboard.lua")
AddCSLuaFile("client/scoreboard/settings.lua")
AddCSLuaFile("client/scoreboard/duel.lua")

function GM:Initialize()
	LogPrint("Initializing...")
end
