/*------------------------------------------
				Propkill init
------------------------------------------*/

/*------------------------------------------
				Includes
------------------------------------------*/

include("shared.lua")
include("server/player.lua")
include("server/entity.lua")
include("server/commands.lua")
include("server/base.lua")
include("server/spectating.lua")
include("shared/entity.lua")
include("shared/networking.lua")


AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("client/hud.lua")
AddCSLuaFile("client/hax.lua")
AddCSLuaFile("client/derma.lua")
AddCSLuaFile("client/base.lua")
AddCSLuaFile("client/commands.lua")
AddCSLuaFile("shared/entity.lua")
AddCSLuaFile("shared/networking.lua")

// Settings
AddCSLuaFile("client/settings/view.lua")
AddCSLuaFile("client/settings/misc.lua")

// Scoreboard/Menu
AddCSLuaFile("client/scoreboard/frame.lua")
AddCSLuaFile("client/scoreboard/scoreboard.lua")
AddCSLuaFile("client/scoreboard/leaderboard.lua")
AddCSLuaFile("client/scoreboard/settings.lua")
AddCSLuaFile("client/scoreboard/duel.lua")

//sync
include("server/sync/socket.lua")
AddCSLuaFile("client/sync.lua")



function GM:Initialize()
	LogPrint("Initializing...")
end

local function spawnProp(ply, model, weight, angle)
	local start = ply:GetShootPos()
	local forward = ply:GetAimVector()
	
	local trace = {}
	trace.start = start
	trace.endpos = start + (forward * 2048)
	trace.filter = ply // dont hit ourselves
	
	local tr = util.TraceLine(trace)
	
	local ent = ents.Create("prop_physics")
	if not IsValid(ent) then return false end
	
	local pos = tr.HitPos // + offset
	
	ent:SetModel(model)
	ent:SetAngles(angle)
	ent:SetPos(tr.HitPos)
	ent:Spawn()
	ent:Activate()
	
	// this is called after the inital spawn pos in commands.lua
	// replace this with a hull trace?
	local flushPoint = pos - (tr.HitNormal * 512)
	flushPoint = ent:NearestPoint(flushPoint)
	flushPoint = ent:GetPos() - flushPoint
	flushPoint = tr.HitPos + flushPoint
	
	ent:SetPos(flushPoint)
	
	gamemode.Call("PlayerSpawnedProp", ply, model, ent)
	
	// add weight
	local phys = ent:GetPhysicsObject()
	if IsValid(phys) and weight != 0 then
		phys:SetMass(weight)	
	end
	
	undo.Create("Prop")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish("Prop (" .. tostring(model) .. ")")
	
	ply:AddCleanup("props", ent)
	
	ply:SendLua("achievements.SpawnedProp()")
end

function PKSpawn(ply, command, args)
	if not IsValid(ply) then return end // dont run as server
	
	if args[1] == nil then // no initial arg, disregard call
		ply:PrintMessage(HUD_PRINTCONSOLE, "pk_spawn <model> <weight> <pitch> <yaw> <roll>")
		return
	end
	if args[1]:find("%.[/\\]") then return end
	
	local model = args[1]
	model = model:gsub("\\\\+", "/")
	model = model:gsub("//+", "/")
	model = model:gsub("\\/+", "/")
	model = model:gsub("/\\+", "/")
		
	if not gamemode.Call("PlayerSpawnObject", ply, model, 0) then return end
	if not util.IsValidModel(model) then return end
	
	local weight = args[2] or 0
	weight = math.Clamp(weight, 0, 5000) // shouldnt exceed 5k, or any limit you wish to set -> maybe add a variable

	local ang = Angle(0, ply:EyeAngles().yaw + 180, 0)
	if args[3] then ang.pitch = ang.pitch + args[3] end
	if args[4] then ang.yaw = ang.yaw + args[4] end
	if args[5] then ang.roll = ang.roll + args[5] end
	
	if util.IsValidProp(model) then
		spawnProp(ply, model, weight, ang)
	end
end

concommand.Add("pk_spawn", PKSpawn)








