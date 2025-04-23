hook.Add("PlayerSpawnedProp", "pk_setpropowner", function(ply, model, ent)
	ent.Owner = ply
	ent:SetNWEntity("Owner", ply)
	ent:SetNW2Entity("Owner", ply)
end)

function GM:OnPhysgunReload() return false end
function GM:PlayerSpawnSENT(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnSWEP(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerGiveSWEP(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnEffect(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnVehicle(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnNPC(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnRagdoll(ply) Notify(ply, "You can only spawn props!") return false end

hook.Add("PlayerSpawnProp", "pk_canspawnprop", function(ply, model)
	if not ply:Alive() then
		return false
	end

	if ply:IsSpectating() then
		return false
	end
end)

function GM:InitPostEntity()
	physenv.SetPerformanceSettings({
		LookAheadTimeObjectsVsObject = 0.5,
		LookAheadTimeObjectsVsWorld = 1,
		MaxAngularVelocity = 3636,
		MaxCollisionChecksPerTimestep = 500,
		MaxCollisionsPerObjectPerTimestep = 10,
		MaxFrictionMass = 1,
		MaxVelocity = 2200,
		MinFrictionMass = 10,
	})

	game.ConsoleCommand("physgun_DampingFactor 1\n")
	game.ConsoleCommand("physgun_timeToArrive 0.033\n")
	game.ConsoleCommand("sv_sticktoground 0\n")
	game.ConsoleCommand("sv_airaccelerate 2000\n")
	game.ConsoleCommand("collision_shake_amp 0\n")

	local tickrate = math.Round(1/engine.TickInterval(), 5)
	if tickrate != 66.66667 then
		MsgC(Color(255,255,255), "[Propkill]", Color(255,0,0), " WARNING", Color(255,255,255), ": tickrate is wrong, boosting+surfing will not work properly, props will clip into players. to fix, remove -tickrate from the launch option, or set it to 0. setting it to 66 will not work.\n")
	end
end

hook.Add("CanProperty", "block all properties", function(ply, property, ent)
	return ply:IsAdmin()
end)
